-- The main file of CursorOutline addon
local addonName = "CursorOutline"
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Performance: Localize Global Functions for the OnUpdate loop
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent

addon.defaults = {
  profile = {
    scale = 1.0,
    marker = 7, -- Default marker: Cross (X)
    opacity = 1.0,
    showOutOfCombat = false,
  },
}

-- List of raid target marker texture paths
local RAID_TARGET_MARKERS = {
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- Star
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- Circle
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- Diamond
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- Triangle
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- Moon
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", -- Square
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- Cross (X)
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- Skull
}

-- Create the frame for the marker
local mainFrame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
-- CRITICAL FIX: Ensure the frame doesn't intercept mouse clicks
mainFrame:EnableMouse(false)
mainFrame:SetFrameStrata("TOOLTIP") -- High strata to ensure it's on top
local mainTexture = mainFrame:CreateTexture(nil, "OVERLAY")

-- Updates the position of the marker to follow the mouse
local function UpdateMarkerPosition()
  local x, y = GetCursorPosition()
  -- Using EffectiveScale ensures it works correctly even if UI Scale is modified
  local scale = UIParent:GetEffectiveScale()
  mainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- Initializes the marker frame
function addon:InitializeFrame()
  local scale = self.db.profile.scale
  mainFrame:SetSize(38 * scale, 38 * scale) -- Base size is 38
  mainFrame:SetPoint("CENTER", UIParent, "CENTER")
  mainFrame:Hide()
  self:UpdateMarkerTexture()
  self:UpdateMarkerOpacity()
end

-----------------------------------------------------------------------
-- AceAddon Standard Methods
-----------------------------------------------------------------------

function addon:OnInitialize()
  -- Initialize Database
  self.db = AceDB:New("CursorOutlineDB", self.defaults, true)
  
  -- Initialize Frame Logic
  self:InitializeFrame()
  
  -- Register Slash Commands
  self:RegisterChatCommand("co", "HandleSlashCommand")
  self:RegisterChatCommand("cursoroutline", "HandleSlashCommand")

  -- Initialize Config UI (If loaded)
  if self.SetupConfigUI then
    self:SetupConfigUI()
  end
end

function addon:OnEnable()
  -- Register Combat Events using AceEvent
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  
  -- Initial Visibility Check
  self:UpdateMarkerVisibility()
end

-----------------------------------------------------------------------
-- Logic & Display Updates
-----------------------------------------------------------------------

function addon:PLAYER_REGEN_DISABLED()
  -- Enter Combat
  mainFrame:Show()
  mainFrame:SetScript("OnUpdate", UpdateMarkerPosition)
end

function addon:PLAYER_REGEN_ENABLED()
  -- Leave Combat
  if not self.db.profile.showOutOfCombat then
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  end
end

function addon:UpdateMarkerSize()
  local scale = self.db.profile.scale
  mainFrame:SetSize(38 * scale, 38 * scale)
end

function addon:UpdateMarkerTexture()
  local markerIndex = self.db.profile.marker
  local texturePath = RAID_TARGET_MARKERS[markerIndex]
  mainTexture:SetTexture(texturePath)
  mainTexture:SetAllPoints(mainFrame)
end

function addon:UpdateMarkerOpacity()
  mainTexture:SetAlpha(self.db.profile.opacity)
end

function addon:UpdateMarkerVisibility()
  if self.db.profile.showOutOfCombat or InCombatLockdown() or self.testMode then
    mainFrame:Show()
    mainFrame:SetScript("OnUpdate", UpdateMarkerPosition)
  else
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  end
end

-- Test mode (for previewing the marker from Config)
function addon:EnableTestMode()
  self.testMode = true
  self:UpdateMarkerVisibility()
end

function addon:DisableTestMode()
  self.testMode = false
  self:UpdateMarkerVisibility()
end

-----------------------------------------------------------------------
-- Slash Command Logic
-----------------------------------------------------------------------

function addon:HandleSlashCommand(input)
  local command, value = input:match("^(%S+)%s*(%S*)$")
  command = (command or ""):lower()

  if command == "scale" then
    self:setScale(value) -- BUG FIX: Passed 'value'
  elseif command == "marker" then
    self:setMarker(value) -- BUG FIX: Passed 'value'
  elseif command == "opacity" then
    self:updateOpacity(value) -- BUG FIX: Passed 'value'
  elseif command == "combat" then
    self:updateCombatVisibility(value) -- BUG FIX: Passed 'value'
  elseif command == "config" then
    self:openConfigurationUI()
  elseif command == "help" or command == "" then
    self:displayHelp()
  else
    self:Print("Unknown command. Type /co help for a list of commands.")
  end
end

function addon:setScale(value) -- BUG FIX: Added parameter
  if not value or value == "" then
    self:Print("Current scale is " .. self.db.profile.scale)
    self:Print("Usage: /co scale <value> (0.5 to 2.0)")
  else
    local scale = tonumber(value)
    if scale and scale >= 0.5 and scale <= 2.0 then
      self.db.profile.scale = scale
      self:UpdateMarkerSize()
      self:Print("X mark scale set to " .. scale)
    else
      self:Print("Scale must be a number between 0.5 and 2.0.")
    end
  end
end

function addon:setMarker(value) -- BUG FIX: Added parameter
  if not value or value == "" then
    local current = self.db.profile.marker
    self:Print("Current marker is " .. current)
    self:Print("Usage: /co marker <value> (1-8)")
  else
    local marker = tonumber(value)
    if marker and marker >= 1 and marker <= 8 then
      self.db.profile.marker = marker
      self:UpdateMarkerTexture()
      self:Print("Marker set to " .. marker)
    else
      self:Print("Marker must be a number between 1 and 8.")
    end
  end
end

function addon:updateOpacity(value) -- BUG FIX: Added parameter
  if not value or value == "" then
    self:Print("Current opacity is " .. self.db.profile.opacity)
    self:Print("Usage: /co opacity <value> (0 to 1)")
  else
    local opacity = tonumber(value)
    if opacity and opacity >= 0 and opacity <= 1 then
      self.db.profile.opacity = opacity
      self:UpdateMarkerOpacity()
      self:Print("Opacity set to " .. opacity)
    else
      self:Print("Opacity must be a number between 0 and 1.")
    end
  end
end

function addon:updateCombatVisibility(value) -- BUG FIX: Added parameter
  if not value or value == "" then
    local status = self.db.profile.showOutOfCombat and "on" or "off"
    self:Print("Show Out of Combat is currently " .. status)
    self:Print("Usage: /co combat <on|off>")
  else
    value = value:lower()
    if value == "on" then
      self.db.profile.showOutOfCombat = true
      self:UpdateMarkerVisibility()
      self:Print("Show Out of Combat enabled.")
    elseif value == "off" then
      self.db.profile.showOutOfCombat = false
      self:UpdateMarkerVisibility()
      self:Print("Show Out of Combat disabled.")
    else
      self:Print("Invalid value. Usage: /co combat <on|off>")
    end
  end
end

function addon:openConfigurationUI()
  -- Modern approach to opening Settings
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(addonName)
  else
    -- Fallback for legacy (Wrath/Classic eras)
    if not InterfaceOptionsFrame then
      C_AddOns.LoadAddOn("Blizzard_InterfaceOptions")
    end
    if InterfaceOptionsFrame_OpenToCategory then
      InterfaceOptionsFrame_OpenToCategory(addonName)
      InterfaceOptionsFrame_OpenToCategory(addonName) -- Twice to force redraw bug in old clients
    else
      self:Print("Unable to open the configuration UI.")
    end
  end
end

function addon:displayHelp()
  self:Print("CursorOutline Commands:")
  self:Print("/co - Show this help message.")
  self:Print("/co config - Open the configuration UI.")
  self:Print("/co scale <value> - Set the size of the X mark (0.5 to 2.0).")
  self:Print("/co marker <value> - Set the raid target marker (1-8).")
  self:Print("/co opacity <value> - Set the X mark opacity (0 to 1).")
  self:Print("/co combat <on|off> - Toggle displaying the X mark out of combat.")
end