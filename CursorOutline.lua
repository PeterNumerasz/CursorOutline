-- The main file of CursorOutline addon
local addonName = "CursorOutline"
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local AceDB = LibStub("AceDB-3.0")

local GetCursorPosition = GetCursorPosition
local UIParent = UIParent

-- FEATURE DETECTION:
-- Specializations only exist on Retail and MoP Classic. On the other Classic flavors
-- the addon always uses the global profile.
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local SUPPORTS_SPECS = (GetSpecialization ~= nil)

local BASE_SIZE = 38
addon.MIN_SCALE, addon.MAX_SCALE = 0.5, 3.0

addon.CUSTOM_FILE_INPUT = "CUSTOM_FILE_INPUT"
local CUSTOM_TEXTURE_PATH = "Interface\\AddOns\\CursorOutline\\Textures\\Custom\\"
local SPEC_TEXTURE_PATH = "Interface\\AddOns\\CursorOutline\\Textures\\Specs\\"

-- Spec icons: { specID, class tag, file name in Textures/Specs (without .tga), dropdown label }
local SPEC_ICON_LIST = {
    { 250, "DEATHKNIGHT", "DeathKnight_Blood", "DK: Blood" },
    { 251, "DEATHKNIGHT", "DeathKnight_Frost", "DK: Frost" },
    { 252, "DEATHKNIGHT", "DeathKnight_Unholy", "DK: Unholy" },
    { 577, "DEMONHUNTER", "DemonHunter_Havoc", "DH: Havoc" },
    { 581, "DEMONHUNTER", "DemonHunter_Vengeance", "DH: Vengeance" },
    { 1480, "DEMONHUNTER", "DemonHunter_Devourer", "DH: Devourer" },
    { 102, "DRUID", "Druid_Balance", "Druid: Balance" },
    { 103, "DRUID", "Druid_Feral", "Druid: Feral" },
    { 104, "DRUID", "Druid_Guardian", "Druid: Guardian" },
    { 105, "DRUID", "Druid_Restoration", "Druid: Restoration" },
    { 1467, "EVOKER", "Evoker_Devastation", "Evoker: Devastation" },
    { 1468, "EVOKER", "Evoker_Preservation", "Evoker: Preservation" },
    { 1473, "EVOKER", "Evoker_Augmentation", "Evoker: Augmentation" },
    { 253, "HUNTER", "Hunter_BeastMastery", "Hunter: Beast Mastery" },
    { 254, "HUNTER", "Hunter_Marksmanship", "Hunter: Marksmanship" },
    { 255, "HUNTER", "Hunter_Survival", "Hunter: Survival" },
    { 62, "MAGE", "Mage_Arcane", "Mage: Arcane" },
    { 63, "MAGE", "Mage_Fire", "Mage: Fire" },
    { 64, "MAGE", "Mage_Frost", "Mage: Frost" },
    { 268, "MONK", "Monk_Brewmaster", "Monk: Brewmaster" },
    { 270, "MONK", "Monk_Mistweaver", "Monk: Mistweaver" },
    { 269, "MONK", "Monk_Windwalker", "Monk: Windwalker" },
    { 65, "PALADIN", "Paladin_Holy", "Paladin: Holy" },
    { 66, "PALADIN", "Paladin_Protection", "Paladin: Protection" },
    { 70, "PALADIN", "Paladin_Retribution", "Paladin: Retribution" },
    { 256, "PRIEST", "Priest_Discipline", "Priest: Discipline" },
    { 257, "PRIEST", "Priest_Holy", "Priest: Holy" },
    { 258, "PRIEST", "Priest_Shadow", "Priest: Shadow" },
    { 259, "ROGUE", "Rogue_Assassination", "Rogue: Assassination" },
    { 260, "ROGUE", "Rogue_Outlaw", "Rogue: Outlaw" },
    { 261, "ROGUE", "Rogue_Subtlety", "Rogue: Subtlety" },
    { 262, "SHAMAN", "Shaman_Elemental", "Shaman: Elemental" },
    { 263, "SHAMAN", "Shaman_Enhancement", "Shaman: Enhancement" },
    { 264, "SHAMAN", "Shaman_Restoration", "Shaman: Restoration" },
    { 265, "WARLOCK", "Warlock_Affliction", "Warlock: Affliction" },
    { 266, "WARLOCK", "Warlock_Demonology", "Warlock: Demonology" },
    { 267, "WARLOCK", "Warlock_Destruction", "Warlock: Destruction" },
    { 71, "WARRIOR", "Warrior_Arms", "Warrior: Arms" },
    { 72, "WARRIOR", "Warrior_Fury", "Warrior: Fury" },
    { 73, "WARRIOR", "Warrior_Protection", "Warrior: Protection" },
}

-- Texture path -> { class = classTag, label = dropdown label }, used by the options UI
addon.SPEC_ICONS = {}
-- Spec ID -> texture path, used as the default icon for new spec profiles
local SPEC_TEXTURES = {}
for _, entry in ipairs(SPEC_ICON_LIST) do
    local specID, class, file, label = unpack(entry)
    local path = SPEC_TEXTURE_PATH .. file .. ".tga"
    SPEC_TEXTURES[specID] = path
    addon.SPEC_ICONS[path] = { class = class, label = label }
end

local RAID_TARGET_MARKERS = {}
for i = 1, 8 do
    RAID_TARGET_MARKERS[i] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i
end

local DEFAULT_APPEARANCE = {
    mode = "RAID_MARKER",
    markerIndex = 7,
    customShape = "",
    customFilePath = "",
    customColor = { r = 1, g = 1, b = 1, a = 1 },
    scale = 1.0,
    opacity = 1.0,
}

addon.defaults = {
  profile = {
    showOutOfCombat = false,
    useSpecProfiles = false,
    showAllShapes = false,
    showGCD = false,
    global = DEFAULT_APPEARANCE,
    specs = {},
  },
}

local mainFrame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
mainFrame:EnableMouse(false)
mainFrame:SetFrameStrata("TOOLTIP")
mainFrame:Hide()
local mainTexture = mainFrame:CreateTexture(nil, "OVERLAY")
mainTexture:SetAllPoints(mainFrame)
addon.markerFrame = mainFrame

-- -----------------------------------------------------------------------
-- PROFILE LOGIC
-- -----------------------------------------------------------------------

local function CreateSpecProfile(specID)
    local profile = CopyTable(DEFAULT_APPEARANCE)
    local icon = SPEC_TEXTURES[specID]
    if icon then
        profile.mode = "CUSTOM"
        profile.customShape = icon
    end
    return profile
end

-- Returns the appearance settings currently in use: the per-spec table when spec
-- profiles are enabled, otherwise the global one.
function addon:GetActiveProfile()
    local p = self.db.profile

    if SUPPORTS_SPECS and p.useSpecProfiles then
        local specIndex = GetSpecialization()
        local specID = specIndex and GetSpecializationInfo(specIndex)
        if specID then
            if not p.specs[specID] then
                p.specs[specID] = CreateSpecProfile(specID)
            end
            return p.specs[specID]
        end
    end

    return p.global
end

-- -----------------------------------------------------------------------
-- DISPLAY UPDATES
-- -----------------------------------------------------------------------

-- Last applied cursor position; lets OnUpdate skip SetPoint while the mouse is idle
local lastX, lastY

-- OnUpdate only runs while the frame is shown, so a hidden marker costs no CPU
mainFrame:SetScript("OnUpdate", function()
  local x, y = GetCursorPosition()
  if x == lastX and y == lastY then return end
  lastX, lastY = x, y
  local scale = UIParent:GetEffectiveScale()
  mainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end)

-- Force a reposition on the first frame after showing
mainFrame:SetScript("OnShow", function()
  lastX, lastY = nil, nil
end)

function addon:UpdateMarkerAppearance()
  local settings = self:GetActiveProfile()
  mainFrame:SetSize(BASE_SIZE * settings.scale, BASE_SIZE * settings.scale)

  local texture, isTinted
  if settings.mode == "CUSTOM" then
    texture = settings.customShape
    if texture == addon.CUSTOM_FILE_INPUT then
        texture = CUSTOM_TEXTURE_PATH .. (settings.customFilePath or "")
    end
    if not texture or texture == "" then
        texture = "Interface\\BUTTONS\\WHITE8X8"
    end

    local c = settings.customColor
    mainTexture:SetVertexColor(c.r, c.g, c.b, c.a)
    isTinted = (c.r + c.g + c.b) < 2.7 -- near-white counts as untinted
  else
    texture = RAID_TARGET_MARKERS[settings.markerIndex]
    mainTexture:SetVertexColor(1, 1, 1, settings.opacity)
    isTinted = false
  end
  mainTexture:SetTexture(texture)

  -- The GCD swipe uses the marker's own texture so it only covers the icon's shape
  self:UpdateGCDTexture(texture, isTinted)
end

function addon:UpdateMarkerVisibility()
  mainFrame:SetShown(self.db.profile.showOutOfCombat or self.inCombat)
end

-- -----------------------------------------------------------------------
-- EVENTS
-- -----------------------------------------------------------------------

function addon:OnInitialize()
  self.db = AceDB:New("CursorOutlineDB", self.defaults, true)
  self:RegisterChatCommand("co", "HandleSlashCommand")
  self:RegisterChatCommand("cursoroutline", "HandleSlashCommand")
  self:SetupConfigUI()
end

function addon:OnEnable()
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  if SUPPORTS_SPECS then
      self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  end

  -- Track combat state ourselves: InCombatLockdown() is not yet true inside PLAYER_REGEN_DISABLED
  self.inCombat = InCombatLockdown() and true or false

  self:EnableGCD()
  self:UpdateMarkerAppearance()
  self:UpdateMarkerVisibility()
end

function addon:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    -- On Retail this also fires for group members; only react to our own spec
    if unit and unit ~= "player" then return end
    self:UpdateMarkerAppearance()
    self:RefreshConfigUI()
end

function addon:PLAYER_REGEN_DISABLED()
  self.inCombat = true
  self:UpdateMarkerVisibility()
end

function addon:PLAYER_REGEN_ENABLED()
  self.inCombat = false
  self:UpdateMarkerVisibility()
end

-- -----------------------------------------------------------------------
-- SLASH COMMANDS
-- -----------------------------------------------------------------------

function addon:HandleSlashCommand(input)
  local command, value = input:match("^(%S*)%s*(%S*)")
  command = command:lower()

  if command == "config" then
    self:OpenConfigUI()
  elseif command == "scale" then
    self:SetScaleCommand(value)
  elseif command == "combat" then
    self:SetCombatCommand(value:lower())
  else
    self:PrintHelp()
  end
end

function addon:SetScaleCommand(value)
  local scale = tonumber(value)
  if not scale then
    self:Print("Current scale: " .. self:GetActiveProfile().scale)
  elseif scale < self.MIN_SCALE or scale > self.MAX_SCALE then
    self:Print(("Scale must be between %.1f and %.1f."):format(self.MIN_SCALE, self.MAX_SCALE))
  else
    self:GetActiveProfile().scale = scale
    self:UpdateMarkerAppearance()
    self:RefreshConfigUI()
    self:Print("Scale set to " .. scale)
  end
end

function addon:SetCombatCommand(value)
  if value == "on" then
    self.db.profile.showOutOfCombat = true
  elseif value == "off" then
    self.db.profile.showOutOfCombat = false
  else
    self:Print("Usage: /co combat on|off")
    return
  end
  self:UpdateMarkerVisibility()
  self:RefreshConfigUI()
  self:Print(self.db.profile.showOutOfCombat and "Marker is now always shown." or "Marker is now only shown in combat.")
end

function addon:PrintHelp()
  self:Print("Commands:")
  self:Print("/co config - Open the settings.")
  self:Print("/co combat on|off - on: always show the marker, off: only show it in combat.")
  self:Print(("/co scale <%.1f-%.1f> - Set the marker size."):format(self.MIN_SCALE, self.MAX_SCALE))
end
