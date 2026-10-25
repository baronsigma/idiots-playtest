extends RefCounted
## Deterministic, engine-independent combination resolver.
## The selected SET of components determines the result, NOT input order.
const DATA_PATH := "res://data/parts.json"
const HOST_ORDER := ["chicken", "goblin", "saucer", "hive", "mushroom", "bones", "magnet", "battery", "board", "hammer", "mirror", "ghost", "grease", "coffee", "paper", "boots", "bandage", "ice", "torch", "venom"]
const SPECIAL := {
    "chicken|goblin": "DUI: Poultry Edition",
    "chicken|torch": "The Roast Runner",
    "hive|torch": "Spicy Air Force",
    "chicken|saucer": "Poultry Discus",
    "hive|saucer": "BEE-52 Bomber",
    "ghost|goblin": "Haunted Happy Hour",
    "chicken|goblin|hive|torch": "The Department of Flaming Poultry",
    "chicken|hive|saucer|torch": "The Flying Fried Chicken",
    "battery|saucer": "Tesla Frisbee",
    "grease|torch": "Kitchen Catastrophe",
    "bones|hive": "The Necro-Hive",
    "hive|mushroom": "Plague Bees",
    "chicken|magnet": "Poultry Polarity",
    "chicken|ice": "The Frosty Clucker",
    "bandage|chicken": "Emergency Cluck",
    "board|chicken": "Armored Poultry",
    "magnet|saucer": "Orbital Nonsense",
    "coffee|goblin": "Happy Hour Overtime",
    "bones|coffee": "Overtime Interns",
    "battery|ice": "Unlicensed Refrigeration",
    "ice|mushroom": "Cold Storage Spores",
    "paper|saucer": "Airborne Tax Office",
    "magnet|torch": "Illegal Power Station",
    "grease|ice": "Black Ice",
    "hammer|saucer": "The Flying Brick",
    "battery|hive": "The Sting Grid"
}

const SOLO_EFFECTS := {
    "goblin": "Throws bottles and irritates the nearest enemy.",
    "chicken": "Wanders, pecks enemies and occasionally launches eggs.",
    "torch": "Burns nearby foes with a flame bolt and a persistent fire patch.",
    "hive": "Dispatches independent seeking bees.",
    "saucer": "Fires ricocheting metal discs.",
    "ghost": "Haunts targets with spectral blasts.",
    "venom": "Leaks persistent toxic puddles.",
    "mushroom": "Grows spreading clouds of spores.",
    "board": "Raises a brief shield and knocks nearby enemies back.",
    "battery": "Chains lightning between nearby targets.",
    "grease": "Spills slick patches that can catch fire.",
    "bones": "Raises temporary skeleton interns.",
    "paper": "Stuns foes and occasionally collects fines.",
    "boots": "Gives the hero a temporary speed boost.",
    "hammer": "Calls down a telegraphed rockfall with area damage and knockback.",
    "coffee": "Temporarily increases the hero's attack speed.",
    "bandage": "Periodically heals a little damage.",
    "magnet": "Pulls enemies into a dangerous cluster.",
    "mirror": "Fires a weaker duplicate of its attack.",
    "ice": "Freezes nearby enemies and leaves icy fields."
}

var parts: Dictionary = {}

func _init() -> void:
    var file := FileAccess.open(DATA_PATH, FileAccess.READ)
    if file == null:
        push_error("Missing component data: " + DATA_PATH)
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        parts = parsed

func resolve(input_ids: Array) -> Dictionary:
    var ids: Array[String] = []
    for value in input_ids:
        var id := str(value)
        if parts.has(id) and not ids.has(id):
            ids.append(id)
    ids.sort()
    if ids.is_empty():
        return {}
    var actors: Array = []
    for id in ids:
        actors.append(parts[id])
    var best_score := -99999
    var rider := ""
    var mount := ""
    var best_key := ""
    for r in ids:
        if int(parts[r].get("rider", 0)) <= 0:
            continue
        for m in ids:
            if m == r or int(parts[m].get("mount", 0)) <= 0:
                continue
            var score := int(parts[r].get("rider", 0)) * 8 + int(parts[m].get("mount", 0)) * 5
            if m == "saucer":
                score += 1
            var pair_key := r + "|" + m
            if score > best_score or (score == best_score and (best_key == "" or pair_key < best_key)):
                best_score = score
                best_key = pair_key
                rider = r
                mount = m
    var host := mount
    if host == "":
        for possible in HOST_ORDER:
            if ids.has(possible):
                host = possible
                break
    var mods := {
        "fire": ids.has("torch"), "poison": ids.has("venom"), "ghost": ids.has("ghost"),
        "spores": ids.has("mushroom"), "bees": ids.has("hive"), "electric": ids.has("battery"),
        "grease": ids.has("grease"), "bones": ids.has("bones"), "paper": ids.has("paper"),
        "boots": ids.has("boots"), "heavy": ids.has("hammer"), "armor": ids.has("board"),
        "coffee": ids.has("coffee"), "healing": ids.has("bandage"), "magnet": ids.has("magnet"),
        "mirror": ids.has("mirror"), "ice": ids.has("ice")
    }
    var sidekick := ids.has("chicken") and host != "chicken" and rider != "chicken"
    var mode := "pylon"
    match host:
        "chicken": mode = "wander"
        "goblin": mode = "stagger"
        "saucer": mode = "ricochet"
        "hive": mode = "stationary-hive"
        "mushroom": mode = "growing-fungus"
        "ghost": mode = "haunt"
        "bones": mode = "necromancy"
        "magnet": mode = "magnetic-field"
        "battery": mode = "tesla-coil"
        "ice": mode = "frost"
    var rules: Array[String] = []
    if rider != "":
        rules.append(parts[rider]["name"] + " RIDES " + parts[mount]["name"])
    else:
        rules.append(parts[host]["name"] + " is the HOST")
    for id in ids:
        if id != host and id != rider:
            rules.append(parts[host]["name"] + " CARRIES " + parts[id]["name"])
    if mods.bees:
        rules.append("EMITS: seeking bees")
    if mods.spores:
        rules.append("EMITS: spreading spores")
    if mods.ghost:
        rules.append("EMITS: passing spirits")
    if mods.fire:
        rules.append("MODIFIES: moving fire")
    if mods.poison:
        rules.append("MODIFIES: persistent poison")
    if sidekick:
        rules.append("ASSISTS: chicken companion")
    if mods.electric: rules.append("ELECTRIFIES: branching lightning arcs")
    if mods.ice: rules.append("FREEZES: spreading ice fields")
    if mods.grease: rules.append("SPILLS: flammable slippery patches")
    if mods.bones: rules.append("RAISES: short-lived skeleton interns")
    if mods.magnet: rules.append("PULLS: enemies into clusters")
    if mods.healing: rules.append("PATCHES: limited healing")
    if mods.paper: rules.append("AUDITS: stuns and fines")
    if mods.heavy: rules.append("BONKS: impact knockback")
    if mods.armor: rules.append("GUARDS: defensive ward")
    if mods.boots: rules.append("ACCELERATES: moving inventions")
    if mods.coffee: rules.append("OVERCLOCKS: faster activations")
    if mods.mirror: rules.append("DUPLICATES: weakened echoes")
    var key := "|".join(PackedStringArray(ids))
    var title := str(SPECIAL.get(key, ""))
    if title == "":
        var prefix := ""
        if mods.fire: prefix = "Flaming "
        elif mods.electric: prefix = "Electrified "
        elif mods.ice: prefix = "Frozen "
        elif mods.bones: prefix = "Undead "
        elif mods.magnet: prefix = "Magnetic "
        elif mods.poison: prefix = "Toxic "
        elif mods.ghost: prefix = "Haunted "
        elif mods.spores: prefix = "Fungal "
        elif mods.bees: prefix = "Buzzing "
        title = prefix + parts[host]["name"] + " Apparatus"
        if rider != "":
            title = prefix + parts[rider]["name"] + " on " + parts[host]["name"]
    if ids.size() == 1:
        title = str(parts[host]["name"])
    var solo_effect: String = str(SOLO_EFFECTS.get(ids[0], "")) if ids.size() == 1 else ""
    var weakness := "Exposed rider / awkward steering" if rider != "" else "Short reach and fragile attachments"
    if mods.bees: weakness = "Fragile swarms; limited lifetime"
    elif mods.grease and mods.fire: weakness = "Flammable accidents; unpredictable area"
    elif mods.ice: weakness = "Slow activations; fragile frost"
    elif mods.bones: weakness = "Interns have short contracts"
    elif mods.fire: weakness = "Overheats; attracts attention"
    elif mods.poison: weakness = "Slow damage, decaying pools"
    return {"key":key, "ids":ids, "title":title, "host":host, "rider":rider, "mount":mount, "mode":mode, "mods":mods, "sidekick":sidekick, "rules":rules, "weakness":weakness, "solo_effect":solo_effect}
