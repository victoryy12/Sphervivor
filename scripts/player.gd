extends RigidBody3D

@export var rolling_force = 70.0
@export var jump_force = 150.0
@export var slam_speed = 5000.0
@export var player_health = 1000.0
@export var mouse_sensitivity := 0.002

var yaw := 0.0   # left/right
var pitch := 0.0 # up/down

func _ready() -> void:
	$CameraRig.top_level = true
	$touchingFloor.top_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		# clamp vertical look so you don’t flip
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
	
	
func _physics_process(delta: float) -> void:
	$CameraRig.global_transform.origin = global_transform.origin
	$touchingFloor.global_transform.origin = global_transform.origin

	death_plane() 
	player_movement(delta)	
	
	
func player_movement(delta):
	$CameraRig.rotation.y = yaw
	$CameraRig.rotation.x = pitch
	
	var onFloor =  $touchingFloor.is_colliding()
	var x_input = Input.get_axis("down", "up")
	var z_input = Input.get_axis("right", "left")
	
	var cam = $CameraRig
	
	# Get camera directions
	var forward = -cam.global_transform.basis.z
	var right = cam.global_transform.basis.x

	# Flatten so we don't move up/down
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction = (forward * z_input + right * x_input).normalized()

	if onFloor:
		angular_velocity.x -= direction.x * rolling_force * delta
		angular_velocity.z -= direction.z * rolling_force * delta
		#jump
		if Input.is_action_pressed("jump"):
			apply_central_impulse(Vector3.UP * jump_force)
			#reduces slam angular velocity
			angular_velocity.y /= 1.2

	if Input.is_action_pressed("slam") and !onFloor:
		apply_central_force(Vector3.DOWN * slam_speed)



#testing..going to make death function
func death_plane():
	var deathBarrierDepth = -25
	if global_position.y < deathBarrierDepth:
		get_tree().reload_current_scene()
