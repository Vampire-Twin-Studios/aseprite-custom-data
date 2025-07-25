-- order.lua
-- Enum type for order selection (0-10)

local M = {
  options = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }
}

function M.draw(dlg, id, value, onchange)
  dlg:combobox{
    id = id,
    label = "Value",
    option = value or M.options[1],
    options = M.options,
    onchange = onchange
  }
end

function M.getValue(data, id)
  return data[id] or M.options[1]
end

function M.isType(value)
  for _, v in ipairs(M.options) do
    if value == v then return true end
  end
  return false
end

return M
