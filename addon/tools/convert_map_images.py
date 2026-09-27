"""Convert the fan-made maps of the new WoW Forever dungeons (tools/map_sources/<JournalKey>.jpg) into
textures the game can load from the addon folder: Evergreen/Maps/<JournalKey>.blp, 1024x1024 (WoW
textures must be power-of-two), the map scaled to 1024 wide at the top, the rest left black.
Prints the used width/height for Journal_Map.lua's SHIPPED_IMAGES. Run: python convert_map_images.py

Maps: recreations by Santiago Reyes, Atlas de Azeroth Forever (wowhead.com screenshots)."""
import os, glob
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "Evergreen", "Maps")
SIZE = 1024
for src in sorted(glob.glob(os.path.join(HERE, "map_sources", "*.jpg"))):
    key = os.path.splitext(os.path.basename(src))[0]
    im = Image.open(src).convert("RGB")
    w, h = SIZE, round(im.height * SIZE / im.width)
    canvas = Image.new("RGB", (SIZE, SIZE))
    canvas.paste(im.resize((w, h), Image.LANCZOS), (0, 0))
    out = os.path.join(OUT, key + ".blp")
    canvas.quantize(256, method=Image.Quantize.MEDIANCUT).save(out)
    print(key, "used", w, h, "->", out, os.path.getsize(out), "bytes")
