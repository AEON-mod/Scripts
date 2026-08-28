import os
import random
import math
import argparse
from PIL import Image, ImageDraw

def get_all_images(base_folder):
    valid_exts = {'.png', '.jpg', '.jpeg', '.webp'}
    images = []
    for root, dirs, files in os.walk(base_folder):
        for f in files:
            if f.lower() in ['banner.jpg', 'inspiration.png', 'banner.png', 'banner.gif', 'banner_large.gif', 'banner_small.gif', 'banner_final3.gif', 'banner_final3.png']:
                continue
            if any(f.lower().endswith(ext) for ext in valid_exts):
                images.append(os.path.join(root, f))
    images.sort()
    rng = random.Random(42)
    rng.shuffle(images)
    return images

def add_rounded_corners(im, rad):
    circle = Image.new('L', (rad * 2, rad * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, rad * 2 - 1, rad * 2 - 1), fill=255)
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
    alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
    alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
    alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
    im.putalpha(alpha)
    return im

def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    rgb = tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))
    return rgb + (255,)

def process_image(path, size=(160, 90), radius=8, border_color=(255,255,255,255)):
    try:
        im = Image.open(path).convert("RGBA")
        target_ratio = size[0] / size[1]
        im_ratio = im.width / im.height
        if im_ratio > target_ratio:
            new_width = int(target_ratio * im.height)
            offset = (im.width - new_width) // 2
            im = im.crop((offset, 0, offset + new_width, im.height))
        else:
            new_height = int(im.width / target_ratio)
            offset = (im.height - new_height) // 2
            im = im.crop((0, offset, im.width, offset + new_height))
            
        im = im.resize(size, Image.Resampling.LANCZOS)
        im = add_rounded_corners(im, radius)
        
        border_width = 2
        bordered = Image.new("RGBA", (size[0] + border_width*2, size[1] + border_width*2), (0,0,0,0))
        draw = ImageDraw.Draw(bordered)
        draw.rounded_rectangle((0, 0, bordered.width-1, bordered.height-1), radius=radius+border_width, fill=border_color)
        bordered.paste(im, (border_width, border_width), im)
        return bordered
    except Exception as e:
        return None

def create_collages(folder, output_format="both"):
    images = get_all_images(folder)
    print(f"Found {len(images)} images")
    
    if not images:
        print("No images found.")
        return
    
    border_colors = [
        hex_to_rgb('#FF79C6'),
        hex_to_rgb('#8BE9FD'),
        hex_to_rgb('#F1FA8C'),
        hex_to_rgb('#50FA7B'),
        hex_to_rgb('#BD93F9')
    ]
    
    img_w, img_h = 160, 90
    gap_x = 12
    gap_y = 6
    step_x = img_w + gap_x
    step_y = img_h + gap_y
    
    # Smooth loop parameters
    c_period = 6
    r_period = 5
    
    unit_cell = {}
    rng_cell = random.Random(999)
    idx = 0
    for r in range(r_period):
        for c in range(c_period):
            if idx >= len(images): idx = 0
            color = rng_cell.choice(border_colors)
            img = process_image(images[idx], size=(img_w, img_h), radius=8, border_color=color)
            unit_cell[(c, r)] = img
            idx += 1
            
    cols, rows = 30, 30
    grid_w = cols * step_x
    grid_h = rows * step_y
    grid_canvas = Image.new("RGBA", (grid_w, grid_h), (0,0,0,0))
    
    for r in range(rows):
        for c in range(cols):
            img = unit_cell[(c % c_period, r % r_period)]
            if img:
                x = c * step_x
                y = r * step_y
                grid_canvas.paste(img, (x, y), img)
                
    angle = 25
    rotated_grid = grid_canvas.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    
    banner_w, banner_h = 1140, 380
    bg_color = (35, 37, 49, 255)
    
    rad = math.radians(25)
    dx_shift = c_period * step_x * math.cos(rad) - (-r_period) * step_y * math.sin(rad)
    dy_shift = c_period * step_x * math.sin(rad) + (-r_period) * step_y * math.cos(rad)
    
    rg_w, rg_h = rotated_grid.size
    start_crop_x = (rg_w - banner_w - dx_shift) / 2
    start_crop_y = (rg_h - banner_h - dy_shift) / 2
    
    generate_gif = output_format in ['gif', 'both']
    generate_png = output_format in ['png', 'both']
    
    # Optimize rendering time if we only need a static image
    total_frames = 240 if generate_gif else 1
    raw_frames = []
    static_frame = None
    
    if generate_gif:
        print(f"Generating super smooth animated banner ({total_frames} frames)...")
    else:
        print("Generating static banner...")
        
    for i in range(total_frames):
        t = i / float(total_frames)
        crop_x = start_crop_x + t * dx_shift
        crop_y = start_crop_y + t * dy_shift
        
        frame = Image.new("RGBA", (banner_w, banner_h), bg_color)
        crop_region = rotated_grid.crop((int(crop_x), int(crop_y), int(crop_x) + banner_w, int(crop_y) + banner_h))
        frame.paste(crop_region, (0, 0))
        
        rgb_frame = frame.convert("RGB")
        
        # Save the first frame in unquantized high-quality for the PNG output
        if i == 0 and generate_png:
            static_frame = rgb_frame
        
        # Quantize frames to keep file sizes down for GIFs
        if generate_gif:
            raw_frames.append(rgb_frame.quantize(colors=128))
            
    if generate_png and static_frame:
        out_path_png = os.path.join(folder, "banner.png")
        static_frame.save(out_path_png)
        print(f"Saved {out_path_png}")
        
    if generate_gif and raw_frames:
        out_path_gif = os.path.join(folder, "banner.gif")
        raw_frames[0].save(
            out_path_gif,
            save_all=True,
            append_images=raw_frames[1:],
            duration=50, # 20 fps for maximum smoothness
            loop=0,
            optimize=True
        )
        print(f"Saved {out_path_gif}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a collage banner.")
    parser.add_argument(
        'folder', 
        nargs='?', 
        default=os.getcwd(), 
        help="Optional: Path to the folder containing images. Defaults to current directory."
    )
    args = parser.parse_args()
    
    print("Select output format:")
    print("1. Create .gif")
    print("2. Create .png")
    print("3. Create both")
    
    choice = input("Enter 1, 2, or 3: ").strip()
    
    if choice == '1':
        out_fmt = 'gif'
    elif choice == '2':
        out_fmt = 'png'
    elif choice == '3':
        out_fmt = 'both'
    else:
        print("Invalid choice. Defaulting to both.")
        out_fmt = 'both'
        
    create_collages(folder=args.folder, output_format=out_fmt)
