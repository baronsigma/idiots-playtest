extends SceneTree
## A scene-import test is insufficient: alpha.5 once shipped with no _draw().
## This regression checks both callback source and actual rendering after combat starts.
var failures := 0

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("BATTLEFIELD RENDER: " + reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var source_file := FileAccess.open("res://scripts/battlefield.gd", FileAccess.READ)
    check(source_file != null, "Battlefield source was not found")
    if source_file == null:
        quit(1)
        return
    var source: String = source_file.get_as_text()
    check(source.contains("func _draw() -> void:"), "Battlefield is missing its draw callback")
    check(source.contains("func _draw() -> void:\n    render_frame_count += 1\n    _environment()"),
        "Battlefield scene must draw the background from _draw, not recurse inside _environment")

    var game = load("res://scenes/Main.tscn").instantiate()
    root.add_child(game)
    game._select_hero("jimothy")
    for i in range(12):
        await process_frame
    check(game.world.clock > 0.0, "Combat simulation did not tick")
    check(game.world.render_frame_count > 0, "Simulation runs but the battlefield is invisible")
    check(game.world.enemies.size() > 0, "Battle scene contains no enemies at startup")
    check(game.world.visible, "Battlefield Node2D is hidden")
    print("IDIOTS RENDER CHECK: ", "PASS" if failures == 0 else "FAIL",
        " draw_frames=", game.world.render_frame_count, " sim_time=", game.world.clock)
    game.queue_free()
    quit(0 if failures == 0 else 1)
