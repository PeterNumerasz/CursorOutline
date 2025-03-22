-- CursorOutline.lua
-- Main addon file.

local LibStub = LibStub
local AceDB = LibStub("AceDB-3.0")

-- Create the addon object
local CursorOutline = LibStub("AceAddon-3.0"):NewAddon("CursorOutline")

-- Default saved variables
CursorOutline.defaults = {
    profile = {
        scale = 1.0,
        marker = 7,  -- Default marker: Cross (X)
        opacity = 1.0,  -- Default opacity: fully visible
        showOutOfCombat = false,
    },
}

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

-- Initialize the addon
function CursorOutline:OnInitialize()
    -- Set up saved variables using AceDB
    self.db = AceDB:New("CursorOutlineDB", self.defaults, true)

    -- Initialize the configuration UI
    self:SetupConfigUI()

    -- Initialize the X mark frame and texture
    self:InitializeFrame()

    -- Register slash commands
    self:RegisterSlashCommands()

    -- Apply the visibility setting after reload
    self:UpdateXMarkVisibility()
end

-- Load the ConfigUI module
function CursorOutline:SetupConfigUI()
    -- This function is defined in ConfigUI.lua
end

-----------------------------------------
-- Frame and Texture
-----------------------------------------
local frame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
local xMarkTexture = frame:CreateTexture(nil, "OVERLAY")

-- Initialize the X mark frame and texture
function CursorOutline:InitializeFrame()
    local scale = self.db.profile.scale
    frame:SetSize(38 * scale, 38 * scale)  -- Base size of the X mark is 38
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Hide()

    -- Set the initial texture
    self:UpdateXMarkTexture()

    -- Set the initial opacity
    self:UpdateXMarkOpacity()
end

-- Update the X mark's position to follow the mouse
local function UpdateXMarkPosition()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- Handle combat state changes
local function OnCombatStateChange(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        frame:Show()
        frame:SetScript("OnUpdate", UpdateXMarkPosition)
    elseif event == "PLAYER_REGEN_ENABLED" then
        frame:Hide()
        frame:SetScript("OnUpdate", nil)
    end
end

-- Update the X mark size
function CursorOutline:UpdateXMarkSize()
    local scale = self.db.profile.scale
    frame:SetSize(38 * scale, 38 * scale)
end

-- Update the X mark texture
function CursorOutline:UpdateXMarkTexture()
    local markerIndex = self.db.profile.marker
    local texture = RAID_TARGET_MARKERS[markerIndex]
    xMarkTexture:SetTexture(texture)
    xMarkTexture:SetAllPoints(frame)
end

-- Update the X mark opacity
function CursorOutline:UpdateXMarkOpacity()
    local opacity = self.db.profile.opacity
    xMarkTexture:SetAlpha(opacity)
end

-- Update the X mark visibility
function CursorOutline:UpdateXMarkVisibility()
    if self.db.profile.showOutOfCombat then
        frame:Show()
        frame:SetScript("OnUpdate", UpdateXMarkPosition)
    else
        frame:Hide()
        frame:SetScript("OnUpdate", nil)
    end
end

-- Enable test mode
function CursorOutline:EnableTestMode()
    self.testMode = true
    frame:Show()
    frame:SetScript("OnUpdate", UpdateXMarkPosition)
end

-- Disable test mode
function CursorOutline:DisableTestMode()
    self.testMode = false
    if not self.db.profile.showOutOfCombat then
        frame:Hide()
        frame:SetScript("OnUpdate", nil)
    else
        self:UpdateXMarkVisibility()
    end
end

-----------------------------------------
-- Slash Commands
-----------------------------------------
function CursorOutline:RegisterSlashCommands()
    SLASH_CURSOROUTLINE1 = "/co"
    SLASH_CURSOROUTLINE2 = "/cursoroutline"
    SlashCmdList["CURSOROUTLINE"] = function(input)
        if input == "config" then
            -- Use the modern Settings API if available
            if Settings and Settings.OpenToCategory then
                Settings.OpenToCategory("CursorOutline")
            else
                -- Fallback to the old InterfaceOptionsFrame_OpenToCategory
                if not InterfaceOptionsFrame then
                    C_AddOns.LoadAddOn("Blizzard_InterfaceOptions")
                end
                if InterfaceOptionsFrame_OpenToCategory then
                    InterfaceOptionsFrame_OpenToCategory("CursorOutline")
                    InterfaceOptionsFrame_OpenToCategory("CursorOutline")  -- Call twice to ensure it opens
                else
                    print("|cFF008000CursorOutline:|r Unable to open the configuration UI. Please try again.")
                end
            end
        else
            self:HandleSlashCommand(input)
        end
    end
end

function CursorOutline:HandleSlashCommand(input)
    local command, value = input:match("^(%S+)%s*(%S*)$")
    command = command and command:lower() or ""

    if command == "scale" then
        if value == "" then
            print("|cFF008000CursorOutline:|r Current scale is " .. self.db.profile.scale)
            print("|cFF008000Usage:|r /co scale <value> (0.5 to 2.0)")
        else
            local scale = tonumber(value)
            if scale and scale >= 0.5 and scale <= 2.0 then
                self.db.profile.scale = scale
                self:UpdateXMarkSize()
                print("|cFF008000CursorOutline:|r X mark scale set to " .. scale)
            else
                print("|cFF008000CursorOutline:|r Scale must be a number between 0.5 and 2.0.")
            end
        end
    elseif command == "help" or command == "" then
        print("|cFF008000CursorOutline Commands:|r")
        print("|cFF008000/co|r - |cFFFFA500Show this help message.|r")
        print("|cFF008000/co scale <value>|r - |cFFFFA500Set the size of the X mark (0.5 = half size, 1.0 = default, 2.0 = double size).|r")
    else
        print("|cFF008000CursorOutline:|r Unknown command. Type /co help for a list of commands.")
    end
end

-----------------------------------------
-- Event Registration
-----------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        CursorOutline:OnInitialize()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        OnCombatStateChange(self, event, ...)
    end
end)