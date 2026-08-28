import os
import re
import argparse
import io
import subprocess
import shutil
from pathlib import Path
from PIL import Image
import torch
import warnings

from transformers import BlipProcessor, BlipForConditionalGeneration

warnings.filterwarnings("ignore")

IMAGE_EXTS      = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}
VIDEO_EXTS      = {".mp4", ".webm", ".mkv", ".avi", ".mov", ".gif"}
SUPPORTED       = IMAGE_EXTS | VIDEO_EXTS
STOP_WORDS      = {"a", "an", "the", "in", "on", "of", "with", "is", "at", "to", "and", "by", "for", "from", "some", "there", "are", "it", "very", "photo", "image", "background", "man", "woman", "men", "women", "guy"}

print("Loading BLIP local VLM...", flush=True)
processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base").to("cuda")

def get_blip_name(img_path: Path):
    try:
        if img_path.suffix.lower() in VIDEO_EXTS:
            cmd = [
                "ffmpeg",
                "-i", str(img_path),
                "-vframes", "1",
                "-f", "image2pipe",
                "-vcodec", "png",
                "-"
            ]
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=10)
            if result.returncode != 0 or not result.stdout:
                return None, None
            image = Image.open(io.BytesIO(result.stdout)).convert('RGB')
        else:
            image = Image.open(img_path).convert('RGB')
            
        # unconditional image captioning
        inputs = processor(image, return_tensors="pt").to("cuda")
        out = model.generate(**inputs, max_new_tokens=15)
        caption = processor.decode(out[0], skip_special_tokens=True)
        
        # clean the output
        caption = caption.strip().lower()
        
        # apply user rules
        caption = re.sub(r'\bwoman\b', 'girl', caption)
        caption = re.sub(r'\bwomen\b', 'girls', caption)
        caption = re.sub(r'\bman\b', 'boy', caption)
        caption = re.sub(r'\bmen\b', 'boys', caption)
        
        caption = re.sub(r'[^\w\s_]', '', caption)
        words = [w for w in re.split(r'[\s_]+', caption) if w and w not in STOP_WORDS]
        
        # build a stem up to 25 characters max
        stem = ""
        for w in words:
            if not stem:
                stem = w
            elif len(stem) + len(w) + 1 <= 25:
                stem += "_" + w
            else:
                break
                
        if not stem:
            stem = "aesthetic"
                
        return stem, image
    except Exception as e:
        return None, None

def unique_dest(folder: Path, stem: str, suffix: str) -> Path:
    dest = folder / f"{stem}_01{suffix}"
    counter = 2
    while dest.exists():
        dest = folder / f"{stem}_{counter:02d}{suffix}"
        counter += 1
    return dest

def process_directory(target_dir: Path):
    targets = []
    # Support both flat directories and subdirectories
    for item in sorted(target_dir.rglob("*")):
        if item.is_file() and item.suffix.lower() in SUPPORTED:
            targets.append(item)
            
    total = len(targets)
    print(f"Files to process: {total}", flush=True)
    if total == 0:
        return
        
    renamed = errors = 0
    for i, src in enumerate(targets, 1):
        name, image = get_blip_name(src)
        if not name:
            errors += 1
            continue
            
        try:
            if src.suffix.lower() in VIDEO_EXTS:
                dest = unique_dest(src.parent, name, src.suffix.lower())
                if src.absolute() != dest.absolute():
                    shutil.move(str(src), str(dest))
            else:
                dest = unique_dest(src.parent, name, ".jpg")
                image.save(dest, "JPEG", quality=95)
                if src.absolute() != dest.absolute():
                    src.unlink()
            renamed += 1
        except Exception as e:
            errors += 1
            
        if i % 10 == 0:
            print(f"Processed {i}/{total} files...", flush=True)
            
    print(f"\nFinished!")
    print(f"Successfully processed: {renamed}")
    print(f"Errors: {errors}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Rename and convert images using BLIP")
    parser.add_argument("directory", help="The directory containing the images you want to rename (e.g. /path/to/folder)")
    args = parser.parse_args()
    
    target_path = Path(args.directory)
    if not target_path.is_dir():
        print(f"Error: Directory '{target_path}' does not exist.")
    else:
        process_directory(target_path)
