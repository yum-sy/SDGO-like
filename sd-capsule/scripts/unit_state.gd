extends RefCounted
# Serializable authority state. Visuals and platform input never own health.
var hp := 100
var booster := 100.0
var invulnerable := 0.0
var boost_locked := false
func tick(delta: float) -> void:
	invulnerable = maxf(0, invulnerable - delta)
func damage(amount: int) -> bool:
	if hp <= 0 or invulnerable > 0:
		return false
	hp = maxi(0, hp - amount)
	invulnerable = 0.28
	return true
func snapshot() -> Dictionary:
	return {"hp":hp,"booster":booster,"boost_locked":boost_locked}
