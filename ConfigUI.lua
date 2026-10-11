local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local addonName = "CursorOutline"
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

local SUPPORTS_SPECS = (_G.GetSpecialization ~= nil)

local RAID_MARKER_NAMES = {
  "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross (X)", "Skull",
}

local CUSTOM_FILE_LABEL = " [!] Custom File (Type Name Below)"

-- Shape dropdown: the custom file option plus spec icons, limited to the player's class
-- unless "Show All Icons" is enabled
local function GetShapeValues()
    local _, playerClass = UnitClass("player")
    local showAll = addon.db.profile.showAllShapes or not playerClass

    local values = { [addon.CUSTOM_FILE_INPUT] = CUSTOM_FILE_LABEL }
    for path, icon in pairs(addon.SPEC_ICONS) do
        if showAll or icon.class == playerClass then
            values[path] = icon.label
        end
    end
    return values
end

local function IsCustomMode()
    return addon:GetActiveProfile().mode == "CUSTOM"
end

-- Getter/setter for a field of the active appearance profile. Pass redraw = true when
-- the change affects which options are shown.
local function AppearanceGet(key)
    return function() return addon:GetActiveProfile()[key] end
end

local function AppearanceSet(key, redraw)
    return function(_, value)
        addon:GetActiveProfile()[key] = value
        addon:UpdateMarkerAppearance()
        if redraw then addon:RefreshConfigUI() end
    end
end

-- -------------------------------------------------------------------
-- Options Table
-- -------------------------------------------------------------------

function addon:GetOptionsTable()
  return {
    name = addonName,
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
            min = addon.MIN_SCALE, max = addon.MAX_SCALE, step = 0.1,
            get = AppearanceGet("scale"),
            set = AppearanceSet("scale"),
          },
          opacity = {
            order = 3,
            type = "range",
            name = "Opacity",
            desc = "Set the transparency.",
            min = 0, max = 1, step = 0.1,
            hidden = IsCustomMode,
            get = AppearanceGet("opacity"),
            set = AppearanceSet("opacity"),
          },
          showGCD = {
            order = 4,
            type = "toggle",
            name = "Show Global Cooldown",
            desc = "Darken the marker while the global cooldown is active and reveal it clockwise as it finishes.",
            get = function() return addon.db.profile.showGCD end,
            set = function(_, value)
              addon.db.profile.showGCD = value
              addon:EnableGCD()
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
               if not SUPPORTS_SPECS then
                  return "Settings apply to all characters (this game version has no specializations)."
               elseif addon.db.profile.useSpecProfiles then
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
            hidden = not SUPPORTS_SPECS,
            get = function() return addon.db.profile.useSpecProfiles end,
            set = function(_, value)
               addon.db.profile.useSpecProfiles = value
               addon:UpdateMarkerAppearance()
               addon:RefreshConfigUI()
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
            get = AppearanceGet("mode"),
            set = AppearanceSet("mode", true),
          },
          markerIndex = {
            order = 2,
            type = "select",
            name = "Raid Marker",
            values = RAID_MARKER_NAMES,
            width = 1,
            hidden = IsCustomMode,
            get = AppearanceGet("markerIndex"),
            set = AppearanceSet("markerIndex"),
          },
          customShape = {
            order = 3,
            type = "select",
            name = "Shape",
            values = GetShapeValues,
            width = 1,
            hidden = function() return not IsCustomMode() end,
            get = AppearanceGet("customShape"),
            set = AppearanceSet("customShape", true),
          },
          customFilePath = {
            order = 3.1,
            type = "input",
            name = "Filename",
            desc = "Enter the full name (including .tga) of your file in Textures/Custom.\nExample: myIcon.tga",
            width = 2.0,
            hidden = function()
              return not IsCustomMode() or addon:GetActiveProfile().customShape ~= addon.CUSTOM_FILE_INPUT
            end,
            get = AppearanceGet("customFilePath"),
            set = AppearanceSet("customFilePath"),
          },
          showAllShapes = {
            order = 3.5,
            type = "toggle",
            name = "Show All Icons",
            desc = "Show icons for all classes in the dropdown.",
            width = 0.75,
            hidden = function() return not IsCustomMode() end,
            get = function() return addon.db.profile.showAllShapes end,
            set = function(_, value)
              addon.db.profile.showAllShapes = value
              addon:RefreshConfigUI()
            end,
          },
          customColor = {
            order = 4,
            type = "color",
            name = "Color",
            hasAlpha = true,
            width = 0.5,
            hidden = function() return not IsCustomMode() end,
            get = function()
              local c = addon:GetActiveProfile().customColor
              return c.r, c.g, c.b, c.a
            end,
            set = function(_, r, g, b, a)
              local c = addon:GetActiveProfile().customColor
              c.r, c.g, c.b, c.a = r, g, b, a
              addon:UpdateMarkerAppearance()
            end,
          },
        },
      },
    },
  }
end

-- -------------------------------------------------------------------
-- Registration / opening
-- -------------------------------------------------------------------

function addon:SetupConfigUI()
  AceConfig:RegisterOptionsTable(addonName, self:GetOptionsTable())
  -- The category ID is a number on 12.0+ and must be passed to Settings.OpenToCategory
  local _, categoryID = AceConfigDialog:AddToBlizOptions(addonName, addonName)
  self.optionsCategoryID = categoryID
end

function addon:OpenConfigUI()
  Settings.OpenToCategory(self.optionsCategoryID)
end

-- Rebuilds the options panel if it is open, so dynamic hidden/values callbacks re-run
function addon:RefreshConfigUI()
  AceConfigRegistry:NotifyChange(addonName)
end
