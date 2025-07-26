-- phase.lua
-- Enum type for phase selection (solo, 1-10). Handy for denoting phases in animation sequences.

local M = {
  options = {
    "Solo",
    "First",
    "Second",
    "Third",
    "Fourth",
    "Fifth",
    "Sixth",
    "Seventh",
    "Eighth",
    "Ninth",
    "Tenth"
  }
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
