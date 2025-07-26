--@name Custom Tag Data
--@description Adds a context menu item to edit custom tag data.
--@author Shervin Mortazavi

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local DEBUG = false 
local PAGE_SIZE = 3
local DEFAULT_DIALOG_WIDTH = 200
local DEFAULT_DIALOG_HEIGHT = 350
local TYPES_DIR = "types"
local CONFIG = dofile("config.lua")

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

local function debugPrint(...)
  if DEBUG then print(...) end
end

--=============================================================================

local function setProperty(object, property, value)
  object.properties(PLUGIN_KEY)[property] = value
end

--=============================================================================

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

--=============================================================================

local function getPredefinedKeys(pluginKeyID)
  if not CONFIG.keys or not CONFIG.keys[pluginKeyID] or not CONFIG.keys[pluginKeyID].default_properties then
    return {}
  end
  return deepcopy(CONFIG.keys[pluginKeyID].default_properties)
end

--=============================================================================

local function populateTypes()
    -- Get base path of this script file
    local thisFilePath = debug.getinfo(1, "S").source:sub(2)
    local basePath = app.fs.filePath(thisFilePath)

    -- Scan types folder for custom type helpers
    local supportedTypes = {}
    local typeHelpers = {}
    local typesAbsPath = app.fs.joinPath(basePath, TYPES_DIR)

    if app.fs.isDirectory(typesAbsPath) then
      if DEBUG then debugPrint("Scanning types directory:", typesAbsPath) end
      for _, file in ipairs(app.fs.listFiles(typesAbsPath)) do
        local filename = app.fs.fileName(file)
        if DEBUG then debugPrint("Found types file:", filename) end
        local name = filename:match("([^/\\]+)%.lua$") -- strip .lua extension
        if name then
          table.insert(supportedTypes, name)
          local fullPath = app.fs.joinPath(typesAbsPath, name .. ".lua")
          typeHelpers[name] = dofile(fullPath)
        end
      end
    end

    return supportedTypes, typeHelpers
end
local SUPPORTED_TYPES, TYPE_HELPERS = populateTypes()

--=============================================================================

local function reloadProperties(object, pluginKeyID)
  -- Load any defaults properites
  local kvRows = getPredefinedKeys(pluginKeyID)

  -- Then load any existing properties from the selected tag
  if object.properties(PLUGIN_KEY) then
    for key, value in pairs(object.properties(PLUGIN_KEY)) do
      local typeFound = nil
      for _, typeName in ipairs(SUPPORTED_TYPES) do
        local typeHelper = TYPE_HELPERS[typeName]
        if typeHelper and typeHelper.isType and typeHelper.isType(value) then
          debugPrint("Found type for key:", key, "->", typeName)
          typeFound = typeName
          break
        end
      end
      table.insert(kvRows, { key = key, value = value, type = typeFound or "string" })
    end
  end
  return kvRows
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

      -- Build plugin key options
      local pluginKeyIDs = {}
      for key, _ in pairs(CONFIG.keys) do
        table.insert(pluginKeyIDs, key)
      end
      local pluginKeyID = CONFIG.defaultKeyID
      PLUGIN_KEY = CONFIG.keys[pluginKeyID].plugin
      
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

      -- Tracking variables for dialog state
      local lastDialogBounds = nil
      local dlg = nil
      local selectedTab = "page1"
      local properties = reloadProperties(selectedTag, pluginKeyID)

      local function showDialog()
        -- If dialogue already exists, close it, save bounds and selected tab
        if dlg then
          lastDialogBounds = Rectangle(
            dlg.bounds.x,
            dlg.bounds.y,
            dlg.bounds.width,
            dlg.bounds.height
          )
          selectedTab = dlg.data and dlg.data.props_tabs or selectedTab
          dlg:close()
        end

        -- Create a new dialog
        dlg = Dialog{
          title = "Custom Tag Data",
          onclose = function()
            app.refresh()
          end
        }

        -- Tag selection
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
        
        -- Plugin key selection
        dlg:combobox{
          id = "pluginKey",
          label = "Plugin Key",
          option = pluginKeyID,
          options = pluginKeyIDs,
          onchange = function()
            pluginKeyID = dlg.data.pluginKey
            PLUGIN_KEY = CONFIG.keys[pluginKeyID].plugin
            properties = reloadProperties(selectedTag, pluginKeyID)
            showDialog()
          end
        }
        
        -- Split properties into pages
        local pages = {}
        for i = 1, #properties, PAGE_SIZE do
          local page = {}
          for j = i, math.min(i+PAGE_SIZE-1, #properties) do
            table.insert(page, properties[j])
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
                properties[idx].key = dlg.data["key"..idx]
              end
            }
            dlg:combobox{
              id = "type"..idx,
              label = "Type",
              option = row.type or "string",
              options = SUPPORTED_TYPES,
              onchange = function()
                properties[idx].type = dlg.data["type"..idx]
                showDialog()
              end
            }
            local typeHelper = TYPE_HELPERS[row.type]
            if typeHelper and typeHelper.draw then
              typeHelper.draw(dlg, "value"..idx, row.value, function()
                properties[idx].value = typeHelper.getValue and typeHelper.getValue(dlg.data, "value"..idx) or dlg.data["value"..idx]
              end)
            else
              dlg:entry{
                id = "value"..idx,
                label = "Value",
                text = row.value or "",
                onchange = function()
                  properties[idx].value = dlg.data["value"..idx]
                end
              }
            end
            dlg:button{
              text = "Remove",
              onclick = function()
                table.remove(properties, idx)
                showDialog()
              end,
              focus = false
            }

            -- Only draw separator if not last element in the page
            if i < #pageRows then
              dlg:separator{}
            end
          end
        end
        dlg:endtabs{ id = "props_tabs", selected = selectedTab }
        dlg:button{ text = "Add Property", onclick = function()
          table.insert(properties, { key = "", value = "" })
          showDialog()
        end }
        dlg:button{ text = "Apply", onclick = function()
          local props = {}
          for _, row in ipairs(properties) do
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
            math.max(DEFAULT_DIALOG_WIDTH, dlg.bounds.width, lastDialogBounds.width),
            math.max(DEFAULT_DIALOG_HEIGHT, dlg.bounds.height)
          )
        else
          dlg.bounds = Rectangle(
            dlg.bounds.x,
            dlg.bounds.y,
            math.max(DEFAULT_DIALOG_WIDTH, dlg.bounds.width),
            math.max(DEFAULT_DIALOG_HEIGHT, dlg.bounds.height)
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
