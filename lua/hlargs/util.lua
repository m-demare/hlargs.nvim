local M = {}

function M.contains(arr, val)
  for i, value in ipairs(arr) do
      if value == val then
          return true
      end
  end
  return false
end

return M

