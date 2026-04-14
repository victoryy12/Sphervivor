extends RigidBody3D

@export var speed = 10.0
@export var accel = 10.0
@export var enemy_damage = 100.0

@onready var player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	movement_tracking(delta)

func movement_tracking(delta):
	if not player:
		return
	
	var direction = player.global_position - global_position
	direction.y = 0

	if direction.length() > 0.001:
		direction = direction.normalized()
		
		# rotate toward player
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)

		# desired velocity
		var target_velocity = direction * speed
		
		# smooth acceleration
		linear_velocity.x = lerp(linear_velocity.x, target_velocity.x, accel * delta)
		linear_velocity.z = lerp(linear_velocity.z, target_velocity.z, accel * delta)
