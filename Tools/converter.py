# Texture Converter for CursorOutline
# - Resizes to 256x256
# - INTELLIGENT TRANSPARENCY:
#   1. Detects if the background is White or Black.
#   2. Removes the background (makes it transparent).
#   3. Turns the remaining shape PURE WHITE (so you can color it in-game).
#
# Usage: Put PNG/JPG files in 'input/', run script.

import os
from PIL import Image, ImageOps

# Configuration
INPUT_FOLDER = "input"
OUTPUT_FOLDER = "output"
TARGET_SIZE = (256, 256)


def process_batch():
    if not os.path.exists(OUTPUT_FOLDER):
        os.makedirs(OUTPUT_FOLDER)

    # Allow PNG and JPG now, since we handle transparency manually
    files = [f for f in os.listdir(INPUT_FOLDER) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]

    if not files:
        print(f"No images found in '{INPUT_FOLDER}/'.")
        return

    print(f"Processing {len(files)} images...")

    for filename in files:
        input_path = os.path.join(INPUT_FOLDER, filename)
        output_filename = os.path.splitext(filename)[0] + ".tga"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)

        make_transparent_tga(input_path, output_path)


def make_transparent_tga(input_path, output_path):
    try:
        # 1. Load and convert to Grayscale (Luminance)
        # We don't care about color yet, just brightness/shape
        img = Image.open(input_path).convert("L")

        # 2. Resize
        if img.size != TARGET_SIZE:
            img = img.resize(TARGET_SIZE, Image.Resampling.LANCZOS)

        # 3. Detect Background Color
        # Check the 4 corners. If they are bright, the BG is white.
        w, h = img.size
        corners = [
            img.getpixel((0, 0)),
            img.getpixel((w - 1, 0)),
            img.getpixel((0, h - 1)),
            img.getpixel((w - 1, h - 1))
        ]
        avg_corner_brightness = sum(corners) / 4

        # 4. Create the "Alpha Mask" (The shape definition)
        if avg_corner_brightness > 128:
            # BACKGROUND IS WHITE (Like your screenshot)
            # We want the Dark parts to be the Icon (Opaque)
            # We want the White parts to be Transparent
            print(f" [AUTO] {os.path.basename(input_path)}: Detected White BG -> Removing it.")

            # Invert: Now Shape is White, BG is Black
            alpha_mask = ImageOps.invert(img)
        else:
            # BACKGROUND IS BLACK
            # We want the Light parts to be the Icon
            # We want the Black parts to be Transparent
            print(f" [AUTO] {os.path.basename(input_path)}: Detected Black BG -> Removing it.")

            # Already correct: Shape is White, BG is Black
            alpha_mask = img

        # 5. Create the Final Image
        # WoW Cursors need to be PURE WHITE RGB to allow coloring.
        # The Shape is defined entirely by the Alpha Channel we just made.

        flat_white = Image.new("RGB", TARGET_SIZE, (255, 255, 255))

        # Combine: Pure White Color + Our Calculated Transparency
        final_img = Image.merge("RGBA", (*flat_white.split(), alpha_mask))

        # 6. Save
        final_img.save(output_path, format='TGA', compression=None)
        print(f" [OK] Saved {os.path.basename(output_path)}")

    except Exception as e:
        print(f" [ERROR] {os.path.basename(input_path)}: {e}")


if __name__ == "__main__":
    if not os.path.exists(INPUT_FOLDER):
        os.makedirs(INPUT_FOLDER)
        print(f"Created '{INPUT_FOLDER}'. Put your images inside.")
    else:
        process_batch()