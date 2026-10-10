import os
import math
from PIL import Image, ImageDraw

def create_icons():
    src_path = r'C:\Users\marcu\.gemini\antigravity-ide\brain\ac32532f-c49b-4d50-8e00-9bce6f0aea10\.user_uploaded\media_1787496957063.png'
    raw_img = Image.open(src_path).convert('RGBA')

    # 1. Find bounding box of the logo
    w, h = raw_img.size
    pixels = raw_img.load()
    xmin, ymin, xmax, ymax = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 30 and (r < 245 or g < 245 or b < 245):
                if x < xmin: xmin = x
                if x > xmax: xmax = x
                if y < ymin: ymin = y
                if y > ymax: ymax = y

    # Add 4px margin
    xmin = max(0, xmin - 4)
    ymin = max(0, ymin - 4)
    xmax = min(w - 1, xmax + 4)
    ymax = min(h - 1, ymax + 4)

    cropped = raw_img.crop((xmin, ymin, xmax + 1, ymax + 1))
    cw, ch = cropped.size

    # 2. Extract transparent logo
    trans_logo = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
    c_pixels = cropped.load()
    t_pixels = trans_logo.load()

    for y in range(ch):
        for x in range(cw):
            r, g, b, a = c_pixels[x, y]
            whiteness = min(r, g, b)
            if whiteness > 245:
                t_pixels[x, y] = (255, 255, 255, 0)
            elif whiteness > 200:
                alpha = int(255 * (245 - whiteness) / 45)
                # Un-multiply white background color
                t_pixels[x, y] = (r, g, b, alpha)
            else:
                t_pixels[x, y] = (r, g, b, 255)

    # 3. Create assets directories
    os.makedirs('assets/images', exist_ok=True)
    os.makedirs('assets/icon', exist_ok=True)

    # Save transparent logo
    trans_logo.save('assets/images/logo.png', 'PNG')

    # Save high-res master 1024x1024 logo icon (white background + centered logo)
    master_1024 = Image.new('RGBA', (1024, 1024), (255, 255, 255, 255))
    # Scale logo to fit 750px width
    scale = 750 / cw
    new_w = int(cw * scale)
    new_h = int(ch * scale)
    scaled_logo = trans_logo.resize((new_w, new_h), Image.Resampling.LANCZOS)
    pos_x = (1024 - new_w) // 2
    pos_y = (1024 - new_h) // 2
    master_1024.paste(scaled_logo, (pos_x, pos_y), scaled_logo)
    master_1024.save('assets/icon/app_icon.png', 'PNG')
    master_1024.save('assets/images/logo_square.png', 'PNG')

    # 4. Generate Android Legacy Icons (Square & Round)
    densities = {
        'mipmap-mdpi': (48, 108),
        'mipmap-hdpi': (72, 162),
        'mipmap-xhdpi': (96, 216),
        'mipmap-xxhdpi': (144, 324),
        'mipmap-xxxhdpi': (192, 432),
    }

    res_base = 'android/app/src/main/res'

    for folder, (size, fg_size) in densities.items():
        dir_path = os.path.join(res_base, folder)
        os.makedirs(dir_path, exist_ok=True)

        # Legacy Square Icon
        sq_icon = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        lw = int(size * 0.78)
        lh = int(ch * (lw / cw))
        s_logo = trans_logo.resize((lw, lh), Image.Resampling.LANCZOS)
        sq_icon.paste(s_logo, ((size - lw) // 2, (size - lh) // 2), s_logo)
        sq_icon.save(os.path.join(dir_path, 'ic_launcher.png'), 'PNG')

        # Legacy Round Icon
        rd_icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(rd_icon)
        draw.ellipse((0, 0, size - 1, size - 1), fill=(255, 255, 255, 255))
        # Inner logo scaled to 68% for round circle
        rlw = int(size * 0.68)
        rlh = int(ch * (rlw / cw))
        rs_logo = trans_logo.resize((rlw, rlh), Image.Resampling.LANCZOS)
        rd_icon.paste(rs_logo, ((size - rlw) // 2, (size - rlh) // 2), rs_logo)
        rd_icon.save(os.path.join(dir_path, 'ic_launcher_round.png'), 'PNG')

        # Adaptive Foreground Icon (108dp base, logo in safe zone ~60%)
        fg_icon = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
        flw = int(fg_size * 0.62)
        flh = int(ch * (flw / cw))
        fs_logo = trans_logo.resize((flw, flh), Image.Resampling.LANCZOS)
        fg_icon.paste(fs_logo, ((fg_size - flw) // 2, (fg_size - flh) // 2), fs_logo)
        fg_icon.save(os.path.join(dir_path, 'ic_launcher_foreground.png'), 'PNG')

    # 5. Generate Notification Icon (monochrome white silhouette on transparent)
    # Using the shape of the logo filled with solid white
    notif_densities = {
        'drawable-mdpi': 24,
        'drawable-hdpi': 36,
        'drawable-xhdpi': 48,
        'drawable-xxhdpi': 72,
        'drawable-xxxhdpi': 96,
        'drawable': 48,
    }

    white_logo = Image.new('RGBA', (cw, ch), (0, 0, 0, 0))
    w_pixels = white_logo.load()
    for y in range(ch):
        for x in range(cw):
            _, _, _, a = t_pixels[x, y]
            if a > 40:
                w_pixels[x, y] = (255, 255, 255, a)

    for folder, size in notif_densities.items():
        dir_path = os.path.join(res_base, folder)
        os.makedirs(dir_path, exist_ok=True)
        notif_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        nlw = int(size * 0.85)
        nlh = int(ch * (nlw / cw))
        ns_logo = white_logo.resize((nlw, nlh), Image.Resampling.LANCZOS)
        notif_img.paste(ns_logo, ((size - nlw) // 2, (size - nlh) // 2), ns_logo)
        notif_img.save(os.path.join(dir_path, 'ic_notification.png'), 'PNG')

    # 6. Create Adaptive XML files
    anydpi_dir = os.path.join(res_base, 'mipmap-anydpi-v26')
    os.makedirs(anydpi_dir, exist_ok=True)

    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    with open(os.path.join(anydpi_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)

    with open(os.path.join(anydpi_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)

    print('All icons generated successfully!')

if __name__ == '__main__':
    create_icons()
