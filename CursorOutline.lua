-- The main file of CursorOutline addon

local AceDB = LibStub("AceDB-3.0")
local addon = LibStub("AceAddon-3.0"):NewAddon("CursorOutline", "AceConsole-3.0")
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

-- Helper to get a readable marker name
local function GetMarkerName(markerIndex)
  local names = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross (X)",
    [8] = "Skull",
  }
  return names[markerIndex] or "Unknown"
end

-- Create the frame for the marker
local mainFrame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
local mainTexture = mainFrame:CreateTexture(nil, "OVERLAY")

-- Updates the position of the marker to follow the mouse
local function UpdateXMarkPosition()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  mainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- Handles combat state changes
local function OnCombatStateChange(event)
  if event == "PLAYER_REGEN_DISABLED" then
    mainFrame:Show()
    mainFrame:SetScript("OnUpdate", UpdateXMarkPosition)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if not addon.db.profile.showOutOfCombat then
      mainFrame:Hide()
      mainFrame:SetScript("OnUpdate", nil)
    end
  end
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

-- Test mode (for previewing the marker)
function addon:EnableTestMode()
  self.testMode = true
  mainFrame:Show()
  mainFrame:SetScript("OnUpdate", UpdateXMarkPosition)
end

function addon:DisableTestMode()
  self.testMode = false
  if not self.db.profile.showOutOfCombat then
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  else
    self:UpdateMarkerVisibility()
  end
end

-- Slash command handling with added functionalities for marker, opacity, and combat toggle
function addon:HandleSlashCommand(input)
  local command, value = input:match("^(%S+)%s*(%S*)$")
  command = (command or ""):lower()

  if command == "scale" then
    addon:setScale()
  elseif command == "marker" then
    addon:setMarker()
  elseif command == "opacity" then
    addon:updateOpacity()
  elseif command == "combat" then
    addon:updateCombatVisibility()
  elseif command == "config" then
    addon:openConfigurationUI()
  elseif command == "help" or command == "" then
    addon:displayHelp()
  else
    addon:Print("Unknown command. Type /co help for a list of commands.")
  end
end

-- Registers slash commands
function addon:RegisterSlashCommands()
  SLASH_CURSOROUTLINE1 = "/co"
  SLASH_CURSOROUTLINE2 = "/cursoroutline"
  SlashCmdList["CURSOROUTLINE"] = function(input)
    if input:lower() == "config" then
      if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory("CursorOutline")
      else
        if not InterfaceOptionsFrame then
          C_AddOns.LoadAddOn("Blizzard_InterfaceOptions")
        end
        if InterfaceOptionsFrame_OpenToCategory then
          InterfaceOptionsFrame_OpenToCategory("CursorOutline")
          InterfaceOptionsFrame_OpenToCategory("CursorOutline")
        else
          addon:Print("Unable to open the configuration UI. Please try again.")
        end
      end
    else
      addon:HandleSlashCommand(input)
    end
  end
end

-- Initialization
function addon:onInitialize()
  self.db = AceDB:New("CursorOutlineDB", self.defaults, true)
  self:RegisterSlashCommands()
  self:InitializeFrame()
  self:UpdateMarkerVisibility()
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
  if self.db.profile.showOutOfCombat then
    mainFrame:Show()
    mainFrame:SetScript("OnUpdate", UpdateXMarkPosition)
  else
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  end
end

function addon:setScale()
  if value == "" then
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

function addon:setMarker()
  if value == "" then
    local current = self.db.profile.marker
    self:Print("Current marker is " .. current .. " (" .. GetMarkerName(current) .. ").")
    self:Print("Usage: /co marker <value> (1-8)")
  else
    local marker = tonumber(value)
    if marker and marker >= 1 and marker <= 8 then
      self.db.profile.marker = marker
      self:UpdateMarkerTexture()
      self:Print("Marker set to " .. marker .. " (" .. GetMarkerName(marker) .. ").")
    else
      self:Print("Marker must be a number between 1 and 8.")
    end
  end
end

function addon:updateCombatVisibility()
  if value == "" then
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

function addon:updateOpacity()
  if value == "" then
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

function addon:openConfigurationUI()
  -- Open configuration UI if "config" command is used
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("CursorOutline")
  else
    if not InterfaceOptionsFrame then
      C_AddOns.LoadAddOn("Blizzard_InterfaceOptions")
    end
    if InterfaceOptionsFrame_OpenToCategory then
      InterfaceOptionsFrame_OpenToCategory("CursorOutline")
      InterfaceOptionsFrame_OpenToCategory("CursorOutline")
    else
      self:Print("Unable to open the configuration UI. Please try again.")
    end
  end
end

function addon:displayHelp()
  self:Print("CursorOutline Commands:")
  self:Print("/co - Show this help message.")
  self:Print("/co config - Open the configuration UI.")
  self:Print("/co scale <value> - Set the size of the X mark (0.5 = half size, 1.0 = default, 2.0 = double size).")
  self:Print("/co marker <value> - Set the raid target marker (1-8).")
  self:Print("/co opacity <value> - Set the X mark opacity (0 to 1).")
  self:Print("/co combat <on|off> - Toggle displaying the X mark out of combat.")
end

-- Event registration
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    addon:onInitialize()
  elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    OnCombatStateChange(event)
  end
end)
