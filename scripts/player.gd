extends RigidBody3D

@export var rolling_force = 40

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
		
