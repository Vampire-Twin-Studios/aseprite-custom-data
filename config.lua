-- config.lua
-- Configuration for custom tag data extension

local config = {}

-- Predefined properties (array of key/type/value tables)
config.properties = {
  { key = "Author", type = "string", value = "" },
  { key = "Description", type = "string", value = "" },
  { key = "Category", type = "order", value = 1 },
  { key = "Version", type = "int", value = 1 },
  { key = "Scale", type = "float", value = 1.0 }
}

-- Predefined keys for plugin key selection
config.keys = {
  { id = "Root", value = "" },
  { id = "Animation", value = "Animation"}
}

config.defaultKeyID = "Root"

return config
