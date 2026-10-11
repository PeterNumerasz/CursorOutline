# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

CursorOutline is a World of Warcraft addon (Lua, Ace3) that draws a texture (raid marker, class/spec icon, or user-supplied TGA) on the mouse cursor. One codebase targets every **official** WoW client — Retail, the Classic flavors (Era, Anniversary, Titan Reforged, Cata, MoP), and WoW Forever — listed in the multi-value `## Interface:` line of `CursorOutline.toc`. Private-server/pre-Settings-panel clients are not supported (the embedded Ace3 dropped them).

There is no build, lint, or test tooling. Testing is manual in-game: copy/symlink the repo into `Interface/AddOns/CursorOutline/`, `/reload`, and use `/co`, `/co config`, `/co combat on|off`, `/co scale <n>`. New texture files require a full client restart, not just `/reload`.

## Architecture

- **Load order** is defined in `CursorOutline.toc`: embedded Ace3 libs → `CursorOutline.lua` → `GCD.lua` → `WhatsNew.lua` → `ConfigUI.lua`. The later files fetch the addon via `AceAddon:GetAddon("CursorOutline")` and attach methods to it (`EnableGCD`/`UpdateGCDTexture`, `CheckWhatsNew`/`ShowWhatsNew`, and `SetupConfigUI`/`OpenConfigUI`/`RefreshConfigUI`/`GetOptionsTable`). These are only called from `OnInitialize` onwards, when all files are loaded.
- **Rendering** (`CursorOutline.lua`): a single `TOOLTIP`-strata frame + texture. An `OnUpdate` script repositions it to `GetCursorPosition() / UIParent:GetEffectiveScale()`, skipping `SetPoint` when the cursor hasn't moved. `OnUpdate` doesn't fire on hidden frames, so the "zero CPU" goal relies on `UpdateMarkerVisibility` hiding the frame unless in combat (`addon.inCombat`, tracked via `PLAYER_REGEN_*`) or `showOutOfCombat` is on.
- **Profiles / SavedVariables** (`CursorOutlineDB`, AceDB): `db.profile` holds account-level toggles (`showOutOfCombat`, `useSpecProfiles`, `showAllShapes`) plus appearance tables in `global` and `specs[specID]`. Always read/write appearance settings (mode, markerIndex, customShape, customFilePath, customColor, scale, opacity) through `addon:GetActiveProfile()`, which returns the per-spec table (lazily created from `DEFAULT_APPEARANCE` with the spec's icon) or falls back to `global`.
- **Version compatibility**: feature-detect rather than version-check. `SUPPORTS_SPECS = (_G.GetSpecialization ~= nil)` gates spec profiles and the `PLAYER_SPECIALIZATION_CHANGED` event; `ConfigUI.lua` does the same check to hide spec UI. All official clients share the modern API (`Settings`, `C_Spell`, `C_Timer`, Cooldown swipe textures), so those can be used directly; guard only things that differ between Retail and Classic flavors. `SetupConfigUI` stores the category ID returned by `AddToBlizOptions` (numeric on 12.0+) for `Settings.OpenToCategory`. When updating the embedded Ace3, replace each `Libs/` folder wholesale from `WoWUIDev/Ace3`.
- **Modes**: `RAID_MARKER` uses Blizzard `UI-RaidTargetingIcon_N` textures with `opacity`; `CUSTOM` uses a texture path tinted by `customColor` (`opacity` is hidden). The sentinel `customShape == addon.CUSTOM_FILE_INPUT` means load `Textures/Custom/<customFilePath>`.
- **GCD swipe** (`GCD.lua`): a `Cooldown` frame on the marker whose swipe texture is the marker's own texture (set via `UpdateGCDTexture` from `UpdateMarkerAppearance`), so the sweep matches the icon shape. Tinted custom icons get a white sweep (flash white, fade back to their color); raid markers and near-white icons get a dark one, since white would be invisible on them. The frame uses `CooldownFrameTemplate` (without it Classic draws nothing); set the color with `SetSwipeColor` after `SetSwipeTexture`, since the template brings its own dark color. Driven by `SPELL_UPDATE_COOLDOWN` on spell 61304, registered only while `showGCD` is on; if 61304 reports nothing (it returns nil on Classic Era), it falls back to the last cast spell's cooldown (`UNIT_SPELLCAST_*`) when that is ≤ 1.5s. In Midnight, cooldown values may be secret in combat (`issecretvalue`); they can be passed to the widget but not read or compared.
- **What's new** (`WhatsNew.lua`): `CHANGELOG` (newest first) drives a once-per-update AceGUI window. `CheckWhatsNew` on login compares the `.toc` version with `db.global.lastSeenVersion` (account-wide AceDB `global`, not `db.profile.global`). Entries with `popup = true` open the window (deferred until out of combat); otherwise, or if the user opted out (`db.global.showWhatsNew`), only a chat line. Fresh installs (no `CursorOutlineDB` before `AceDB:New`) see nothing.
- **Options UI** (`ConfigUI.lua`): AceConfig options table registered into Blizzard options. Appearance options use the `AppearanceGet(key)` / `AppearanceSet(key, redraw)` helpers; pass `redraw = true` (or call `addon:RefreshConfigUI()`) when a setter changes which widgets are shown. `GetShapeValues` filters the shape dropdown to the player's class.

### Adding/renaming spec icons

Spec textures live in `Textures/Specs/<Class>_<Spec>.tga`. Register each with one row in `SPEC_ICON_LIST` in `CursorOutline.lua` (`{ specID, classTag, fileName, label }`); the spec-default map and the options dropdown are both built from it.

## Tools (Python, not shipped)

`Tools/` holds helper scripts for producing WoW-compatible textures (see `Tools/INSTRUCTIONS.md`). Run from inside `Tools/`:

```
pip install -r requirements.txt   # Pillow, matplotlib
python converter.py               # input/*.png|jpg -> output/*.tga (256x256, bg removed, shape turned white for tinting)
python reviewer.py                # preview output/*.tga on a black background
```

## Release

Pushing a `v*` tag triggers `.github/workflows/release.yml`, which runs BigWigsMods/packager to build the zip, create the GitHub Release, and upload to CurseForge (project ID in the `.toc`, API key in the `CF_API_KEY` repo secret). `.pkgmeta` excludes `Tools/` and `CLAUDE*.md` from the package; dotfiles are excluded automatically. Before tagging: bump `## Version:` in `CursorOutline.toc` and add a matching entry at the top of `CHANGELOG` in `WhatsNew.lua` (`popup = true` for feature releases).
