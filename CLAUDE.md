# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

CursorOutline is a World of Warcraft addon (Lua, Ace3) that draws a texture (raid marker, class/spec icon, or user-supplied TGA) on the mouse cursor. One codebase targets **all** WoW clients — Retail, Classic, and legacy (Vanilla/TBC/WotLK) — listed in the multi-value `## Interface:` line of `CursorOutline.toc`.

There is no build, lint, or test tooling. Testing is manual in-game: copy/symlink the repo into `Interface/AddOns/CursorOutline/`, `/reload`, and use `/co`, `/co config`, `/co combat on|off`, `/co scale <n>`. New texture files require a full client restart, not just `/reload`.

## Architecture

- **Load order** is defined in `CursorOutline.toc`: embedded Ace3 libs → `CursorOutline.lua` → `ConfigUI.lua`. `ConfigUI.lua` fetches the addon via `AceAddon:GetAddon("CursorOutline")` and attaches `SetupConfigUI`, `OpenConfigUI`, `RefreshConfigUI`, and `GetOptionsTable` to it. These are only called from `OnInitialize` onwards, when both files are loaded.
- **Rendering** (`CursorOutline.lua`): a single `TOOLTIP`-strata frame + texture. An `OnUpdate` script repositions it to `GetCursorPosition() / UIParent:GetEffectiveScale()`, skipping `SetPoint` when the cursor hasn't moved. `OnUpdate` doesn't fire on hidden frames, so the "zero CPU" goal relies on `UpdateMarkerVisibility` hiding the frame unless in combat (`addon.inCombat`, tracked via `PLAYER_REGEN_*`) or `showOutOfCombat` is on.
- **Profiles / SavedVariables** (`CursorOutlineDB`, AceDB): `db.profile` holds account-level toggles (`showOutOfCombat`, `useSpecProfiles`, `showAllShapes`) plus appearance tables in `global` and `specs[specID]`. Always read/write appearance settings (mode, markerIndex, customShape, customFilePath, customColor, scale, opacity) through `addon:GetActiveProfile()`, which returns the per-spec table (lazily created from `DEFAULT_APPEARANCE` with the spec's icon) or falls back to `global`.
- **Version compatibility**: feature-detect rather than version-check. `SUPPORTS_SPECS = (_G.GetSpecialization ~= nil)` gates spec profiles and the `PLAYER_SPECIALIZATION_CHANGED` event; `ConfigUI.lua` does the same check to hide spec UI. `OpenConfigUI` branches on `Settings.OpenToCategory` (Retail/modern Classic) vs `InterfaceOptionsFrame_OpenToCategory` (legacy). Any new WoW API usage must be guarded so it doesn't error on older clients — e.g. `C_Timer`, `CopyTable`, `SetShown`, and `C_AddOns` don't exist on 3.3.5.
- **Modes**: `RAID_MARKER` uses Blizzard `UI-RaidTargetingIcon_N` textures with `opacity`; `CUSTOM` uses a texture path tinted by `customColor` (`opacity` is hidden). The sentinel `customShape == addon.CUSTOM_FILE_INPUT` means load `Textures/Custom/<customFilePath>`.
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

Pushing a `v*` tag triggers `.github/workflows/release.yml`, which runs BigWigsMods/packager to build the zip, create the GitHub Release, and upload to CurseForge (project ID in the `.toc`, API key in the `CF_API_KEY` repo secret). `.pkgmeta` excludes `Tools/` and `CLAUDE*.md` from the package; dotfiles are excluded automatically. Bump `## Version:` in `CursorOutline.toc` before tagging.
