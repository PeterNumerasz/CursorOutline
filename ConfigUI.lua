local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("CursorOutline")

local RAID_TARGET_MARKERS = {
  "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross (X)", "Skull",
}

local P = "Interface\\AddOns\\CursorOutline\\Textures\\Specs\\"

local CLASS_PREFIXES = {
    ["DEATHKNIGHT"] = "DeathKnight",
    ["DEMONHUNTER"] = "DemonHunter",
    ["DRUID"] = "Druid",
    ["EVOKER"] = "Evoker",
    ["HUNTER"] = "Hunter",
    ["MAGE"] = "Mage",
    ["MONK"] = "Monk",
    ["PALADIN"] = "Paladin",
    ["PRIEST"] = "Priest",
    ["ROGUE"] = "Rogue",
    ["SHAMAN"] = "Shaman",
    ["WARLOCK"] = "Warlock",
    ["WARRIOR"] = "Warrior",
}

-- All Specs + The Custom File Option
local CUSTOM_SHAPES = {
  ["CUSTOM_FILE_INPUT"] = " [!] Custom File (Type Name Below)",

  -- Death Knight
  [P.."DeathKnight_Blood.tga"] = "DK: Blood",
  [P.."DeathKnight_Frost.tga"] = "DK: Frost",
  [P.."DeathKnight_Unholy.tga"] = "DK: Unholy",
  
  -- Demon Hunter
  [P.."DemonHunter_Havoc.tga"] = "DH: Havoc",
  [P.."DemonHunter_Vengeance.tga"] = "DH: Vengeance",
  [P.."DemonHunter_Devourer.tga"] = "DH: Devourer",
  
  -- Druid
  [P.."Druid_Balance.tga"] = "Druid: Balance",
  [P.."Druid_Feral.tga"] = "Druid: Feral",
  [P.."Druid_Guardian.tga"] = "Druid: Guardian",
  [P.."Druid_Restoration.tga"] = "Druid: Restoration",
  
  -- Evoker
  [P.."Evoker_Augmentation.tga"] = "Evoker: Augmentation",
  [P.."Evoker_Devastation.tga"] = "Evoker: Devastation",
  [P.."Evoker_Preservation.tga"] = "Evoker: Preservation",
  
  -- Hunter
  [P.."Hunter_BeastMastery.tga"] = "Hunter: Beast Mastery",
  [P.."Hunter_Marksmanship.tga"] = "Hunter: Marksmanship",
  [P.."Hunter_Survival.tga"] = "Hunter: Survival",
  
  -- Mage
  [P.."Mage_Arcane.tga"] = "Mage: Arcane",
  [P.."Mage_Fire.tga"] = "Mage: Fire",
  [P.."Mage_Frost.tga"] = "Mage: Frost",
  
  -- Monk
  [P.."Monk_Brewmaster.tga"] = "Monk: Brewmaster",
  [P.."Monk_Mistweaver.tga"] = "Monk: Mistweaver",
  [P.."Monk_Windwalker.tga"] = "Monk: Windwalker",
  
  -- Paladin
  [P.."Paladin_Holy.tga"] = "Paladin: Holy",
  [P.."Paladin_Protection.tga"] = "Paladin: Protection",
  [P.."Paladin_Retribution.tga"] = "Paladin: Retribution",
  
  -- Priest
  [P.."Priest_Discipline.tga"] = "Priest: Discipline",
  [P.."Priest_Holy.tga"] = "Priest: Holy",
  [P.."Priest_Shadow.tga"] = "Priest: Shadow",
  
  -- Rogue
  [P.."Rogue_Assassination.tga"] = "Rogue: Assassination",
  [P.."Rogue_Outlaw.tga"] = "Rogue: Outlaw",
  [P.."Rogue_Subtlety.tga"] = "Rogue: Subtlety",
  
  -- Shaman
  [P.."Shaman_Elemental.tga"] = "Shaman: Elemental",
  [P.."Shaman_Enhancement.tga"] = "Shaman: Enhancement",
  [P.."Shaman_Restoration.tga"] = "Shaman: Restoration",
  
  -- Warlock
  [P.."Warlock_Affliction.tga"] = "Warlock: Affliction",
  [P.."Warlock_Demonology.tga"] = "Warlock: Demonology",
  [P.."Warlock_Destruction.tga"] = "Warlock: Destruction",
  
  -- Warrior
  [P.."Warrior_Arms.tga"] = "Warrior: Arms",
  [P.."Warrior_Fury.tga"] = "Warrior: Fury",
  [P.."Warrior_Protection.tga"] = "Warrior: Protection",
}

-- Smart Filter Function
local function GetFilteredShapes()
    if addon.db.profile.showAllShapes then
        return CUSTOM_SHAPES
    end

    local _, classTag = UnitClass("player")
    if not classTag then return CUSTOM_SHAPES end
    local prefix = CLASS_PREFIXES[classTag] or "Unknown"
    
    local filtered = {}
    filtered["CUSTOM_FILE_INPUT"] = CUSTOM_SHAPES["CUSTOM_FILE_INPUT"]
    
    for path, label in pairs(CUSTOM_SHAPES) do
        if path:find(prefix .. "_") then
            filtered[path] = label
        end
    end
    return filtered
end

-- -------------------------------------------------------------------
-- Options Table
-- -------------------------------------------------------------------

function addon:GetOptionsTable()
  return {
    name = "CursorOutline",
    type = "group",
    args = {
      description = {
        order = 0,
        type = "description",
        name = "Customize your cursor tracking visual.",
      },
      generalGroup = {
        order = 1,
        type = "group",
        name = "General Settings",
        inline = true,
        args = {
          showOutOfCombat = {
            order = 1,
            type = "toggle",
            name = "Show Out of Combat",
            desc = "Display the marker even when not in combat.",
            get = function() return addon.db.profile.showOutOfCombat end,
            set = function(_, value)
              addon.db.profile.showOutOfCombat = value
              addon:UpdateMarkerVisibility()
            end,
          },
          scale = {
            order = 2,
            type = "range",
            name = "Scale",
            desc = "Adjust the size of the marker.",
            min = 0.5, max = 3.0, step = 0.1,
            get = function() return addon:GetActiveProfile().scale end,
            set = function(_, value)
              addon:GetActiveProfile().scale = value
              addon:UpdateMarkerAppearance()
            end,
          },
          opacity = {
            order = 3,
            type = "range",
            name = "Opacity",
            desc = "Set the transparency.",
            min = 0, max = 1, step = 0.1,
            hidden = function() return addon:GetActiveProfile().mode == "CUSTOM" end,
            get = function() return addon:GetActiveProfile().opacity end,
            set = function(_, value)
              addon:GetActiveProfile().opacity = value
              addon:UpdateMarkerAppearance()
            end,
          },
        },
      },
      appearanceGroup = {
        order = 2,
        type = "group",
        name = "Appearance",
        inline = true,
        args = {
           profileInfo = {
            order = 0,
            type = "description",
            name = function() 
               if addon.db.profile.useSpecProfiles then
                  return "|cff00ff00[Spec Profile Active]|r Settings are saved for your current spec."
               else
                  return "Settings apply to all characters."
               end
            end,
          },
          useSpecProfiles = {
            order = 0.5,
            type = "toggle",
            name = "Enable Spec Profiles",
            desc = "If enabled, your Shape, Color, and Size will be saved separately for each Specialization.",
            width = "full",
            get = function() return addon.db.profile.useSpecProfiles end,
            set = function(_, val)
               addon.db.profile.useSpecProfiles = val
               addon:RefreshActiveProfile()
               addon:ForceRedraw()
            end,
          },
          mode = {
            order = 1,
            type = "select",
            name = "Mode",
            desc = "Choose between standard Raid Markers or a Custom Colored Shape.",
            values = {
              ["RAID_MARKER"] = "Raid Marker (Standard)",
              ["CUSTOM"] = "Custom Shape & Color",
            },
            width = 1,
            get = function() return addon:GetActiveProfile().mode end,
            set = function(_, value)
              addon:GetActiveProfile().mode = value
              addon:UpdateMarkerAppearance()
              addon:ForceRedraw()
            end,
          },
          markerIndex = {
            order = 2,
            type = "select",
            name = "Raid Marker",
            values = RAID_TARGET_MARKERS,
            width = 1, 
            hidden = function() return addon:GetActiveProfile().mode == "CUSTOM" end,
            get = function() return addon:GetActiveProfile().markerIndex end,
            set = function(_, value)
              addon:GetActiveProfile().markerIndex = value
              addon:UpdateMarkerAppearance()
            end,
          },
          
          -- CUSTOM SHAPE SELECTOR
          customShape = {
            order = 3,
            type = "select",
            name = "Shape",
            values = GetFilteredShapes,
            width = 1,
            hidden = function() return addon:GetActiveProfile().mode ~= "CUSTOM" end,
            get = function() return addon:GetActiveProfile().customShape end,
            set = function(_, value)
              addon:GetActiveProfile().customShape = value
              addon:UpdateMarkerAppearance()
              addon:ForceRedraw() 
            end,
          },
          
          -- COLOR PICKER
          customColor = {
            order = 4,
            type = "color",
            name = "Color",
            hasAlpha = true,
            width = 0.5, 
            hidden = function() return addon:GetActiveProfile().mode ~= "CUSTOM" end,
            get = function(info)
              local c = addon:GetActiveProfile().customColor
              return c.r, c.g, c.b, c.a
            end,
            set = function(info, r, g, b, a)
              local c = addon:GetActiveProfile().customColor
              c.r, c.g, c.b, c.a = r, g, b, a
              addon:UpdateMarkerAppearance()
            end,
          },

          -- FILE INPUT BOX
          customFilePath = {
            order = 3.1,
            type = "input",
            name = "Filename",
            desc = "Enter the full name (including .tga) of your file in Textures/Custom.\nExample: myIcon.tga",
            width = 2.0,
            hidden = function() return addon:GetActiveProfile().customShape ~= "CUSTOM_FILE_INPUT" end,
            get = function() return addon:GetActiveProfile().customFilePath end,
            set = function(_, value)
              addon:GetActiveProfile().customFilePath = value
              addon:UpdateMarkerAppearance()
            end,
          },
          
          -- SHOW ALL TOGGLE
          showAllShapes = {
            order = 3.5,
            type = "toggle",
            name = "Show All Icons",
            desc = "Show icons for all classes in the dropdown.",
            width = 0.75, 
            hidden = function() return addon:GetActiveProfile().mode ~= "CUSTOM" end,
            get = function() return addon.db.profile.showAllShapes end,
            set = function(_, value)
              addon.db.profile.showAllShapes = value
              addon:ForceRedraw()
            end,
          },
        },
      },
    },
  }
end

-- -------------------------------------------------------------------
-- Initialization
-- -------------------------------------------------------------------

function addon:SetupConfigUI()
  AceConfig:RegisterOptionsTable("CursorOutline", addon:GetOptionsTable())
  AceConfigDialog:AddToBlizOptions("CursorOutline", "CursorOutline")

  if SettingsPanel then
     SettingsPanel:HookScript("OnShow", function() addon:ForceRedraw() end)
  elseif InterfaceOptionsFrame then
     InterfaceOptionsFrame:HookScript("OnShow", function() addon:ForceRedraw() end)
  end
end

function addon:ForceRedraw()
    C_Timer.After(0.1, function() 
        LibStub("AceConfigRegistry-3.0"):NotifyChange("CursorOutline") 
    end)
end