extends RefCounted
## Deterministic, engine-independent combination resolver.
## The selected SET of components determines the result, NOT input order.
const DATA_PATH := "res://data/parts.json"
const HOST_ORDER := ["chicken", "goblin", "saucer", "hive", "mushroom", "ghost", "torch", "venom"]
const SPECIAL := {
    "chicken|goblin": "DUI: Poultry Edition",
    "chicken|torch": "The Roast Runner",
    "hive|torch": "Spicy Air Force",
    "chicken|saucer": "Poultry Discus",
    "hive|saucer": "BEE-52 Bomber",
    "ghost|goblin": "Haunted Happy Hour",
    "chicken|goblin|hive|torch": "The Department of Flaming Poultry",
    "chicken|hive|saucer|torch": "The Flying Fried Chicken"
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
    var mods := {"fire": ids.has("torch"), "poison": ids.has("venom"), "ghost": ids.has("ghost"), "spores": ids.has("mushroom"), "bees": ids.has("hive")}
    var sidekick := ids.has("chicken") and host != "chicken" and rider != "chicken"
    var mode := "pylon"
    match host:
        "chicken": mode = "wander"
        "goblin": mode = "stagger"
        "saucer": mode = "ricochet"
        "hive": mode = "stationary-hive"
        "mushroom": mode = "growing-fungus"
        "ghost": mode = "haunt"
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
    var key := "|".join(PackedStringArray(ids))
    var title := str(SPECIAL.get(key, ""))
    if title == "":
        var prefix := ""
        if mods.fire: prefix = "Flaming "
        elif mods.poison: prefix = "Toxic "
        elif mods.ghost: prefix = "Haunted "
        elif mods.spores: prefix = "Fungal "
        elif mods.bees: prefix = "Buzzing "
        title = prefix + parts[host]["name"] + " Apparatus"
        if rider != "":
            title = prefix + parts[rider]["name"] + " on " + parts[host]["name"]
    var weakness := "Exposed rider / awkward steering" if rider != "" else "Short reach and fragile attachments"
    if mods.bees: weakness = "Fragile swarms; limited lifetime"
    elif mods.fire: weakness = "Overheats; attracts attention"
    elif mods.poison: weakness = "Slow damage, decaying pools"
    return {"key":key, "ids":ids, "title":title, "host":host, "rider":rider, "mount":mount, "mode":mode, "mods":mods, "sidekick":sidekick, "rules":rules, "weakness":weakness}
