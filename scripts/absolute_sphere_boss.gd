extends "res://scripts/enemy_ai_RB.gd"

## Chase tuning vs base enemy_ai_RB (4 / 10 / 10); boss is not scaled by spawner difficulty.
@export var boss_move_speed := 5.25
@export var boss_move_max_speed := 12.0
@export var boss_move_accel := 11.5

## Defaults to 5x DEFAULT_ENEMY_MAX_HP from enemy_ai_RB (tunable in the inspector).
@export var boss_max_hp: float = DEFAULT_ENEMY_MAX_HP * 100.0
## Damage per second to the player while inside the shield aura (shields up).
@export var shield_aura_dps: float = 100.0

signal weakness_changed(is_weak: bool)

## While true, damage from projectiles and contact is blocked (handled here and by ring colliders).
var shields_active: bool = true
## Filled by AbsoluteSphere (parent) each frame while vulnerable; used by the boss health bar.
var weak_time_remaining: float = 0.0

@onready var _shield_loop: AudioStreamPlayer3D = $ForceFieldLoop
@onready var _shield_down: AudioStreamPlayer3D = $ForceFieldDown
@onready var _shield_aura: MeshInstance3D = $ShieldAura
@onready var _shield_damage_area: Area3D = $"ShieldAura/ShieldDamageArea"

var _aura_material: StandardMaterial3D
var _aura_pulse_t: float = 0.0


func _ready() -> void:
	speed = boss_move_speed
	max_speed = boss_move_max_speed
	accel = boss_move_accel
	enemy_hp = boss_max_hp
	current_hp = boss_max_hp
	super._ready()
	_configure_shield_loop_stream()
	if is_instance_valid(_shield_aura):
		var surf: Material = _shield_aura.get_surface_override_material(0)
		if surf != null:
			var dup: Material = surf.duplicate()
			_shield_aura.set_surface_override_material(0, dup)
			_aura_material = dup as StandardMaterial3D
	_sync_shield_aura_visibility()
	call_deferred("_start_shield_loop_if_shielded")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not shields_active:
		return
	if not is_instance_valid(_shield_damage_area) or not _shield_damage_area.monitoring:
		return
	for body in _shield_damage_area.get_overlapping_bodies():
		if body.is_in_group("Player") and body.has_method("take_damage"):
			body.take_damage(shield_aura_dps * delta)


func _process(delta: float) -> void:
	if not shields_active or _aura_material == null:
		return
	if not is_instance_valid(_shield_aura) or not _shield_aura.visible:
		return
	_aura_pulse_t += delta
	var base: float = 1.35
	_aura_material.emission_energy_multiplier = base + 0.35 * sin(_aura_pulse_t * 2.6)


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
	_sync_shield_aura_visibility()


func _sync_shield_aura_visibility() -> void:
	if is_instance_valid(_shield_aura):
		_shield_aura.visible = shields_active
	if is_instance_valid(_shield_damage_area):
		_shield_damage_area.monitoring = shields_active


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
