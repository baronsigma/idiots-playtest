extends SceneTree
## Engineering parity regression: all 20 parts, deterministic recipes and combat manifestations.
const GrammarScript = preload("res://scripts/grammar.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func expect(condition: bool, reason: String) -> void:
    if not condition:
        failures += 1
        push_error("ENGINEERING: " + reason)

func _run() -> void:
    var grammar = GrammarScript.new()
    var keys: Array = grammar.parts.keys()
    keys.sort()
    expect(keys.size() == 20, "Expected 20 tagged parts")
    var count := 0
    for left in keys:
        for right in keys:
            if str(left) >= str(right):
                continue
            var recipe: Dictionary = grammar.resolve([left, right])
            var reverse: Dictionary = grammar.resolve([right, left])
            count += 1
            expect(not recipe.is_empty(), "No recipe for " + str(left) + " and " + str(right))
            expect(recipe.get("key") == reverse.get("key") and recipe.get("host") == reverse.get("host") and recipe.get("title") == reverse.get("title"), "Input-order-dependent recipe")
            expect(recipe.has("mods") and recipe.has("rules"), "Recipe missing behavior metadata")
    expect(count == 190, "All unique unordered pairs covered")
    expect(grammar.resolve(["chicken", "goblin"]).get("rider") == "goblin", "Rider priority changed")
    expect(grammar.resolve(["battery", "saucer"]).mods.electric, "Tesla Frisbee missing electricity")
    expect(grammar.resolve(["bandage", "chicken"]).mods.healing, "Emergency Cluck missing healing")
    expect(grammar.resolve(["grease", "torch"]).mods.grease, "Kitchen Catastrophe missing grease")
    expect(grammar.resolve(["ice", "mushroom"]).mods.ice, "Frozen spores missing ice")
    expect(grammar.resolve(["bones", "hive"]).mods.bones, "Necro-Hive missing summon tag")

    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    expect(game.inventory_buttons.size() == 20, "Scrollable inventory does not show full library")
    var world = game.world
    world.start("jimothy")
    var electric: Dictionary = grammar.resolve(["battery", "saucer"])
    world.set_inventions([electric])
    expect(world.actors.size() == 1, "Electric circuit not spawned")
    world.actors[0].pos = Vector2(300, 300)
    world.enemies[0].pos = Vector2(312, 300)
    world.actors[0].cooldown = 0.0
    world._update_actors(0.05)
    expect(world.lightning_arcs.size() > 0, "Electric effect did not draw an arc")
    world._make_hazard(Vector2(310,300),"grease",28.0)
    world._make_hazard(Vector2(305,300),"fire",28.0)
    world._update_hazards(0.1)
    var ignited := false
    for hazard in world.hazards:
        if hazard.kind == "fire" and float(hazard.radius) >= 39.0:
            ignited = true
    expect(ignited, "Grease does not ignite near fire")
    var bones: Dictionary = grammar.resolve(["bones", "coffee"])
    world.set_inventions([bones])
    world.actors[0].pos = Vector2(300, 300)
    world._update_actors(4.0)
    expect(world.skeletons.size() > 0, "Undead allies not raised")
    world.set_inventions([grammar.resolve(["ice", "mushroom"])])
    world.actors[0].pos = Vector2(300, 300)
    world._update_actors(4.0)
    var has_ice := false
    for hazard in world.hazards:
        if hazard.kind == "ice":
            has_ice = true
    expect(has_ice, "Ice inventions do not make freezing fields")
    print("IDIOTS engineering parity: ", "PASS" if failures == 0 else "FAIL", " — ", count, " pairs, ", failures, " failures")
    game.queue_free()
    quit(0 if failures == 0 else 1)
