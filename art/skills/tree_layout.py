"""Lay out the skill tree and write it into src/shared/Skills.luau.

The tree is drawn as wedges round the Prospector, one skill family each, with a family's later
skills further out in the same wedge. Each skill below has a ring (1 is next to the Prospector) and
a lane (sideways steps of one gem; positive is clockwise on screen). This script turns those into
map positions, checks that no two gems or names overlap, that no two links cross and that no link
runs through a gem, then rewrites each skill's position, branch and requirements in Skills.luau.
Names, text, effects and icons stay as they are in Skills.luau.

Changing a requirement is safe for saves: when a miner joins, any skill whose requirements they no
longer own is refunded as a skill point (Skills.prune). The script lists every requirement it
changes so a tightening is never a surprise.

    python art/skills/tree_layout.py             # check, then write Skills.luau
    python art/skills/tree_layout.py --check     # check only
    python art/skills/tree_layout.py --plot tree.png
"""

import itertools
import math
import re
import sys
from pathlib import Path

SKILLS = Path(__file__).resolve().parents[2] / "src" / "shared" / "Skills.luau"
FIRST_RING, RING_STEP, LANE_WIDTH = 190, 176, 178

# Order matters: a family's requirements must come from families listed before it.
FAMILIES = ["Pickwork", "Lamplight", "Survey optics", "Footwork", "Hauling", "Geology",
            "Momentum", "Showmanship", "Scholar", "Assaying", "Trade"]
NOTES = {
    "Pickwork": "-- The tree is drawn as wedges round the Prospector, one family each, with its later skills further\n"
                "-- out in the same wedge: Pickwork (upper left) leads on to Momentum, Survey optics (top) to Showmanship,\n"
                "-- Geology (right) to Scholar and Assaying, Hauling (lower left) to Trade. Positions come from\n"
                "-- art/skills/tree_layout.py; requirements only cross into a neighbouring wedge.\n"
                "-- Pickwork: reach and cutting.",
    "Lamplight": "-- Lamplight: your lamp and survey flares.",
    "Survey optics": "-- Survey optics: the mining light.",
    "Footwork": "-- Footwork: walking and jumping.",
    "Hauling": "-- Hauling: the pack, tempering and supplies.",
    "Geology": "-- Geology: XP from ore, and Fortune.\n"
               "-- Fresh Find (once First Edition, which only paid for each ore's first find and then went dead):\n"
               "-- XP for an ore you aren't carrying any of, which keeps paying for good.",
    "Momentum": "-- Each family below has one rule in Skills.cutTime, Skills.oreXP, Bonuses or Profile, so a skill\n"
                "-- is never just a number on a card.\n"
                "-- Momentum: speed from mining well.",
    "Showmanship": "-- Showmanship: mining near other miners.",
    "Scholar": "-- Scholar: experience.",
    "Assaying": "-- Assaying: purity and luck.",
    "Trade": "-- Trade: gold and tonics.",
}

# Wedges: centre angle and half width in degrees (0 is right, 90 is down), then
# (skill, family, ring, lane, requires).
WEDGES = [
    (-90, 24, [  # top
        ("Focus", "Survey optics", 2, 0, ["Reach", "Lamp"]),
        ("FocusII", "Survey optics", 3, 0, ["Focus"]),
        ("Longbeam", "Survey optics", 4, -0.6, ["FocusII"]),
        ("LightTrail", "Survey optics", 4, 0.6, ["FocusII"]),
        ("Constellation", "Survey optics", 5, 0, ["Longbeam", "LightTrail"]),
        ("ShowOff", "Showmanship", 6, 0, ["Constellation"]),
        ("ShowOffII", "Showmanship", 7, -1, ["ShowOff"]),
        ("CashOut", "Showmanship", 7, 0, ["ShowOff"]),
        ("CrowdPleaser", "Showmanship", 7, 1, ["ShowOff"]),
        ("ShowOffIII", "Showmanship", 8, -1, ["ShowOffII"]),
        ("CashOutII", "Showmanship", 8, 0, ["CashOut"]),
        ("CrowdPleaserII", "Showmanship", 8, 1, ["CrowdPleaser"]),
        ("CashOutIII", "Showmanship", 9, 0, ["CashOutII"]),
    ]),
    (-42, 24, [  # upper right
        ("Lamp", "Lamplight", 1, 0, []),
        ("Lantern", "Lamplight", 2, 0, ["Lamp"]),
        ("LanternIII", "Lamplight", 3, -0.6, ["Lantern"]),
        ("LongBurn", "Lamplight", 3, 0.6, ["Lantern"]),
        ("LanternIV", "Lamplight", 4, -1.0, ["LanternIII"]),
        ("LongBurnII", "Lamplight", 4, 1.0, ["LongBurn"]),
        ("CaveEcho", "Lamplight", 5, 0, ["LongBurnII", "LanternIII"]),
        ("FlareThrow", "Lamplight", 5, 1.4, ["LongBurnII"]),
        ("LongBurnIII", "Lamplight", 6, 1.4, ["FlareThrow"]),
    ]),
    (19, 37, [  # right
        ("Notes", "Geology", 1, 0, []),
        ("NotesII", "Geology", 2, 0, ["Notes"]),
        ("FirstFind", "Geology", 3, -1, ["NotesII"]),
        ("NotesIII", "Geology", 3, 0, ["NotesII"]),
        ("Rockhound", "Geology", 3, 1, ["NotesII", "StrideII"]),
        ("FirstFindII", "Geology", 4, -1.5, ["FirstFind"]),
        ("DeepStudy", "Geology", 4, -0.5, ["NotesIII"]),
        ("RareStudy", "Geology", 4, 0.5, ["NotesIII"]),
        ("Scholar", "Scholar", 5, -2.0, ["FirstFindII"]),
        ("AbyssScholar", "Scholar", 5, -0.8, ["DeepStudy"]),
        ("GemJournalII", "Scholar", 5, 0.3, ["RareStudy"]),
        ("Fortune", "Geology", 5, 1.4, ["RareStudy"]),
        ("ScholarII", "Scholar", 6, -2.2, ["Scholar"]),
        ("CraterScholar", "Scholar", 6, -1.0, ["AbyssScholar"]),
        ("CleanCut", "Scholar", 6, 0.2, ["GemJournalII"]),
        ("Assayer", "Assaying", 6, 1.2, ["Fortune"]),
        ("FortuneII", "Assaying", 6, 2.2, ["Fortune"]),
        ("LuckyStrike", "Assaying", 6, 3.2, ["Fortune"]),
        ("ScholarIII", "Scholar", 7, -2.2, ["ScholarII"]),
        ("AssayerII", "Assaying", 7, 1.2, ["Assayer"]),
        ("LuckyStrikeII", "Assaying", 7, 3.2, ["LuckyStrike"]),
        ("ScholarIV", "Scholar", 8, -2.2, ["ScholarIII"]),
        ("AssayerIII", "Assaying", 8, 0.7, ["AssayerII"]),
        ("Polish", "Assaying", 8, 1.7, ["AssayerII"]),
        ("LuckyStrikeIII", "Assaying", 8, 3.2, ["LuckyStrikeII"]),
        ("ScholarV", "Scholar", 9, -2.2, ["ScholarIV"]),
    ]),
    (84, 28, [  # bottom
        ("Stride", "Footwork", 1, 0, []),
        ("StrideII", "Footwork", 2, -0.5, ["Stride"]),
        ("Spring", "Footwork", 2, 0.5, ["Stride"]),
        ("StrideIII", "Footwork", 3, -0.5, ["StrideII"]),
        ("Scout", "Footwork", 3, 0.5, ["Spring"]),
        ("SpringII", "Footwork", 4, 0.5, ["Scout"]),
        ("Summit", "Footwork", 5, -0.2, ["StrideIII", "SpringII"]),
        ("ScoutII", "Footwork", 5, 0.9, ["SpringII"]),
        ("StrideIV", "Footwork", 6, -0.5, ["Summit"]),
        ("SpringIII", "Footwork", 6, 0.9, ["ScoutII"]),
    ]),
    (149, 37, [  # lower left
        ("Pack", "Hauling", 1, 0, []),
        ("PackII", "Hauling", 2, 0, ["Pack"]),
        ("PackMule", "Hauling", 3, -1, ["PackII", "Stride"]),
        ("PackIII", "Hauling", 3, 0, ["PackII"]),
        ("TemperKit", "Hauling", 3, 1, ["PackII"]),
        ("DeepPockets", "Hauling", 4, -1.5, ["PackIII", "PackMule"]),
        ("PackIV", "Hauling", 4, -0.5, ["PackIII"]),
        ("Broker", "Hauling", 4, 0.5, ["PackIII"]),
        ("TemperKitII", "Hauling", 4, 1.5, ["TemperKit"]),
        ("SupplyRunner", "Hauling", 5, -2.4, ["DeepPockets"]),
        ("DeepPocketsII", "Hauling", 5, -1.4, ["PackIV"]),
        ("PackV", "Hauling", 5, -0.4, ["PackIV"]),
        ("Haggler", "Trade", 5, 0.6, ["Broker"]),
        ("TemperKitIII", "Hauling", 5, 1.6, ["TemperKitII"]),
        ("HotSteel", "Hauling", 5, 2.6, ["TemperKitII", "TempoIII"]),
        ("EarlyBird", "Trade", 6, -2.4, ["SupplyRunner"]),
        ("BulkSeller", "Trade", 6, 0.2, ["Haggler"]),
        ("HagglerII", "Trade", 6, 1.2, ["Haggler"]),
        ("Brewmaster", "Trade", 7, -2.4, ["EarlyBird"]),
        ("RebornTrader", "Trade", 7, 0.2, ["BulkSeller"]),
        ("HagglerIII", "Trade", 7, 1.2, ["HagglerII"]),
        ("BrewmasterII", "Trade", 8, -2.9, ["Brewmaster"]),
        ("DoubleDose", "Trade", 8, -1.9, ["Brewmaster"]),
        ("HagglerIV", "Trade", 8, 1.2, ["HagglerIII"]),
        ("HagglerV", "Trade", 9, 1.2, ["HagglerIV"]),
    ]),
    (-144, 30, [  # upper left
        ("Reach", "Pickwork", 1, 0, []),
        ("ReachII", "Pickwork", 2, 0.5, ["Reach"]),
        ("Tempo", "Pickwork", 2, -0.5, ["Reach"]),
        ("ReachIII", "Pickwork", 3, 0.8, ["ReachII"]),
        ("TempoII", "Pickwork", 3, -0.8, ["Tempo"]),
        ("ReachIV", "Pickwork", 4, 1.5, ["ReachIII"]),
        ("StoneSplit", "Pickwork", 4, -0.1, ["TempoII"]),
        ("TempoIII", "Pickwork", 4, -1.2, ["TempoII"]),
        ("GemCutter", "Pickwork", 5, 0.8, ["ReachIII", "StoneSplit"]),
        ("HotStreak", "Momentum", 5, -0.6, ["TempoIII"]),
        ("StoneBreaker", "Momentum", 5, -1.8, ["TempoIII"]),
        ("FacetCutterII", "Momentum", 6, 1.2, ["GemCutter"]),
        ("HotStreakII", "Momentum", 6, -0.4, ["HotStreak"]),
        ("StoneBreakerII", "Momentum", 6, -1.8, ["StoneBreaker"]),
        ("RareTouch", "Momentum", 7, 1.2, ["FacetCutterII"]),
        ("HotStreakIII", "Momentum", 7, 0.2, ["HotStreakII"]),
        ("StreakKeeper", "Momentum", 7, -0.8, ["HotStreakII"]),
        ("Deepcutter", "Momentum", 7, -1.8, ["StoneBreakerII"]),
        ("CraterVeteran", "Momentum", 8, -1.8, ["Deepcutter"]),
    ]),
]

CALL = re.compile(r'\b(\w+)\(\s*"(\w+)",\s*"([^"]*)",\s*"([^"]*)",\s*(-?\d+),\s*(-?\d+),\s*\{([^}]*)\}'
                  r'((?:\s*,\s*(?:"[^"]*"|nil|-?\d+(?:\.\d+)?))*)\s*,?\s*\)', re.S)


def place():
    nodes = {}
    for centre, _, rows in WEDGES:
        for sid, family, ring, lane, requires in rows:
            radius = FIRST_RING + (ring - 1) * RING_STEP
            angle = math.radians(centre) + lane * LANE_WIDTH / radius
            nodes[sid] = dict(family=family, ring=ring, requires=requires,
                              x=round(radius * math.cos(angle) / 5) * 5, y=round(radius * math.sin(angle) / 5) * 5)
    return nodes


def problems(nodes):
    found = []
    # A gem is 84 studs square; its name sits under it, 160 wide.
    def boxes(n):
        return [(n["x"] - 44, n["y"] - 44, n["x"] + 44, n["y"] + 44), (n["x"] - 82, n["y"] + 36, n["x"] + 82, n["y"] + 66)]
    for a, b in itertools.combinations(nodes, 2):
        if any(p[0] < q[2] + 4 and q[0] < p[2] + 4 and p[1] < q[3] + 4 and q[1] < p[3] + 4
               for p in boxes(nodes[a]) for q in boxes(nodes[b])):
            found.append(f"{a} and {b} overlap")
    def at(k):
        return (0, 0) if k is None else (nodes[k]["x"], nodes[k]["y"])
    links = [(r, sid) for sid, n in nodes.items() for r in (n["requires"] or [None])]
    for r, sid in links:
        if r is not None and r not in nodes:
            found.append(f"{sid} needs unknown {r}")
    def side(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
    for (a, b), (c, d) in itertools.combinations(links, 2):
        p1, p2, p3, p4 = at(a), at(b), at(c), at(d)
        if len({p1, p2, p3, p4}) == 4 and side(p1, p2, p3) * side(p1, p2, p4) < 0 and side(p3, p4, p1) * side(p3, p4, p2) < 0:
            found.append(f"link {a}->{b} crosses {c}->{d}")
    for a, b in links:
        (ax, ay), (bx, by) = at(a), at(b)
        for k in nodes:
            if k in (a, b):
                continue
            px, py = at(k)
            t = max(0, min(1, ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / max(1e-9, (bx - ax) ** 2 + (by - ay) ** 2)))
            if math.hypot(ax + t * (bx - ax) - px, ay + t * (by - ay) - py) < 60:
                found.append(f"link {a}->{b} runs through {k}")
    return found


def read_skills(source):
    body = source[source.index("local pickwork = branch("):source.index("function Skills.ready(")]
    branches = {m.group(1): (m.group(2), m.group(3)) for m in re.finditer(r'local (\w+) = branch\("([^"]+)", "([^"]+)"\)', body)}
    skills = {}
    for m in CALL.finditer(body):
        var, sid, title, detail, x, y, requires, rest = m.groups()
        if var not in branches:
            continue
        args = re.findall(r'"[^"]*"|nil|-?\d+(?:\.\d+)?', rest) + ["nil"] * 3
        family, family_icon = branches[var]
        skills[sid] = dict(title=title, detail=detail, effect=args[0], amount=args[1],
                           icon=args[2].strip('"') if args[2] != "nil" else family_icon,
                           family=family, requires=re.findall(r'"(\w+)"', requires))
    icons = {family: icon for family, icon in branches.values()}
    variables = {family: var for var, (family, _) in branches.items()}
    return skills, icons, variables


def write(source, nodes, skills, icons, variables):
    lines, seen = [], set()
    for family in FAMILIES:
        var = variables[family]
        lines.append(NOTES[family])
        lines.append(f'local {var} = branch("{family}", "{icons[family]}")')
        members = sorted((k for k, n in nodes.items() if n["family"] == family),
                         key=lambda k: (nodes[k]["ring"], nodes[k]["x"], nodes[k]["y"]))
        for sid in members:
            n, s = nodes[sid], skills[sid]
            missing = [r for r in n["requires"] if r not in seen]
            if missing:
                raise SystemExit(f"{sid} would be listed before {missing}; reorder FAMILIES or rings")
            args = [s["effect"], s["amount"], "nil" if s["icon"] == icons[family] else f'"{s["icon"]}"']
            while args and args[-1] == "nil":
                args.pop()
            requires = "{ " + ", ".join(f'"{r}"' for r in n["requires"]) + " }" if n["requires"] else "{}"
            tail = ", " + ", ".join(args) if args else ""
            lines.append(f'{var}("{sid}", "{s["title"]}", "{s["detail"]}", {n["x"]}, {n["y"]}, {requires}{tail})')
            seen.add(sid)
        lines.append("")
    start, end = source.index("-- The tree is drawn as wedges") if "-- The tree is drawn as wedges" in source \
        else source.index("local pickwork = branch("), source.index("function Skills.ready(")
    return source[:start] + "\n".join(lines) + "\n" + source[end:]


def plot(nodes, skills, out):
    from PIL import Image, ImageDraw, ImageFont
    palette = [(255, 99, 99), (255, 190, 60), (120, 220, 255), (120, 255, 140), (200, 140, 255), (255, 140, 220),
               (255, 255, 120), (140, 160, 255), (90, 230, 200), (255, 160, 110), (180, 180, 180)]
    colours = dict(zip(FAMILIES, palette))
    xs, ys = [n["x"] for n in nodes.values()], [n["y"] for n in nodes.values()]
    pad, scale = 120, 0.62
    image = Image.new("RGB", (int((max(xs) - min(xs) + 2 * pad) * scale), int((max(ys) - min(ys) + 2 * pad) * scale)), (20, 20, 36))
    draw, font = ImageDraw.Draw(image), ImageFont.load_default()
    def at(p):
        return ((p[0] - min(xs) + pad) * scale, (p[1] - min(ys) + pad) * scale)
    for sid, n in nodes.items():
        for r in n["requires"] or [None]:
            draw.line([at((n["x"], n["y"])), at((0, 0) if r is None else (nodes[r]["x"], nodes[r]["y"]))], fill=(95, 95, 130), width=2)
    for sid, n in nodes.items():
        x, y = at((n["x"], n["y"]))
        draw.rectangle([x - 8, y - 8, x + 8, y + 8], fill=colours[n["family"]])
        draw.text((x - 45, y + 10), skills[sid]["title"], fill=colours[n["family"]], font=font)
    x, y = at((0, 0))
    draw.ellipse([x - 13, y - 13, x + 13, y + 13], fill=(255, 215, 0))
    image.save(out)


def main():
    raw = SKILLS.read_text(encoding="utf8")
    source = raw.replace("\r\n", "\n")
    skills, icons, variables = read_skills(source)
    nodes = place()
    if set(nodes) != set(skills):
        raise SystemExit(f"layout and Skills.luau disagree on: {sorted(set(nodes) ^ set(skills))}")
    for sid, n in nodes.items():
        added = sorted(set(n["requires"]) - set(skills[sid]["requires"]))
        if added:
            print(f"{sid} now also needs {', '.join(added)}: miners without it get {sid} refunded")
    found = problems(nodes)
    for line in found:
        print(line)
    if "--plot" in sys.argv:
        plot(nodes, skills, sys.argv[sys.argv.index("--plot") + 1])
    if found:
        raise SystemExit(f"{len(found)} layout problems")
    if "--check" not in sys.argv:
        result = write(source, nodes, skills, icons, variables)
        SKILLS.write_text(result.replace("\n", "\r\n") if "\r\n" in raw else result, encoding="utf8", newline="")
        print(f"wrote {len(nodes)} skills to {SKILLS.name}")


if __name__ == "__main__":
    main()
