# Aseprite Custom Data Manager

Aseprite Custom Data Manager is a flexible and extensible plugin for Aseprite that allows you to view, edit, and manage custom metadata for a variety of sprite objects—including Tags, Layers, Slices, and Cels—using a modern, type-driven dialog interface.

## Features

- **Universal Custom Data Editing:**
  - Add, edit, and remove custom properties for Tags, Layers, Slices, and Cels.
  - Supports multiple property types: string, int, float, bool, enum/order, and vector3.
- **Configurable & Extensible:**
  - Property keys, types, and defaults are defined in a config file for easy customization.
  - Easily add new property types by dropping a Lua file in the `types/` folder.
- **Type-Driven UI:**
  - Each property type has its own input widget and validation logic.
  - Dynamic type detection for existing properties.
- **Per-Plugin Key Support:**
  - Manage multiple sets of custom data using plugin keys (e.g., for different workflows or extensions).
- **Pagination & Usability:**
  - Properties are paginated for large sets, with a clean, user-friendly dialog.
- **Safe & Non-Destructive:**
  - All data is stored as Aseprite [user-defined properties](https://www.aseprite.org/api/properties#properties)—your artwork remains untouched.
- **Debug Logging:**
  - Optional debug output for troubleshooting and development.

## User-Defined Properties & Export

This plugin leverages Aseprite's [user-defined properties](https://www.aseprite.org/api/properties#properties) system. These properties are exported with your sprite's JSON data, making them accessible to external tools and game engines (such as Unity, Godot, etc.).

- You can use these custom properties in your own pipelines, importers, or runtime systems.
- For more details, see the [Aseprite API documentation on properties](https://www.aseprite.org/api/properties#properties).

## Installation

1. Download or clone this repository.
2. Place the folder (or zip) in your Aseprite extensions directory.
3. Enable the extension in Aseprite via `Edit > Preferences > Extensions`.

## Usage

1. Open a sprite in Aseprite.
2. Right-click a Tag, Layer, Slice, or Cel in the timeline or workspace.
3. Select the "Custom ... Data" context menu item.
4. Use the dialog to add, edit, or remove custom properties. Change property types, values, and keys as needed.
5. Click "Apply" to save changes.

## Configuration

- Edit `config.lua` to define plugin keys, default properties, and property types.
- Add new type helpers in the `types/` folder to support additional property types.

## Advanced

- The plugin is modular and easy to extend. Each type helper implements `draw`, `getValue`, and `isType` functions.
- The dialog UI is dynamically generated based on config and detected property types.

---

Feedback, issues, and contributions are welcome!
