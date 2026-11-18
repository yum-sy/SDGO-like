extends Node3D
const Kit = preload("res://scripts/weapon_kit.gd")
var muzzle: Marker3D
var rails: Array[Node3D] = []
var cells: Array[MeshInstance3D] = []
func _ready() -> void:
	name = "HeavyBeamRifle"
	Kit.block(self,"Grip",Vector3(0.14,0.25,0.16),Vector3.ZERO,Color("354554"))
	Kit.block(self,"Receiver",Vector3(0.50,0.44,0.85),Vector3(0,0.25,0.22),Color("d3dfe4"))
	Kit.block(self,"Stock",Vector3(0.32,0.34,0.60),Vector3(0,0.22,-0.38),Color("354554"))
	Kit.tube(self,"Accelerator",0.18,1.4,Vector3(0,0.25,1.15),Color("526574"))
	Kit.tube(self,"MuzzleCollar",0.26,0.16,Vector3(0,0.25,1.92),Color("d3dfe4"))
	Kit.tube(self,"Bore",0.19,0.02,Vector3(0,0.25,2.01),Color("142334"))
	for side in [-1,1]:
		var rail := Kit.block(self,"DeploymentRail",Vector3(0.16,0.28,1.45),Vector3(side*0.22,0.25,1.13),Color("e6c269"))
		rails.append(rail)
		for i in range(3):
			var cell := Kit.block(self,"ChargeCell",Vector3(0.035,0.13,0.12),Vector3(side*0.26,0.30,0.05+i*0.18),Color("204b62"))
			cell.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cells.append(cell)
	Kit.block(self,"RearArmor",Vector3(0.52,0.32,0.14),Vector3(0,0.28,-0.40),Color("e6c269"))
	Kit.block(self,"Capacitor",Vector3(0.35,0.22,0.72),Vector3(0,0.58,0.20),Color("526574"))
	for i in range(3):
		var top_cell := Kit.block(self,"TopCharge",Vector3(0.29,0.025,0.11),Vector3(0,0.70,0.02+i*0.20),Color("204b62"))
		top_cell.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cells.append(top_cell)
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0,0.25,2.04)
	add_child(muzzle)
	hide()
func sync(direction: Vector3, phase: String, elapsed: float) -> void:
	visible = phase in ["WINDUP","DISCHARGE","RECOVERY"]
	if not visible: return
	global_basis = Basis.looking_at(direction,Vector3.UP if absf(direction.y)<0.95 else Vector3.RIGHT,true)
	var deploy := smoothstep(0,1,elapsed/0.4)
	for i in range(rails.size()):
		rails[i].position.x = (-1 if i == 0 else 1)*(0.27+deploy*0.13)
	var charge := clampf(elapsed/0.65,0,1)
	if phase == "RECOVERY": charge = 1-clampf((elapsed-1.85)/0.45,0,1)
	for i in range(cells.size()):
		cells[i].material_override.albedo_color = Color("8cefff") if charge >= float(i%3+1)/3 else Color("204b62")
