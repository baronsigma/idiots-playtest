extends Node2D
## IDIOTS! – Godot migration, alpha.2. A larger, accessible HUD over the same
## persistent battle simulation. The deterministic grammar is unchanged.
const GrammarScript = preload("res://scripts/grammar.gd")
const BOARD_LINKS := [[0,1],[1,2],[3,4],[4,5],[0,3],[1,4],[2,5]]
const PART_IDS := ["goblin","chicken","torch","hive","saucer","ghost","venom","mushroom"]
const BASE_SIZE := Vector2(1152.0,648.0)
const INK := Color("#f1e7d0")
const GOLD := Color("#e8bb70")
const MUTED := Color("#b1c3c8")
const GREEN := Color("#98dca6")
const FIRE := Color("#df9567")
const PANEL := Color("#172331")

@onready var world = $Battlefield
@onready var canvas: CanvasLayer = $HUD
var grammar
var ui_root: Control
var hero_menu: Control
var start_overlay: ColorRect
var hp_bar: ProgressBar
var concern_bar: ProgressBar
var title_label: Label
var hp_label: Label
var stats_label: Label
var stage_label: Label
var info_label: Label
var message_label: Label
var selection_label: Label
var recipe_title: Label
var recipe_details: Label
var difficulty_label: Label
var slot_buttons: Array = []
var slot_icons: Array = []
var slot_names: Array = []
var link_buttons: Array = []
var inventory_buttons: Dictionary = {}
var slot_ids: Array = ["goblin","chicken","torch","hive","",""]
var wires: Array = [true,true,false,false,true,false,false]
var chosen := ""
var hero_id := "jimothy"
var running := false
var toast_seconds := 0.0
var refresh_elapsed := 0.0
var latest_recipes: Array = []
var owned_parts: Array = ["goblin", "chicken", "torch", "hive"]
var reward_overlay: Control
var reward_heading: Label
var reward_note: Label
var reward_buttons: Array = []
var reward_descriptions: Array = []
var reward_options: Array = []
var reward_mode := ""
var meta_label: Label
var meta: Dictionary = {"renown": 0, "wins": 0, "hp": 0, "purse": 0}
const META_PATH := "user://idiots_godot_alpha_meta.json"

func _ready() -> void:
    grammar = GrammarScript.new()
    _load_meta()
    ui_root = Control.new()
    ui_root.name = "IdiotHUD"
    ui_root.size = BASE_SIZE
    canvas.add_child(ui_root)
    _build_hud()
    _build_engineering()
    _build_menu()
    _build_reward_overlay()
    world.discovery_due.connect(_offer_discovery)
    world.evolution_due.connect(_offer_evolution)
    world.updated.connect(_refresh_stats)
    world.finished.connect(_finished)
    world.notice.connect(_toast)
    get_viewport().size_changed.connect(_fit_canvas)
    _fit_canvas()
    _refresh_board()
    _refresh_stats()
    _refresh_meta()

func _fit_canvas() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    var scale_amount: float = maxf(0.25,minf(viewport_size.x/BASE_SIZE.x,viewport_size.y/BASE_SIZE.y))
    var offset: Vector2 = (viewport_size - BASE_SIZE*scale_amount)*0.5
    world.scale = Vector2.ONE*scale_amount
    world.position = offset
    ui_root.scale = Vector2.ONE*scale_amount
    ui_root.position = offset

func _rect(parent: Control, at: Vector2, dimensions: Vector2, color: Color, intercept: bool = false) -> ColorRect:
    var r := ColorRect.new()
    r.position = at
    r.size = dimensions
    r.color = color
    r.mouse_filter = Control.MOUSE_FILTER_STOP if intercept else Control.MOUSE_FILTER_IGNORE
    parent.add_child(r)
    return r

func _text(parent: Control, words: String, at: Vector2, font_size: int = 16, color: Color = INK, width: float = 290.0, height: float = 32.0) -> Label:
    var l := Label.new()
    l.position = at
    l.size = Vector2(width,height)
    l.text = words
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func _button(parent: Control, words: String, at: Vector2, dimensions: Vector2, callback: Callable, prominent: bool=false) -> Button:
    var b := Button.new()
    b.position = at
    b.size = dimensions
    b.text = words
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size",16 if prominent else 14)
    b.add_theme_color_override("font_color",INK)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#4c675a") if prominent else Color("#293a4a")
    style.border_color = Color("#9cca9d") if prominent else Color("#647b8e")
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    b.add_theme_stylebox_override("normal",style)
    var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#678b75") if prominent else Color("#405972")
    b.add_theme_stylebox_override("hover",hover)
    var pressed: StyleBoxFlat = style.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#81925a")
    b.add_theme_stylebox_override("pressed",pressed)
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    parent.add_child(b)
    b.pressed.connect(callback)
    return b

func _sprite(parent: Control, id: String, at: Vector2, dimensions: Vector2) -> TextureRect:
    var tex := TextureRect.new()
    tex.position = at
    tex.size = dimensions
    tex.texture = load("res://assets/sprites/"+id+".png")
    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(tex)
    return tex

func _meter(parent: Control, at: Vector2, dimensions: Vector2, foreground: Color) -> ProgressBar:
    var p := ProgressBar.new()
    p.position = at
    p.size = dimensions
    p.show_percentage = false
    p.min_value = 0.0
    p.max_value = 100.0
    p.value = 100.0
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#0d151f")
    bg.set_border_width_all(1)
    bg.border_color = Color("#526071")
    var fg := StyleBoxFlat.new()
    fg.bg_color = foreground
    p.add_theme_stylebox_override("background",bg)
    p.add_theme_stylebox_override("fill",fg)
    parent.add_child(p)
    return p

func _build_hud() -> void:
    _rect(ui_root,Vector2.ZERO,Vector2(827,93),Color("#182331"))
    _rect(ui_root,Vector2(823,0),Vector2(329,648),Color("#14212d"))
    _rect(ui_root,Vector2(822,0),Vector2(3,648),Color("#9c815a"))
    title_label = _text(ui_root,"IDIOTS!",Vector2(20,9),30,GOLD,218,42)
    _text(ui_root,"EARLY ALPHA  ·  GODOT",Vector2(20,49),11,MUTED,205)
    hp_label = _text(ui_root,"HP",Vector2(244,10),14,INK,286)
    hp_bar = _meter(ui_root,Vector2(244,38),Vector2(285,17),Color("#d56564"))
    _text(ui_root,"CONCERN",Vector2(553,10),12,GOLD,175)
    concern_bar = _meter(ui_root,Vector2(552,38),Vector2(249,13),Color("#d59d52"))
    stats_label = _text(ui_root,"",Vector2(244,63),14,MUTED,555)
    stage_label = _text(ui_root,"",Vector2(20,103),16,GOLD,575)
    info_label = _text(ui_root,"",Vector2(22,589),13,MUTED,770)
    message_label = _text(ui_root,"",Vector2(21,561),16,GOLD,782)
    _button(ui_root,"+ FIELD KIT  [F]",Vector2(20,614),Vector2(182,32),_heal,true)
    _button(ui_root,"PAUSE  [SPACE]",Vector2(210,614),Vector2(178,32),_pause)
    _button(ui_root,"FULLSCREEN [F11]",Vector2(396,614),Vector2(190,32),_fullscreen)
    _button(ui_root,"RESTART",Vector2(594,614),Vector2(112,32),_restart)
    _text(ui_root,"IDIOT ENGINEERING",Vector2(839,10),23,GOLD,299,31)
    _text(ui_root,"Build something regrettable. Change it live.",Vector2(840,44),12,MUTED,310)
    _rect(ui_root,Vector2(834,87),Vector2(308,3),Color("#846b50"))
    _text(ui_root,"6 PARTS  ·  CONNECT THE WIRES",Vector2(843,100),13,INK,300)

func _build_engineering() -> void:
    var xs := [845.0,946.0,1047.0]
    var ys := [129.0,232.0]
    for i in range(6):
        var b := _button(ui_root,"",Vector2(xs[i%3],ys[int(i/3)]),Vector2(88,91),_slot_clicked.bind(i))
        slot_buttons.append(b)
        slot_icons.append(_sprite(b,"chicken",Vector2(23,8),Vector2(43,48)))
        var caption := _text(b,"EMPTY",Vector2(3,64),12,INK,82,18)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        slot_names.append(caption)
    for i in range(BOARD_LINKS.size()):
        var a: int = int(BOARD_LINKS[i][0])
        var b: int = int(BOARD_LINKS[i][1])
        var mid: Vector2 = (slot_buttons[a].position+slot_buttons[a].size*0.5 + slot_buttons[b].position+slot_buttons[b].size*0.5)*0.5
        var wire := _button(ui_root,"",mid-Vector2(15,11),Vector2(30,24),_wire_clicked.bind(i))
        link_buttons.append(wire)
    _text(ui_root,"ACTIVE INVENTIONS",Vector2(843,336),15,GOLD,292)
    _rect(ui_root,Vector2(839,365),Vector2(302,92),Color("#263443"))
    recipe_title = _text(ui_root,"No invention",Vector2(847,370),15,INK,285,23)
    recipe_details = _text(ui_root,"Connect parts to create a machine.",Vector2(847,395),12,MUTED,285,56)
    recipe_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _text(ui_root,"SPARE PARTS  ·  SELECT THEN PLACE",Vector2(843,465),13,GOLD,300)
    for i in range(PART_IDS.size()):
        var id: String = PART_IDS[i]
        var label_name: String = str(grammar.parts[id].get("name",id))
        var tile: Button = _button(ui_root,"",Vector2(841+int(i%2)*151,490+int(i/2)*35),Vector2(145,33),_part_clicked.bind(id))
        var icon_node := _sprite(tile,id,Vector2(4,3),Vector2(26,27))
        icon_node.name = "PartSprite"
        _text(tile,label_name.substr(0,15),Vector2(35,3),12,INK,110,26)
        inventory_buttons[id]=tile
    selection_label = _text(ui_root,"Choose a part, then an empty slot",Vector2(843,634),11,MUTED,308)

func _build_menu() -> void:
    start_overlay = _rect(ui_root,Vector2.ZERO,BASE_SIZE,Color(0.03,0.06,0.09,0.98),true)
    hero_menu = Control.new()
    hero_menu.size = BASE_SIZE
    ui_root.add_child(hero_menu)
    _text(hero_menu,"IDIOTS!",Vector2(345,32),64,GOLD,520,85)
    _text(hero_menu,"A village disaster in progress.",Vector2(376,112),20,MUTED,480)
    _text(hero_menu,"CHOOSE YOUR IDIOT",Vector2(435,172),19,INK,340)
    var heroes := ["jimothy","kram","bog"]
    var blurbs := ["Went on a hike once. It was a Tuesday.","Found a slightly magical twig. Pew pew.","Don't you dare make fun of his helmet!"]
    for i in range(3):
        var x: float = 112.0+float(i)*317.0
        _rect(hero_menu,Vector2(x,230),Vector2(300,245),Color("#1e3040"))
        _sprite(hero_menu,heroes[i],Vector2(x+97,246),Vector2(106,118))
        _text(hero_menu,heroes[i].to_upper(),Vector2(x+20,365),23,GOLD,255)
        var blurb: Label = _text(hero_menu,blurbs[i],Vector2(x+20,396),13,MUTED,265,36)
        blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _button(hero_menu,"PLAY AS "+heroes[i].to_upper(),Vector2(x+18,439),Vector2(265,35),_select_hero.bind(heroes[i]),true)
    _text(hero_menu,"Continuous combat  ·  Procedural inventions  ·  Very poor decisions",Vector2(228,526),16,INK,735)
    meta_label = _text(hero_menu,"",Vector2(330,555),15,GOLD,580)
    _button(hero_menu,"RENOWN: +10 HP",Vector2(331,594),Vector2(222,37),_buy_meta.bind("hp"))
    _button(hero_menu,"RENOWN: +8 GOLD",Vector2(566,594),Vector2(222,37),_buy_meta.bind("purse"))

func _select_hero(id: String) -> void:
    hero_menu.visible = false
    start_overlay.visible = false
    hero_id = id
    running = true
    owned_parts = ["goblin", "chicken", "torch", "hive"]
    slot_ids = ["goblin", "chicken", "torch", "hive", "", ""]
    wires = [true, true, false, false, true, false, false]
    world.start(id, int(meta.get("hp", 0)) * 10, int(meta.get("purse", 0)) * 8)
    _refresh_board()
    _toast("You're now responsible for several objects. Terrible news.")

func _finished(won: bool) -> void:
    running = false
    reward_overlay.visible = false
    var earned := (12 if won else 2) + mini(int(world.kills / 20), 8)
    meta["renown"] = int(meta.get("renown", 0)) + earned
    if won:
        meta["wins"] = int(meta.get("wins", 0)) + 1
    _save_meta()
    _refresh_meta()
    hero_menu.visible = true
    start_overlay.visible = true
    _toast(("THE MAYOR FELL." if won else "YOUR IDIOT FELL.") + " +" + str(earned) + " RENOWN.")

func _restart() -> void:
    if running:
        reward_overlay.visible = false
        owned_parts = ["goblin", "chicken", "torch", "hive"]
        slot_ids = ["goblin", "chicken", "torch", "hive", "", ""]
        wires = [true, true, false, false, true, false, false]
        world.start(hero_id, int(meta.get("hp", 0)) * 10, int(meta.get("purse", 0)) * 8)
        _refresh_board()
    else:
        hero_menu.visible = true
        start_overlay.visible = true

func _part_clicked(id: String) -> void:
    if not owned_parts.has(id):
        selection_label.text = "Not discovered yet: " + str(grammar.parts[id].name)
        return
    chosen=id
    selection_label.text="Selected: "+str(grammar.parts[id].name)+"  →  select a board slot"
    _refresh_board()

func _slot_clicked(index: int) -> void:
    if chosen == "":
        if slot_ids[index] != "":
            var id: String = str(slot_ids[index])
            selection_label.text=str(grammar.parts[id].name)+"  ·  "+", ".join(PackedStringArray(grammar.parts[id].get("tags",[])))
        return
    if slot_ids[index] == chosen:
        slot_ids[index]=""
    else:
        var existing: int = slot_ids.find(chosen)
        if existing >= 0:
            var previous: String = str(slot_ids[index])
            slot_ids[index] = chosen
            slot_ids[existing] = previous
        else:
            slot_ids[index] = chosen
    chosen=""
    _refresh_board()

func _wire_clicked(i: int) -> void:
    wires[i] = not bool(wires[i])
    _refresh_board()

func _recipes() -> Array:
    var seen: Dictionary = {}
    var result: Array = []
    for start in range(6):
        if slot_ids[start]=="" or seen.has(start):continue
        var queue: Array = [start]
        var collected: Array = []
        seen[start]=true
        while not queue.is_empty():
            var node: int = int(queue.pop_back())
            collected.append(node)
            for k in range(BOARD_LINKS.size()):
                if not bool(wires[k]):continue
                var left: int = int(BOARD_LINKS[k][0])
                var right: int = int(BOARD_LINKS[k][1])
                var next := -1
                if left==node:next=right
                elif right==node:next=left
                if next>=0 and slot_ids[next]!="" and not seen.has(next):
                    seen[next]=true
                    queue.append(next)
        var ids: Array=[]
        for idx in collected:
            ids.append(slot_ids[int(idx)])
        var recipe: Dictionary=grammar.resolve(ids)
        if not recipe.is_empty():result.append(recipe)
    return result

func _refresh_board() -> void:
    for i in range(6):
        var id: String = str(slot_ids[i])
        slot_icons[i].visible = id!=""
        slot_icons[i].texture=load("res://assets/sprites/"+id+".png") if id!="" else null
        slot_names[i].text=str(grammar.parts[id].name).substr(0,10).to_upper() if id!="" else "+ EMPTY"
        slot_buttons[i].modulate=GOLD if id==chosen and chosen!="" else Color.WHITE
    for i in range(wires.size()):
        link_buttons[i].text = "●" if bool(wires[i]) else "×"
        link_buttons[i].modulate = GREEN if bool(wires[i]) else Color("#bc8393")
    for id in PART_IDS:
        inventory_buttons[id].disabled = not owned_parts.has(id)
        inventory_buttons[id].modulate = GOLD if id==chosen else Color.WHITE
    latest_recipes=_recipes()
    world.set_inventions(latest_recipes)
    if latest_recipes.is_empty():
        recipe_title.text="No contraptions yet"
        recipe_details.text="Place two parts and connect them.\nClick wires to split machines."
    else:
        var first: Dictionary=latest_recipes[0]
        recipe_title.text=str(first.title).to_upper()
        recipe_details.text="HOST: "+str(first.host).to_upper()+"  •  "+str(first.mode).to_upper()+"\nWEAKNESS: "+str(first.weakness)
        if latest_recipes.size()>1:
            recipe_details.text += "\n+"+str(latest_recipes.size()-1)+" independent invention(s)"
    selection_label.text="Select a part, then place it.  "+str(latest_recipes.size())+" active circuits."

func _heal() -> void:
    world.use_field_kit()

func _pause() -> void:
    if not running:return
    world.paused=not world.paused
    _toast("Paused for irresponsible engineering." if world.paused else "Resume the calamity.")

func _fullscreen() -> void:
    if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    call_deferred("_fit_canvas")

func _toast(s: String) -> void:
    message_label.text=s
    toast_seconds=5.0

func _refresh_stats() -> void:
    var r: Dictionary=world.report()
    hp_bar.max_value=maxf(1.0,float(r.max_hp))
    hp_bar.value=float(r.hp)
    hp_label.text="HP  %d / %d" % [int(r.hp),int(r.max_hp)]
    concern_bar.value=float(r.concern)
    stats_label.text="GOLD %d     KILLS %d     KITS %d" % [int(r.gold),int(r.kills),int(r.kits)]
    stage_label.text="THE VILLAGE INCIDENT  /  "+str(r.stage)+"   •   %02d:%02d" % [int(float(r.time)/60.0),int(r.time)%60]
    info_label.text="ENEMIES %d    •    ACTIVE INVENTIONS %d    •    LOCAL CONCERN %d%%" % [int(r.enemies),int(r.actors),int(r.concern)]

func _process(delta: float) -> void:
    refresh_elapsed += delta
    if refresh_elapsed>=0.2:
        refresh_elapsed=0.0
        _refresh_stats()
    if toast_seconds>0.0:
        toast_seconds -= delta
        if toast_seconds<=0.0:message_label.text=""


func _load_meta() -> void:
    if not FileAccess.file_exists(META_PATH):
        return
    var file := FileAccess.open(META_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for key in ["renown", "wins", "hp", "purse"]:
            meta[key] = maxi(0, int(parsed.get(key, 0)))
        meta["hp"] = mini(5, int(meta["hp"]))
        meta["purse"] = mini(5, int(meta["purse"]))

func _save_meta() -> void:
    var file := FileAccess.open(META_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(meta))

func _refresh_meta() -> void:
    if meta_label == null:
        return
    meta_label.text = "RENOWN %d   •   WINS %d   •   HEALTH %d/5   •   PURSE %d/5" % [
        int(meta["renown"]), int(meta["wins"]), int(meta["hp"]), int(meta["purse"])
    ]

func _buy_meta(kind: String) -> void:
    if running:
        return
    var level := int(meta.get(kind, 0))
    var cost := 4 + level * 5
    if level >= 5 or int(meta["renown"]) < cost:
        _toast("Not enough Renown, or that upgrade is capped.")
        return
    meta["renown"] = int(meta["renown"]) - cost
    meta[kind] = level + 1
    _save_meta()
    _refresh_meta()
    _toast("A lasting improvement. The villagers remain concerned.")

func _build_reward_overlay() -> void:
    reward_overlay = Control.new()
    reward_overlay.position = Vector2(17, 100)
    reward_overlay.size = Vector2(793, 505)
    reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    ui_root.add_child(reward_overlay)
    _rect(reward_overlay, Vector2.ZERO, reward_overlay.size, Color("#101b28"), true)
    _rect(reward_overlay, Vector2(19, 18), Vector2(754, 4), GOLD)
    reward_heading = _text(reward_overlay, "DISCOVERY", Vector2(34, 39), 27, GOLD, 730, 46)
    reward_note = _text(reward_overlay, "", Vector2(34, 95), 15, MUTED, 735, 66)
    reward_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for i in range(3):
        var x := 37.0 + i * 246.0
        var b := _button(reward_overlay, "", Vector2(x, 182), Vector2(226, 66), _select_reward.bind(i), true)
        reward_buttons.append(b)
        var label := _text(reward_overlay, "", Vector2(x + 6, 264), 14, INK, 213, 120)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        reward_descriptions.append(label)
    _text(reward_overlay, "No purchase required. Your idiot found this lying around.", Vector2(35, 437), 13, MUTED, 730)
    reward_overlay.visible = false

func _show_rewards(title: String, note: String, options: Array, mode: String) -> void:
    reward_mode = mode
    reward_options = options
    reward_heading.text = title
    reward_note.text = note
    for i in range(3):
        reward_buttons[i].visible = i < options.size()
        reward_descriptions[i].visible = i < options.size()
        if i < options.size():
            reward_buttons[i].text = str(options[i].get("label", "???"))
            reward_descriptions[i].text = str(options[i].get("description", ""))
    reward_overlay.visible = true

func _offer_discovery(tier: int) -> void:
    if not running:
        return
    var missing: Array = []
    for id in PART_IDS:
        if not owned_parts.has(id):
            missing.append(id)
    missing.shuffle()
    var options: Array = []
    for i in range(mini(3, missing.size())):
        var id: String = str(missing[i])
        options.append({"id": "part:" + id, "label": str(grammar.parts[id].name).to_upper(),
            "description": "New part • " + ", ".join(PackedStringArray(grammar.parts[id].get("tags", []))) +
            ". Connect it on the live board."})
    var services := [
        {"id": "kit", "label": "FIELD KIT", "description": "+1 limited-use emergency heal."},
        {"id": "heal", "label": "VERY SUSPICIOUS MEDICINE", "description": "Restore 40 HP immediately."},
        {"id": "gold", "label": "UNCLAIMED COINS", "description": "+45 gold. Surprisingly legitimate."}
    ]
    for service in services:
        if options.size() >= 3:
            break
        options.append(service)
    _show_rewards("FOUND SOMETHING QUESTIONABLE", "Discovery %d • pick one; combat resumes afterward." % (tier + 1), options, "loot")

func _offer_evolution(tier: int) -> void:
    if not running:
        return
    var choices: Array = []
    if hero_id == "jimothy":
        choices = [{"id": "wide", "label": "SOUP LADLE", "description": "Wider melee sweep; more crowd control."},
                   {"id": "heated", "label": "HOT SPOON", "description": "Melee attacks start fires."}]
    elif hero_id == "kram":
        choices = [{"id": "split", "label": "FORKED TWIG", "description": "Cast additional branching projectiles."},
                   {"id": "heated", "label": "UNLICENSED EMBERS", "description": "Spells cause lingering burns."}]
    else:
        choices = [{"id": "wide", "label": "PLANK OF AUTHORITY", "description": "Broader, heavier board swings."},
                   {"id": "guard", "label": "BUCKET SUPREMACY", "description": "Incoming hits deal less damage."}]
    _show_rewards("SIGNATURE WEAPON EVOLVES", "Evolution %d of 2 • choose how your idiot becomes more dangerous." % tier, choices, "weapon")

func _select_reward(index: int) -> void:
    if not reward_overlay.visible or index < 0 or index >= reward_options.size():
        return
    var id: String = str(reward_options[index].id)
    if reward_mode == "weapon":
        world.apply_weapon_upgrade(id)
    elif id.begins_with("part:"):
        var part_id := id.substr(5)
        if not owned_parts.has(part_id):
            owned_parts.append(part_id)
        chosen = part_id
        selection_label.text = "New part discovered: " + str(grammar.parts[part_id].name) + ". Place it on the board."
        _refresh_board()
    elif id == "kit":
        world.kits = mini(world.kits + 1, 5)
    elif id == "heal":
        world.hp = minf(world.max_hp, world.hp + 40.0)
    elif id == "gold":
        world.gold += 45
    reward_overlay.visible = false
    world.paused = false
    world.updated.emit()
    _toast("Bad idea acquired. Carry on.")

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:return
    if not event.pressed or event.echo:return
    if event.keycode==KEY_SPACE:_pause()
    elif event.keycode==KEY_F:_heal()
    elif event.keycode==KEY_F11:_fullscreen()
