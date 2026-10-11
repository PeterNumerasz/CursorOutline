# CursorOutline

A small WoW addon that sticks a marker on your mouse cursor so you can actually find it during busy fights.

Works on Retail and all current Classic versions.

## Features

- Use a raid marker (Star, Skull, X, ...) or a class/spec icon as the cursor marker.
- Recolor icons and shapes with a color picker.
- Show it only in combat, or all the time.
- Optional global cooldown sweep: the marker flashes and refills clockwise while the GCD runs.
- On Retail, settings are saved per spec, and the icon switches when you change spec.
- Doesn't touch actual raid targets, so it won't conflict with DBM, BigWigs, MRT, etc.

## Commands

| Command | What it does |
| :--- | :--- |
| `/co` | Show help |
| `/co config` | Open settings |
| `/co combat on/off` | `on`: always show the marker, `off`: only in combat |
| `/co scale <0.5-3.0>` | Change marker size |

## Custom textures

1. Convert your image to a TGA with the Python script in `Tools/` (see `Tools/INSTRUCTIONS.md`).
2. Put the file in `Textures/Custom/`.
3. Restart the game (a `/reload` won't pick up new files).
4. In settings, pick "[!] Custom File" as the shape and type the filename.

## Download

[CurseForge](https://www.curseforge.com/wow/addons/cursoroutline)

Bugs and suggestions: open an issue on GitHub.

## Credits

Icons by [Game-Icons.net](https://game-icons.net).
