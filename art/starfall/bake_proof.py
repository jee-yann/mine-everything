"""Rebuild the split ore block and its step-cut emerald in the mine's colors."""
from bake_waymark import STAGE, build

if __name__ == "__main__":
    build("ProspectorProof", "cook_proof.luau", "PROOF", {
        "MineralRelief": {"$path": str(STAGE.parents[1] / "shared/MineralRelief.luau")}
    })
