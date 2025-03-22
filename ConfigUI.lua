-- ConfigUI.lua
-- Handles the configuration UI for CursorOutline.

local LibStub = LibStub
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- List of raid target markers
local RAID_TARGET_MARKERS = {
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",  -- Star
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",  -- Circle
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",  -- Diamond
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",  -- Triangle
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",  -- Moon
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",  -- Square
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",  -- Cross (X)
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",  -- Skull
}

-- Wait for the addon to be initialized
local function InitializeConfigUI()
    local CursorOutline = LibStub("AceAddon-3.0"):GetAddon("CursorOutline")

    -- Define the configuration options
    function CursorOutline:GetOptionsTable()
        return {
            name = "CursorOutline",
            type = "group",
            args = {
                scale = {
                    type = "range",
                    name = "Scale",
                    desc = "Adjust the size of the X mark.",
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function() return self.db.profile.scale end,
                    set = function(_, value)
                        self.db.profile.scale = value
                        self:UpdateXMarkSize()
                    end,
                },
                marker = {
                    type = "select",
                    name = "Marker",
                    desc = "Choose the raid target marker to display.",
                    values = {
                        [1] = "Star",
                        [2] = "Circle",
                        [3] = "Diamond",
                        [4] = "Triangle",
                        [5] = "Moon",
                        [6] = "Square",
                        [7] = "Cross (X)",
                        [8] = "Skull",
                    },
                    get = function() return self.db.profile.marker end,
                    set = function(_, value)
                        self.db.profile.marker = value
                        self:UpdateXMarkTexture()
                    end,
                },
                opacity = {
                    type = "range",
                    name = "Opacity",
                    desc = "Set the transparency of the X mark.",
                    min = 0,
                    max = 1,
                    step = 0.1,
                    get = function() return self.db.profile.opacity end,
                    set = function(_, value)
                        self.db.profile.opacity = value
                        self:UpdateXMarkOpacity()
                    end,
                },
                showOutOfCombat = {
                    type = "toggle",
                    name = "Show Out of Combat",
                    desc = "Display the X mark even when not in combat.",
                    get = function() return self.db.profile.showOutOfCombat end,
                    set = function(_, value)
                        self.db.profile.showOutOfCombat = value
                        self:UpdateXMarkVisibility()
                    end,
                },
            },
        }
    end

    -- Register the configuration options
    AceConfig:RegisterOptionsTable("CursorOutline", CursorOutline:GetOptionsTable())

    -- Add the options to the Blizzard Interface Options panel
    AceConfigDialog:AddToBlizOptions("CursorOutline", "CursorOutline")

    -- Hook into the InterfaceOptionsFrame to enable/disable test mode
    local function OnInterfaceOptionsShow()
        CursorOutline:EnableTestMode()
    end

    local function OnInterfaceOptionsHide()
        CursorOutline:DisableTestMode()
    end

    -- Hook into the InterfaceOptionsFrame
    if InterfaceOptionsFrame then
        InterfaceOptionsFrame:HookScript("OnShow", OnInterfaceOptionsShow)
        InterfaceOptionsFrame:HookScript("OnHide", OnInterfaceOptionsHide)
    end
    -- Force sliders to update their positions
    local function UpdateSliders()
        if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            for _, child in ipairs({ InterfaceOptionsFrame:GetChildren() }) do
                if child:GetObjectType() == "Slider" then
                    child:SetValue(child:GetValue())
                end
            end
        end
    end

    -- Update sliders after a short delay
    C_Timer.After(0.1, UpdateSliders)
end

-- Hook into the addon's initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "CursorOutline" then
        InitializeConfigUI()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)