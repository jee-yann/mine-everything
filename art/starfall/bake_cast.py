"""Rebuild the film's R15 supporting cast with their tools welded to the hand."""
from bake_waymark import build

if __name__ == "__main__":
    build("CoveCast", "cook_cast.luau", "CAST")
