local M = {}
local util = require "hlargs.util"
local paint = require "hlargs.paint"

local data = {}
local main_ns = vim.api.nvim_create_namespace "hlargs_main"

M.TaskTypes = {
  PARTIAL = 1,
  TOTAL = 2,
  SLOW = 3,
}

function M.get(bufnr)
  data[bufnr] = data[bufnr]
    or {
      change_idx = 0,
      tasks = {},
      debouncers = {},
      ranges_to_parse = {},
      marks_ns = vim.api.nvim_create_namespace "",
      initialized = false,
      ts_cb_attached = false,
    }
  return data[bufnr]
end

function M.get_all()
  return data
end

function M.new_task(bufnr, type, mark)
  local buf_data = M.get(bufnr)
  if buf_data.ignore then
    error(
      "Attempting to create task of type "
        .. tostring(type)
        .. " in invalid buffer "
        .. tostring(bufnr)
    )
  end
  buf_data.change_idx = buf_data.change_idx + 1

  local task = {
    mark = mark,
    change_idx = buf_data.change_idx,
    ns = vim.api.nvim_create_namespace "",
    stop = false,
    type = type,
    stopped_tasks = {},
  }

  table.insert(buf_data.tasks, task)
  return task
end

function M.total_parse_is_running(bufnr)
  local buf_data = M.get(bufnr)
  for _, t in ipairs(buf_data.tasks) do
    if t.type == M.TaskTypes.TOTAL then return true end
  end
  return false
end

local function clean_stopped_tasks(bufnr, buf_data, task)
  if not task.stopped_tasks then return end
  for _, t in ipairs(task.stopped_tasks) do
    if t.mark then vim.api.nvim_buf_del_extmark(bufnr, buf_data.marks_ns, t.mark) end
    paint.clear(bufnr, t.ns)
    clean_stopped_tasks(bufnr, buf_data, t)
  end
end

function M.end_task(bufnr, task)
  local buf_data = M.get(bufnr)
  local limits = nil
  if task.mark and vim.api.nvim_buf_is_loaded(bufnr) then
    local from, to = util.get_marks_limits(bufnr, buf_data.marks_ns, task.mark)
    limits = { from, to + 1 }
  end

  for _, t in ipairs(buf_data.tasks) do
    if t.change_idx < task.change_idx then
      paint.clear(bufnr, t.ns, limits)
      paint.combine_nss(bufnr, t.ns, task.ns, limits)
    end
  end

  -- Merge changes to main
  paint.clear(bufnr, main_ns, limits)
  paint.combine_nss(bufnr, main_ns, task.ns, limits)
  paint.clear(bufnr, task.ns)

  if task.mark then vim.api.nvim_buf_del_extmark(bufnr, buf_data.marks_ns, task.mark) end
  clean_stopped_tasks(bufnr, buf_data, task)
  for i = #buf_data.tasks, 1, -1 do
    if buf_data.tasks[i] == task then table.remove(buf_data.tasks, i) end
  end
  if #buf_data.tasks == 0 then
    -- Reset change_idx so that it doesn't grow too much
    -- (Especially for people who never close nvim)
    buf_data.change_idx = 0
  end
end

function M.stop_older_contained(bufnr, task)
  if not vim.api.nvim_buf_is_loaded(bufnr) then return end
  local buf_data = M.get(bufnr)
  local range_start, range_end = util.get_marks_limits(bufnr, buf_data.marks_ns, task.mark)
  for _, t in ipairs(buf_data.tasks) do
    if t.change_idx < task.change_idx and t.mark then
      local t_start, t_end = util.get_marks_limits(bufnr, buf_data.marks_ns, task.mark)
      if t_start >= range_start and t_end <= range_end then
        t.stop = true
        -- I remove it from the tasklist, but keep a reference
        -- to it to later clean the namespaces
        table.insert(task.stopped_tasks, t)
        for i = #buf_data.tasks, 1, -1 do
          if buf_data.tasks[i] == t then table.remove(buf_data.tasks, i) end
        end
      end
    end
  end
end

local function clean_debouncers(buf_data)
  if buf_data.debouncers.range_queue then buf_data.debouncers.range_queue() end
  if buf_data.debouncers.total_parse then buf_data.debouncers.total_parse() end
  if buf_data.debouncers.slow_parse then buf_data.debouncers.slow_parse() end
end

-- Gets called on disable / BufDelete
function M.delete_data(bufnr)
  if data[bufnr] == nil then return end
  for _, t in ipairs(data[bufnr].tasks) do
    t.stop = true
    if vim.api.nvim_buf_is_valid(bufnr) then
      if t.mark then vim.api.nvim_buf_del_extmark(bufnr, data[bufnr].marks_ns, t.mark) end
      paint.clear(bufnr, t.ns)
    end
  end
  if vim.api.nvim_buf_is_valid(bufnr) then paint.clear(bufnr, main_ns) end
  clean_debouncers(data[bufnr])
  if data[bufnr].detach then data[bufnr].detach() end
  data[bufnr] = nil
end

function M.debug()
  vim.pretty_print(data)
end

return M
