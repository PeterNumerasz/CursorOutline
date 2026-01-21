-- The main file of CursorOutline addon
local addonName = "CursorOutline"
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local AceDB = LibStub("AceDB-3.0")

local GetCursorPosition = GetCursorPosition
local UIParent = UIParent
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo

-- Path shortcut
local P = "Interface\\AddOns\\CursorOutline\\Textures\\Specs\\"

-- Mapping WoW Spec IDs to your Filenames
local SPEC_TEXTURES = {
    -- Death Knight
    [250] = P.."DeathKnight_Blood.tga", [251] = P.."DeathKnight_Frost.tga", [252] = P.."DeathKnight_Unholy.tga",
    -- Demon Hunter
    [577] = P.."DemonHunter_Havoc.tga", [581] = P.."DemonHunter_Vengeance.tga",
    -- Druid
    [102] = P.."Druid_Balance.tga", [103] = P.."Druid_Feral.tga", [104] = P.."Druid_Guardian.tga", [105] = P.."Druid_Restoration.tga",
    -- Evoker
    [1467] = P.."Evoker_Devastation.tga", [1468] = P.."Evoker_Preservation.tga", [1473] = P.."Evoker_Augmentation.tga",
    -- Hunter
    [253] = P.."Hunter_BeastMastery.tga", [254] = P.."Hunter_Marksmanship.tga", [255] = P.."Hunter_Survival.tga",
    -- Mage
    [62] = P.."Mage_Arcane.tga", [63] = P.."Mage_Fire.tga", [64] = P.."Mage_Frost.tga",
    -- Monk
    [268] = P.."Monk_Brewmaster.tga", [270] = P.."Monk_Mistweaver.tga", [269] = P.."Monk_Windwalker.tga",
    -- Paladin
    [65] = P.."Paladin_Holy.tga", [66] = P.."Paladin_Protection.tga", [70] = P.."Paladin_Retribution.tga",
    -- Priest
    [256] = P.."Priest_Discipline.tga", [257] = P.."Priest_Holy.tga", [258] = P.."Priest_Shadow.tga",
    -- Rogue
    [259] = P.."Rogue_Assassination.tga", [260] = P.."Rogue_Outlaw.tga", [261] = P.."Rogue_Subtlety.tga",
    -- Shaman
    [262] = P.."Shaman_Elemental.tga", [263] = P.."Shaman_Enhancement.tga", [264] = P.."Shaman_Restoration.tga",
    -- Warlock
    [265] = P.."Warlock_Affliction.tga", [266] = P.."Warlock_Demonology.tga", [267] = P.."Warlock_Destruction.tga",
    -- Warrior
    [71] = P.."Warrior_Arms.tga", [72] = P.."Warrior_Fury.tga", [73] = P.."Warrior_Protection.tga",
}

-- Standard Defaults (Used if no profile exists)
addon.defaults = {
  profile = {
    showOutOfCombat = false, 
    useSpecProfiles = false,
    showAllShapes = false,

    -- Default "Global" settings
    global = {
        mode = "RAID_MARKER",
        markerIndex = 7,
        customShape = "", 
        customFilePath = "", -- New Field for custom filenames
        customColor = { r = 1, g = 1, b = 1, a = 1 },
        scale = 1.0,
        opacity = 1.0,
    },

    specs = {}, 
  },
}

local RAID_TARGET_MARKERS = {
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
  "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}

local mainFrame = CreateFrame("Frame", "CursorOutlineFrame", UIParent)
mainFrame:EnableMouse(false)
mainFrame:SetFrameStrata("TOOLTIP")
local mainTexture = mainFrame:CreateTexture(nil, "OVERLAY")

-- -----------------------------------------------------------------------
-- PROFILE LOGIC
-- -----------------------------------------------------------------------

function addon:GetActiveProfile()
    local p = self.db.profile
    
    if p.useSpecProfiles then
        local specIndex = GetSpecialization()
        if specIndex then
            local specID = GetSpecializationInfo(specIndex)
            if specID then
                -- INTELLIGENT DEFAULTING
                if not p.specs[specID] then
                    local defaultIcon = SPEC_TEXTURES[specID]
                    
                    local startMode = defaultIcon and "CUSTOM" or "RAID_MARKER"
                    
                    p.specs[specID] = {
                        mode = startMode,
                        markerIndex = 7, 
                        customShape = defaultIcon or "", 
                        customFilePath = "", -- Default empty
                        customColor = { r = 1, g = 1, b = 1, a = 1 }, 
                        scale = 1.0,
                        opacity = 1.0,
                    }
                end
                return p.specs[specID]
            end
        end
    end
    
    -- Fallback: Use Global
    if not p.global then p.global = {} end
    if not p.global.mode and p.mode then
        -- Migration logic
        p.global.mode = p.mode
        p.global.markerIndex = p.markerIndex
        p.global.customShape = p.customShape
        p.global.customFilePath = "" -- Ensure key exists
        p.global.customColor = p.customColor
        p.global.scale = p.scale
        p.global.opacity = p.opacity
    end
    
    return p.global
end

function addon:RefreshActiveProfile()
    self:UpdateMarkerAppearance()
end

-- -----------------------------------------------------------------------
-- DISPLAY UPDATES
-- -----------------------------------------------------------------------

local function UpdateXMarkPosition()
  local x, y = GetCursorPosition()
  local scale = UIParent:GetEffectiveScale()
  mainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

function addon:UpdateMarkerAppearance()
  local settings = self:GetActiveProfile()
  
  -- 1. Set Size
  mainFrame:SetSize(38 * settings.scale, 38 * settings.scale)
  
  -- 2. Set Texture & Color
  if settings.mode == "CUSTOM" then
    local textureToUse = settings.customShape
    
    -- LOGIC: If "Custom File" mode, look in the Custom folder
    if settings.customShape == "CUSTOM_FILE_INPUT" then
        textureToUse = "Interface\\AddOns\\CursorOutline\\Textures\\Custom\\" .. (settings.customFilePath or "")
    end
    
    -- Safety check to avoid green boxes if string is empty
    if textureToUse and textureToUse ~= "" then
        mainTexture:SetTexture(textureToUse)
    else
        mainTexture:SetTexture("Interface\\BUTTONS\\WHITE8X8") -- Fallback
    end

    mainTexture:SetVertexColor(settings.customColor.r, settings.customColor.g, settings.customColor.b, settings.customColor.a)
    mainTexture:SetBlendMode("BLEND") 
  else
    -- RAID MARKER MODE
    local texturePath = RAID_TARGET_MARKERS[settings.markerIndex]
    mainTexture:SetTexture(texturePath)
    mainTexture:SetVertexColor(1, 1, 1, settings.opacity)
    mainTexture:SetBlendMode("BLEND")
  end
  
  mainTexture:SetAllPoints(mainFrame)
end

function addon:UpdateMarkerVisibility()
  if self.db.profile.showOutOfCombat or InCombatLockdown() or self.testMode then
    mainFrame:Show()
    mainFrame:SetScript("OnUpdate", UpdateXMarkPosition)
  else
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  end
end

-- -----------------------------------------------------------------------
-- EVENTS
-- -----------------------------------------------------------------------

function addon:OnInitialize()
  self.db = AceDB:New("CursorOutlineDB", self.defaults, true)
  mainFrame:SetPoint("CENTER", UIParent, "CENTER"); mainFrame:Hide()
  
  self:RegisterChatCommand("co", "HandleSlashCommand")
  self:RegisterChatCommand("cursoroutline", "HandleSlashCommand")
  
  if self.SetupConfigUI then self:SetupConfigUI() end
end

function addon:OnEnable()
  self:RegisterEvent("PLAYER_REGEN_DISABLED")
  self:RegisterEvent("PLAYER_REGEN_ENABLED")
  self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  
  self:UpdateMarkerAppearance()
  self:UpdateMarkerVisibility()
end

function addon:PLAYER_SPECIALIZATION_CHANGED()
    self:UpdateMarkerAppearance()
    if self.ForceRedraw then self:ForceRedraw() end
end

function addon:PLAYER_REGEN_DISABLED()
  mainFrame:Show()
  mainFrame:SetScript("OnUpdate", UpdateXMarkPosition)
end

function addon:PLAYER_REGEN_ENABLED()
  if not self.db.profile.showOutOfCombat then
    mainFrame:Hide()
    mainFrame:SetScript("OnUpdate", nil)
  end
end

function addon:EnableTestMode()
  self.testMode = true
  self:UpdateMarkerVisibility()
end

function addon:DisableTestMode()
  self.testMode = false
  self:UpdateMarkerVisibility()
end

-- -----------------------------------------------------------------------
-- SLASH COMMANDS
-- -----------------------------------------------------------------------

function addon:HandleSlashCommand(input)
  local command, value = input:match("^(%S+)%s*(%S*)$")
  command = (command or ""):lower()

  if command == "config" then
    self:openConfigurationUI()
  elseif command == "scale" then
    self:setScale(value)
  elseif command == "combat" then
    self:updateCombatVisibility(value)
  elseif command == "help" or command == "" then
    self:displayHelp()
  else
    self:Print("Unknown command or command handled in UI. Type /co config")
  end
end

function addon:setScale(value)
  if not value or value == "" then
    self:Print("Current scale: " .. self:GetActiveProfile().scale)
    return
  end
  local scale = tonumber(value)
  if scale and scale >= 0.5 and scale <= 2.0 then
    self:GetActiveProfile().scale = scale
    self:UpdateMarkerAppearance()
    self:Print("Scale set to " .. scale)
  end
end

function addon:updateCombatVisibility(value)
  if value == "on" then
    self.db.profile.showOutOfCombat = true
  elseif value == "off" then
    self.db.profile.showOutOfCombat = false
  end
  self:UpdateMarkerVisibility()
end

function addon:openConfigurationUI()
  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(addonName)
  else
    if not InterfaceOptionsFrame then C_AddOns.LoadAddOn("Blizzard_InterfaceOptions") end
    InterfaceOptionsFrame_OpenToCategory(addonName)
    InterfaceOptionsFrame_OpenToCategory(addonName)
  end
  
  if self.ForceRedraw then self:ForceRedraw() end
end

function addon:displayHelp()
  self:Print("CursorOutline Commands:")
  self:Print("/co config - Open the configuration UI.")
  self:Print("/co combat <on|off> - Toggle out of combat display.")
  self:Print("/co scale <number> - Set size.")
end