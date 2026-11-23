"""Rebuild the embedded expedition vane with Rojo and the installed Roblox Studio."""

import base64
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ART = Path(__file__).resolve().parent
STAGE = ART.parents[1] / "src/client/Starfall"


def build(name="ExpeditionVane", recipe="cook_waymark.luau", prefix="VANE", modules=None):
    studio = max(
        (Path(os.environ["LOCALAPPDATA"]) / "Roblox/Versions").glob(
            "*/RobloxStudioBeta.exe"
        ),
        key=lambda p: p.stat().st_mtime,
    )
    with tempfile.TemporaryDirectory(prefix="cove-survey-cast-") as work:
        work = Path(work)
        scene = work / "Vane.rbxlx"
        project = work / "cast.project.json"
        project.write_text(
            json.dumps(
                {
                    "name": "Survey",
                    "tree": {
                        "$className": "DataModel",
                        "ReplicatedStorage": {
                            "Scenery": {"$path": str(STAGE / "Scenery.luau")},
                            **(modules or {}),
                        },
                    },
                }
            )
        )
        subprocess.run(["rojo", "build", project, "-o", scene], check=True)
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        si.wShowWindow = subprocess.SW_HIDE
        log = work / "cast.log"
        subprocess.run(
            [
                studio,
                "--task",
                "RunScript",
                "--localPlaceFile",
                scene,
                "--runScriptFile",
                ART / recipe,
                "--outputFile",
                log,
                "--quitAfterExecution",
            ],
            check=True,
            startupinfo=si,
            timeout=150,
        )
        result = log.read_text(encoding="utf8", errors="replace")
        if not re.search(rf"^{prefix}_READY\s*$", result, re.M):
            errors = [
                line
                for line in result.splitlines()
                if not line.startswith(f"{prefix}_DATA ")
            ]
            raise RuntimeError("\n".join(errors[-12:]))
        parts = re.findall(rf"^{prefix}_DATA ([A-Za-z0-9+/=]+)", result, re.M)
        data = base64.b64decode("".join(parts), validate=True)
        if not data.startswith(b"<roblox!"):
            raise ValueError("Invalid serialized model")
        (STAGE / f"{name}.rbxm").write_bytes(data)
        print(f"{len(data):,} bytes")


if __name__ == "__main__":
    build()
