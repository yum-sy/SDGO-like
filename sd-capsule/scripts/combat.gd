extends Node3D
const Bolt = preload("res://scripts/enemy_bolt.gd")
const FX = preload("res://scripts/combat_fx.gd")
const Rifle = preload("res://scripts/beam_rifle.gd")
const RANGE := 45.0
var attack := preload("res://scripts/attack_clock.gd").new()
var attack_facing := Vector3.FORWARD
var melee_buffer := 0.0
var melee_was_held := false
var rifle := Rifle.new()
var targets: Array = []
var manual_target_left := 0.0
var selected: Node3D
var player: CharacterBody3D
var camera: Camera3D
var auto_aim := true
var melee_kills := 0
var notice := ""
var notice_left := 0.0
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
	if not auto_aim and not cycle:
		selected = null
		return
	if cycle:
		auto_aim = true
		var available: Array = []
		for target in targets:
			if target.hp <= 0 or player.global_position.distance_to(target.global_position) > RANGE: continue
			var sight := ray(player.aim_point(),target.aim_point())
			if not sight.is_empty() and sight.collider == target: available.append(target)
		if not available.is_empty():
			selected = available[(available.find(selected)+1)%available.size()]
			var offset: Vector3 = selected.global_position-player.global_position
			player.focus_yaw = atan2(-offset.x,-offset.z)
			manual_target_left = 0.35
			return
		# A blocked target can still be located, but never receives a through-wall lock.
		var hidden: Array = targets.filter(func(t): return t.hp > 0 and player.global_position.distance_to(t.global_position) <= RANGE)
		if not hidden.is_empty():
			hidden.sort_custom(func(a,b): return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
			var offset: Vector3 = hidden[0].global_position-player.global_position
			player.focus_yaw = atan2(-offset.x,-offset.z)
			selected = null
			announce("TARGET BEHIND COVER / REPOSITION OR BOOST")
			return
	if manual_target_left > 0 and not is_nan(player.focus_yaw) and is_instance_valid(selected) and selected.hp > 0:
		var sight := ray(player.aim_point(),selected.aim_point())
		if player.global_position.distance_to(selected.global_position) <= RANGE and not sight.is_empty() and sight.collider == selected: return
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
	notice_left = maxf(0,notice_left-delta)
	manual_target_left = maxf(0,manual_target_left-delta)
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
	if player.dash_left > 0 and attack.running: cancel_melee()
	advance_melee(delta)
	if command.get("aim",false):
		auto_aim = not auto_aim
		player.focus_yaw = NAN
		selected = null
		announce("TARGET ASSIST ON" if auto_aim else "FREE AIM / SHOOT COVER")
	update_target(command.get("cycle",false))
	if command.get("weapon",false):
		weapon = 1-weapon
	player.rig.saber_equipped = weapon == 1
	if command.get("reload",false):
		rifle.reload()
	var melee_requested: bool = command.get("melee",false) or (command.get("fire",false) and weapon == 1)
	melee_buffer = maxf(0,melee_buffer-delta)
	if melee_requested and not melee_was_held: melee_buffer = 0.18
	melee_was_held = melee_requested
	if melee_buffer > 0 and not attack.running and melee_cooldown == 0 and player.dash_left == 0:
		melee()
		melee_buffer = 0
	elif command.get("fire",false) and weapon == 0 and not attack.running and melee_cooldown == 0 and is_nan(player.focus_yaw) and rifle.try_fire():
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
	bolt.global_position = shooter.model.muzzle_position()
	FX.spawn(self,bolt.global_position,Color(1,0.65,0.2),0.16)
	bolt.velocity = (point-bolt.global_position).normalized()*(20 if shooter.veteran else 17)
	sound("enemy")
func cancel_melee() -> void:
	attack.cancel()
	melee_buffer = 0
	combo_window = 0
	melee_cooldown = 0.18
	player.attack_slow = 1.0
	player.rig.set_attack_pose(attack)
func melee() -> void:
	combo = combo%3+1 if combo_window > 0 else 1
	attack.begin(combo)
	combo_window = attack.duration()+0.6
	melee_cooldown = attack.duration()
	attack_facing = -Basis(Vector3.UP,player.yaw).z
	if is_instance_valid(selected) and player.global_position.distance_to(selected.global_position) < 4:
		attack_facing = selected.global_position-player.global_position
		attack_facing.y = 0
		attack_facing = attack_facing.normalized()
	player.visual.rotation.y = atan2(-attack_facing.x,-attack_facing.z)
	player.rig.set_attack_pose(attack)
	message = "SABER %d / WINDUP" % combo
func advance_melee(delta: float) -> void:
	if not attack.running: return
	var strike := attack.advance(delta)
	player.visual.rotation.y = atan2(-attack_facing.x,-attack_facing.z)
	player.attack_slow = 0.55 if attack.stage() == "WINDUP" else 0.35
	player.rig.set_attack_pose(attack)
	if strike:
		preload("res://scripts/saber_trail.gd").spawn(self,player.aim_point(),attack_facing,attack)
		if attack.previous < attack.CLIPS[combo-1].x:
			sound("saber")
			player.impulse = attack_facing*3
		for target in targets+get_tree().get_nodes_in_group("breakable_cover"):
			if target.hp <= 0 or attack.hit_ids.has(target.get_instance_id()): continue
			var offset: Vector3 = target.aim_point()-player.aim_point()
			if not attack.intersects(offset,attack_facing): continue
			var obstruction := ray(player.aim_point(),target.aim_point())
			if not obstruction.is_empty() and obstruction.collider == target:
				attack.hit_ids[target.get_instance_id()] = true
				var amount: int = [25,30,45][combo-1]
				target.damage(amount,"saber")
				if target is CharacterBody3D: target.knockback = attack_facing*(9 if combo == 3 else 3)
				impact(target.aim_point(),amount,Color(1,0.25,0.6))
				camera_trauma = 0.35 if combo == 3 else 0.16
				hit_left = 0.18
				sound("heavy_hit" if combo == 3 else "hit")
	attack.finish_tick()
	if not attack.running:
		player.attack_slow = 1.0
		player.rig.set_attack_pose(attack)

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
	player.rig.aim_pitch = asin(clampf(direction.y,-1,1))
	player.visual.rotation.y = atan2(-direction.x,-direction.z)
	FX.spawn(self,muzzle,Color(0.5,1,0.8),0.35)
	var endpoint: Vector3 = muzzle + direction * RANGE
	var result := ray(muzzle, endpoint)
	if not result.is_empty():
		endpoint = result.position
		if result.collider.has_method("damage"):
			result.collider.damage(Rifle.DAMAGE,"rifle")
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
	FX.spawn(self,point,tint,1.35 if amount >= 45 else 1.0)
	damage_popups.append({"point":point,"amount":amount,"life":0.65,"tint":tint})
	if damage_popups.size() > 12: damage_popups.pop_front()
func announce(text: String) -> void:
	notice = text
	notice_left = 2.0
func on_destroyed(_target: Node3D) -> void:
	if _target.last_hit_kind == "saber": melee_kills += 1
	announce(_target.role+" ELIMINATED")
	FX.spawn(self,_target.aim_point(),Color(1,0.5,0.12),2.0)
	camera_trauma = maxf(camera_trauma,0.28)
	sound("destroy")
	kills += 1
	selected = null
	won = kills == targets.size()
	if won:
		clear_bolts()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
