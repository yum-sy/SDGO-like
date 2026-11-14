extends RefCounted
# One authoritative clock drives both blade pose and swept hit interval.
const CLIPS = [Vector3(0.12,0.12,0.18),Vector3(0.14,0.14,0.18),Vector3(0.22,0.18,0.30)]
var custom_clip := Vector3.ZERO
func clip() -> Vector3:
	return custom_clip if custom_clip != Vector3.ZERO else CLIPS[index-1]
var elapsed := 0.0
var previous := 0.0
var index := 1
var running := false
var hit_ids := {}
func begin(combo: int) -> void:
	index = combo
	elapsed = 0
	previous = 0
	hit_ids.clear()
	running = true
func duration() -> float:
	var c: Vector3 = clip()
	return c.x+c.y+c.z
func advance(delta: float) -> bool:
	previous = elapsed
	elapsed = minf(duration(),elapsed+maxf(0,delta))
	var c: Vector3 = clip()
	return previous < c.x+c.y and elapsed >= c.x
func finish_tick() -> void:
	if elapsed >= duration(): running = false
func stage() -> String:
	if not running: return "READY"
	var c: Vector3 = clip()
	if elapsed < c.x: return "WINDUP"
	if elapsed < c.x+c.y: return "STRIKE"
	return "RECOVERY"
func sweep_angle(at: float) -> float:
	var c: Vector3 = clip()
	var sweep := clampf((at-c.x)/c.y,0,1)
	return lerpf(-1.15,1.15,sweep)*(1 if index%2 else -1)
func pose_angle() -> float:
	var c: Vector3 = clip()
	if elapsed < c.x: return lerpf(-0.3,sweep_angle(c.x),elapsed/c.x)
	if elapsed > c.x+c.y: return lerpf(sweep_angle(c.x+c.y),0.3,(elapsed-c.x-c.y)/c.z)
	return sweep_angle(elapsed)
func intersects(offset: Vector3, facing: Vector3) -> bool:
	var right := Vector3(facing.z,0,-facing.x)
	# Match the visible hand anchor and 1.6m blade, plus target capsule radius.
	offset -= right*(-0.65)+facing*0.55+Vector3.UP*0.05
	if absf(offset.y) > 1.2 or Vector2(offset.x,offset.z).length() > 2.25: return false
	var angle := atan2(offset.dot(right),offset.dot(facing))
	var a := sweep_angle(previous)
	var b := sweep_angle(elapsed)
	# Capsule radius gives a small angular tolerance, not a full frontal cone.
	var tolerance := atan2(0.65,maxf(0.5,offset.length()))
	return angle >= minf(a,b)-tolerance and angle <= maxf(a,b)+tolerance
func cancel() -> void:
	running = false
	hit_ids.clear()
