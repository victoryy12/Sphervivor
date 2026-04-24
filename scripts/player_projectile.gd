extends Area3D

@export var speed: float = 10.0
@export var projectile_scene: PackedScene
@export var min_height: float = 0.5        # Floor clearance
@export var arc_height: float = 1.2        # How high the arc peaks
@export var turn_speed: float = 4.0  
@export var missile_knockback = 3.0      

var target: Node3D = null
var direction: Vector3 = Vector3.ZERO
var shooter: Node = null
var elapsed_time: float = 0.0
var start_position: Vector3

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	start_position = global_position
	find_closest_target()
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = -global_transform.basis.z
		projectile_life()

func projectile_life():
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	elapsed_time += delta

	# Smoothly steer toward target instead of locking direction at spawn
	if is_instance_valid(target):
		var desired = (target.global_position - global_position).normalized()
		direction = direction.lerp(desired, turn_speed * delta).normalized()

	global_position += direction * speed * delta

	# Arc: sine curve lifts the missile over its lifetime, then lets it fall
	var arc_offset = sin(elapsed_time * (PI / 3.0)) * arc_height
	global_position.y += arc_offset * delta

	# Hard floor clamp — prevents clipping terrain entirely
	if global_position.y < min_height:
		global_position.y = min_height
		direction.y = abs(direction.y)   # Bounce direction upward if it clips

	# Rotate the missile to always face its travel direction
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)

func find_closest_target() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemies")
	var closest_distance: float = INF
	for enemy in enemies:
		if enemy is Node3D:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_distance:
				closest_distance = dist
				target = enemy

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("BossShield"):
		queue_free()
		return
	if body.is_in_group("Enemies"):
		if shooter and shooter.has_method("apply_projectile_damage"):
			shooter.apply_projectile_damage(body)
			body.launch(global_position, missile_knockback)
		queue_free()
