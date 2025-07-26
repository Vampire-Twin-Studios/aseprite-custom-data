return {
  draw = function(dlg, id, value, onchange)
    value = value or { x = 0, y = 0, z = 0 }
    dlg:newrow()
    dlg:entry{ id = id.."_x", label = "X", text = tostring(value.x or 0), onchange = function() onchange() end }
    dlg:entry{ id = id.."_y", label = "Y", text = tostring(value.y or 0), onchange = function() onchange() end }
  end,
  getValue = function(data, id)
    return {
      x = tonumber(data[id.."_x"]) or 0,
      y = tonumber(data[id.."_y"]) or 0
    }
  end,
  isType = function(value)
    return type(value) == "table" and value.x ~= nil and value.y ~= nil
  end
}
