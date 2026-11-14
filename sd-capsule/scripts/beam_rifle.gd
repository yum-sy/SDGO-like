extends RefCounted
# Weapon state has no scene/input dependency. Server/AI can drive the same state.
const CAPACITY := 6
const DAMAGE := 25
const INTERVAL := 0.28
const RELOAD_TIME := 1.6
var ammo := CAPACITY
var cooldown := 0.0
var reload_left := 0.0

func tick(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if reload_left > 0:
		reload_left = maxf(0, reload_left - delta)
		if reload_left == 0:
			ammo = CAPACITY

func reload() -> void:
	if reload_left == 0 and ammo < CAPACITY:
		reload_left = RELOAD_TIME

func try_fire() -> bool:
	if reload_left > 0 or cooldown > 0:
		return false
	if ammo == 0:
		reload()
		return false
	ammo -= 1
	cooldown = INTERVAL
	if ammo == 0:
		reload()
	return true
