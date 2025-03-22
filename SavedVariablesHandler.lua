-- Refactored SavedVariablesHandler.lua
-- A simple module to initialize and manage saved variables.

local SavedVariablesHandler = {}

SavedVariablesHandler.defaults = {
  scale = 1.0,
}

function SavedVariablesHandler:Initialize()
  CursorOutlineDB = CursorOutlineDB or {}
  for key, value in pairs(self.defaults) do
    if CursorOutlineDB[key] == nil then
      CursorOutlineDB[key] = value
    end
  end
end

function SavedVariablesHandler:Get(key)
  return CursorOutlineDB[key]
end

function SavedVariablesHandler:Set(key, value)
  CursorOutlineDB[key] = value
end

_G.SavedVariablesHandler = SavedVariablesHandler
