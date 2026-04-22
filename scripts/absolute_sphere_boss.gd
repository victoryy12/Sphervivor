extends "res://scripts/enemy_ai_RB.gd"

signal weakness_changed(is_weak: bool)

## While true, damage from projectiles and contact is blocked (handled here and by ring colliders).
var shields_active: bool = true


func set_shields_active(active: bool) -> void:
	var was: bool = shields_active
	shields_active = active
	if was != shields_active:
		weakness_changed.emit(not shields_active)


func is_boss_weak() -> bool:
	return not shields_active


func take_damage(amount: float) -> void:
	if shields_active:
		return
	super.take_damage(amount)


func _on_body_entered(body: Node) -> void:
	if shields_active:
		return
	super._on_body_entered(body)
