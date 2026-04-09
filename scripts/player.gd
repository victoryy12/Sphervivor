extends RigidBody3D

@onready var cam = $CameraRig
@onready var arrow = $arrow

@export var rolling_force = 30.0
@export var jump_force = 150.0
@export var slam_speed = 5000.0
@export var player_health = 1000.0
@export var charge_power = 0.0
var charging = false 
var max_charge = 5000.0; var charge_speed = 25000

@export var mouse_sensitivity := 0.002

var yaw := 0.0   # left/right
var pitch := 0.0 # up/down

func _ready() -> void:
	cam.top_level = true
	arrow.top_level = true
	$touchingFloor.top_level = true
	arrow.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		# clamp vertical look so you don’t flip
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
	
	charge_input(event)

func charge_input(event):
	if event.is_action_pressed("charge ball"):
		arrow.visible = true
		charging = true
		charge_power = 0.0
		Engine.time_scale = 0.2
	
	if event.is_action_released("charge ball"):
		arrow.visible = false
		bullet_time_launch()
		charging = false
		Engine.time_scale = 1.0
	
	
func _physics_process(delta: float) -> void:
	cam.global_transform.origin = global_transform.origin
	$touchingFloor.global_transform.origin = global_transform.origin
	arrow.global_transform.origin = global_transform.origin
	player_death() 
	player_movement(delta)
	
	
func player_movement(delta):
	cam.rotation.y = yaw
	cam.rotation.x = pitch
	
	var onFloor =  $touchingFloor.is_colliding()
	var x_input = Input.get_axis("down", "up")
	var z_input = Input.get_axis("right", "left")
	# Get camera directions
	var forward = -cam.global_transform.basis.z
	var right = cam.global_transform.basis.x

	# Flatten so we don't move up/down
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var direction = (forward * z_input + right * x_input).normalized()
	var move_velocity = direction * rolling_force
	
	if onFloor:
		angular_velocity.x -= direction.x * rolling_force * delta
		angular_velocity.z -= direction.z * rolling_force * delta
		apply_central_impulse(move_velocity * delta)
		
		if Input.is_action_pressed("jump"):
			apply_central_impulse(Vector3.UP * jump_force)
			#reduces slam angular velocity
			angular_velocity.y /= 1.2

	if Input.is_action_pressed("slam") and !onFloor:
		apply_central_force(Vector3.DOWN * slam_speed)
	#bullet time charge
	if charging:
		var scale_amount = lerp(0.5, 5.0, charge_power / max_charge)
		arrow.look_at(global_position + direction, Vector3.UP)
		arrow.scale = Vector3(scale_amount, scale_amount, scale_amount)
		charge_power += charge_speed * delta
		charge_power = clamp(charge_power, 0, max_charge)
		print(charge_power)


func bullet_time_launch():
	var direction = -cam.global_transform.basis.z
	direction =direction.normalized()
	apply_central_impulse(direction * charge_power)
	
	
func player_death():
	death_plane()
	

func death_plane():
	var deathBarrierDepth = -25
	if global_position.y < deathBarrierDepth:
		get_tree().reload_current_scene()
