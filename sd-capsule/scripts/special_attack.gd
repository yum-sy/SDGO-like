extends RefCounted
# Authority-only gauge and timing; no input/render dependencies.
const CHARGE_TIME := 0.65
const FIRE_TIME := 1.2
const RECOVERY_TIME := 0.45
const PULSE_TIME := 0.12
var gauge := 0.0
var elapsed := 0.0
var running := false
var pulses := 0
var uses := 0
func gain(amount: float) -> bool:
	var was_ready := gauge >= 100
	if not running: gauge = clampf(gauge+maxf(0,amount),0,100)
	return not was_ready and gauge >= 100
func begin() -> bool:
	if running or gauge < 100: return false
	gauge = 0
	elapsed = 0
	pulses = 0
	uses += 1
	running = true
	return true
func stage() -> String:
	if not running: return "READY" if gauge >= 100 else "CHARGING"
	if elapsed < CHARGE_TIME: return "WINDUP"
	if elapsed < CHARGE_TIME+FIRE_TIME: return "DISCHARGE"
	return "RECOVERY"
func advance(delta: float) -> int:
	if not running: return 0
	elapsed += maxf(0,delta)
	var due := mini(10,int(maxf(0,elapsed-CHARGE_TIME)/PULSE_TIME))
	var count := due-pulses
	pulses = due
	if elapsed >= CHARGE_TIME+FIRE_TIME+RECOVERY_TIME: running = false
	return count
func cancel() -> void:
	running = false
