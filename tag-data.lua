--@name Custom Tag Data
--@description Adds a context menu item to edit custom tag data.
--@author Shervin Mortazavi

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local DEBUG = true
local function debugPrint(...)
  if DEBUG then print(...) end
end

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

function setProperty(object, property, value)
  object.properties(PLUGIN_KEY)[property] = value
end

local config = dofile("config.lua")
if DEBUG then
  local debugInfo = "Config:\n"
  for i, row in ipairs(config) do
    debugInfo = debugInfo .. string.format("Row %d: key=%s, value=%s\n", i, row.key, tostring(row.value))
  end
  app.alert(debugInfo)
end
-- Load predefined keys from config file
local function loadPredefinedRows()
  return config or { { key = "", value = "" } }
end

--=============================================================================
-- INIT
--=============================================================================

function init(plugin)
  plugin:newCommand{
    id = "CustomTagData",
    title = "Custom Tag Data",
    group = "tag_popup_properties",
    onclick = function()

      -- Get the active sprite
      local sprite = app.activeSprite
      if not sprite or #sprite.tags == 0 then
        app.alert("This sprite has no tags.")
        return
      end
      
      -- Build all tag options
      local tagNames = {}
      local tagMap = {}
      for _, t in ipairs(sprite.tags) do
        table.insert(tagNames, t.name)
        tagMap[t.name] = t
      end

      -- Default selection to tag that contains the current frame otherwise first tag
      local currentFrame = app.activeFrame.frameNumber
      local selectedTag = nil
      for _, tag in ipairs(sprite.tags) do
        if currentFrame >= tag.fromFrame.frameNumber and currentFrame <= tag.toFrame.frameNumber then
          selectedTag = tag
          break
        end
      end
      if not selectedTag then
        selectedTag = sprite.tags[1]
      end

      -- Create the dialog box
      local dlg = Dialog{
        title = "Custom Tag Data",
        onclose = function()
          app.refresh()
        end
      }

      -- Select tag dropdown
      dlg:combobox{
        id = "tag",
        label = "Tag",
        option = selectedTag.name,
        options = tagNames,
        onchange = function()
          selectedTag = tagMap[dlg.data.tag]
          -- Change frame if outside selected tag
          local currentFrame = app.activeFrame.frameNumber
          if currentFrame < selectedTag.fromFrame.frameNumber or currentFrame > selectedTag.toFrame.frameNumber then
            app.activeFrame = selectedTag.fromFrame.frameNumber
          end
        end
      }

      -- Key-Value pairs data
      local kvRows = loadPredefinedRows()
      -- debug alert values of kvRows
      if DEBUG then
        local debugInfo = "KV Rows:\n"
        for i, row in ipairs(kvRows) do
          debugInfo = debugInfo .. string.format("Row %d: key=%s, value=%s\n", i, row.key, tostring(row.value))
        end
        app.alert(debugInfo)
      end
      local lastDialogBounds = nil
      local dlg = nil
      local function showDialog()
        if dlg then
          lastDialogBounds = Rectangle(
            dlg.bounds.x,
            dlg.bounds.y,
            dlg.bounds.width,
            dlg.bounds.height
          )
          dlg:close()
        end
        dlg = Dialog{
          title = "Custom Tag Data",
          onclose = function()
            app.refresh()
          end
        }
        dlg:combobox{
          id = "tag",
          label = "Tag",
          option = selectedTag.name,
          options = tagNames,
          onchange = function()
            selectedTag = tagMap[dlg.data.tag]
            local currentFrame = app.activeFrame.frameNumber
            if currentFrame < selectedTag.fromFrame.frameNumber or currentFrame > selectedTag.toFrame.frameNumber then
              app.activeFrame = selectedTag.fromFrame.frameNumber
            end
            showDialog()
          end
        }
        for i, row in ipairs(kvRows) do
          if row.type == "dropdown" and type(row.dropdownOptions) == "table" then
            dlg:combobox{
              id = "value"..i,
              label = row.key,
              option = row.value or row.dropdownOptions[1],
              options = row.dropdownOptions,
              onchange = function()
                kvRows[i].value = dlg.data["value"..i]
              end
            }
          elseif row.type == "int" then
            dlg:entry{
              id = "value"..i,
              label = row.key,
              text = tostring(row.value or ""),
              onchange = function()
                local v = tonumber(dlg.data["value"..i])
                if v and math.floor(v) == v then
                  kvRows[i].value = v
                else
                  kvRows[i].value = row.value
                end
              end
            }
          elseif row.type == "float" then
            dlg:entry{
              id = "value"..i,
              label = row.key,
              text = tostring(row.value or ""),
              onchange = function()
                local v = tonumber(dlg.data["value"..i])
                if v then
                  kvRows[i].value = v
                else
                  kvRows[i].value = row.value -- fallback to previous value if not float
                end
              end
            }
          else -- default to string
            dlg:entry{
              id = "value"..i,
              label = row.key,
              text = row.value or "",
              onchange = function()
                kvRows[i].value = dlg.data["value"..i]
              end
            }
          end
          dlg:button{ text = "Remove", onclick = function()
            table.remove(kvRows, i)
            showDialog()
          end }
        end
        dlg:button{ text = "Add Row", onclick = function()
          table.insert(kvRows, { key = "", value = "" })
          showDialog()
        end }
        dlg:button{ text = "Apply", onclick = function()
          local props = {}
          for _, row in ipairs(kvRows) do
            if row.key and row.key ~= "" then
              props[row.key] = row.value
            end
          end
          setProperty(selectedTag, "customData", props)
          app.alert("Data saved!")
        end }
        dlg:label{ id = "info", label = "", text = string.rep(" ", 25), color = Color{ r=0, g=180, b=0 } }
        if (lastDialogBounds) then
          dlg.bounds = Rectangle(
            lastDialogBounds.x,
            lastDialogBounds.y,
            dlg.bounds.width,
            dlg.bounds.height
          )
        end
        dlg:show()
      end
      showDialog()
    end
  }

  app.events:on('aftercommand', afterCommandHandler)
end

--=============================================================================
-- EXIT
--=============================================================================

function exit(plugin)
  app.events:off('aftercommand', afterCommandHandler)
end
