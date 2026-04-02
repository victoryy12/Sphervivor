<<<<<<< Updated upstream
extends CharacterBody3D

@export var speed = 10.0
@export var accel = 10.0

# Path to the player node - you can also use groups
@onready var player = get_tree().get_first_node_in_group("player")
=======
extends RigidBody3D

@export var speed = 20.0
@export var detection_range = 200000.0
@export var player_path: NodePath

var player = null
# You'll need a RayCast3D or ShapeCast3D as a child named "FloorCheck"
@onready var floor_check = $FloorCheck 

func _ready():
	if player_path:
		player = get_node(player_path)
>>>>>>> Stashed changes

func _physics_process(delta):
	if not player:
		return

<<<<<<< Updated upstream
	# 1. Calculate direction toward the player
	# We ignore the Y axis so the enemy doesn't tilt upward
	var direction = player.global_position - global_position
	direction.y = 0 
	direction = direction.normalized()

	# 2. Smoothly rotate to look at the player
	if direction != Vector3.ZERO:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)

	# 3. Handle Movement
	velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
	velocity.z = lerp(velocity.z, direction.z * speed, accel * delta)

	# Add gravity if the enemy isn't on the floor
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	move_and_slide()
=======
	var direction = player.global_transform.origin - global_transform.origin
	var distance = direction.length()

	# Only move if within range AND on the floor
	if distance < detection_range and floor_check.is_colliding():
		move_towards_player(direction.normalized(), delta)

func move_towards_player(dir, delta):
	# To roll toward a direction, we apply torque perpendicular to that direction
	# Rolling forward (Z) requires rotation around X
	# Rolling sideways (X) requires rotation around Z
	
	var torque_vector = Vector3(dir.z, 0, -dir.x) * speed
	apply_torque(torque_vector)
>>>>>>> Stashed changes
