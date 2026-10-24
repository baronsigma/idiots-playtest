extends SceneTree
## Run with: godot --headless --path . --script res://tests/test_grammar.gd
const GrammarScript = preload("res://scripts/grammar.gd")
var count := 0
var failures := 0

func _initialize() -> void:
    var g = GrammarScript.new()
    var keys := ["goblin","chicken","torch","hive","saucer","ghost","venom","mushroom"]
    for mask in range(1,256):
        var ids: Array = []
        for bit in range(8):
            if mask & (1 << bit):ids.append(keys[bit])
        if ids.size()<2 or ids.size()>4:continue
        var forward: Dictionary = g.resolve(ids)
        var reversed: Array = ids.duplicate()
        reversed.reverse()
        var backwards: Dictionary = g.resolve(reversed)
        var rotated: Array = ids.duplicate()
        rotated.push_back(rotated.pop_front())
        var shifted: Dictionary = g.resolve(rotated)
        count += 1
        if forward.get("key")!=backwards.get("key") or forward.get("key")!=shifted.get("key") or forward.get("rider")!=backwards.get("rider") or forward.get("title")!=backwards.get("title"):
            failures+=1
            push_error("Inconsistent recipe: " + str(ids))
    if g.resolve(["goblin","chicken"]).rider!="goblin":
        failures += 1
        push_error("Drunk Goblin must ride Chicken")
    if g.resolve(["chicken","goblin","torch","hive"]).title!="The Department of Flaming Poultry":
        failures += 1
        push_error("Incorrect 4-part recipe")
    print("IDIOTS grammar checked ",count," configurations. Failures: ",failures)
    quit(0 if failures==0 and count==154 else 1)
