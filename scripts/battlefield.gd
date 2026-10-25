extends Node2D
## Standalone continuous-combat slice. Only stateful simulation lives here.
signal updated
signal finished(victory: bool)
signal notice(message: String)
signal discovery_due(tier: int)
signal evolution_due(tier: int)

const ARENA := Rect2(18.0, 95.0, 799.0, 525.0)
const MAX_ENEMIES := 36
const MAX_BEES := 44
const MAX_HAZARDS := 22
const MAX_PROJECTILES := 70
const TOTAL_TIME := 390.0
const DISCOVERY_TIMES := [32.0, 75.0, 130.0, 192.0, 255.0, 324.0]
const EVOLUTION_TIMES := [98.0, 294.0]
const HEROES := {
    "jimothy": {"name":"Jimothy", "hp":130.0, "speed":103.0, "range":54.0, "damage":15.0},
    "kram": {"name":"Kram", "hp":103.0, "speed":112.0, "range":214.0, "damage":12.0},
    "bog": {"name":"Bog", "hp":163.0, "speed":96.0, "range":57.0, "damage":17.0}
}
var sprites: Dictionary = {}
var rng := RandomNumberGenerator.new()
var active := false
var paused := false
var ended := false
var hero_type := "jimothy"
var hp := 130.0
var max_hp := 130.0
var gold := 28
var concern := 0.0
var kills := 0
var clock := 0.0
var hero_position := Vector2(380, 360)
var hero_cooldown := 0.0
var dash_cooldown := 0.0
var kits := 2
var enemies: Array = []
var actors: Array = []
var projectiles: Array = []
var bees: Array = []
var hazards: Array = []
var sparks: Array = []
var spawn_clock := 0.0
var notice_clock := 0.0
var boss_spawned := false
var discovery_index := 0
var evolution_index := 0
var weapon_level := 0
var weapon_wide := 0
var weapon_guard := 0
var weapon_split := 0
var weapon_heated := 0
var color_fire := Color("#fd8a50")
var color_poison := Color("#7de06f")
var color_ice := Color("#93e2e5")
var color_gold := Color("#f4cf83")

func _ready() -> void:
    rng.randomize()
    for key in ["jimothy","kram","bog","goblin","chicken","rat","taxman","bee","hive","torch","saucer","ghost","venom","mushroom","shot","stone"]:
        sprites[key] = load("res://assets/sprites/" + key + ".png")
    queue_redraw()

func start(hero_id: String, hp_boost: int = 0, gold_boost: int = 0) -> void:
    hero_type = hero_id if HEROES.has(hero_id) else "jimothy"
    hp = float(HEROES[hero_type].hp) + hp_boost
    max_hp = hp
    gold = 28 + gold_boost
    concern = 0.0
    kills = 0
    clock = 0.0
    hero_position = Vector2(380, 355)
    hero_cooldown = 0.0
    dash_cooldown = 2.5
    kits = 2
    enemies.clear()
    projectiles.clear()
    bees.clear()
    hazards.clear()
    sparks.clear()
    actors.clear()
    spawn_clock = 0.0
    boss_spawned = false
    discovery_index = 0
    evolution_index = 0
    weapon_level = 0
    weapon_wide = 0
    weapon_guard = 0
    weapon_split = 0
    weapon_heated = 0
    active = true
    paused = false
    ended = false
    for i in range(5):
        _spawn_enemy(false)
    notice.emit("The village has lodged a formal complaint.")
    updated.emit()

func set_inventions(recipes: Array) -> void:
    var old: Dictionary = {}
    for actor in actors:
        old[actor.key] = actor
    var next: Array = []
    for recipe in recipes:
        if recipe.is_empty():
            continue
        var key: String = str(recipe.key)
        if old.has(key):
            var maintained: Dictionary = old[key]
            maintained["recipe"] = recipe
            next.append(maintained)
        else:
            next.append({"key":key, "recipe":recipe, "pos":hero_position + Vector2(rng.randf_range(-90.0,90.0),rng.randf_range(-64.0,64.0)), "target":Vector2.ZERO, "cooldown":rng.randf_range(0.7,1.6), "wander":0.0, "phase":rng.randf_range(0.0,9.0), "damage":0.0, "casts":0})
    actors = next
    updated.emit()

func apply_weapon_upgrade(kind: String) -> void:
    if not active or weapon_level >= 2:
        return
    weapon_level += 1
    match kind:
        "wide": weapon_wide += 1
        "guard": weapon_guard += 1
        "split": weapon_split += 1
        "heated": weapon_heated += 1
    notice.emit("Weapon evolution %d: %s. This seems legally questionable." % [weapon_level, kind.to_upper()])
    updated.emit()

func use_field_kit() -> void:
    if not active or ended or kits <= 0 or hp >= max_hp - 1.0:
        return
    kits -= 1
    var heal := minf(48.0, max_hp-hp)
    hp += heal
    _spark(hero_position, color_poison, 14)
    notice.emit("Field Kit: +" + str(int(heal)) + " HP. Medical license pending.")
    updated.emit()

func _spawn_enemy(elite: bool, force_boss: bool = false) -> void:
    if enemies.size() >= MAX_ENEMIES:
        return
    var side := rng.randi_range(0,3)
    var pos := Vector2(ARENA.position.x+8, rng.randf_range(ARENA.position.y+28,ARENA.end.y-28))
    if side == 1: pos.x = ARENA.end.x-14
    if side == 2: pos = Vector2(rng.randf_range(ARENA.position.x+20,ARENA.end.x-20),ARENA.position.y+18)
    if side == 3: pos = Vector2(rng.randf_range(ARENA.position.x+20,ARENA.end.x-20),ARENA.end.y-18)
    var boss := force_boss
    var tax := boss or elite or (clock>55.0 and rng.randf()<0.10 + concern*0.0012)
    var archer := not boss and clock>95.0 and concern>20.0 and rng.randf()<0.17
    var sprinter := not boss and clock>60.0 and rng.randf()<0.13
    var toughness := 1.0 + clock / 450.0
    var base_hp := 85.0 if tax else 37.0
    var base_dmg := 12.0 if tax else 5.5
    if boss:
        base_hp = 1250.0
        base_dmg = 24.0
    enemies.append({"pos":pos, "hp":base_hp*toughness, "max_hp":base_hp*toughness, "damage":base_dmg, "speed":(37.0 if tax else 58.0)+(35.0 if sprinter else 0.0)+clock*0.018, "cooldown":rng.randf_range(0.0,0.9), "tax":tax, "boss":boss, "archer":archer, "sprinter":sprinter, "burn":0.0, "poison":0.0, "stun":0.0, "flash":0.0})
    if boss:
        notice.emit("THE MAYOR HAS REQUESTED YOUR IMMEDIATE DISCONTINUATION.")

func _nearest_enemy(point: Vector2) -> int:
    var index := -1
    var dist := 1.0e12
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        var d: float = point.distance_squared_to(enemy.pos)
        if d < dist:
            dist = d
            index = i
    return index

func _hurt_enemy(index: int, damage: float, kind: String = "physical") -> void:
    if index<0 or index>=enemies.size():return
    var e: Dictionary = enemies[index]
    var dealt := damage * (0.82 if e.tax else 1.0)
    e.hp = float(e.hp)-dealt
    e.flash = 0.13
    if kind == "fire":e.burn = maxf(float(e.burn),2.6)
    if kind == "poison":e.poison = maxf(float(e.poison),3.5)
    if kind == "ice":e.stun = maxf(float(e.stun),0.25)
    _spark(e.pos, color_fire if kind=="fire" else color_poison if kind=="poison" else color_gold, 2)
    if e.hp <= 0.0:
        var was_boss: bool = e.boss
        enemies.remove_at(index)
        kills += 1
        gold += 4 if e.tax else 1
        concern = minf(100.0,concern + (0.35 if e.tax else 0.17))
        if was_boss:
            ended = true
            active = false
            finished.emit(true)
        elif kills % 20 == 0:
            notice.emit("Local Concern rises. A very concerned goblin has been dispatched.")
        updated.emit()

func _spark(pos: Vector2, color: Color, count: int) -> void:
    for i in range(count):
        if sparks.size()>110:return
        sparks.append({"pos":pos, "vel":Vector2(rng.randf_range(-75.0,75.0),rng.randf_range(-85.0,45.0)), "life":rng.randf_range(0.15,0.48), "color":color})

func _emit_bees(pos: Vector2, recipe: Dictionary) -> void:
    for i in range(5):
        if bees.size()>=MAX_BEES:return
        bees.append({"pos":pos+Vector2(rng.randf_range(-12.0,12.0),rng.randf_range(-12.0,12.0)), "life":rng.randf_range(4.5,7.0), "cooldown":rng.randf_range(0.1,0.4), "mods":recipe.mods, "phase":rng.randf_range(0.0,6.3)})
    _spark(pos, color_gold, 4)

func _make_hazard(pos: Vector2, kind: String, radius: float = 19.0) -> void:
    if hazards.size()>=MAX_HAZARDS:return
    hazards.append({"pos":pos, "kind":kind, "age":0.0, "life":rng.randf_range(3.5,5.2), "radius":radius, "damage_timer":0.0})

func _projectile(from: Vector2, to: Vector2, kind: String, power: float) -> void:
    if projectiles.size()>=MAX_PROJECTILES:return
    var direction := (to-from).normalized()
    projectiles.append({"pos":from, "vel":direction * (270.0 if kind=="saucer" else 240.0), "kind":kind, "damage":power, "life":2.5, "hits":0})

func _process(delta: float) -> void:
    if not active or paused or ended:
        return
    var dt := minf(delta,0.045)
    clock += dt
    concern = minf(100.0, concern + dt * (0.035 + clock*0.0007))
    _update_hero(dt)
    _update_enemies(dt)
    _update_actors(dt)
    _update_projectiles(dt)
    _update_bees(dt)
    _update_hazards(dt)
    if ended:
        queue_redraw()
        return
    if discovery_index < DISCOVERY_TIMES.size() and clock >= float(DISCOVERY_TIMES[discovery_index]):
        var due := discovery_index
        discovery_index += 1
        paused = true
        discovery_due.emit(due)
    elif evolution_index < EVOLUTION_TIMES.size() and clock >= float(EVOLUTION_TIMES[evolution_index]):
        var tier := evolution_index + 1
        evolution_index += 1
        paused = true
        evolution_due.emit(tier)
    for i in range(sparks.size()-1,-1,-1):
        var s: Dictionary = sparks[i]
        s.life = float(s.life)-dt
        s.pos += s.vel * dt
        if s.life<=0.0:sparks.remove_at(i)
    if not boss_spawned and clock>TOTAL_TIME-28.0:
        boss_spawned = true
        _spawn_enemy(true,true)
    if clock<TOTAL_TIME-12.0:
        spawn_clock -= dt
        if spawn_clock<=0.0:
            spawn_clock = maxf(0.62, 2.3 - clock*0.003 - concern*0.006)
            _spawn_enemy(rng.randf() < 0.06 + concern*0.003)
            if concern>68.0 and rng.randf()<0.16:
                _spawn_enemy(true)
    if clock>TOTAL_TIME+46.0 and boss_spawned and not ended:
        ended = true
        active = false
        finished.emit(false)
    queue_redraw()

func _update_hero(dt: float) -> void:
    dash_cooldown -= dt
    hero_cooldown -= dt
    var nearest := _nearest_enemy(hero_position)
    if nearest<0:return
    var e: Dictionary = enemies[nearest]
    var delta_pos: Vector2 = e.pos-hero_position
    var dist := delta_pos.length()
    var ideal_range: float = HEROES[hero_type].range
    var speed: float = HEROES[hero_type].speed
    if hero_type == "kram" and dist < 100.0:
        hero_position -= delta_pos.normalized()*speed*dt
    elif dist>ideal_range*0.75:
        hero_position += delta_pos.normalized()*speed*dt
    if hero_type=="bog" and dash_cooldown<=0.0 and dist>60.0:
        hero_position += delta_pos.normalized()*minf(55.0,dist*0.33)
        dash_cooldown = 6.0
        _spark(hero_position, color_gold,7)
    hero_position = Vector2(clampf(hero_position.x, ARENA.position.x+20.0,ARENA.end.x-20.0), clampf(hero_position.y,ARENA.position.y+20.0,ARENA.end.y-18.0))
    if hero_cooldown<=0.0 and dist<ideal_range+12.0:
        hero_cooldown = 0.78 if hero_type!="kram" else 0.94
        var damage := float(HEROES[hero_type].damage) + float(weapon_level) * 5.0
        var kind := "fire" if weapon_heated > 0 else "physical"
        if hero_type == "kram":
            _projectile(hero_position,e.pos,"fire" if weapon_heated > 0 else "arcane",damage)
            for n in range(weapon_split):
                _projectile(hero_position,e.pos + Vector2(28.0 * (1 if n % 2 == 0 else -1), -29.0), "arcane",damage * 0.55)
        else:
            for j in range(enemies.size()-1,-1,-1):
                if hero_position.distance_to(enemies[j].pos) < 68.0 + float(weapon_wide) * 21.0:
                    _hurt_enemy(j,damage*(0.82 if j!=nearest else 1.0),kind)
            _spark(e.pos,color_gold,4)

func _update_enemies(dt: float) -> void:
    for i in range(enemies.size()-1,-1,-1):
        if i>=enemies.size():continue
        var e: Dictionary = enemies[i]
        e.cooldown = float(e.cooldown)-dt
        e.flash = maxf(0.0,float(e.flash)-dt)
        if e.burn>0.0:
            e.burn -= dt
            e.hp -= dt*4.5
        if e.poison>0.0:
            e.poison -= dt
            e.hp -= dt*3.7
        if e.hp <= 0.0:
            _hurt_enemy(i, 0.0)
            continue
        if e.stun>0.0:
            e.stun -= dt
            continue
        var goal := hero_position
        if actors.size()>0 and rng.randf()<0.18*dt:
            goal = actors[rng.randi_range(0,actors.size()-1)].pos
        var direction: Vector2 = (goal-e.pos).normalized()
        var distance := e.pos.distance_to(hero_position)
        if e.archer:
            if distance < 120.0:
                e.pos -= direction * float(e.speed) * dt
            elif distance > 205.0:
                e.pos += direction * float(e.speed) * dt
            if distance < 250.0 and e.cooldown <= 0.0:
                e.cooldown = 2.6
                _damage_hero(float(e.damage) * 0.72)
                _spark(hero_position, Color("#d17d69"), 4)
        else:
            e.pos += direction * float(e.speed) * dt
            if distance < 24.0 and e.cooldown <= 0.0:
                e.cooldown = 1.1 if e.tax else 1.45
                _damage_hero(float(e.damage))

func _damage_hero(raw_damage: float) -> void:
    if ended:
        return
    var armor_factor := 0.86 if hero_type=="bog" else 1.0
    armor_factor *= maxf(0.68, 1.0 - 0.12 * float(weapon_guard))
    hp = maxf(0.0, hp - raw_damage * armor_factor)
    _spark(hero_position, Color("#e76d70"), 5)
    updated.emit()
    if hp <= 0.0:
        ended = true
        active = false
        finished.emit(false)

func _update_actors(dt: float) -> void:
    for a in actors:
        var recipe: Dictionary = a.recipe
        a.phase = float(a.phase)+dt
        a.cooldown = float(a.cooldown)-dt
        a.wander = float(a.wander)-dt
        var host: String = str(recipe.host)
        if host in ["chicken","goblin","saucer","ghost"]:
            if a.wander<=0.0:
                a.wander = rng.randf_range(0.7,2.1)
                a.target = Vector2(rng.randf_range(ARENA.position.x+45,ARENA.end.x-40),rng.randf_range(ARENA.position.y+45,ARENA.end.y-30))
            var target: Vector2 = a.target
            var near := _nearest_enemy(a.pos)
            if near>=0 and recipe.mode in ["stagger","ricochet"]:
                target = enemies[near].pos
            var vel: Vector2 = (target - a.pos).normalized()
            var velocity := 48.0 if host=="goblin" else 64.0 if host=="chicken" else 113.0 if host=="saucer" else 42.0
            a.pos += vel * velocity*dt
        else:
            # Stationary emplacements stay independent; never attach to hero each frame.
            pass
        var away: Vector2 = a.pos - hero_position
        if away.length()<38.0:
            a.pos += (away.normalized() if away.length()>0.1 else Vector2.RIGHT) * 54.0*dt
        for other in actors:
            if other==a:continue
            var gap: Vector2 = a.pos-other.pos
            if gap.length()<36.0 and gap.length()>0.1:
                a.pos += gap.normalized()*29.0*dt
        a.pos = Vector2(clampf(a.pos.x,ARENA.position.x+18,ARENA.end.x-18),clampf(a.pos.y,ARENA.position.y+22,ARENA.end.y-17))
        if a.cooldown<=0.0:
            a.cooldown = 3.0 if recipe.mods.bees else 2.15
            a.casts = int(a.casts)+1
            var near := _nearest_enemy(a.pos)
            if recipe.mods.bees:
                _emit_bees(a.pos, recipe)
            if recipe.mods.fire:
                _make_hazard(a.pos,"fire",24.0)
            if recipe.mods.poison:
                _make_hazard(a.pos,"poison",30.0)
            if recipe.mods.spores:
                _make_hazard(a.pos,"spores",35.0)
            if recipe.mods.ghost:
                _spark(a.pos, Color("#a4cce9"),11)
            if near>=0:
                var kind := "saucer" if host=="saucer" else "fire" if recipe.mods.fire else "poison" if recipe.mods.poison else "arcane"
                _projectile(a.pos,enemies[near].pos,kind,18.0+recipe.ids.size()*4.0)

func _update_projectiles(dt: float) -> void:
    for i in range(projectiles.size()-1,-1,-1):
        var p: Dictionary = projectiles[i]
        p.pos += p.vel*dt
        p.life -= dt
        var impact := -1
        for j in range(enemies.size()):
            if p.pos.distance_to(enemies[j].pos)<19.0:
                impact = j
                break
        if impact>=0:
            _hurt_enemy(impact,float(p.damage),"fire" if p.kind=="fire" else "poison" if p.kind=="poison" else "physical")
            if p.kind=="saucer" and int(p.hits)<2 and enemies.size()>0:
                p.hits += 1
                p.life = 0.7
                var near := _nearest_enemy(p.pos + p.vel.normalized()*60.0)
                if near>=0:p.vel = (enemies[near].pos-p.pos).normalized()*310.0
            else:
                projectiles.remove_at(i)
                continue
        if p.life<=0.0 or not ARENA.grow(50.0).has_point(p.pos):projectiles.remove_at(i)

func _update_bees(dt: float) -> void:
    for i in range(bees.size()-1,-1,-1):
        var b: Dictionary = bees[i]
        b.life -= dt
        b.cooldown -= dt
        b.phase += dt*12.0
        var near := _nearest_enemy(b.pos)
        if near>=0:
            b.pos += (enemies[near].pos-b.pos).normalized()*145.0*dt
            if b.pos.distance_to(enemies[near].pos)<16.0 and b.cooldown<=0.0:
                var kind := "fire" if b.mods.fire else "poison" if b.mods.poison else "physical"
                _hurt_enemy(near,8.0,kind)
                b.cooldown = 0.52
                b.life -= 1.2
        if b.life<=0.0:bees.remove_at(i)

func _update_hazards(dt: float) -> void:
    for i in range(hazards.size()-1,-1,-1):
        var h: Dictionary = hazards[i]
        h.age += dt
        h.damage_timer -= dt
        if h.damage_timer<=0.0:
            h.damage_timer = 0.6
            var radius := float(h.radius)*(1.0+minf(0.6,float(h.age)*0.13))
            for j in range(enemies.size()-1,-1,-1):
                if j>=enemies.size():continue
                if h.pos.distance_to(enemies[j].pos)<radius:
                    _hurt_enemy(j,6.0,h.kind if h.kind in ["fire","poison"] else "poison")
        if h.age>=h.life:hazards.remove_at(i)

func _draw_sprite(id: String, at: Vector2, size: float = 38.0, alpha: float = 1.0) -> void:
    if not sprites.has(id):return
    var texture: Texture2D = sprites[id]
    var rect := Rect2(at-Vector2(size*0.5,size*0.70),Vector2(size,size*1.17))
    draw_texture_rect(texture,rect,false,Color(1,1,1,alpha))

func _draw() -> void:
    draw_rect(Rect2(0,0,832,648),Color("#141d29"))
    draw_rect(ARENA,Color("#33464a"))
    # Deterministic tile texture (no RNG used during rendering).
    for y in range(6,28):
        for x in range(1,36):
            var xx := x*23.0
            var yy := y*23.0
            if ARENA.has_point(Vector2(xx,yy)) and (x*7+y*11)%5==0:
                draw_rect(Rect2(xx, yy, 17, 3),Color("#455859"))
            if ARENA.has_point(Vector2(xx,yy)) and (x*13+y*3)%13==0:
                draw_rect(Rect2(xx+6, yy+5, 3, 3),Color("#648479"))
    for x in range(int(ARENA.position.x)+20,int(ARENA.end.x)-20,98):
        draw_rect(Rect2(x, ARENA.position.y+4,24,5),Color("#7b725e"))
        draw_rect(Rect2(x, ARENA.end.y-8,34,4),Color("#7b725e"))
    # Persistent hazards with safe non-negative radii.
    for h in hazards:
        var ratio: float = clampf(float(h.age)/float(h.life),0.0,1.0)
        var rad: float = maxf(1.0,float(h.radius)*(0.8+minf(0.8,ratio*1.7)))
        var col := color_fire if h.kind=="fire" else color_poison if h.kind=="poison" else Color("#bd91df")
        draw_circle(h.pos,rad,Color(col.r,col.g,col.b,0.22*(1.0-ratio)))
        draw_arc(h.pos,rad,0.0,TAU,25,Color(col.r,col.g,col.b,0.65*(1.0-ratio)),2.0)
        if h.kind=="spores":_draw_sprite("mushroom",h.pos,32.0)
    for e in enemies:
        _draw_sprite("taxman" if e.tax else "goblin" if e.archer else "rat",e.pos,53.0 if e.boss else 41.0)
        if e.archer:
            draw_line(e.pos + Vector2(-12, -28), e.pos + Vector2(12, -28), Color("#f8c06a"), 2.0)
        if e.sprinter:
            draw_arc(e.pos, 22.0, 0.0, TAU, 16, Color(0.94, 0.78, 0.54, 0.55), 1.5)
        var w := 46.0 if e.boss else 31.0
        draw_rect(Rect2(e.pos+Vector2(-w*0.5,-32),Vector2(w,4)),Color("#1b2027"))
        draw_rect(Rect2(e.pos+Vector2(-w*0.5,-32),Vector2(w*clampf(float(e.hp)/float(e.max_hp),0.0,1.0),4)),Color("#d36a65"))
        if e.flash>0.0:
            draw_arc(e.pos,19.0,0.0,TAU,12,Color("#ffe9ba"),1.8)
        if e.burn>0.0:draw_circle(e.pos+Vector2(0,-23),5.0,Color("#f28c57"))
        if e.poison>0.0:draw_circle(e.pos+Vector2(12,-17),4.0,Color("#88d769"))
    for a in actors:
        var recipe: Dictionary = a.recipe
        draw_ellipse_shadow(a.pos,22.0)
        var host: String = str(recipe.host)
        _draw_sprite(host,a.pos,48.0 if host=="saucer" else 41.0,0.68 if recipe.mods.ghost else 1.0)
        if str(recipe.rider)!="":
            _draw_sprite(str(recipe.rider),a.pos+Vector2(0,-26),30.0)
        if recipe.mods.fire:
            draw_arc(a.pos,23.0+sin(float(a.phase)*4.0)*3.0,3.2,5.8,10,color_fire,3.5)
        if recipe.mods.poison:
            draw_circle(a.pos+Vector2(10,8),5.0,Color(color_poison.r,color_poison.g,color_poison.b,0.65))
        if recipe.mods.bees:
            _draw_sprite("hive",a.pos+Vector2(17,-14),21.0)
        if recipe.ids.has("torch"):
            _draw_sprite("torch",a.pos+Vector2(-18,-12),20.0)
        draw_string(ThemeDB.fallback_font,a.pos+Vector2(-37,34),str(recipe.title).substr(0,20),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#f6e1af"))
    for b in bees:
        _draw_sprite("bee",b.pos+Vector2(0,sin(float(b.phase))*3.0),15.0)
    for p in projectiles:
        var col := color_fire if p.kind=="fire" else color_poison if p.kind=="poison" else color_ice if p.kind=="arcane" else color_gold
        draw_line(p.pos-p.vel.normalized()*10.0,p.pos,col,3.5)
        _draw_sprite("saucer" if p.kind=="saucer" else "shot",p.pos,22.0 if p.kind=="saucer" else 14.0)
    for s in sparks:
        draw_rect(Rect2(s.pos,Vector2(4,4)),s.color)
    draw_ellipse_shadow(hero_position,24.0)
    _draw_sprite(hero_type,hero_position,49.0)
    draw_string(ThemeDB.fallback_font,Vector2(24,116),"THE VILLAGE INCIDENT  /  GODOT MIGRATION SLICE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f8ddb3"))

func draw_ellipse_shadow(pos: Vector2, radius: float) -> void:
    draw_circle(pos+Vector2(0,15),radius,Color(0.02,0.03,0.04,0.30))

func stage() -> String:
    if clock<TOTAL_TIME*0.34:return "OUTSKIRTS"
    if clock<TOTAL_TIME*0.69:return "GOBLIN ROAD"
    if clock<TOTAL_TIME-28.0:return "TOLL APPROACH"
    return "THE MAYOR"

func report() -> Dictionary:
    return {"hp":hp, "max_hp":max_hp, "gold":gold, "kills":kills, "concern":concern, "time":clock, "stage":stage(), "kits":kits, "enemies":enemies.size(), "actors":actors.size(), "weapon_level":weapon_level, "discovered":discovery_index}
