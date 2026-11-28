"""Render the Creator Dashboard images for every game pass and developer product (512 x 512 PNG).

Each image is the item's Shop art (the Field Kit icon from art/hud/field_kit.html) on its Shop section's
colours, with soft rays. Game pass icons are shown cropped to a circle, so everything that matters sits
inside it. Tags only where the Shop's art alone wouldn't tell two items apart (2x on the gold boosts,
the crate counts, VIP and the bundle). The Founder's Halo gets its own drawing of the aura.

    python art/listings/render_listings.py [chrome.exe]

Writes art/listings/<Key>.png. Text uses Roblox's own Fredoka One from the local Roblox install.
"""

import glob
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"

# Shop section colours (src/client/ShopPanel.luau), light then dark.
FEATURED, CRATES, PASSES = ("#ff9fc8", "#e3458a"), ("#cfaeff", "#8150e6"), ("#ffe680", "#f3a51a")
BOOSTS, GOLD, HALO = ("#a6f59a", "#34b24a"), ("#ffd678", "#d68c28"), ("#ffc878", "#d66028")
SYMBOL = {"Achievements": "i-trophy", "Pack": "i-packA", "Coins": "i-coins", "Speed": "i-speed",
          "Crystal": "i-gems", "Compass": "i-compass", "Geode": "i-geode", "Friends": "i-friends",
          "Power": "i-pick", "Boosts": "i-potion", "Skills": "i-bolt", "GoldPouch": "i-gpouch",
          "GoldBag": "i-gbag", "GoldChest": "i-gchest", "GoldVault": "i-gvault"}

# key, art, colours, big tag (corner), ribbon (bottom)
LISTINGS = [
    ("Everything", "Achievements", PASSES, None, "ALL PASSES"),
    ("BiggerPack", "Pack", PASSES, None, None),
    ("DoubleGold", "Coins", PASSES, "x2", None),
    ("FastPick", "Speed", PASSES, None, None),
    ("VIP", "Achievements", PASSES, None, "VIP"),
    ("Lucky", "Crystal", PASSES, "x2", None),
    ("StarfallCompass", "Compass", PASSES, None, None),
    ("StarterPack", "Geode", FEATURED, None, "STARTER"),
    ("FounderHalo", "halo", HALO, None, "LIMITED"),
    ("Crate1", "Geode", CRATES, None, None),
    ("Crate3", "Geode", CRATES, "x3", None),
    ("Crate10", "Geode", CRATES, "x10", None),
    ("Gold2x15", "Coins", BOOSTS, "x2", "15 MIN"),
    ("Gold2x60", "Coins", BOOSTS, "x2", "1 HOUR"),
    ("ServerLuck", "Friends", BOOSTS, "x2", None),
    ("Instamine10", "Power", BOOSTS, None, "10 MIN"),
    ("AutoSell30", "Coins", BOOSTS, None, "30 MIN"),
    ("Fling", "Boosts", BOOSTS, None, None),
    ("ResetSkills", "Skills", BOOSTS, None, None),
    ("GoldPouch", "GoldPouch", GOLD, None, None),
    ("GoldBag", "GoldBag", GOLD, None, None),
    ("GoldChest", "GoldChest", GOLD, None, None),
    ("GoldVault", "GoldVault", GOLD, None, None),
]

# The Founder's Halo: wings of light either side of a gold crown inside a rose ring, in a warm glow.
HALO_ART = """
<symbol id="i-founderhalo" viewBox="0 0 100 100">
  <circle cx="50" cy="54" r="34" fill="#fff3c4" opacity=".45"/>
  <g filter="url(#ol)">
    <g id="wing">
      <path d="M45 60 C36 38 18 20 3 17 C7 31 21 48 43 64 Z" fill="#fff8e2"/>
      <path d="M45 62 C31 47 13 38 0 38 C6 51 22 60 43 66 Z" fill="#ffe6ad"/>
      <path d="M45 64 C31 60 14 60 1 64 C11 71 28 73 44 68 Z" fill="#ffc69c"/>
      <path d="M45 66 C35 71 23 80 13 91 C28 88 38 79 46 70 Z" fill="#ff9d9d"/>
    </g>
    <use href="#wing" transform="translate(100 0) scale(-1 1)"/>
    <path d="M32 50 L34 34 L41 48 Z M39 47 L42 24 L48 46 Z M44 46 L50 13 L56 46 Z M52 46 L58 24 L61 47 Z M59 48 L66 34 L68 50 Z" fill="#ffd23f"/>
    <path d="M50 13 L56 46 H50 Z M58 24 L61 47 L56 46 Z" fill="#f5a31e"/>
    <circle cx="50" cy="15" r="3.6" fill="#ff6f86"/>
    <circle cx="42" cy="26" r="2.6" fill="#ff6f86"/><circle cx="58" cy="26" r="2.6" fill="#ff6f86"/>
    <ellipse cx="50" cy="57" rx="36" ry="12" fill="none" stroke="#ff5f6f" stroke-width="6"/>
    <ellipse cx="50" cy="54" rx="24" ry="8" fill="none" stroke="#ffc83a" stroke-width="7.5"/>
    <path d="M30 58 Q36 61.5 44 62" stroke="#fff" stroke-width="2.6" stroke-linecap="round" fill="none"/>
    <use href="#spark" transform="translate(84 12) scale(.8)" fill="#fff"/>
    <use href="#spark" transform="translate(16 86) scale(.6)" fill="#fff"/>
    <use href="#spark" transform="translate(86 88) scale(.5)" fill="#fff"/>
  </g>
</symbol>
"""


def fredoka():
    found = glob.glob(os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "Versions", "*", "content", "fonts", "FredokaOne-Regular.ttf"))
    return Path(found[0]).as_uri() if found else None


def page(defs, art, colours, tag, ribbon, font):
    light, dark = colours
    symbol = "i-founderhalo" if art == "halo" else SYMBOL[art]
    face = "'Fredoka One', 'Arial Black', sans-serif"
    tag_html = f'<div class="tag{" long" if len(tag) > 2 else ""}">{tag}</div>' if tag else ""
    ribbon_html = f'<div class="ribbon">{ribbon}</div>' if ribbon else ""
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>
@font-face {{ font-family: 'Fredoka One'; src: url('{font or ''}'); }}
html, body {{ margin: 0; width: 512px; height: 512px; overflow: hidden; }}
body {{ background: radial-gradient(circle at 50% 42%, {light} 0%, {dark} 78%); position: relative; }}
.rays {{ position: absolute; inset: 0; background: repeating-conic-gradient(from 0deg at 50% 46%, #ffffff22 0deg 9deg, #ffffff00 9deg 22.5deg);
  -webkit-mask: radial-gradient(circle at 50% 46%, #000 0%, #000 30%, transparent 70%); }}
.art {{ position: absolute; left: 86px; top: 70px; width: 340px; height: 340px; overflow: visible; filter: drop-shadow(10px 16px 0 #29264a40); }}
.tag {{ position: absolute; left: 318px; top: 86px; min-width: 104px; height: 84px; padding: 0 10px; box-sizing: border-box;
  border-radius: 42px; background: linear-gradient(#ff6b7c, #e5304a); border: 7px solid #29264a; transform: rotate(10deg);
  font: 58px/72px {face}; color: #fff; text-align: center; -webkit-text-stroke: 3px #29264a; paint-order: stroke fill; }}
.tag.long {{ font-size: 50px; }}
.ribbon {{ position: absolute; left: 50%; top: 392px; transform: translateX(-50%); padding: 0 26px; height: 62px; border-radius: 31px;
  background: linear-gradient(#ffe27a, #f5a31e); border: 6px solid #29264a; white-space: nowrap;
  font: 38px/62px {face}; color: #fff; -webkit-text-stroke: 3px #29264a; paint-order: stroke fill; letter-spacing: 1px; }}
</style></head><body>
<svg width="0" height="0" style="position:absolute"><defs>{defs}{HALO_ART}</defs></svg>
<div class="rays"></div>
<svg class="art" viewBox="0 0 100 100"><use href="#{symbol}"/></svg>
{tag_html}{ribbon_html}
</body></html>"""


def main():
    chrome = sys.argv[1] if len(sys.argv) > 1 else CHROME
    kit = (ROOT / "art" / "hud" / "field_kit.html").read_text(encoding="utf8")
    defs = kit[kit.index("<defs>") + len("<defs>"):kit.index("</defs>")]
    config = (ROOT / "src" / "shared" / "StoreConfig.luau").read_text(encoding="utf8")
    keys = set(re.findall(r'key = "(\w+)"', config))
    missing = sorted(keys - {k for k, *_ in LISTINGS} - {"PrismTrail"})
    if missing:
        raise SystemExit(f"StoreConfig items with no listing image: {missing}")
    font = fredoka()
    out = Path(__file__).resolve().parent
    with tempfile.TemporaryDirectory() as temp:
        for key, art, colours, tag, ribbon in LISTINGS:
            if key not in keys:
                raise SystemExit(f"{key} is not in StoreConfig")
            html = Path(temp) / f"{key}.html"
            html.write_text(page(defs, art, colours, tag, ribbon, font), encoding="utf8")
            subprocess.run([chrome, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
                            "--force-device-scale-factor=1", "--window-size=512,512", "--virtual-time-budget=1500",
                            f"--screenshot={out / (key + '.png')}", html.as_uri()], check=True, capture_output=True)
            print("wrote", key)


if __name__ == "__main__":
    main()
