"""Render FieldKit.png from field_kit.html with headless Google Chrome, then run bake_field_kit.py."""

import subprocess
import sys
from pathlib import Path

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def main():
    folder = Path(__file__).resolve().parent
    chrome = sys.argv[1] if len(sys.argv) > 1 else CHROME
    subprocess.run(
        [
            chrome,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--default-background-color=00000000",
            "--force-device-scale-factor=1",
            "--window-size=1024,2304",
            "--virtual-time-budget=2000",
            f"--screenshot={folder / 'FieldKit.png'}",
            (folder / "field_kit.html").as_uri(),
        ],
        check=True,
        capture_output=True,
    )


if __name__ == "__main__":
    main()
