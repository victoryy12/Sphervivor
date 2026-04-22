class_name BossRingDamageArea
extends Area3D

@export var damage: float = 75.0
@export var hit_cooldown_sec: float = 0.45

var _cooldown_left: float = 0.0


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _on_body_entered(body: Node) -> void:
	if _cooldown_left > 0.0:
		return
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_cooldown_left = hit_cooldown_sec
