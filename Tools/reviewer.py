# TGA Asset Reviewer
# Simple visualizer to check transparency of TGA files on a black background.
#
# Note: This script was generated with AI assistance.
# Usage: Run script to verify images in 'output/'.

import os
from PIL import Image
import matplotlib.pyplot as plt

# --- Configuration ---
OUTPUT_FOLDER = "output"


def review_images():
    if not os.path.exists(OUTPUT_FOLDER):
        print(f"Folder '{OUTPUT_FOLDER}' not found.")
        return

    files = [f for f in os.listdir(OUTPUT_FOLDER) if f.lower().endswith('.tga')]

    if not files:
        print("No .tga files found in the output folder.")
        return

    print(f"Found {len(files)} images. Starting Dark Mode Viewer...")

    for i, filename in enumerate(files):
        file_path = os.path.join(OUTPUT_FOLDER, filename)

        try:
            img = Image.open(file_path)

            # 1. Create Figure with Black Background (Outer Window)
            fig = plt.figure(figsize=(6, 6), facecolor='black')

            # 2. Set the Plot Area Background to Black
            # This ensures transparent parts of your image show up as black
            ax = plt.gca()
            ax.set_facecolor('black')

            # Display the image
            plt.imshow(img)
            plt.axis('off')

            # 3. Set Title Text to White (so you can read it)
            plt.title(f"[{i + 1}/{len(files)}] {filename}", color='white')

            # Block until closed
            plt.show()

            print(f" -> Reviewed: {filename}")

        except Exception as e:
            print(f"Could not open {filename}: {e}")

    print("--- All images reviewed! ---")


if __name__ == "__main__":
    review_images()