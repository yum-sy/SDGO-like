extends Node3D
const Bolt = preload("res://scripts/enemy_bolt.gd")
const FX = preload("res://scripts/combat_fx.gd")
const Rifle = preload("res://scripts/beam_rifle.gd")
const RANGE := 45.0
var rifle := Rifle.new()
var targets: Array = []
var selected: Node3D
var player: CharacterBody3D
var camera: Camera3D
var kills := 0
var hit_left := 0.0
var message := ""
var won := false
var lost := false
var weapon := 0
var melee_cooldown := 0.0
var combo_window := 0.0
var combo := 0
var hurt_left := 0.0
var elapsed := 0.0
var sounds: Node
var ai_enabled := true
var shots := 0
var hits := 0
var was_reloading := false
var camera_trauma := 0.0
var damage_popups: Array[Dictionary] = []

func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 3, [player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query)

func eligible(target: Node3D) -> bool:
	if target.hp <= 0 or player.global_position.distance_to(target.global_position) > RANGE:
		return false
	var point: Vector3 = target.aim_point()
	var toward: Vector3 = (point - camera.global_position).normalized()
	if (-camera.global_basis.z).dot(toward) < 0.78 or camera.is_position_behind(point):
		return false
	var screen := camera.unproject_position(point)
	if not get_viewport().get_visible_rect().has_point(screen):
		return false
	var obstruction := ray(player.global_position + Vector3.UP * 1.3, point)
	return not obstruction.is_empty() and obstruction.collider == target

func update_target(cycle: bool) -> void:
	var candidates: Array = []
	for target in targets:
		if eligible(target):
			candidates.append(target)
	candidates.sort_custom(func(a, b):
		var center := get_viewport().get_visible_rect().size * 0.5
		return camera.unproject_position(a.aim_point()).distance_squared_to(center) < camera.unproject_position(b.aim_point()).distance_squared_to(center))
	if candidates.is_empty():
		selected = null
	elif cycle:
		selected = candidates[(candidates.find(selected) + 1) % candidates.size()]
	elif not selected in candidates:
		selected = candidates[0]

func step(command: Dictionary, delta: float) -> void:
	if won or lost:
		return
	elapsed += delta
	camera_trauma = move_toward(camera_trauma,0,delta*3)
	for popup in damage_popups: popup.life -= delta
	damage_popups = damage_popups.filter(func(p): return p.life > 0)
	player.rig.reload_progress = 1-rifle.reload_left/1.6 if rifle.reload_left > 0 else 0
	rifle.tick(delta)
	hit_left = maxf(0,hit_left-delta)
	hurt_left = maxf(0,hurt_left-delta)
	melee_cooldown = maxf(0,melee_cooldown-delta)
	combo_window = maxf(0,combo_window-delta)
	if player.hp <= 0:
		lost = true
		clear_bolts()
		return
	update_target(command.get("cycle",false))
	if command.get("weapon",false):
		weapon = 1-weapon
	player.rig.saber_equipped = weapon == 1
	if command.get("reload",false):
		rifle.reload()
	if command.get("melee",false) or (command.get("fire",false) and weapon == 1):
		if melee_cooldown == 0:
			melee()
	elif command.get("fire",false) and melee_cooldown == 0 and rifle.try_fire():
		shoot()
	if rifle.reload_left > 0 and not was_reloading: sound("reload")
	if rifle.reload_left == 0 and was_reloading: sound("ready")
	was_reloading = rifle.reload_left > 0
	if ai_enabled and not won:
		for target in targets:
			target.step(player,self,delta)

func sound(kind: String) -> void:
	if is_instance_valid(sounds):
		sounds.play_effect(kind)
func clear_bolts() -> void:
	for child in get_children():
		if child is Bolt:
			child.queue_free()
func enemy_shot(shooter: CharacterBody3D, point: Vector3) -> void:
	if won or lost:
		return
	var bolt := preload("res://scripts/enemy_bolt.gd").new()
	bolt.shooter = shooter.get_rid()
	add_child(bolt)
	bolt.global_position = shooter.aim_point()
	bolt.velocity = (point-bolt.global_position).normalized()*17
	sound("enemy")
func melee() -> void:
	combo = combo%3+1 if combo_window > 0 else 1
	combo_window = 0.9
	melee_cooldown = 0.3 if combo < 3 else 0.65
	var damage_amount: int = [25,30,45][combo-1]
	var facing := -Basis(Vector3.UP,player.yaw).z
	if is_instance_valid(selected) and player.global_position.distance_to(selected.global_position) < 5:
		facing = (selected.global_position-player.global_position).normalized()
		facing.y = 0
		player.visual.rotation.y = atan2(-facing.x,-facing.z)
		player.impulse = facing*4
	if is_instance_valid(player.rig):
		player.rig.swing(combo)
	sound("saber")
	message = "SABER COMBO %d" % combo
	for target in targets:
		if target.hp <= 0:
			continue
		var offset: Vector3 = target.aim_point()-player.aim_point()
		if offset.length() > 3.4 or (offset.length()>0.1 and facing.dot(offset.normalized()) < 0.3):
			continue
		var obstruction := ray(player.aim_point(),target.aim_point())
		if not obstruction.is_empty() and obstruction.collider == target:
			target.damage(damage_amount)
			impact(target.aim_point(),damage_amount,Color(1,0.25,0.6))
			camera_trauma = 0.35 if combo == 3 else 0.16
			target.knockback = facing*(9 if combo == 3 else 3)
			hit_left = 0.18
			sound("hit")

func shoot() -> void:
	shots += 1
	player.rig.fire()
	camera_trauma = maxf(camera_trauma,0.1)
	sound("shot")
	var direction := -camera.global_basis.z
	var aim := camera.global_position + direction * RANGE
	if is_instance_valid(selected):
		aim = selected.aim_point()
	else:
		var sight := ray(camera.global_position, aim)
		if not sight.is_empty():
			aim = sight.position
	var muzzle: Vector3 = player.global_position + Vector3.UP * 1.35 + player.visual.global_basis.x * 0.5
	direction = (aim - muzzle).normalized()
	player.visual.rotation.y = atan2(-direction.x,-direction.z)
	FX.spawn(self,muzzle,Color(0.5,1,0.8),0.35)
	var endpoint: Vector3 = muzzle + direction * RANGE
	var result := ray(muzzle, endpoint)
	if not result.is_empty():
		endpoint = result.position
		if result.collider.has_method("damage"):
			result.collider.damage(Rifle.DAMAGE)
			impact(endpoint,Rifle.DAMAGE,Color(0.5,1,0.8))
			hits += 1
			sound("hit")
			hit_left = 0.16
			message = "HIT  -25"
		else:
			message = "BLOCKED"
			FX.spawn(self,endpoint,Color(1,0.8,0.4),0.6)
	else:
		message = "MISS"
	beam(muzzle, endpoint)

func beam(from: Vector3, to: Vector3) -> void:
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.065, 0.065, maxf(0.01, from.distance_to(to)))
	tracer.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.35, 1, 0.8)
	tracer.material_override = material
	add_child(tracer)
	tracer.global_position = (from + to) * 0.5
	if from.distance_to(to) > 0.01:
		tracer.look_at(to, Vector3.UP if absf((to-from).normalized().y) < 0.99 else Vector3.RIGHT)
	get_tree().create_timer(0.09).timeout.connect(tracer.queue_free)

func impact(point: Vector3, amount: int, tint: Color) -> void:
	FX.spawn(self,point,tint)
	damage_popups.append({"point":point,"amount":amount,"life":0.65,"tint":tint})
	if damage_popups.size() > 12: damage_popups.pop_front()
func on_destroyed(_target: Node3D) -> void:
	FX.spawn(self,_target.aim_point(),Color(1,0.5,0.12),2.0)
	camera_trauma = maxf(camera_trauma,0.28)
	sound("destroy")
	kills += 1
	selected = null
	won = kills == targets.size()
	if won:
		clear_bolts()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
