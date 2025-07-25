--@name Custom Tag Data
--@description Adds a context menu item to edit custom tag data.
--@author Shervin Mortazavi

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local DEBUG = false
local PAGE_SIZE = 3
local function debugPrint(...)
  if DEBUG then print(...) end
end

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

function setProperty(object, property, value)
  object.properties(PLUGIN_KEY)[property] = value
end

-- Deep copy utility for tables
local function deepcopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepcopy(orig_key)] = deepcopy(orig_value)
    end
    setmetatable(copy, getmetatable(orig))
  else
    copy = orig
  end
  return copy
end

-- Load predefined keys from config file
local config = dofile("config.lua")
local function loadPredefinedRows()
  -- print debug info if DEBUG is true
  if DEBUG then
    debugPrint("Loading predefined rows from config:")
    for i, row in ipairs(config) do
      debugPrint(string.format("Row %d: key=%s, type=%s, value=%s", i, row.key, row.type or "string", tostring(row.value)))
    end
  end
  return deepcopy(config) or { { key = "", value = "" } }
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

      -- Load any defaults first
      local kvRows = loadPredefinedRows()

      -- Then load any existing properties from the selected tag
      if selectedTag.properties(PLUGIN_KEY) then
        for key, value in pairs(selectedTag.properties(PLUGIN_KEY)) do
          table.insert(kvRows, { key = key, value = value })
        end
      end

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
        dlg:separator{ id = "kv_sep", text = "Properties" }
        -- Split kvRows into pages
        local pages = {}
        for i = 1, #kvRows, PAGE_SIZE do
          local page = {}
          for j = i, math.min(i+PAGE_SIZE-1, #kvRows) do
            table.insert(page, kvRows[j])
          end
          table.insert(pages, page)
        end
        -- Add tabs for each page
        for p, pageRows in ipairs(pages) do
          dlg:tab{ id = "page"..p, text = "Page "..p }
          for i, row in ipairs(pageRows) do
            local idx = (p-1)*PAGE_SIZE + i
            dlg:entry{
              id = "key"..idx,
              label = "Key",
              text = row.key or "",
              onchange = function()
                kvRows[idx].key = dlg.data["key"..idx]
              end
            }
            if row.type == "dropdown" and type(row.dropdownOptions) == "table" then
              dlg:combobox{
                id = "value"..idx,
                label = "Value",
                option = row.value or row.dropdownOptions[1],
                options = row.dropdownOptions,
                onchange = function()
                  kvRows[idx].value = dlg.data["value"..idx]
                end
              }
            elseif row.type == "int" then
              dlg:entry{
                id = "value"..idx,
                label = "Value",
                text = tostring(row.value or ""),
                onchange = function()
                  local v = tonumber(dlg.data["value"..idx])
                  if v and math.floor(v) == v then
                    kvRows[idx].value = v
                  else
                    kvRows[idx].value = row.value
                  end
                end
              }
            elseif row.type == "float" then
              dlg:entry{
                id = "value"..idx,
                label = "Value",
                text = tostring(row.value or ""),
                onchange = function()
                  local v = tonumber(dlg.data["value"..idx])
                  if v then
                    kvRows[idx].value = v
                  else
                    kvRows[idx].value = row.value
                  end
                end
              }
            else -- default to string
              dlg:entry{
                id = "value"..idx,
                label = "Value",
                text = row.value or "",
                onchange = function()
                  kvRows[idx].value = dlg.data["value"..idx]
                end
              }
            end
            dlg:button{
              text = "Remove",
              onclick = function()
                table.remove(kvRows, idx)
                showDialog()
              end,
              focus = false
            }
            dlg:separator{}
          end
        end
        dlg:endtabs{ id = "props_tabs", selected = "page1" }
        dlg:button{ text = "Add Row", onclick = function()
          table.insert(kvRows, { key = "", value = "" })
          showDialog()
        end }
        dlg:button{ text = "Apply", onclick = function()
          local props = {}
          for _, row in ipairs(kvRows) do
            if row.key and row.key ~= "" and row.value and row.value ~= "" then
              setProperty(selectedTag, row.key, row.value)
            end
          end
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
