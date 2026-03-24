extends RigidBody3D

@export var rolling_force = 40
@export var jump_force = 150

func _ready() -> void:
	$CameraRig.top_level = true
	$touchingFloor.top_level = true
	
func _physics_process(delta: float) -> void:
	$CameraRig.global_transform.origin = global_transform.origin
	$touchingFloor.global_transform.origin = global_transform.origin

	#death plane (add death screen and death function at some point)
	var deathBarrierDepth = -25
	if global_position.y < deathBarrierDepth:
		get_tree().reload_current_scene()

	#movement 
	var onFloor =  $touchingFloor.is_colliding()
	#get some bugs when rolling while in the air
	if Input.is_action_pressed("up") and onFloor:
		angular_velocity.x -= rolling_force * delta
	elif Input.is_action_pressed("down") and onFloor:
		angular_velocity.x += rolling_force * delta
	if Input.is_action_pressed("left") and onFloor:
		angular_velocity.z += rolling_force * delta
	elif Input.is_action_pressed("right") and onFloor:
		angular_velocity.z -= rolling_force * delta
		
	if Input.is_action_pressed("jump") and onFloor:
		apply_central_impulse(Vector3.UP * jump_force)
	if Input.is_action_pressed("slam") and !onFloor:
		angular_velocity.y -= rolling_force * delta
		apply_central_force(Vector3.DOWN * 10000)
	
