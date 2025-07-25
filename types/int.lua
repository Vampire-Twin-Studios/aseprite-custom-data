return {
  draw = function(dlg, id, value, onchange)
    dlg:entry{
      id = id,
      label = "Value",
      text = tostring(value or 0),
      onchange = onchange
    }
  end,
  getValue = function(data, id)
    return tonumber(data[id]) or 0
  end,
  isType = function(value)
    return type(value) == "number" and math.floor(value) == value
  end
}
