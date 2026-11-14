extends Node3D
const Bolt = preload("res://scripts/enemy_bolt.gd")
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
	if command.get("reload",false):
		rifle.reload()
	if command.get("melee",false) or (command.get("fire",false) and weapon == 1):
		if melee_cooldown == 0:
			melee()
	elif command.get("fire",false) and melee_cooldown == 0 and rifle.try_fire():
		shoot()
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
			target.knockback = facing*(9 if combo == 3 else 3)
			hit_left = 0.18
			sound("hit")

func shoot() -> void:
	shots += 1
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
	var endpoint: Vector3 = muzzle + direction * RANGE
	var result := ray(muzzle, endpoint)
	if not result.is_empty():
		endpoint = result.position
		if result.collider.has_method("damage"):
			result.collider.damage(Rifle.DAMAGE)
			hits += 1
			sound("hit")
			hit_left = 0.16
			message = "HIT  -25"
		else:
			message = "BLOCKED"
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

func on_destroyed(_target: Node3D) -> void:
	sound("destroy")
	kills += 1
	selected = null
	won = kills == targets.size()
	if won:
		clear_bolts()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
