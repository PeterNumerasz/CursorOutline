-- Refactored ConfigUI.lua
-- Handles the configuration UI for CursorOutline.

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("CursorOutline")

-- List of raid target markers (for display in the select box)
local RAID_TARGET_MARKERS = {
  "Star",
  "Circle",
  "Diamond",
  "Triangle",
  "Moon",
  "Square",
  "Cross (X)",
  "Skull",
}

-- Returns the configuration options table
function addon:GetOptionsTable()
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
        get = function() return addon.db.profile.scale end,
        set = function(_, value)
          addon.db.profile.scale = value
          addon:UpdateMarkerSize()
        end,
      },
      marker = {
        type = "select",
        name = "Marker",
        desc = "Choose the raid target marker to display.",
        values = {
          [1] = RAID_TARGET_MARKERS[1],
          [2] = RAID_TARGET_MARKERS[2],
          [3] = RAID_TARGET_MARKERS[3],
          [4] = RAID_TARGET_MARKERS[4],
          [5] = RAID_TARGET_MARKERS[5],
          [6] = RAID_TARGET_MARKERS[6],
          [7] = RAID_TARGET_MARKERS[7],
          [8] = RAID_TARGET_MARKERS[8],
        },
        get = function() return addon.db.profile.marker end,
        set = function(_, value)
          addon.db.profile.marker = value
          addon:UpdateMarkerTexture()
        end,
      },
      opacity = {
        type = "range",
        name = "Opacity",
        desc = "Set the transparency of the X mark.",
        min = 0,
        max = 1,
        step = 0.1,
        get = function() return addon.db.profile.opacity end,
        set = function(_, value)
          addon.db.profile.opacity = value
          addon:UpdateMarkerOpacity()
        end,
      },
      showOutOfCombat = {
        type = "toggle",
        name = "Show Out of Combat",
        desc = "Display the X mark even when not in combat.",
        get = function() return addon.db.profile.showOutOfCombat end,
        set = function(_, value)
          addon.db.profile.showOutOfCombat = value
          addon:UpdateMarkerVisibility()
        end,
      },
    },
  }
end

local function InitializeConfigUI()
  AceConfig:RegisterOptionsTable("CursorOutline", addon:GetOptionsTable())
  AceConfigDialog:AddToBlizOptions("CursorOutline", "CursorOutline")

  -- Hook the Blizzard Interface Options to enable test mode
  if InterfaceOptionsFrame then
    InterfaceOptionsFrame:HookScript("OnShow", function()
      addon:EnableTestMode()
    end)
    InterfaceOptionsFrame:HookScript("OnHide", function()
      addon:DisableTestMode()
    end)
  end

  -- Force sliders to update after a slight delay
  C_Timer.After(0.1, function()
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
      for _, child in ipairs({ InterfaceOptionsFrame:GetChildren() }) do
        if child:GetObjectType() == "Slider" then
          child:SetValue(child:GetValue())
        end
      end
    end
  end)
end

-- Initialize the configuration UI when the addon loads
local configFrame = CreateFrame("Frame")
configFrame:RegisterEvent("ADDON_LOADED")
configFrame:SetScript("OnEvent", function(self, event, addonName)
  if addonName == "CursorOutline" then
    InitializeConfigUI()
    self:UnregisterEvent("ADDON_LOADED")
  end
end)
