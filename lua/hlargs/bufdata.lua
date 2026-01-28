local M = {}
local util = require "hlargs.util"
local paint = require "hlargs.paint"

local data = {} ---@type table<integer, HlArgs.BufData.Data>
local main_ns = vim.api.nvim_create_namespace "hlargs_main"

---@class HlArgs.BufData.Debouncers
---@field range_queue? function
---@field total_parse? function
---@field slow_parse? function

---@class HlArgs.BufData.Task
---@field change_idx integer
---@field mark? integer
---@field ns integer
---@field stop boolean
---@field stopped_tasks? HlArgs.BufData.Task[]
---@field type TaskTypes

---@class HlArgs.BufData.Data
---@field change_idx integer
---@field debouncers HlArgs.BufData.Debouncers
---@field detach? function
---@field filetype? string
---@field ignore? boolean
---@field initialized boolean
---@field marks_ns integer
---@field ranges_to_parse? integer[]
---@field tasks HlArgs.BufData.Task[]
---@field ts_cb_attached boolean

---@enum TaskTypes
M.TaskTypes = { PARTIAL = 1, TOTAL = 2, SLOW = 3 }

---@param bufnr integer
---@return HlArgs.BufData.Data data
function M.get(bufnr)
  local default = { ---@type HlArgs.BufData.Data
    change_idx = 0,
    tasks = {},
    debouncers = {},
    ranges_to_parse = {},
    marks_ns = vim.api.nvim_create_namespace "",
    initialized = false,
    ts_cb_attached = false,
  }
  data[bufnr] = data[bufnr] or default
  return data[bufnr]
end

---@return table<integer, HlArgs.BufData.Data> data
function M.get_all()
  return data
end

---@param bufnr integer
---@param task_type TaskTypes
---@param mark integer
---@return HlArgs.BufData.Task task
function M.new_task(bufnr, task_type, mark)
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

  local task = { ---@type HlArgs.BufData.Task
    change_idx = buf_data.change_idx,
    mark = mark,
    ns = vim.api.nvim_create_namespace "",
    stop = false,
    stopped_tasks = {},
    type = task_type,
  }

  table.insert(buf_data.tasks, task)
  return task
end

---@param bufnr integer
---@return boolean running
function M.total_parse_is_running(bufnr)
  local buf_data = M.get(bufnr)
  for _, t in ipairs(buf_data.tasks) do
    if t.type == M.TaskTypes.TOTAL then return true end
  end
  return false
end

---@param bufnr integer
---@param buf_data HlArgs.BufData.Data
---@param task HlArgs.BufData.Task
local function clean_stopped_tasks(bufnr, buf_data, task)
  if not task.stopped_tasks then return end
  for _, t in ipairs(task.stopped_tasks) do
    if t.mark then vim.api.nvim_buf_del_extmark(bufnr, buf_data.marks_ns, t.mark) end
    paint.clear(bufnr, t.ns)
    clean_stopped_tasks(bufnr, buf_data, t)
  end
end

---@param bufnr integer
---@param task HlArgs.BufData.Task
function M.end_task(bufnr, task)
  local buf_data = M.get(bufnr)
  local limits = nil ---@type nil|{ [1]: integer, [2]: integer }
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
  if vim.tbl_isempty(buf_data.tasks) then
    -- Reset change_idx so that it doesn't grow too much
    -- (Especially for people who never close nvim)
    buf_data.change_idx = 0
  end
end

---@param bufnr integer
---@param task HlArgs.BufData.Task
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

---@param buf_data HlArgs.BufData.Data
local function clean_debouncers(buf_data)
  if buf_data.debouncers.range_queue then buf_data.debouncers.range_queue() end
  if buf_data.debouncers.total_parse then buf_data.debouncers.total_parse() end
  if buf_data.debouncers.slow_parse then buf_data.debouncers.slow_parse() end
end

-- Gets called on disable / BufDelete
---@param bufnr integer
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
  if vim.fn.has "nvim-0.9" ~= 1 then
    vim.pretty_print(data)
    return
  end
  vim.print(data)
end

return M
