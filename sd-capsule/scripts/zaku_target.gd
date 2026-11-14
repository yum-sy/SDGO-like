extends CharacterBody3D
signal destroyed(target)
const Brain = preload("res://scripts/ai_input.gd")
var brain := Brain.new()
var hp := 100
var target_number := 0
var model: Node3D
var flash_left := 0.0
var flash_mesh: MeshInstance3D
var stun := 0.0
var cooldown := 2.0
var windup := 0.0
var pending_aim := Vector3.ZERO
var knockback := Vector3.ZERO
var ai_enabled := true
var step_time := 0.0
func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	brain.side = -1 if target_number % 2 else 1
	cooldown += target_number * 0.45
	model = preload("res://assets/prepared/zaku.scn").instantiate()
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
	brain.evade()
	if hp == 0:
		collision_layer = 0
		collision_mask = 0
		model.hide()
		destroyed.emit(self)
func step(player: CharacterBody3D, battle: Node3D, delta: float) -> void:
	if hp <= 0 or not ai_enabled:
		return
	stun = maxf(0,stun-delta)
	cooldown = maxf(0,cooldown-delta)
	var command := brain.sample(self,player,delta)
	var direction: Vector3 = command.move
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
	step_time += delta * 10
	model.position.y = absf(sin(step_time))*0.035 if is_on_floor() else 0
	if windup > 0:
		windup = maxf(0,windup-delta)
		if windup == 0 and stun == 0:
			battle.enemy_shot(self,pending_aim)
	elif command.fire and cooldown == 0 and stun == 0:
		var sight := PhysicsRayQueryParameters3D.create(aim_point(),player.aim_point(),1,[get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(sight)
		if not hit.is_empty() and hit.collider == player:
			pending_aim = player.aim_point()
			windup = 0.65
			cooldown = 2.5 + target_number*0.2
	if position.y < -12:
		damage(100)
func _process(delta: float) -> void:
	flash_left = maxf(0,flash_left-delta)
	flash_mesh.visible = flash_left > 0 or windup > 0
