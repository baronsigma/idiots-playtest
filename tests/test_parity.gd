extends SceneTree
## Headless migration smoke test.
## godot --headless --path . --script res://tests/test_parity.gd

var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("PARITY: " + message)

func _run() -> void:
    var main = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    check(main.world != null, "Battlefield exists")
    check(main.reward_overlay != null, "Reward overlay exists")
    main._select_hero("jimothy")
    check(main.running and main.world.active, "Jimothy starts")
    check(main.owned_parts.size() == 4, "Four starting parts")
    check(main.world.actors.size() > 0, "Starting connections create inventions")
    main.world.paused = true
    main.world.discovery_due.emit(0)
    check(main.reward_overlay.visible, "Discovery appears")
    var before: int = int(main.owned_parts.size())
    main._select_reward(0)
    check(main.owned_parts.size() == before + 1, "Part discovery unlocks a part")
    check(not main.reward_overlay.visible and not main.world.paused, "Reward closes and combat resumes")
    main.world.paused = true
    main.world.evolution_due.emit(1)
    check(main.reward_overlay.visible, "Signature choice appears")
    main._select_reward(0)
    check(main.world.weapon_level == 1, "Weapon evolution applies")
    main.slot_ids = ["goblin", "chicken", "torch", "hive", "saucer", "ghost"]
    main.wires = [true, false, true, false, false, false, false]
    check(main._recipes().size() == 4, "Explicit links split independent inventions")
    main._refresh_board()
    main.world.start("bog", 20, 16)
    check(int(main.world.max_hp) == int(main.world.HEROES["bog"].hp) + 20 and main.world.gold == 44, "Meta starter bonus applies")
    main.world.start("kram")
    check(main.world.weapon_level == 0, "Weapon evolution resets on new run")
    check(main.world.discovery_index == 0, "Discovery milestones reset")
    print("IDIOTS Godot parity smoke: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
    main.queue_free()
    quit(0 if failures == 0 else 1)
