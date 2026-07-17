# Wallpaper Renaming Guide & Methods

## The Script: `wallpaper_renamer.py`
I have saved a fully generalized version of the script to your home folder. You can use this on any folder containing images.

### How to use it:
Open your terminal and run the script, providing the path to the folder you want to process:

```bash
python3 /home/aeon/Projects/Scripts/Wallpaper_Renamer/wallpaper_renamer.py /path/to/your/image/folder
```

---

## How It Works (The Methods)

### 1. The Vision-Language Model (VLM)
The script uses **Salesforce/blip-image-captioning-base**, a machine learning model designed to look at an image and generate a highly descriptive English caption. It runs entirely locally on your GPU (using CUDA).

### 2. Format Unification & Conversion
When the script processes an image:
1. It opens the image in its original format (supports `.jpg`, `.png`, `.webp`, `.gif`, `.bmp`).
2. After generating a new name, it resaves the image as a standard **JPEG** (`.jpg`) with 95% quality.
3. It safely deletes the original file (e.g., the old `.webp`), ensuring you don't end up with duplicate files taking up space. This heavily reduces Git repository sizes.

### 3. Naming Rules & Logic
To ensure the filenames look good and adhere to your strict limits, the script applies a series of filters to the model's generated caption:

* **Word Boundaries (Regex):** 
  The script looks for the *exact words* "man", "woman", "men", and "women". Using Regular Expressions (`\b` for word boundaries), it swaps them:
  * `woman` -> `girl`
  * `women` -> `girls`
  * `man` -> `boy`
  * `men` -> `boys`
  *(Note: Because of the word boundaries, words like "spiderman", "human", or "many" are completely safe and untouched!)*

* **Stop-Word Removal:**
  It strips out filler words that just take up character limits without adding value. Words like `a`, `an`, `the`, `photo`, `background`, and `image` are automatically dropped.

* **Character Limits (25-char max stem):**
  The script loops through the remaining descriptive words and chains them together with underscores (`_`). It stops adding words *right before* it would exceed 25 characters. 

* **Unique Suffixes:**
  Finally, it appends a numbered suffix (e.g., `_01.jpg`). If `anime_girl_01.jpg` already exists, it automatically checks and saves it as `anime_girl_02.jpg`, ensuring nothing is ever accidentally overwritten.
