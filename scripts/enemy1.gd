extends CharacterBody3D

@export var speed = 4.0
@export var accel = 10.0

@onready var player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	movement_tracking(delta)

func movement_tracking(delta):
	if not player:
		return

	var direction = player.global_position - global_position
	direction.y = 0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)

	velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()
