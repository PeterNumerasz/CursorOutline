-- Global cooldown swipe drawn over the cursor marker
local addon = LibStub("AceAddon-3.0"):GetAddon("CursorOutline")

local GCD_SPELL_ID = 61304 -- Blizzard's dummy "Global Cooldown" spell
local MAX_GCD = 1.5 -- longest possible GCD; anything longer on the fallback spell is its own cooldown
local issecretvalue = _G.issecretvalue

-- The swipe uses the marker's own texture, so it only covers the icon's shape instead
-- of a square (see UpdateGCDTexture for its color). Without CooldownFrameTemplate
-- Classic clients draw nothing.
local cooldown = CreateFrame("Cooldown", nil, addon.markerFrame, "CooldownFrameTemplate")
cooldown:SetAllPoints()
cooldown:SetDrawSwipe(true)
cooldown:SetDrawEdge(false)
cooldown:SetDrawBling(false)
cooldown:SetHideCountdownNumbers(true)
cooldown.noCooldownCount = true -- keep OmniCC and similar addons from adding timer text

-- Midnight can return "secret" values in combat: addons can pass them to widgets but
-- can't read or compare them. The GCD isn't secret as of 12.1, but guard against it.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- Last spell the player started or finished casting, used as a GCD fallback
local lastCastSpellID

local function ReadCooldown(spellID)
    local info = C_Spell.GetSpellCooldown(spellID)
    if info then return info.startTime, info.duration, info.modRate end
end

-- Prefers the GCD dummy spell. Classic Era reports nothing for it, so fall back to the
-- cooldown of the spell just cast when it looks like a GCD.
local function ReadGCD()
    local start, duration, modRate = ReadCooldown(GCD_SPELL_ID)
    if IsSecret(duration) or (duration and duration > 0) then
        return start, duration, modRate
    end

    if lastCastSpellID then
        local castStart, castDuration, castModRate = ReadCooldown(lastCastSpellID)
        if not IsSecret(castDuration) and castDuration and castDuration > 0 and castDuration <= MAX_GCD then
            return castStart, castDuration, castModRate
        end
    end
end

local function ApplyGCD()
    local start, duration, modRate = ReadGCD()

    if IsSecret(start) or IsSecret(duration) then
        -- Duration objects are the Midnight way to feed secret cooldowns to a widget
        if C_Spell.GetSpellCooldownDuration and cooldown.SetCooldownFromDurationObject then
            pcall(function()
                cooldown:SetCooldownFromDurationObject(C_Spell.GetSpellCooldownDuration(GCD_SPELL_ID))
            end)
        end
    elseif duration and duration > 0 then
        cooldown:SetCooldown(start, duration, modRate)
    end
    -- No GCD found: leave any running swipe alone, it expires on its own
end

function addon:SPELL_UPDATE_COOLDOWN()
    ApplyGCD()
end

function addon:OnPlayerCast(_, unit, _, spellID)
    if IsSecret(unit) or unit ~= "player" then return end
    if not IsSecret(spellID) then lastCastSpellID = spellID end
    ApplyGCD()
end

local CAST_EVENTS = { "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED" }

-- Registers or unregisters the cooldown events based on the setting
function addon:EnableGCD()
    if self.db.profile.showGCD then
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        for _, event in ipairs(CAST_EVENTS) do self:RegisterEvent(event, "OnPlayerCast") end
        cooldown:Show()
        ApplyGCD()
    else
        self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
        for _, event in ipairs(CAST_EVENTS) do self:UnregisterEvent(event) end
        cooldown:SetCooldown(0, 0)
        cooldown:Hide()
    end
end

-- Tinted custom icons flash white and fade back to their color; raid markers are
-- untinted, so a white swipe would be invisible on them and they get a dark one instead.
-- The color is set separately: CooldownFrameTemplate brings its own dark swipe color.
function addon:UpdateGCDTexture(texture, isTinted)
    cooldown:SetSwipeTexture(texture)
    if isTinted then
        cooldown:SetSwipeColor(1, 1, 1, 1)
    else
        cooldown:SetSwipeColor(0, 0, 0, 0.75)
    end
end
