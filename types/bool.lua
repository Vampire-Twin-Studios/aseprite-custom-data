return {
  draw = function(dlg, id, value, onchange)
    dlg:check{
      id = id,
      label = "Value",
      selected = value == true,
      onclick = onchange
    }
  end,
  getValue = function(data, id)
    return data[id] == true
  end,
  isType = function(value)
    return type(value) == "boolean"
  end
}
