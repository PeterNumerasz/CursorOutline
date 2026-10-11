-- "What's new" window, shown once after updating to a feature release
local addonName = "CursorOutline"
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local AceGUI = LibStub("AceGUI-3.0")

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version")

-- Newest first. popup = true for feature releases; bug-fix releases only get a chat line.
local CHANGELOG = {
    {
        version = "2.0.0",
        popup = true,
        notes = {
            "|cffffd100New: Global cooldown sweep.|r The marker flashes and refills clockwise while the global cooldown runs. Turn it on with \"Show Global Cooldown\" in /co config.",
            "|cffffd100New:|r CursorOutline has its own icon in the AddOns list.",
            "|cffffd100Fixed:|r errors when opening the settings on Midnight.",
            "|cffffd100Changed:|r only official game versions are supported now: Retail, Classic Era, Anniversary, Titan Reforged, Cataclysm and Mists Classic, and WoW Forever.",
        },
    },
}

-- "2.0.1" -> 2, 0, 1
local function ParseVersion(version)
    local major, minor, patch = tostring(version):match("^v?(%d+)%.?(%d*)%.?(%d*)")
    return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

local function IsNewer(a, b)
    local a1, a2, a3 = ParseVersion(a)
    local b1, b2, b3 = ParseVersion(b)
    if a1 ~= b1 then return a1 > b1 end
    if a2 ~= b2 then return a2 > b2 end
    return a3 > b3
end

-- Changelog entries newer than sinceVersion (all of them if nil), newest first
local function GetEntriesSince(sinceVersion)
    local entries = {}
    for _, entry in ipairs(CHANGELOG) do
        if not sinceVersion or IsNewer(entry.version, sinceVersion) then
            table.insert(entries, entry)
        end
    end
    return entries
end

-- sinceVersion: only list changes after this version; nil lists the whole changelog
function addon:ShowWhatsNew(sinceVersion)
    if self.whatsNewFrame then return end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(addonName .. ": What's new")
    frame:SetStatusText("Installed version: " .. (CURRENT_VERSION or "?"))
    frame:SetWidth(480)
    frame:SetHeight(380)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        addon.whatsNewFrame = nil
    end)
    self.whatsNewFrame = frame

    -- ScrollFrame needs a Fill-layout container with a fixed height to scroll inside
    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(230)
    scrollContainer:SetLayout("Fill")
    frame:AddChild(scrollContainer)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    scrollContainer:AddChild(scroll)

    for _, entry in ipairs(GetEntriesSince(sinceVersion)) do
        local heading = AceGUI:Create("Heading")
        heading:SetText("Version " .. entry.version)
        heading:SetFullWidth(true)
        scroll:AddChild(heading)

        for _, note in ipairs(entry.notes) do
            local label = AceGUI:Create("Label")
            label:SetText("- " .. note .. "\n")
            label:SetFontObject(GameFontHighlight)
            label:SetFullWidth(true)
            scroll:AddChild(label)
        end
    end

    local dontShow = AceGUI:Create("CheckBox")
    dontShow:SetLabel("Don't open this window after updates")
    dontShow:SetDescription("You'll get a short chat message instead.")
    dontShow:SetFullWidth(true)
    dontShow:SetValue(not self.db.global.showWhatsNew)
    dontShow:SetCallback("OnValueChanged", function(_, _, value)
        addon.db.global.showWhatsNew = not value
    end)
    frame:AddChild(dontShow)
end

-- Waits until combat ends so the window doesn't pop up mid-fight
local function ShowWhenOutOfCombat(sinceVersion)
    if not InCombatLockdown() then
        addon:ShowWhatsNew(sinceVersion)
        return
    end
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("PLAYER_REGEN_ENABLED")
    waiter:SetScript("OnEvent", function(self)
        self:UnregisterAllEvents()
        addon:ShowWhatsNew(sinceVersion)
    end)
end

-- Called on login: opens the window (or prints a chat line) once after an update
function addon:CheckWhatsNew()
    local lastSeen = self.db.global.lastSeenVersion
    self.db.global.lastSeenVersion = CURRENT_VERSION

    if self.isFreshInstall or not CURRENT_VERSION then return end
    -- lastSeen is nil when upgrading from a version before this window existed
    if lastSeen and not IsNewer(CURRENT_VERSION, lastSeen) then return end

    local entries = GetEntriesSince(lastSeen)
    if #entries == 0 then return end

    local isFeatureRelease = false
    for _, entry in ipairs(entries) do
        if entry.popup then isFeatureRelease = true end
    end

    if isFeatureRelease and self.db.global.showWhatsNew then
        -- Give the login chat spam a moment to settle first
        C_Timer.After(3, function() ShowWhenOutOfCombat(lastSeen) end)
    else
        self:Print(("Updated to %s. Type /co whatsnew to see what changed."):format(CURRENT_VERSION))
    end
end
