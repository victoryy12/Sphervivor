extends RigidBody3D

@onready var cam = $CameraRig

@export var level = 1
@export var curr_exp = 0
@export var exp_to_lvl = 100
signal leveled_up

@export var rolling_force = 1000.0
@export var jump_force = 70.0
@export var impact_mult = 450.0

@export var slam_speed = 5000.0
@export var slam_damage = 100
var slam_height = 0.0
var is_slamming := false
var was_in_air := false
var slam_on_cooldown = false

@export var max_hp = 1000.0
@export var curr_hp = 1000.0
@export var hp_regen = 1

@export var charge_power = 0.0
var charging = false 
var max_charge = 2500.0; var charge_speed = 25000

@export var mouse_sensitivity := 0.002

var yaw := 0.0   # left/right
var pitch := 0.0 # up/down

@onready var jump_sfx: AudioStreamPlayer3D = $JumpSFX
@onready var slam_sfx: AudioStreamPlayer3D = $SlamSFX

func _ready() -> void:
	cam.top_level = true
	$touchingFloor.top_level = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	health_regen()
	auto_fire()

	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		# clamp vertical look so you don’t flip
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
	
	charge_input(event)
	
	
func _physics_process(delta: float) -> void:
	cam.global_transform.origin = global_transform.origin
	$touchingFloor.global_transform.origin = global_transform.origin
	player_death() 
	player_movement(delta)

	
func player_movement(delta):
	var onFloor = $touchingFloor.is_colliding()

	cam.rotation.y = yaw
	cam.rotation.x = pitch

	var x_input = Input.get_axis("left", "right")
	var z_input = Input.get_axis("down", "up")

	var forward = -cam.global_transform.basis.z
	var right = cam.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction = (forward * z_input + right * x_input).normalized()

	if onFloor and direction != Vector3.ZERO:
		apply_central_force(direction * rolling_force)

		# Steering correction
		var horizontal_vel = Vector3(linear_velocity.x, 0, linear_velocity.z)
		var desired = direction * horizontal_vel.length()
		var steer = (desired - horizontal_vel) * 5.0
		apply_central_force(steer)
			
	if onFloor and Input.is_action_pressed("jump"):
		apply_central_impulse(Vector3.UP * jump_force)
		angular_velocity.y /= 1.2
		if jump_sfx and jump_sfx.stream:
			jump_sfx.pitch_scale = randf_range(0.97, 1.03)
			jump_sfx.play()
				
	slam(onFloor)
	
	#bullet time charge
	if charging:
		charge_power += charge_speed * delta
		charge_power = clamp(charge_power, 0, max_charge)
		linear_velocity *= 0.999


func bullet_time_launch():
	var direction = -cam.global_transform.basis.z
	direction =direction.normalized()
	apply_central_impulse(direction * charge_power)


func charge_input(event):
	if event.is_action_pressed("charge ball"):
		charging = true
		charge_power = 0.0
		Engine.time_scale = 0.2
	
	if event.is_action_released("charge ball"):
		bullet_time_launch()
		charging = false
		Engine.time_scale = 1.0
	
	
func _on_body_entered(body):
	if body.is_in_group("Enemies"):
		if int(linear_velocity.length()) < 10:
			take_damage(body.enemy_damage)


func slam_impact():
	var fall_distance = slam_height - global_position.y
	fall_distance = max(fall_distance, 0)
	
	if slam_sfx and slam_sfx.stream:
		slam_sfx.pitch_scale = randf_range(0.95, 1.05)
		slam_sfx.play()
	
	var damage = (slam_damage + fall_distance) * 5.0
	
	for body in $damageAura.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			body.take_damage(damage)
			
			var dir = (body.global_position - global_position).normalized()
			body.apply_impulse(Vector3.UP * 80 + dir * 50)


func slam(onFloor):
	if !onFloor:
		was_in_air = true
		
	if onFloor and was_in_air:
		if is_slamming:
			slam_impact()  
		is_slamming = false
		was_in_air = false
	
	if !onFloor:
		was_in_air = true
		if Input.is_action_pressed("slam"):
			is_slamming = true
			slam_height = global_position.y
			
			apply_central_force(Vector3.DOWN * slam_speed)


func deal_damage() -> float:
	return impact_mult
	
		
func take_damage(amount):
	curr_hp -= amount
	print("took damage:", amount)

func get_impact_damage() -> float:
	return linear_velocity.length() * impact_mult
	
	
func health_regen():
	while true:
		await get_tree().create_timer(0.1).timeout
		curr_hp += hp_regen
		curr_hp = min(curr_hp, max_hp)
	
		
func add_exp(amount):
	curr_exp += amount
	
	while curr_exp >= exp_to_lvl:
		curr_exp -= exp_to_lvl
		level_up()


func level_up() -> void:
	level += 1
	exp_to_lvl = int(exp_to_lvl * 1.2)
	max_hp += 100
	
	emit_signal("leveled_up")
	
		
func player_death():
	death_plane()
	if curr_hp <= 0:
		get_tree().reload_current_scene()
	
	
func death_plane():
	var deathBarrierDepth = -25
	if global_position.y < deathBarrierDepth:
		#set player spawn point and respawn with reduced hp
		take_damage(10)


@export var projectile_scene: PackedScene
@export var fire_rate := 3.0


func auto_fire():
	while true:
		await get_tree().create_timer(fire_rate).timeout
		spawn_projectile()


func spawn_projectile():
	var projectile = projectile_scene.instantiate()

	# Spawn slightly in front of player
	var forward = -global_transform.basis.z
	projectile.global_position = global_position + forward * 2.0

	get_tree().current_scene.add_child(projectile)
