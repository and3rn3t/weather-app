#!/usr/bin/env python3
"""
Generate Android app icons from iOS icon assets.
"""
import os
from PIL import Image, ImageDraw

# Define the icon sizes for each density
ICON_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

def create_weather_icon(size, output_path):
    """Create a simple weather app icon with a cloud and sun."""
    # Create a new image with a blue gradient background
    img = Image.new('RGB', (size, size), '#4A90E2')
    draw = ImageDraw.Draw(img)
    
    # Calculate sizes based on icon size
    sun_radius = int(size * 0.15)
    sun_x = int(size * 0.7)
    sun_y = int(size * 0.25)
    
    # Draw sun (yellow circle)
    draw.ellipse(
        [sun_x - sun_radius, sun_y - sun_radius, 
         sun_x + sun_radius, sun_y + sun_radius],
        fill='#FFD700',
        outline='#FFA500',
        width=max(1, size // 96)
    )
    
    # Draw cloud (white rounded shape)
    cloud_y = int(size * 0.6)
    cloud_size = int(size * 0.4)
    
    # Draw multiple overlapping circles to create cloud shape
    circle_radius = int(cloud_size * 0.25)
    positions = [
        (int(size * 0.3), cloud_y),
        (int(size * 0.4), cloud_y - circle_radius // 2),
        (int(size * 0.5), cloud_y),
        (int(size * 0.6), cloud_y - circle_radius // 3),
    ]
    
    for x, y in positions:
        draw.ellipse(
            [x - circle_radius, y - circle_radius,
             x + circle_radius, y + circle_radius],
            fill='#FFFFFF'
        )
    
    # Save the icon
    img.save(output_path, 'PNG', quality=95)
    print(f"Created: {output_path}")

def create_round_icon(square_icon_path, output_path, size):
    """Create a round version of the icon."""
    # Open the square icon
    img = Image.open(square_icon_path).convert('RGBA')
    
    # Create a circular mask
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([0, 0, size, size], fill=255)
    
    # Apply the mask
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)
    
    # Save the round icon
    output.save(output_path, 'PNG', quality=95)
    print(f"Created: {output_path}")

def main():
    # Base directory
    base_dir = os.path.dirname(os.path.abspath(__file__))
    res_dir = os.path.join(base_dir, 'app', 'src', 'main', 'res')
    
    # Create icons for each density
    for density, size in ICON_SIZES.items():
        # Create mipmap directory
        mipmap_dir = os.path.join(res_dir, density)
        os.makedirs(mipmap_dir, exist_ok=True)
        
        # Create regular launcher icon
        icon_path = os.path.join(mipmap_dir, 'ic_launcher.png')
        create_weather_icon(size, icon_path)
        
        # Create round launcher icon
        round_icon_path = os.path.join(mipmap_dir, 'ic_launcher_round.png')
        create_round_icon(icon_path, round_icon_path, size)
    
    print("\n✓ All Android app icons generated successfully!")
    print(f"Icons created in: {res_dir}")

if __name__ == '__main__':
    main()
