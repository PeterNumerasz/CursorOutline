local SavedVariablesHandler = {}

-- Default values
SavedVariablesHandler.defaults = {
    scale = 1.0
}

-- Initialize or load saved variables
function SavedVariablesHandler:Initialize()
    CursorOutlineDB = CursorOutlineDB or {}
    for key, value in pairs(self.defaults) do
        if CursorOutlineDB[key] == nil then
            CursorOutlineDB[key] = value
        end
    end
end

-- Get a saved variable
function SavedVariablesHandler:Get(key)
    return CursorOutlineDB[key]
end

-- Set a saved variable
function SavedVariablesHandler:Set(key, value)
    CursorOutlineDB[key] = value
end

-- Expose the module globally
_G.SavedVariablesHandler = SavedVariablesHandler