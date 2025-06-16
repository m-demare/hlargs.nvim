local M = {}
local parser = require "hlargs.parse"
local config = require "hlargs.config"
local util = require "hlargs.util"
local bufdata = require "hlargs.bufdata"
local paint = require "hlargs.paint"
local async = require "hlargs.async"
local attach = async.attach
local defer = async.defer

local enabled = false

local function paint_nodes(bufnr, ns, node_group, hl_group)
  if not node_group then return end
  for _, node in ipairs(node_group) do
    paint(bufnr, ns, node, hl_group)
  end
end

local function find_and_paint_iteration(bufnr, task, co)
  local delay = config.opts.performance.parse_delay
  if task.type == bufdata.TaskTypes.SLOW then delay = config.opts.performance.slow_parse_delay end
  vim.defer_fn(function()
    if coroutine.status(co) ~= "dead" and not task.stop and vim.api.nvim_buf_is_loaded(bufnr) then
      local buf_data = bufdata.get(bufnr)
      local marks_ns = buf_data.marks_ns
      local running, arg_nodes, unused_arg_nodes, usage_nodes =
        coroutine.resume(co, bufnr, marks_ns, task.mark)
      if task.mark then
        -- Mainly to prevent tasks from insert mode from accumulating
        -- Can't do this on new_task because the tasks' marks
        -- get modified during the parsing
        bufdata.stop_older_contained(bufnr, task)
      end
      if running then
        if config.opts.paint_arg_declarations then paint_nodes(bufnr, task.ns, arg_nodes) end
        if config.opts.extras.unused_args then
          paint_nodes(bufnr, task.ns, unused_arg_nodes, paint.hl_group .. "Unused")
        end
        paint_nodes(bufnr, task.ns, usage_nodes)
        find_and_paint_iteration(bufnr, task, co)
      end
    else
      if vim.api.nvim_buf_is_valid(bufnr) then
        if not task.stop then bufdata.end_task(bufnr, task) end
      else
        bufdata.delete_data(bufnr)
      end
    end
  end, delay)
end

local function is_excluded(bufnr)
  local lang = util.get_lang(bufnr)
  return config.opts.disable(lang, bufnr)
end

function M.find_and_paint_nodes(bufnr, task_type, mark)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not enabled then return end

  local task = bufdata.new_task(bufnr, task_type, mark)
  if not task then return end

  local co = coroutine.create(parser.get_nodes_to_paint)
  find_and_paint_iteration(bufnr, task, co)
end

local function schedule_partial_repaints(bufnr, buf_data)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  buf_data.ranges_to_parse = util.merge_ranges(bufnr, buf_data.marks_ns, buf_data.ranges_to_parse)

  if
    config.opts.performance.max_concurrent_partial_parses ~= 0
    and #buf_data.ranges_to_parse + #buf_data.tasks
      > config.opts.performance.max_concurrent_partial_parses
  then
    for _, mark in ipairs(buf_data.ranges_to_parse) do
      vim.api.nvim_buf_del_extmark(bufnr, buf_data.marks_ns, mark)
    end
    buf_data.ranges_to_parse = {}
    M.schedule_total_repaint(bufnr)
    return
  end

  for _, r in ipairs(buf_data.ranges_to_parse) do
    M.find_and_paint_nodes(bufnr, bufdata.TaskTypes.PARTIAL, r)
  end
  buf_data.ranges_to_parse = {}
  M.schedule_slow_repaint(bufnr)
end

function M.add_range_to_queue(bufnr, from, to)
  if not enabled then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
  if to > buf_line_count then to = buf_line_count end

  local buf_data = bufdata.get(bufnr)

  -- `merge_ranges` won't be able to get the number under `max_concurrent_partial_parses` anyway,
  -- and creating this many extmarks would be pointless
  if
    #buf_data.ranges_to_parse + #buf_data.tasks
    >= config.opts.performance.max_concurrent_partial_parses * 3
  then
    M.schedule_total_repaint(bufnr)
    return
  end

  local ok, range = paint.set_extmark(bufnr, buf_data.marks_ns, from, 0, to, 0)
  if ok then
    -- If it failed for some reason, the slow_parse
    -- will have to take care of it
    table.insert(buf_data.ranges_to_parse, range)
  end

  if buf_data.debouncers.range_queue then buf_data.debouncers.range_queue() end
  local debounce_time = config.opts.performance.debounce.partial_parse
  if string.sub(vim.api.nvim_get_mode().mode, 1, 1) == "i" then
    -- Higher debouncing for insert mode
    debounce_time = config.opts.performance.debounce.partial_insert_mode
  end
  buf_data.debouncers.range_queue = defer(function()
    schedule_partial_repaints(bufnr, buf_data)
  end, debounce_time)
end

function M.schedule_total_repaint(bufnr, ignore_debounce)
  if not enabled then return end
  if bufdata.total_parse_is_running(bufnr) then
    -- Don't want to run multiple total repaints simultaneously
    M.schedule_slow_repaint(bufnr)
    return
  end

  local buf_data = bufdata.get(bufnr)
  if buf_data.debouncers.total_parse then buf_data.debouncers.total_parse() end
  local debounce_time = ignore_debounce and 100 or config.opts.performance.debounce.total_parse
  buf_data.debouncers.total_parse = defer(function()
    M.find_and_paint_nodes(bufnr, bufdata.TaskTypes.TOTAL)
  end, debounce_time)
end

function M.schedule_slow_repaint(bufnr)
  if not enabled then return end

  local buf_data = bufdata.get(bufnr)
  if buf_data.debouncers.slow_parse then buf_data.debouncers.slow_parse() end
  buf_data.debouncers.slow_parse = defer(function()
    M.find_and_paint_nodes(bufnr, bufdata.TaskTypes.SLOW)
  end, config.opts.performance.debounce.slow_parse)
end

function M.buf_enter(data)
  local bufnr = data.buf
  if is_excluded(bufnr) then return end
  local buf_data = bufdata.get(bufnr)
  if not buf_data.initialized then
    buf_data.initialized = true
    local lang = util.get_lang(bufnr)
    buf_data.ignore = not util.is_supported(lang)
    if buf_data.ignore then return end
    buf_data.filetype = vim.fn.getbufvar(bufnr, "&filetype")

    M.schedule_total_repaint(bufnr, true)

    buf_data.detach = attach(bufnr, {
      on_lines = function(ev, bufnr, _, from, old_to, to)
        vim.schedule(function()
          M.add_range_to_queue(bufnr, from, to)
        end)
      end,
      on_reload = function(ev, bufnr)
        vim.schedule(function()
          M.schedule_total_repaint(bufnr)
        end)
      end,
    })
  end
end

function M.filetype(data)
  local bufnr = data.buf
  local ft = data.match
  local buf_data = bufdata.get(bufnr)
  if buf_data.initialized and buf_data.filetype ~= ft then
    M.buf_delete(data)
    M.buf_enter(data)
  end
end

function M.buf_delete(data)
  local bufnr = data.buf
  bufdata.delete_data(bufnr)
end

function M.external_file_change(data)
  M.buf_delete(data)
  M.buf_enter(data)
end

function M.enable()
  if not enabled then
    enabled = true
    local augroup = vim.api.nvim_create_augroup("Hlargs", { clear = true })
    local create_autocmd = vim.api.nvim_create_autocmd
    create_autocmd("BufEnter", { callback = M.buf_enter, group = augroup })
    create_autocmd("FileType", { callback = M.filetype, group = augroup })
    create_autocmd("BufDelete", { callback = M.buf_delete, group = augroup })
    create_autocmd("FileChangedShellPost", { callback = M.external_file_change, group = augroup })
    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(b) then M.buf_enter { buf = b } end
    end
  end
end

function M.disable()
  if enabled then
    enabled = false
    vim.api.nvim_clear_autocmds { group = "Hlargs" }

    for bufnr, _ in pairs(bufdata.get_all()) do
      bufdata.delete_data(bufnr)
    end
  end
end

local function validate_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    error("Invalid buffer number " .. tostring(bufnr))
  end
end

function M.enable_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  validate_bufnr(bufnr)

  M.buf_delete { buf = bufnr }
  M.buf_enter { buf = bufnr }
end

function M.disable_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  validate_bufnr(bufnr)

  -- Remove current highlights
  M.buf_delete { buf = bufnr }

  -- Prevent from reattaching
  local buf_data = bufdata.get(bufnr)
  buf_data.initialized = true
  buf_data.ignore = true
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
