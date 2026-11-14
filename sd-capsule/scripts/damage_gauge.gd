extends RefCounted
# Delayed loss is presentation only; current health remains authoritative.
var current := 1.0
var trailing := 1.0
var hold := 0.0
func update(ratio: float, delta: float) -> void:
	ratio = clampf(ratio,0,1)
	if ratio < current: hold = 0.22
	if ratio > current: trailing = maxf(trailing,ratio)
	current = ratio
	hold = maxf(0,hold-delta)
	if hold == 0: trailing = move_toward(trailing,current,delta*0.9)
