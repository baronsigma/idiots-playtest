extends SceneTree
## Every component is meaningful when alone, not only when a carrier is attached.
const GrammarScript = preload("res://scripts/grammar.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("SOLO: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var grammar = GrammarScript.new()
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    var world = game.world
    var checked := 0
    for part_id in grammar.parts.keys():
        var id: String = str(part_id)
        var recipe: Dictionary = grammar.resolve([id])
        check(recipe.get("ids",[]).size()==1,"Missing solo recipe for "+id)
        check(recipe.get("title","")==grammar.parts[id].name,"Solo title must name its item: "+id)
        check(str(recipe.get("solo_effect",""))!="","No standalone effect description for "+id)
        world.start("jimothy")
        world.set_inventions([recipe])
        check(world.actors.size()==1,"No solo actor for "+id)
        if world.actors.size()==0:
            continue
        world.actors[0].pos=Vector2(300,300)
        world.actors[0].cooldown=0.0
        for enemy in world.enemies:
            enemy.pos=Vector2(780,585)
        world.enemies[0].pos=Vector2(319,305)
        world._update_actors(0.04)
        check(int(world.actors[0].casts)==1,"No activation for "+id)
        checked += 1

    # Big Rock falls on a target, makes an area impact, and causes real damage.
    world.start("jimothy")
    world.set_inventions([grammar.resolve(["hammer"])])
    world.actors[0].pos=Vector2(300,300)
    world.actors[0].cooldown=0.0
    for enemy in world.enemies:
        enemy.pos=Vector2(780,585)
    world.enemies[0].pos=Vector2(319,305)
    var hp_before: float = float(world.enemies[0].hp)
    world._update_actors(0.04)
    check(world.rockfalls.size()==1,"Standalone Big Rock did not schedule an impact")
    world._update_rockfalls(0.55)
    check(world.rockfalls.is_empty(),"Rockfall did not land")
    check(float(world.enemies[0].hp)<hp_before,"Rockfall dealt no damage")

    world.start("jimothy")
    world.set_inventions([grammar.resolve(["torch"])])
    world.actors[0].pos=Vector2(300,300)
    world.actors[0].cooldown=0.0
    world._update_actors(0.04)
    check(world.projectiles.any(func(p): return p.kind=="fire"),"Standalone Torch fired no flames")
    check(world.hazards.any(func(h): return h.kind=="fire"),"Standalone Torch created no burning area")

    world.start("jimothy")
    world.set_inventions([grammar.resolve(["hammer","torch"])])
    world.actors[0].pos=Vector2(300,300)
    world.actors[0].cooldown=0.0
    world._update_actors(0.04)
    check(world.rockfalls.size()>0 and world.rockfalls[0].kind=="fire",
        "Big Rock + Torch must create a fiery rockfall")

    for key in ["boots","coffee","board"]:
        world.start("jimothy")
        world.set_inventions([grammar.resolve([key])])
        world.actors[0].cooldown=0.0
        world._update_actors(0.04)
        if key=="boots":
            check(world.speed_boost>0.0,"Solo Boots do not speed up the hero")
        elif key=="coffee":
            check(world.coffee_boost>0.0,"Solo Coffee does not speed up attacks")
        else:
            check(world.hero_ward>0.0,"Solo Plank does not protect the hero")

    print("IDIOTS SOLO CHECK: ", "PASS" if failures==0 else "FAIL",
        " — ", checked," solo activations; failures=",failures)
    game.queue_free()
    quit(0 if failures==0 else 1)
