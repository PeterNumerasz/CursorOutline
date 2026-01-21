# Custom Cursor Tools

This folder contains tools to help you convert your own images for use with **CursorOutline**.

## Prerequisites

1.  **Install Python:** [Download Here](https://www.python.org/)
2.  **Open a terminal** inside this `Tools` folder.
3.  **Install requirements:**
    ```bash
    pip install -r requirements.txt
    ```

---

## How to Convert Images

1.  **Prepare your images:**
    Find any `.png` image you want to use.
    *(Tip: White icons on a transparent background work best because they can be colored in-game).*

2.  **Place them in the input folder:**
    Put your `.png` files into the `Tools/input/` folder.

3.  **Run the converter script:**
    ```bash
    python converter.py
    ```

4.  **Check results:**
    Your converted `.tga` files will appear in the `Tools/output/` folder.

---

## How to Install into WoW

1.  Copy your new `.tga` files.
2.  Navigate to your WoW Addon folder:
    `_retail_/Interface/AddOns/CursorOutline/Textures/Custom/`
3.  Paste the files there.
4.  **Restart World of Warcraft.** (The game cannot see new files until it restarts).

---

## How to Use In-Game

1.  Open the addon settings:
    ```bash
    /co config
    ```
2.  Set **Mode** to `Custom Shape & Color`.
3.  In the **Shape** dropdown, select: `[!] Custom File (Type Name Below)`.
4.  In the text box that appears, type your filename (e.g., `MyImage.tga`).
5.  Press Enter. Your custom cursor should appear!