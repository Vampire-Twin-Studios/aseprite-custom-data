--@name Custom Tag Data
--@description Adds a context menu item to edit custom data for supported objects (Cel, Frame, Layer, Slice, Tag).
--@author Shervin Mortazavi

--=============================================================================
-- CONSTANTS
--=============================================================================

local PLUGIN_KEY = ""
local DEBUG = false 
local PAGE_SIZE = 3
local DEFAULT_DIALOG_WIDTH = 200
local DEFAULT_DIALOG_HEIGHT = 150
local TYPES_DIR = "types"
local CONFIG = dofile("config.lua")
local SUPPORTED_OBJECTS = {
  "Cel",
  "Layer",
  "Slice",
  "Tag"
}
local OBJECT_ID_MAP = {
  Cel = {"layer.name", "frameNumber"},
  Layer = {"name"},
  Slice = {"name"},
  Tag = {"name"}
}

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

local function getField(obj, path)
  for key in string.gmatch(path, "[^%.]+") do
    if obj == nil then return nil end
    obj = obj[key]
  end
  return obj
end

--=============================================================================

local function getCustomObjectID(obj, objType)
  local typeIDKey = OBJECT_ID_MAP[objType]
  local objectID = ""
  local idParts = {}
  for _, path in ipairs(typeIDKey) do
    local fieldValue = getField(obj, path)
    if fieldValue then
      table.insert(idParts, tostring(fieldValue))
    end
  end
  objectID = table.concat(idParts, '-')
  return objectID
end


--=============================================================================

local function debugPrint(...)
  if DEBUG then print(...) end
end

--=============================================================================

local function clearProperties(object, key)
  if object.properties(key) then
    object.properties(key, {})
  end
end

--=============================================================================

local function setProperty(object, key, property, value)
  object.properties(key)[property] = value
end

--=============================================================================

local function setAllProperties(object, key, properties, export)
  local props = {}
  clearProperties(object, key)
  for _, row in ipairs(properties) do
    if row.key and row.key ~= "" and row.value and row.value ~= "" then
      setProperty(object, key, row.key, row.value)
    end
  end
  app.command.SaveFile()
  if export then
    app.command.RepeatLastExport()
  end
  app.alert("Data saved!")
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

local function getPredefinedKeys(objType, pluginKeyID)
  if not CONFIG.keys
    or not CONFIG.keys[pluginKeyID]
    or not CONFIG.keys[pluginKeyID].default_properties
    or not CONFIG.keys[pluginKeyID].default_properties[objType] then
      return {}
    end
  return deepcopy(CONFIG.keys[pluginKeyID].default_properties[objType])
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

local function reloadProperties(object, objType, pluginKeyID)
  -- Load any defaults properties
  local kvRows = getPredefinedKeys(objType, pluginKeyID)
  local keyIndex = {}
  -- Build a lookup for quick replacement by key
  for i, row in ipairs(kvRows) do
    keyIndex[row.key] = i
  end

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
      local entry = { key = key, value = value, type = typeFound or "string" }
      if keyIndex[key] then
        kvRows[keyIndex[key]] = entry -- Overwrite default with user value
      else
        table.insert(kvRows, entry)
      end
    end
  end
  return kvRows
end

--=============================================================================

local function drawWindow(objType)

  -- Get type key for ease
  local typeKey = string.lower(objType)
  

  -- Get the active object as the current selection
  local selectedObject = app[typeKey]
  if not selectedObject then
    if objType == "Cel" then
      app.alert("Can't define custom data on an empty cell!")
    else
      app.alert("No " .. objType .. " selected!")
    end
    return
  end
  
  -- Build all object options
  local objectIDs = {}
  local objectMap = {}
  for _, o in ipairs(app.sprite[typeKey.. 's'] ) do
    local objectID = getCustomObjectID(o, objType)
    table.insert(objectIDs, objectID)
    objectMap[objectID] = o
  end

  -- Build plugin key options
  local pluginKeyIDs = {}
  for key, _ in pairs(CONFIG.keys) do
    table.insert(pluginKeyIDs, key)
  end
  local pluginKeyID = CONFIG.defaultKeyID
  PLUGIN_KEY = CONFIG.keys[pluginKeyID].plugin

  -- Tracking variables for dialog state
  local lastDialogBounds = nil
  local dlg = nil
  local selectedTab = "page1"
  local properties = reloadProperties(selectedObject, objType, pluginKeyID)

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
      title = "Custom " .. objType .. " Data",
      onclose = function()
        app.refresh()
      end
    }

    -- Object selection
    if objType == "Cel" then
      local layers = {}
      for _, layer in ipairs(app.sprite.layers) do
        table.insert(layers, layer)
      end
      -- Sort layers by stackIndex (descending)
      table.sort(layers, function(a, b) return a.stackIndex > b.stackIndex end)
      local layerNames = {}
      local layersMap = {}
      for _, layer in ipairs(layers) do
        if #layer.cels > 0 then
          table.insert(layerNames, layer.name)
          layersMap[layer.name] = layer
        end
      end
      local selectedObjectID = getCustomObjectID(selectedObject, objType)
      local currentLayer = layersMap[selectedObjectID:match("^[^-]+")]
      dlg:combobox{
        id = "layer",
        label = "Layer",
        option = currentLayer.name,
        options = layerNames,
        onchange = function()
          selectedObject = objectMap[dlg.data.layer .. '-' .. layersMap[dlg.data.layer].cels[1].frameNumber]
          showDialog()
        end
      }
      local frames = {}
      local framesMap = {}
      for _, cel in ipairs(currentLayer.cels) do
        table.insert(frames, cel.frameNumber)
        framesMap[cel.frameNumber] = cel.frame
      end
      dlg:combobox{
        id = "frame",
        label = "Frame",
        option = selectedObjectID:match("^[^-]+%-([^-]+)"),
        options = frames,
        onchange = function()
          selectedObject = objectMap[dlg.data.layer .. '-' .. dlg.data.frame]
          showDialog()
        end
      }
    else
      dlg:combobox{
        id = typeKey,
        label = objType,
        option = objectID,
        options = objectIDs,
        onchange = function()
          selectedObject = objectMap[dlg.data[typeKey]]
          if (typeKey == "tag") then
            local currentFrame = app.frame.frameNumber
            if currentFrame < selectedObject.fromFrame.frameNumber or currentFrame > selectedObject.toFrame.frameNumber then
              app.frame = selectedObject.fromFrame.frameNumber
            end
          end
          showDialog()
        end
      }
    end
    
    -- Plugin key selection
    dlg:combobox{
      id = "pluginKey",
      label = "Plugin Key",
      option = pluginKeyID,
      options = pluginKeyIDs,
      onchange = function()
        pluginKeyID = dlg.data.pluginKey
        PLUGIN_KEY = CONFIG.keys[pluginKeyID].plugin
        properties = reloadProperties(selectedObject, objType, pluginKeyID)
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
      setAllProperties(selectedObject, PLUGIN_KEY, properties, false)
    end }
    dlg:button{ text = "Apply + Export", onclick = function()
      setAllProperties(selectedObject, PLUGIN_KEY, properties, true)
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

--=============================================================================
-- INIT
--=============================================================================

function init(plugin)
  -- Add context menu items for each supported object type
  for _, objType in ipairs(SUPPORTED_OBJECTS) do
    local group = string.lower(objType) .. "_popup_properties"
    plugin:newCommand{
      id = "Custom" .. objType .. "Data",
      title = "Custom " .. objType .. " Data",
      group = string.lower(objType) .. "_popup_properties",
      onclick = function() drawWindow(objType) end
    }
  end

  app.events:on('aftercommand', afterCommandHandler)
end

--=============================================================================
-- EXIT
--=============================================================================

function exit(plugin)
  app.events:off('aftercommand', afterCommandHandler)
end
