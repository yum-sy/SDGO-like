extends RefCounted
# Damage is visibility-tested from the impact surface: cover really shields blasts.
static func apply(world: Node3D, point: Vector3, victim: Node3D, radius: float, damage: int, exclude: Array[RID] = []) -> int:
 if not is_instance_valid(victim) or not victim.has_method("aim_point"): return 0
 var center: Vector3 = victim.aim_point()
 var distance := center.distance_to(point)
 if distance > radius: return 0
 var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point,center,3,exclude))
 if not hit.is_empty() and hit.collider != victim: return 0
 var amount := maxi(1,roundi(damage*lerpf(1,0.35,distance/radius)))
 if victim.has_method("damage_from"): victim.damage_from(amount,point)
 elif victim.has_method("damage"): victim.damage(amount)
 return amount
