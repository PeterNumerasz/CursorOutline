# 🎯 CursorOutline

**Never lose your cursor again.**

CursorOutline is a lightweight, efficient World of Warcraft addon designed to keep your mouse visible during the most chaotic raid encounters and Mythic+ runs.

If you struggle to spot your mouse pointer amidst spell effects, nameplates, and AoE explosions, this addon is the solution. It attaches a high-visibility texture (like the X marker, Skull, or Star) directly to your cursor.

# ✨ New in v1.4.0: Class Identity & Compatibility

CursorOutline is now fully universal, supporting Retail, Classic, and legacy clients.

*   **40 New Class/Spec Icons:** Automatically sets a matching cursor icon (e.g., a Fire icon for Fire Mages) on modern clients.
*   **Smart Profiles:**
    *   **Modern WoW (Retail):** Enables "Spec Profiles". Settings are saved per-specialization (switch specs, cursor updates automatically).
    *   **Legacy WoW (Vanilla / TBC / WotLK):** Automatically defaults to "Global Mode". Settings apply to the character globally since these versions lack Specializations.

## 🌟 Key Features
* Ultra Lightweight: Zero CPU impact. It just works.
* Combat Focused: Options to show only during combat to keep your UI clean.
* Highly Customizable:
    * Classic Mode: Use standard Raid Markers (Star, Skull, Diamond, etc.).
    * Custom Mode: Use class icons or flat shapes and color them using the built-in Color Picker.
* Safe & Conflict-Free: Uses standalone textures, meaning it does not interfere with Raid Targets, DBM, BigWigs, or Method Raid Tools auto-marking.

## 🔄 An Alternative to StarCursor and CursorTrail

If you are looking for a modern, bloat-free **alternative to StarCursor**, **CursorTrail**, or **CursorMod**, this is it. Unlike heavy WeakAuras that do the same thing, CursorOutline is built purely for performance. It provides the visual clarity of **Cursor Glow** or **Mouse Look Handler** utilities without the complex setup.

## 🎨 How to use Custom Textures
Want to use your own image? CursorOutline includes developer tools to help you import any icon!

1. Navigate to Interface/AddOns/CursorOutline/Tools/.
2. Follow the instructions in INSTRUCTIONS.md to use the included Python Script.
3. The script converts your PNGs into WoW-compatible TGA files.
4. Place your new files in Textures/Custom/.
5. In-game, select "[!] Custom File" in the shape dropdown and type your filename.

## 📥 Download

*   **[Download on CurseForge](https://www.curseforge.com/wow/addons/cursoroutline)**

## ⚙️ Configuration & Usage

You can configure everything via the Interface Options menu or use slash commands.

| Command | Description |
| :--- | :--- |
| `/co` | Show help message |
| `/co config` | **Open the configuration GUI** |
| `/co combat <on/off>` | Toggle "Combat Only" mode (Recommended!) |
| `/co scale <0.5 - 2.0>` | Make the marker bigger or smaller |

## 🐞 Feedback & Support

Found a bug or have a suggestion? Please open an issue here on GitHub!

# Credits
Icons by Game-Icons.net
