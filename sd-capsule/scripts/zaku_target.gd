extends CharacterBody3D
signal destroyed(target)
const Brain = preload("res://scripts/ai_input.gd")
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
func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
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
func aim_point() -> Vector3:
	return global_position + Vector3.UP * 1.05
func damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0,hp-amount)
	flash_left = 0.14
	stun = 0.22
	windup = 0
	burst_left = 0
	brain.evade()
	model.hit()
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
	var direction: Vector3 = command.move
	if windup > 0: command.speed *= 0.3
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
	model.rotation.y = lerp_angle(model.rotation.y,atan2(toward.x,toward.z),8*delta)
	model.animate(velocity,windup,brain.dodge_left > 0,delta)
	if windup > 0:
		windup = maxf(0,windup-delta)
		if windup == 0 and stun == 0:
			model.fire()
			if attack_kind == "melee":
				model.strike()
				var melee_ray := PhysicsRayQueryParameters3D.create(aim_point(),player.aim_point(),3,[get_rid()])
				var contact := get_world_3d().direct_space_state.intersect_ray(melee_ray)
				if global_position.distance_to(player.global_position) < 3.0 and not contact.is_empty() and contact.collider == player:
					player.damage(12)
					player.impulse = (player.global_position-global_position).normalized()*7
					battle.impact(player.aim_point(),12,Color(1,0.4,0.2))
			else:
				battle.enemy_shot(self,pending_aim)
				burst_left = 1
				burst_delay = 0.18
	elif command.fire and cooldown == 0 and stun == 0:
		var sight := PhysicsRayQueryParameters3D.create(aim_point(),player.aim_point(),1,[get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(sight)
		if not hit.is_empty() and hit.collider == player:
			pending_aim = player.aim_point()
			attack_kind = "melee" if global_position.distance_to(player.global_position) < 3 else "ranged"
			windup = 0.6 if attack_kind == "melee" else 0.65
			cooldown = 1.8 + target_number*0.25
	if position.y < -12:
		damage(100)
func _process(delta: float) -> void:
	if get_parent().get("mode") == "paused": return
	if hp <= 0: model.animate(Vector3.ZERO,0,false,delta)
	flash_left = maxf(0,flash_left-delta)
	flash_mesh.visible = hp > 0 and flash_left > 0
