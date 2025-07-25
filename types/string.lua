-- types/string.lua
-- String type helper for custom tag data

local stringType = {}

function stringType.draw(dlg, id, value, onchange)
  dlg:entry{
    id = id,
    label = "Value",
    text = value or "",
    onchange = onchange
  }
end

function stringType.getValue(data, id)
  return data[id] or ""
end

return stringType
