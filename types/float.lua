return {
  draw = function(dlg, id, value, onchange)
    dlg:entry{
      id = id,
      label = "Value",
      text = tostring(value or ""),
      onchange = onchange
    }
  end,
  getValue = function(data, id)
    local v = tonumber(data[id])
    if v then
      return v
    end
    return nil
  end
}
