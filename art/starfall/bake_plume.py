"""Rebuild the self-contained explosion sculptures using Blender and Studio.

python art/starfall/bake_plume.py [--new-scene]
Uses the edited Pressure Bloom.blend when present. --new-scene regenerates it.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ART = Path(__file__).resolve().parent
OUT = ROOT / "src/client/Starfall"


def build(fresh=False):
    with tempfile.TemporaryDirectory(prefix="starfall-plume-bake-") as directory:
        folder = Path(directory)
        blender = shutil.which("blender") or next(
            Path(os.environ["ProgramFiles"]).glob(
                "Blender Foundation/Blender*/blender.exe"
            )
        )
        studio = max(
            (Path(os.environ["LOCALAPPDATA"]) / "Roblox/Versions").glob(
                "*/RobloxStudioBeta.exe"
            ),
            key=lambda f: f.stat().st_mtime,
        )
        scene = ART / "Pressure Bloom.blend"
        cmd = [str(blender), "-b"] + (
            [str(scene)] if scene.exists() and not fresh else []
        )
        subprocess.run(
            cmd
            + ["-P", str(ART / "sculpt_plume.py"), "--", str(folder / "sculpt.json")],
            check=True,
        )
        exported = json.loads((folder / "sculpt.json").read_text())
        library = {"shapes": exported["shapes"], "jets": exported["jets"]}
        source = (
            (ART / "cook_plume.luau")
            .read_text()
            .replace(
                "BRUSH_SOURCE", json.dumps(json.dumps(library, separators=(",", ":")))
            )
        )
        (folder / "cook.luau").write_text(source, encoding="utf8")
        proj = {
            "name": "Cook pressure bloom",
            "tree": {
                "$className": "DataModel",
                "Workspace": {"$className": "Workspace"},
            },
        }
        (folder / "cook.project.json").write_text(json.dumps(proj))
        place = folder / "Cook.rbxlx"
        log = folder / "Cook.log"
        subprocess.run(
            ["rojo", "build", str(folder / "cook.project.json"), "-o", str(place)],
            check=True,
        )
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        si.wShowWindow = subprocess.SW_HIDE
        subprocess.run(
            [
                str(studio),
                "--task",
                "RunScript",
                "--localPlaceFile",
                str(place),
                "--runScriptFile",
                str(folder / "cook.luau"),
                "--outputFile",
                str(log),
                "--quitAfterExecution",
            ],
            startupinfo=si,
            check=True,
            timeout=210,
        )
        output = log.read_text(encoding="utf8", errors="replace")
        if not re.search(r"^PLUME_ARCHIVE_COMPLETE\s*$", output, re.M):
            raise RuntimeError(output[-4200:])
        data = base64.b64decode(
            "".join(re.findall(r"^PLUME_BYTES ([A-Za-z0-9+/=]+)", output, re.M)),
            validate=True,
        )
        assert data.startswith(b"<roblox!") and len(data) > 10000
        (OUT / "PressureBloom.rbxm").write_bytes(data)
        item = {
            "ClassName": "StringValue",
            "Properties": {
                "Value": json.dumps(exported["tracks"], separators=(",", ":"))
            },
        }
        (OUT / "BloomPoses.model.json").write_text(
            json.dumps(item, separators=(",", ":")) + "\n"
        )
        print(
            "Baked", len(data), "bytes and", len(exported["tracks"]), "authored tracks"
        )


if __name__ == "__main__":
    args = argparse.ArgumentParser()
    args.add_argument("--new-scene", action="store_true")
    build(args.parse_args().new_scene)
