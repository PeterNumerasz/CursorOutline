# Texture Converter for CursorOutline
# - Preserves details (Grayscale)
# - Auto-inverts black icons to white (for tinting)
# - Resizes to 256x256
#
# NOTE: Input images MUST have a transparent background!

import os
from PIL import Image, ImageOps
import numpy as np

INPUT_FOLDER = "input"
OUTPUT_FOLDER = "output"
TARGET_SIZE = (256, 256)

def process_batch():
    if not os.path.exists(OUTPUT_FOLDER):
        os.makedirs(OUTPUT_FOLDER)

    files = [f for f in os.listdir(INPUT_FOLDER) if f.lower().endswith('.png')]

    if not files:
        print(f"No PNG files found in '{INPUT_FOLDER}/'.")
        return

    print(f"Processing {len(files)} images...")

    for filename in files:
        input_path = os.path.join(INPUT_FOLDER, filename)
        output_filename = os.path.splitext(filename)[0] + ".tga"
        output_path = os.path.join(OUTPUT_FOLDER, output_filename)
        
        convert_smart(input_path, output_path)

def convert_smart(input_path, output_path):
    try:
        img = Image.open(input_path).convert("RGBA")

        # 1. Resize
        if img.size != TARGET_SIZE:
            img = img.resize(TARGET_SIZE, Image.Resampling.LANCZOS)

        # 2. Analyze Brightness (of non-transparent pixels)
        # We need to know if this is a "Black Icon" or a "White/Colored Icon"
        alpha = np.array(img.split()[-1])
        grayscale = np.array(img.convert("L"))
        
        # Mask: Only look at pixels that are somewhat opaque
        visible_pixels = grayscale[alpha > 20]

        if len(visible_pixels) > 0:
            avg_brightness = np.mean(visible_pixels)
        else:
            avg_brightness = 128 # Default if empty

        # 3. Process Color Channels
        # If the icon is mostly dark (Black icon), Invert it to White.
        # Why? Because in WoW, (Black * Color) = Black. You can't tint black icons.
        # But (White * Color) = Color.
        
        r, g, b, a = img.split()
        
        if avg_brightness < 100:
            # It's a dark icon. Invert the grayscale to make it light.
            print(f" [AUTO-INVERT] {os.path.basename(input_path)} detected as dark.")
            gray_img = ImageOps.invert(img.convert("L"))
        else:
            # It's already light/colored. Just desaturate to Grayscale to preserve shading.
            gray_img = img.convert("L")

        # 4. Reconstruct RGBA
        # Use the new Grayscale for R, G, B channels. Keep original Alpha.
        final_img = Image.merge("RGBA", (gray_img, gray_img, gray_img, a))

        # 5. Save
        final_img.save(output_path, format='TGA', compression=None)
        print(f" [OK] {os.path.basename(input_path)}")

    except Exception as e:
        print(f" [ERROR] {os.path.basename(input_path)}: {e}")

if __name__ == "__main__":
    if not os.path.exists(INPUT_FOLDER):
        os.makedirs(INPUT_FOLDER)
        print("Created 'input' folder. Place Transparent PNGs here.")
    else:
        process_batch()