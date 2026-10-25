extends SceneTree
## v0.0.8-alpha.5 first-90s feel check: measurable pacing, movement, attacks, and effects.
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, why: String) -> void:
    if not condition:
        failures += 1
        push_error("FEEL: " + why)

func _run() -> void:
    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game._select_hero("jimothy")
    var w = game.world
    check(w.enemies.size() == 9, "The opening should start with nine enemies.")
    check(int(w.HEROES["jimothy"].hp) > 200, "Base hero health was not restored.")
    check(w.MAX_ENEMIES >= 40, "Battlefield chaos cap was not raised.")
    # Twenty real-health seconds must have kills and actual movement/attacks.
    for frame in range(500):
        if w.ended:
            break
        w._process(0.04)
    check(w.hero_attack_total >= 3, "Hero did not swing or cast regularly.")
    check(w.enemy_spawn_total >= 17, "Opening was too sparse.")
    check(w.kills >= 1, "No enemies were defeated in the opening.")
    check(w.hp > 0, "Ordinary opening killed Jimothy before the first reward.")
    # Continue at high HP to audit the director, not assert victory or balance.
    w.max_hp = 9999.0
    w.hp = 9999.0
    while w.clock < 90.0 and not w.ended:
        w._process(0.04)
        if w.paused:
            if game.reward_overlay.visible:
                game._select_reward(0)
            else:
                w.paused = false
    check(w.clock >= 89.9, "Simulation stopped before the 90-second marker.")
    check(w.enemy_spawn_total >= 65, "Early director lacks enemy pressure.")
    check(w.max_enemies_observed >= 10, "Fight never filled the stage.")
    check(w.hero_attack_total >= 25, "No sustained attacking.")
    check(w.discovery_index >= 2, "First two discovery moments missing.")
    check(w.hostile_arrow_total >= 1, "Ranged specialists never fired after 45 seconds.")
    check(w.attack_waves.size() <= 10 and w.impact_rings.size() <= 45, "FX population unbounded.")
    print("IDIOTS ALPHA.5 FEEL: ", "PASS" if failures == 0 else "FAIL",
        " • spawned=",w.enemy_spawn_total," • peak=",w.max_enemies_observed,
        " • kills=",w.kills," • attacks=",w.hero_attack_total,
        " • arrows=",w.hostile_arrow_total," • rewards=",w.discovery_index)
    game.queue_free()
    quit(0 if failures == 0 else 1)
