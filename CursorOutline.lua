-- CursorOutline Addon
-- Author: AAAddons
-- Version: 1.27
-- Description: Displays an X mark at the mouse cursor position when in combat. Allows scaling the X mark.

-----------------------------------------
-- Constants
-----------------------------------------
local DEFAULT_SCALE = 1.0
local MIN_SCALE = 0.5
local MAX_SCALE = 2.0
local X_MARK_SIZE = 38 -- Base size of the X mark

-----------------------------------------
-- Saved Variables
-----------------------------------------
CursorOutlineDB = CursorOutlineDB or { scale = DEFAULT_SCALE }

-----------------------------------------
-- Frame and Texture
-----------------------------------------
local frame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
local xMarkTexture = frame:CreateTexture(nil, "OVERLAY")

-----------------------------------------
-- Helper Functions
-----------------------------------------

-- Initialize the X mark frame and texture
local function InitializeFrame()
    frame:SetSize(X_MARK_SIZE * CursorOutlineDB.scale, X_MARK_SIZE * CursorOutlineDB.scale)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:Hide()

    xMarkTexture:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    xMarkTexture:SetAllPoints(frame)
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

-- Validate and set the X mark's scale
local function SetXMarkScale(scale)
    scale = tonumber(scale)
    if not scale or scale < MIN_SCALE or scale > MAX_SCALE then
        print("|cFF008000CursorOutline:|r Scale must be a number between " .. MIN_SCALE .. " and " .. MAX_SCALE .. ".")
        return
    end

    CursorOutlineDB.scale = scale
    frame:SetSize(X_MARK_SIZE * scale, X_MARK_SIZE * scale)
    print("|cFF008000CursorOutline:|r X mark scale set to " .. scale)
    CursorOutlineDB.__changed = true
end

-- Handle slash commands
local function HandleSlashCommand(input)
    local command, value = input:match("^(%S+)%s*(%S*)$")
    command = command and command:lower() or ""

    if command == "scale" then
        if value == "" then
            print("|cFF008000CursorOutline:|r Current scale is " .. CursorOutlineDB.scale)
            print("|cFF008000Usage:|r /co scale <value> (" .. MIN_SCALE .. " to " .. MAX_SCALE .. ")")
        else
            SetXMarkScale(value)
        end
    elseif command == "help" or command == "" then
        print("|cFF008000CursorOutline Commands:|r")
        print("|cFF008000/co|r - |cFFFFA500Show this help message.|r")
        print("|cFF008000/co scale <value>|r - |cFFFFA500Set the size of the X mark (" .. MIN_SCALE .. " = half size, " .. DEFAULT_SCALE .. " = default, " .. MAX_SCALE .. " = double size).|r")
    else
        print("|cFF008000CursorOutline:|r Unknown command. Type /co help for a list of commands.")
    end
end

-- Handle addon initialization
local function OnAddonLoaded(_, _, addonName)
    if addonName == "CursorOutline" then
        -- Debug: Print the saved scale value
        print("|cFF008000CursorOutline:|r Loaded scale from DB: " .. CursorOutlineDB.scale)

        -- Initialize the frame and texture
        InitializeFrame()

        -- Register combat events
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", OnCombatStateChange)

        -- Register slash commands
        SLASH_CURSOROUTLINE1 = "/co"
        SLASH_CURSOROUTLINE2 = "/cursoroutline"
        SlashCmdList["CURSOROUTLINE"] = HandleSlashCommand

        -- Print a one-time load message
        print("|cFF008000CursorOutline loaded! Type /co for help.|r")
    end
end

-- Force saved variables to be written to disk on logout or reload
local function OnPlayerLogout()
    if CursorOutlineDB.__changed then
        CursorOutlineDB.__changed = nil
    end
end

-----------------------------------------
-- Event Registration
-----------------------------------------
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(self, event, ...)
    elseif event == "PLAYER_LOGOUT" then
        OnPlayerLogout()
    end
end)