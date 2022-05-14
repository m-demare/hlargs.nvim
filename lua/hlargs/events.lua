local M = {}
local parser = require 'hlargs.parse'
local config = require 'hlargs.config'
local util = require 'hlargs.util'
local bufdata = require 'hlargs.bufdata'
local paint = require 'hlargs.paint'

local enabled = false

local function paint_nodes(bufnr, ns, node_group)
  if not node_group then return end
  for _, node in ipairs(node_group) do
    paint(bufnr, ns, node)
  end
end

local function ts_on_change(bufnr)
  return function(changes)
    for _, change in ipairs(changes) do
      M.add_range_to_queue(bufnr, change[1], change[3])
    end
  end
end

local function find_and_paint_iteration(bufnr, task, co)
  local delay = config.opts.performance.parse_delay
  if task.type == bufdata.TaskTypes.SLOW then
    delay = config.opts.performance.slow_parse_delay
  end
  vim.defer_fn(function()
    if coroutine.status(co) ~= "dead" and not task.stop then
      local buf_data = bufdata.get(bufnr)
      local marks_ns = buf_data.marks_ns
      local ts_cb
      if not buf_data.ts_cb_attached then
        ts_cb = ts_on_change(bufnr)
        buf_data.ts_cb_attached = true
      end
      local running, arg_nodes, usage_nodes = coroutine.resume(co, bufnr, marks_ns, task.mark, ts_cb)
      if task.mark then
        -- Mainly to prevent tasks from insert mode from accumulating
        -- Can't do this on new_task because the tasks' marks
        -- get modified during the parsing
        bufdata.stop_older_contained(bufnr, task)
      end
      if running then
        if config.opts.paint_arg_declarations then
          paint_nodes(bufnr, task.ns, arg_nodes)
        end
        paint_nodes(bufnr, task.ns, usage_nodes)
        find_and_paint_iteration(bufnr, task, co)
      end
    else
      if vim.api.nvim_buf_is_valid(bufnr) then
        if not task.stop then
          bufdata.end_task(bufnr, task)
        end
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
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  buf_data.ranges_to_parse = util.merge_ranges(bufnr, buf_data.marks_ns, buf_data.ranges_to_parse)

  if config.opts.performance.max_concurrent_partial_parses ~= 0 and
    #buf_data.ranges_to_parse + #buf_data.tasks > config.opts.performance.max_concurrent_partial_parses
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

  local buf_data = bufdata.get(bufnr)

  -- `merge_ranges` won't be able to get the number under `max_concurrent_partial_parses` anyway,
  -- and creating this many extmarks would be pointless
  if #buf_data.ranges_to_parse + #buf_data.tasks >= config.opts.performance.max_concurrent_partial_parses * 3 then
    M.schedule_total_repaint(bufnr)
    return
  end

  local range = paint.set_extmark(bufnr, buf_data.marks_ns, from, 0, to, 0)
  table.insert(buf_data.ranges_to_parse, range)

  if buf_data.debouncers.range_queue then
    vim.loop.timer_stop(buf_data.debouncers.range_queue)
  end
  local debounce_time = config.opts.performance.debounce.partial_parse
  if string.sub(vim.api.nvim_get_mode().mode, 1, 1) == 'i' then
    -- Higher debouncing for insert mode
    debounce_time = config.opts.performance.debounce.partial_insert_mode
  end
  buf_data.debouncers.range_queue = vim.defer_fn(function ()
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
  if buf_data.debouncers.total_parse then
    vim.loop.timer_stop(buf_data.debouncers.total_parse)
  end
  if ignore_debounce then
    M.find_and_paint_nodes(bufnr, bufdata.TaskTypes.TOTAL)
  else
    buf_data.debouncers.total_parse = vim.defer_fn(function ()
      M.find_and_paint_nodes(bufnr, bufdata.TaskTypes.TOTAL)
    end, config.opts.performance.debounce.total_parse)
  end
end

function M.schedule_slow_repaint(bufnr)
  if not enabled then return end

  local buf_data = bufdata.get(bufnr)
  if buf_data.debouncers.slow_parse then
    vim.loop.timer_stop(buf_data.debouncers.slow_parse)
  end
  buf_data.debouncers.slow_parse = vim.defer_fn(function ()
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
    buf_data.filetype = vim.fn.getbufvar(bufnr, '&filetype')
    if not buf_data.ignore then
      M.schedule_total_repaint(bufnr, true)
    end
  end
  if buf_data.ignore then return end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(ev, bufnr, _, from, old_to, to)
      M.add_range_to_queue(bufnr, from, to)
    end,
    on_reload = function (ev, bufnr)
      M.schedule_total_repaint(bufnr)
    end
  })
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

function M.enable()
  if not enabled then
    enabled = true
    local augroup = vim.api.nvim_create_augroup('Hlargs', { clear = true })
    vim.api.nvim_create_autocmd('BufEnter', { callback = M.buf_enter, group = augroup })
    vim.api.nvim_create_autocmd('FileType', { callback = M.filetype, group = augroup })
    vim.api.nvim_create_autocmd('BufDelete', { callback = M.buf_delete, group = augroup })
    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(b) then
        M.buf_enter({buf = b})
      end
    end
  end
end

function M.disable()
  if enabled then
    enabled = false
    pcall(vim.cmd, "autocmd! Hlargs")
    pcall(vim.cmd, "augroup! Hlargs")

    for bufnr, data in pairs(bufdata.get_all()) do
      bufdata.delete_data(bufnr)
    end
  end
end

function M.toggle()
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

return M

