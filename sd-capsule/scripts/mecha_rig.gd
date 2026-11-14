extends Node3D
# Rigid-part animation, not skinning. Original source geometry stays intact.
var joints := {}
var weapon: MeshInstance3D
var saber: MeshInstance3D
var swing_left := 0.0
var swing_duration := 0.32
var swing_index := 0
func _ready() -> void:
	for part in get_children():
		if not part is MeshInstance3D:
			continue
		var name_text := str(part.name)
		if "leg_" in name_text or "hand_" in name_text or "armor_gun" in name_text or "armor_shield" in name_text:
			var bounds: AABB = part.get_aabb()
			var pivot_at := bounds.get_center()
			pivot_at.y = bounds.end.y - bounds.size.y * 0.08
			var joint := Node3D.new()
			add_child(joint)
			joint.position = pivot_at
			part.reparent(joint)
			part.position = -pivot_at
			joints[name_text] = joint
			if "armor_gun" in name_text:
				weapon = part
	saber = MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 0.045
	shape.bottom_radius = 0.045
	shape.height = 1.6
	saber.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1,0.2,0.75)
	saber.material_override = mat
	add_child(saber)
	saber.hide()
func swing(combo: int) -> void:
	swing_index = combo
	swing_left = 0.32 if combo < 3 else 0.45
	swing_duration = swing_left
func animate(velocity: Vector3, grounded: bool, time: float, delta: float) -> void:
	swing_left = maxf(0,swing_left-delta)
	var stride := clampf(Vector2(velocity.x,velocity.z).length()/7.0,0,1) * 0.35 if grounded else 0.0
	for key in joints:
		var joint: Node3D = joints[key]
		var side := 1.0 if "_L" in key else -1.0
		var angle := sin(time) * stride * side
		if "leg_" in key:
			joint.rotation.x = angle if grounded else -0.25
		elif "hand_lengan" in key or "hand_sendi" in key or "hand_L" in key or "hand_R" in key:
			joint.rotation.x = -angle * 0.4
	saber.visible = swing_left > 0
	if is_instance_valid(weapon):
		weapon.visible = swing_left == 0
	if swing_left > 0:
		var phase := 1 - swing_left / swing_duration
		var arc := lerpf(-1.2,1.2,phase) * (1 if swing_index % 2 else -1)
		saber.position = Vector3(-0.65,1.25,0.5)
		saber.rotation = Vector3(PI*0.5,0,arc)
		saber.position += Vector3(sin(arc),0,cos(arc)) * 0.7
