extends RigidBody3D

## Baseline for balance (basic / advanced RigidBody enemies and multiplier-based bosses).
const DEFAULT_ENEMY_MAX_HP := 1000.0

@export var speed = 4.0
@export var max_speed = 10.0
@export var accel = 10.0

@export var enemy_damage = 100.0
@export var enemy_hp: float = DEFAULT_ENEMY_MAX_HP
@export var current_hp: float = DEFAULT_ENEMY_MAX_HP
@export var head_offset: Vector3 = Vector3(0, 2.0, 0)
@export var hit_sound: AudioStream
@export var attack_sound: AudioStream

@onready var hit_sfx = get_node_or_null("HitsSFX") as AudioStreamPlayer3D
@onready var attack_sfx = get_node_or_null("AttacksSFX") as AudioStreamPlayer3D

var experience_drop = preload("res://experience_point.tscn")

var knockback_timer := 0.0
@export var knockback_duration := 0.25
# Compatibility aliases for UI/scripts expecting max_hp/curr_hp names.
var max_hp: float:
	get:
		return enemy_hp

var curr_hp: float:
	get:
		return current_hp

signal health_changed(current_hp: float, max_hp: float)
signal died

@onready var player = get_tree().get_first_node_in_group("Player")


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	#locks the rigidbody upright
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	add_to_group("Enemies")
	
	current_hp = clamp(current_hp, 0.0, enemy_hp)
	health_changed.emit(current_hp, max_hp)

	_setup_sfx()
	
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		knockback_timer -= delta
		return
		
	movement_tracking(delta)
	linear_velocity.y = min(linear_velocity.y, 0.0)
	

func movement_tracking(delta: float) -> void:
	if not player:
		return

	var direction = player.global_position - global_position
	direction.y = 0

	if direction.length() < 0.001:
		return

	direction = direction.normalized()

	# rotate toward player
	var target_rotation = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)

	var target_velocity = direction * speed

	# keep Y velocity untouched (VERY IMPORTANT)
	var new_velocity = linear_velocity
	new_velocity.x = lerp(linear_velocity.x, target_velocity.x, accel * delta)
	new_velocity.z = lerp(linear_velocity.z, target_velocity.z, accel * delta)

	linear_velocity = new_velocity


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("deal_damage"):
		_play_attack_sfx()
		take_damage(body.deal_damage())
		
func take_damage(amount) -> void:
	if amount <= 0.0:
		return

	_play_hit_sfx()
	
	current_hp = maxf(current_hp - amount, 0.0)
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()


func deal_damage(from_position) -> float:
	_play_attack_sfx()
	return enemy_damage


func launch(from_position: Vector3, force: float, upward_bias: float = 0.4) -> void:
	var dir = (global_position - from_position).normalized()
	dir.y = upward_bias
	dir = dir.normalized()

	apply_impulse(dir * force)
	
	knockback_timer = knockback_duration
		

func apply_difficulty(mult: float) -> void:
	enemy_hp *= mult
	current_hp = enemy_hp
	
	enemy_damage *= pow(mult, 0.8) # softer scaling
	speed = lerp(speed, max_speed, 0.1 * (mult - 1.0))
	
	
func die():
	var exp = experience_drop.instantiate()
	get_tree().current_scene.add_child(exp)
	exp.global_position = global_position

	died.emit()
	queue_free() 


func _setup_sfx() -> void:
	if not hit_sfx:
		push_warning("Missing child node 'HitsSFX' on enemy.")
	elif hit_sound:
		# Only overwrite node stream if an exported sound was provided.
		hit_sfx.stream = hit_sound

	if not attack_sfx:
		push_warning("Missing child node 'AttacksSFX' on enemy.")
	elif attack_sound:
		# Only overwrite node stream if an exported sound was provided.
		attack_sfx.stream = attack_sound


func _play_hit_sfx() -> void:
	if hit_sfx and hit_sfx.stream:
		hit_sfx.pitch_scale = randf_range(0.95, 1.05)
		hit_sfx.play()


func _play_attack_sfx() -> void:
	if attack_sfx and attack_sfx.stream:
		attack_sfx.pitch_scale = randf_range(0.95, 1.05)
		attack_sfx.play()


func _on_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.
