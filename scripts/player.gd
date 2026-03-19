extends RigidBody3D

@export var player_speed: float = 20.0
@export var jump_force: float = 8.0
@export var max_speed: float = 10.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var dir = Vector3.ZERO
	
	if Input.is_action_pressed("up"):
		dir += basis.z
	if Input.is_action_pressed("down"):
		dir -= basis.z
	if Input.is_action_pressed("left"):
		dir += basis.x
	if Input.is_action_pressed("right"):
		dir -= basis.x
	
	if dir != Vector3.ZERO:
		apply_impulse(dir.normalized() * player_speed * delta)
	
	if Input.is_action_just_pressed("jump"):
		apply_impulse(Vector3.UP * player_speed)
