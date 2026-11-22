"""Run the Studio input and multiplayer checks against disposable Rojo builds."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"


def make_project(folder, mode):
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    tree = project["tree"]

    def resolve_paths(node):
        if isinstance(node, dict):
            for key, child in node.items():
                if key == "$path":
                    node[key] = str(ROOT / child)
                else:
                    resolve_paths(child)

    resolve_paths(tree)
    tree["ReplicatedStorage"].setdefault("$attributes", {}).update(
        MuteTestMusic=True, MiningTestMode=mode, MiningTestRun=folder.name
    )
    server = tree["ServerScriptService"]["Server"]
    server.setdefault("$attributes", {})["StudioMineSeed"] = 74109
    if mode == "Multiplayer":
        # The test driver seeds the returning player's save before the game accepts joins.
        tree.setdefault("ServerStorage", {})["Server"] = tree["ServerScriptService"].pop("Server")
    tree["ServerScriptService"]["MiningPlaytest"] = {
        "$path": str(TESTS / "play" / "Driver.server.luau")
    }
    tree["StarterPlayer"]["StarterPlayerScripts"]["MiningPlaytest"] = {
        "$path": str(TESTS / "play" / "Miner.client.luau")
    }
    path = folder / f"{mode}.project.json"
    path.write_text(json.dumps(project), encoding="utf-8")
    return path


def studio_results(folder, marker, started):
    # In an asynchronous multiplayer run, Studio can leave the result in the
    # child server's Output. Match this build's token before accepting a line.
    if sys.platform == "win32":
        logs = Path(os.environ["LOCALAPPDATA"]) / "Roblox" / "logs"
    else:
        logs = Path.home() / "Library" / "Logs" / "Roblox"
    results = []
    for path in logs.glob("*Studio*.log"):
        if path.stat().st_mtime < started - 5:
            continue
        with path.open(encoding="utf-8", errors="replace") as log:
            for line in log:
                _, found, result = line.partition("[FLog::CreatorOutput] " + marker + " ")
                if found and result.rstrip().endswith(f"[{folder.name}]"):
                    results.append(marker + " " + result.rstrip())
    return results


def run(studio, folder, mode, marker):
    project = make_project(folder, mode)
    place = folder / f"{mode}.rbxlx"
    log = folder / f"{mode}.log"
    subprocess.run(["rojo", "build", project, "-o", place], check=True)
    startup = None
    if sys.platform == "win32":
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
    started = time.time()
    subprocess.run(
        [
            studio, "--task", "RunScript", "--localPlaceFile", place,
            "--runScriptFile", TESTS / "Play.spec.luau", "--outputFile", log,
            "--quitAfterExecution",
        ],
        check=True,
        startupinfo=startup,
        timeout=250,
    )
    output = log.read_text(encoding="utf-8", errors="replace")
    results = [line for line in output.splitlines() if line.startswith(marker + " ")]
    if not results:
        results = studio_results(folder, marker, started)
    if not results or any(not line.startswith(marker + " PASS ") for line in results):
        raise RuntimeError(f"{mode} failed in Studio.\n{output[-4000:]}")
    print(results[-1], flush=True)


if __name__ == "__main__":
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("studio", type=Path, help="path to the Studio executable")
    studio = args.parse_args().studio.resolve(strict=True)
    with tempfile.TemporaryDirectory(prefix="endless-mining-") as temp:
        run(studio, Path(temp), "Swing", "MINING_SWING_RESULT")
        run(studio, Path(temp), "Multiplayer", "MINING_PLAYTEST_RESULT")
