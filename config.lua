-- config.lua
-- Configuration for custom tag data extension

local config = {}

-- Predefined keys for plugin key selection, along with their default properties
config.keys = {
  Root = {
    plugin = "",
    default_properties = {
      Tag = {
        { key = "phase", type = "phase", value = "Solo" }
      }
    }
  }
}
config.defaultKeyID = "Root"

return config
