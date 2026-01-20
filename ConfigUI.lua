local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("CursorOutline")

local RAID_TARGET_MARKERS = {
  "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross (X)", "Skull",
}

function addon:GetOptionsTable()
  return {
    name = "CursorOutline",
    type = "group",
    args = {
      description = {
        order = 0,
        type = "description",
        name = "Settings for the cursor tracking visual.",
      },
      scale = {
        order = 1,
        type = "range",
        name = "Scale",
        desc = "Adjust the size of the marker.",
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
        order = 2,
        type = "select",
        name = "Marker",
        desc = "Choose the raid target marker to display.",
        values = RAID_TARGET_MARKERS,
        get = function() return addon.db.profile.marker end,
        set = function(_, value)
          addon.db.profile.marker = value
          addon:UpdateMarkerTexture()
        end,
      },
      opacity = {
        order = 3,
        type = "range",
        name = "Opacity",
        desc = "Set the transparency of the marker.",
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
        order = 4,
        type = "toggle",
        name = "Show Out of Combat",
        desc = "Display the marker even when not in combat.",
        get = function() return addon.db.profile.showOutOfCombat end,
        set = function(_, value)
          addon.db.profile.showOutOfCombat = value
          addon:UpdateMarkerVisibility()
        end,
      },
    },
  }
end

-- Called by CursorOutline.lua during OnInitialize
-- Called by CursorOutline.lua during OnInitialize
function addon:SetupConfigUI()
  AceConfig:RegisterOptionsTable("CursorOutline", addon:GetOptionsTable())
  AceConfigDialog:AddToBlizOptions("CursorOutline", "CursorOutline")
end