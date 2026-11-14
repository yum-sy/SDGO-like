extends SceneTree
const Bolt = preload("res://scripts/enemy_bolt.gd")
const Rules = preload("res://scripts/sortie_rules.gd")
var failures := 0
func check(value: bool, label: String) -> void:
	if value: print("PASS ",label)
	else:
		failures += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Rules.selected = 1
	var scene = preload("res://main.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	scene.set_physics_process(false)
	var battle = scene.combat
	battle.ai_enabled = false
	check(battle.targets.all(func(t): return t.hp == 240 and t.veteran),"veteran applies stronger enemies to the encounter")
	battle.enemy_shot(battle.targets[0],scene.unit.aim_point())
	var bolts: Array = battle.get_children().filter(func(n): return n is Bolt)
	check(bolts.size() == 1 and is_equal_approx(bolts[0].velocity.length(),20),"veteran projectiles use intended speed")
	battle.clear_bolts()
	battle.step({"aim":true},0.016)
	check(not battle.auto_aim and battle.selected == null,"free aim disables automatic enemy targeting")
	battle.step({"cycle":true},0.016)
	check(battle.auto_aim,"manual target cycle restores target assist")
	var cover = get_nodes_in_group("breakable_cover")[0]
	check(scene.arena.navigation.is_point_solid(Vector2i(-4,-3)),"intact cover blocks navigation cell")
	cover.damage(25,"rifle")
	cover.damage(25,"rifle")
	check(cover.hp == 25 and cover.collision_layer == 1,"two rifle shots damage but do not remove cover")
	cover.damage(25,"rifle")
	check(cover.hp == 0 and cover.collision_layer == 0 and not cover.visual.visible,"third rifle shot removes cover collision and visuals")
	check(not scene.arena.navigation.is_point_solid(Vector2i(-4,-3)),"destroyed cover opens navigation immediately")
	cover.damage(100)
	check(scene.rules.cover_breaks == 1 and scene.arena.removed_covers.size() == 1,"destroyed cover cannot award duplicate credit")
	await physics_frame
	await physics_frame
	var start: Vector3 = cover.position+Vector3(0,1.35,4)
	var query := PhysicsRayQueryParameters3D.create(start,start+Vector3(0,0,-8),1)
	var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
	check(hit.is_empty() or hit.collider != cover,"physics ray no longer hits destroyed cover")
	battle.targets[0].damage(300,"saber")
	check(battle.melee_kills == 1,"saber finishing blow earns specialty progress")
	battle.targets[1].damage(25,"saber")
	battle.targets[1].damage(300,"rifle")
	check(battle.melee_kills == 1,"earlier saber hit does not count a rifle finishing blow")
	battle.kills = 3
	battle.won = true
	battle.elapsed = 45
	scene.unit.state.hp = 60
	scene.rules.level = 0
	check(scene.rules.medals(battle,scene.unit) == [true,true,true],"cargo medals include exact time and HP boundaries")
	check(scene.rules.score(battle,scene.unit) == 2100,"standard score combines clear, health, time and medals")
	var standard_key: String = scene.rules.record_key()
	scene.rules.level = 1
	check(scene.rules.score(battle,scene.unit) == 2940 and scene.rules.record_key() != standard_key,"veteran score multiplier and record namespace are separate")
	scene.rules.arena_id = 1
	check(not scene.rules.medals(battle,scene.unit)[2],"reactor specialty requires two opened covers")
	scene.rules.cover_breaks = 2
	check(scene.rules.medals(battle,scene.unit)[2],"reactor specialty awarded after two cover breaks")
	battle.won = false
	battle.kills = 2
	check(scene.rules.score(battle,scene.unit) == 600 and scene.rules.medals(battle,scene.unit) == [false,false,false],"defeat grants no completion medals or win bonuses")
	scene.unit.state.invulnerable = 0
	scene.unit.damage_from(8,Vector3(5,0,0))
	scene.unit.damage_from(8,Vector3(-5,0,0))
	check(scene.unit.last_hit_from == Vector3(5,0,0),"invulnerable hits do not overwrite actual damage direction")
	var melee_cover = get_nodes_in_group("breakable_cover")[1]
	scene.unit.position = melee_cover.position+Vector3(0,0,2.4)
	scene.unit.yaw = 0
	scene.unit.focus_yaw = NAN
	battle.auto_aim = false
	battle.selected = null
	battle.step({},0.3)
	await physics_frame
	await physics_frame
	battle.step({"melee":true},0.016)
	battle.step({},0.23)
	check(melee_cover.hp == 50,"saber swept hit also damages destructible cover")
	scene.queue_free()
	await create_timer(0.2).timeout
	Rules.selected = 0
	print("FAILURES ",failures)
	quit(failures)
