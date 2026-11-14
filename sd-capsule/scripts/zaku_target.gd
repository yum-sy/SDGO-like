extends CharacterBody3D
signal destroyed(target)
const Brain = preload("res://scripts/ai_input.gd")
var melee_clock := preload("res://scripts/attack_clock.gd").new()
var melee_facing := Vector3.FORWARD
var veteran := false
var last_hit_kind := "other"
var role := "ASSAULT"
var home := Vector3.ZERO
var attack_warning: MeshInstance3D
var aim_line: MeshInstance3D
var brain := Brain.new()
var max_hp := 180
var hp := 180
var target_number := 0
var model: Node3D
var flash_left := 0.0
var flash_mesh: MeshInstance3D
var stun := 0.0
var cooldown := 0.65
var windup := 0.0
var attack_kind := "ranged"
var burst_left := 0
var burst_delay := 0.0
var pending_aim := Vector3.ZERO
var knockback := Vector3.ZERO
var ai_enabled := true
var step_time := 0.0
var was_evading := false
func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	brain.role = role
	melee_clock.custom_clip = Vector3(0.55,0.14,0.45)
	brain.side = -1 if target_number % 2 else 1
	cooldown += target_number * 0.25
	model = preload("res://assets/prepared/zaku.scn").instantiate()
	model.set_script(preload("res://scripts/zaku_rig.gd"))
	add_child(model)
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.7
	shape.height = 2.1
	collider.shape = shape
	collider.position.y = 1.05
	add_child(collider)
	flash_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.85
	sphere.height = 2.2
	flash_mesh.mesh = sphere
	flash_mesh.position.y = 1.05
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1,0.55,0.15,0.35)
	flash_mesh.material_override = material
	flash_mesh.visible = false
	add_child(flash_mesh)
	attack_warning = preload("res://scripts/attack_warning.gd").new()
	add_child(attack_warning)
	attack_warning.top_level = true
	aim_line = MeshInstance3D.new()
	var line := BoxMesh.new()
	line.size = Vector3(0.025,0.025,1)
	aim_line.mesh = line
	var line_mat := StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.albedo_color = Color(1,0.55,0.15)
	aim_line.material_override = line_mat
	add_child(aim_line)
	aim_line.top_level = true
	aim_line.hide()
func aim_point() -> Vector3:
	return global_position + Vector3.UP * 1.05
func damage(amount: int, kind: String = "other") -> void:
	if hp <= 0:
		return
	last_hit_kind = kind
	hp = maxi(0,hp-amount)
	flash_left = 0.14
	stun = 0.22
	windup = 0
	burst_left = 0
	brain.evade()
	model.hit()
	melee_clock.cancel()
	model.strike_phase = -1
	attack_warning.hide()
	if hp == 0:
		collision_layer = 0
		collision_mask = 0
		model.die()
		destroyed.emit(self)
func step(player: CharacterBody3D, battle: Node3D, delta: float) -> void:
	if hp <= 0 or not ai_enabled:
		return
	stun = maxf(0,stun-delta)
	cooldown = maxf(0,cooldown-delta)
	var command := brain.sample(self,player,delta)
	if veteran: command.speed *= 1.18
	var direction: Vector3 = command.move
	if windup > 0 or melee_clock.running: command.speed = 0
	if burst_left > 0 and stun == 0:
		burst_delay -= delta
		if burst_delay <= 0:
			battle.enemy_shot(self,pending_aim)
			model.fire()
			burst_left -= 1
			burst_delay = 0.18
	# Collision feeler steers around cover; no teleporting or wall penetration.
	var probe := PhysicsRayQueryParameters3D.create(aim_point(),aim_point()+direction*2,1,[get_rid(),player.get_rid()])
	if not get_world_3d().direct_space_state.intersect_ray(probe).is_empty():
		direction = direction.rotated(Vector3.UP, PI*0.5*brain.side)
	velocity.x = direction.x * command.speed if stun == 0 else knockback.x
	velocity.z = direction.z * command.speed if stun == 0 else knockback.z
	knockback = knockback.move_toward(Vector3.ZERO,20*delta)
	velocity.y -= 24*delta
	move_and_slide()
	var toward := player.global_position-global_position
	if melee_clock.running: toward = melee_facing
	model.rotation.y = lerp_angle(model.rotation.y,atan2(toward.x,toward.z),8*delta)
	var evading: bool = brain.dodge_left > 0 and stun == 0
	if evading and not was_evading and is_on_floor():
		preload("res://scripts/ground_fx.gd").spawn(get_parent(),global_position)
	was_evading = evading
	model.melee_windup = melee_clock.running
	model.animate(velocity,windup,brain.dodge_left > 0 and stun == 0,delta)
	if melee_clock.running:
		var active := melee_clock.advance(delta)
		windup = maxf(0,0.55-melee_clock.elapsed)
		model.strike_phase = clampf((melee_clock.elapsed-0.55)/0.14,0,1)
		if melee_clock.stage() == "RECOVERY": model.strike_phase = 1-clampf((melee_clock.elapsed-0.69)/0.45,0,1)
		model.apply_strike_pose()
		if active and not melee_clock.hit_ids.has(player.get_instance_id()):
			var offset: Vector3 = player.aim_point()-aim_point()
			var contact := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(aim_point(),player.aim_point(),3,[get_rid()]))
			if offset.length() < 2.8 and offset.normalized().dot(melee_facing) > 0.45 and not contact.is_empty() and contact.collider == player:
				melee_clock.hit_ids[player.get_instance_id()] = true
				var before: int = player.hp
				player.damage_from(12,global_position)
				if player.hp < before:
					player.impulse = melee_facing*7
					battle.impact(player.aim_point(),12,Color(1,0.4,0.2))
		melee_clock.finish_tick()
		if not melee_clock.running: model.strike_phase = -1
	elif windup > 0:
		windup = maxf(0,windup-delta)
		if windup == 0 and stun == 0:
			model.fire()
			battle.enemy_shot(self,pending_aim)
			burst_left = 2 if role == "SUPPORT" else 1
			burst_delay = 0.18
	elif command.fire and cooldown == 0 and stun == 0:
		var sight := PhysicsRayQueryParameters3D.create(aim_point(),player.aim_point(),3,[get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(sight)
		if not hit.is_empty() and hit.collider == player:
			pending_aim = player.aim_point()
			attack_kind = "melee" if global_position.distance_to(player.global_position) < 3 else "ranged"
			if attack_kind == "melee":
				melee_facing = player.global_position-global_position
				melee_facing.y = 0
				melee_facing = melee_facing.normalized()
				melee_clock.begin(1)
				windup = 0.55
			else:
				windup = 1.0 if role == "SUPPORT" else 0.65
			cooldown = (1.7 if role == "ASSAULT" else 2.8)*(0.8 if veteran else 1.0)
	attack_warning.sync(self)
	if position.y < -12:
		damage(max_hp)
func _process(delta: float) -> void:
	if get_parent().get("mode") == "paused": return
	if hp <= 0: model.animate(Vector3.ZERO,0,false,delta)
	aim_line.visible = hp > 0 and windup > 0 and attack_kind == "ranged" and role == "SUPPORT"
	if aim_line.visible:
		var start := aim_point()
		aim_line.global_position = (start+pending_aim)*0.5
		if start.distance_to(pending_aim) > 0.01:
			aim_line.look_at(pending_aim,Vector3.UP)
			aim_line.scale.z = start.distance_to(pending_aim)
	flash_left = maxf(0,flash_left-delta)
	flash_mesh.visible = hp > 0 and flash_left > 0
