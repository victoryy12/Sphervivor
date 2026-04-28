extends "res://scripts/enemy_ai_RB.gd"

## Chase tuning vs base enemy_ai_RB (4 / 10 / 10); boss is not scaled by spawner difficulty.
@export var boss_move_speed := 5.25
@export var boss_move_max_speed := 12.0
@export var boss_move_accel := 11.5

## Defaults to 5x DEFAULT_ENEMY_MAX_HP from enemy_ai_RB (tunable in the inspector).
@export var boss_max_hp: float = DEFAULT_ENEMY_MAX_HP * 100.0

signal weakness_changed(is_weak: bool)

## While true, damage from projectiles and contact is blocked (handled here and by ring colliders).
var shields_active: bool = true
## Filled by AbsoluteSphere (parent) each frame while vulnerable; used by the boss health bar.
var weak_time_remaining: float = 0.0

@onready var _shield_loop: AudioStreamPlayer3D = $ForceFieldLoop
@onready var _shield_down: AudioStreamPlayer3D = $ForceFieldDown


func _ready() -> void:
	speed = boss_move_speed
	max_speed = boss_move_max_speed
	accel = boss_move_accel
	enemy_hp = boss_max_hp
	current_hp = boss_max_hp
	super._ready()
	_configure_shield_loop_stream()
	call_deferred("_start_shield_loop_if_shielded")


func _configure_shield_loop_stream() -> void:
	if not _shield_loop or not _shield_loop.stream:
		return
	var st: AudioStream = _shield_loop.stream.duplicate()
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	_shield_loop.stream = st


func _start_shield_loop_if_shielded() -> void:
	if shields_active:
		_start_shield_loop()


func set_shields_active(active: bool) -> void:
	var was: bool = shields_active
	shields_active = active
	if was != shields_active:
		weakness_changed.emit(not shields_active)
		if shields_active:
			_start_shield_loop()
		else:
			_stop_shield_loop()
			if _shield_down and _shield_down.stream:
				_shield_down.play()


func _start_shield_loop() -> void:
	if not _shield_loop or not _shield_loop.stream:
		return
	if not _shield_loop.playing:
		_shield_loop.play()


func _stop_shield_loop() -> void:
	if _shield_loop and _shield_loop.playing:
		_shield_loop.stop()


func _stop_shield_audio() -> void:
	_stop_shield_loop()
	if _shield_down and _shield_down.playing:
		_shield_down.stop()


func die() -> void:
	_stop_shield_audio()
	var drop_pos := global_position
	var exp_drop := experience_drop.instantiate()
	get_tree().current_scene.add_child(exp_drop)
	exp_drop.global_position = drop_pos
	died.emit()
	var sphere_root: Node = get_parent()
	if sphere_root != null:
		sphere_root.queue_free()
	else:
		queue_free()


func is_boss_weak() -> bool:
	return not shields_active


func get_weak_time_remaining() -> float:
	return weak_time_remaining


func set_weak_time_remaining(s: float) -> void:
	weak_time_remaining = s


func take_damage(amount: float) -> void:
	if shields_active:
		return
	super.take_damage(amount)


func _on_body_entered(body: Node) -> void:
	if shields_active:
		return
	super._on_body_entered(body)
