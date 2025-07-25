-- order.lua
-- Enum type for order selection (0-10)
return {
  values = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
  draw = function(dlg, id, value, onchange)
    dlg:combobox{
      id = id,
      label = "Value",
      option = value or "0",
      options = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
      onchange = onchange
    }
  end,
  getValue = function(data, id)
    return data[id]
  end
}
