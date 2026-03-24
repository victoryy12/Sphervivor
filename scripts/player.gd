extends RigidBody3D

@export var rolling_force = 40
@export var jump_force = 100

func _ready() -> void:
	$CameraRig.top_level = true
	
func _physics_process(delta: float) -> void:
	$CameraRig.global_transform.origin = global_transform.origin 
	
	if Input.is_action_pressed("up"):
		angular_velocity.x -= rolling_force * delta
	elif Input.is_action_pressed("down"):
		angular_velocity.x += rolling_force * delta
	if Input.is_action_pressed("left"):
		angular_velocity.z += rolling_force * delta
	elif Input.is_action_pressed("right"):
		angular_velocity.z -= rolling_force * delta
		
	if Input.is_action_pressed("jump"):
		apply_central_impulse(Vector3.UP * jump_force)
	if Input.is_action_pressed("slam"):
		apply_central_force(Vector3.DOWN * 10000)
	
