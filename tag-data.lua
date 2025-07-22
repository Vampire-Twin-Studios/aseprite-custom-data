--@name Custom Tag Data
--@description Adds a context menu item to edit custom tag data.
--@author Shervin Mortazavi

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local DEBUG = false
local function debugPrint(...)
  if DEBUG then print(...) end
end

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

function setProperty(object, property, value)
  object.properties(PLUGIN_KEY)[property] = value
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
      local kvRows = { { key = "", value = "" } }
      local function showDialog()
        local dlg = Dialog{
          title = "Custom Tag Data",
          onclose = function() app.refresh() end
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
          dlg:entry{ id = "key"..i, label = "Key", text = row.key or "", onchange = function()
            kvRows[i].key = dlg.data["key"..i]
          end }
          dlg:entry{ id = "value"..i, label = "Value", text = row.value or "", onchange = function()
            kvRows[i].value = dlg.data["value"..i]
          end }
          dlg:button{ text = "Remove", onclick = function()
            dlg:close() -- Close previous dialog
            table.remove(kvRows, i)
            showDialog()
          end }
        end
        dlg:button{ text = "Add Row", onclick = function()
          dlg:close() -- Close previous dialog
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
        dlg:show()
      end
      showDialog()
      clearPreviewLayer(sprite)
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
