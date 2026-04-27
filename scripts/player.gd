extends RigidBody3D

@onready var cam = $CameraRig
@onready var _player_camera: Camera3D = $CameraRig/Camera3D

@export var level = 1
@export var curr_exp = 0
@export var exp_to_lvl = 100
signal leveled_up

@export var rolling_force = 350.0
@export var jump_force = 50.0
@export var impact_mult = 200.0

@export var max_energy = 5.0
@export var energy = max_energy
@export var regen_time := 0.25
@export var energy_regen = 0.1
var can_regen := true

@export var slam_speed = 5000.0
@export var slam_damage = 100
var slam_height = 0.0
var is_slamming := false
var was_in_air := false
var slam_on_cooldown = false

@export var max_hp = 1000.0
@export var curr_hp = 1000.0
@export var hp_regen = 5

@export var charge_power = 0.0
var charging = false 
var max_charge = 2500.0; var charge_speed = 25000
var _death_shown := false

@export var mouse_sensitivity := 0.002

var yaw := 0.0   # left/right
var pitch := 0.0 # up/down

@onready var jump_sfx: AudioStreamPlayer3D = $JumpSFX
@onready var slam_sfx: AudioStreamPlayer3D = $SlamSFX
@onready var level_up_sfx: AudioStreamPlayer3D = $LevelUpSFX

func _ready() -> void:
	add_to_group("player")
	cam.top_level = true
	$touchingFloor.top_level = true
	$spinAttack.top_level = true
	$spinAttack.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_sensitivity = GameSettings.mouse_sensitivity
	GameSettings.mouse_sensitivity_changed.connect(_on_mouse_sensitivity_changed)
	GameSettings.fov_changed.connect(_on_fov_changed)
	_on_fov_changed(GameSettings.fov_degrees)
	health_regen()
	energy_loop()
	

	
func _on_mouse_sensitivity_changed(v: float) -> void:
	mouse_sensitivity = v


func _on_fov_changed(degrees: float) -> void:
	if _player_camera:
		_player_camera.fov = degrees


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
	$spinAttack.global_transform.origin = global_transform.origin
	player_death() 
	player_movement(delta)
	spin_attack(delta)
	handle_projectile_fire(delta)

	
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
		var steer = (desired - horizontal_vel) * 8.0
		apply_central_force(steer)
	
	if onFloor and Input.is_action_pressed("jump"):
		apply_central_impulse(Vector3.UP * jump_force)
		angular_velocity.y /= 1.2
		if jump_sfx and jump_sfx.stream:
			jump_sfx.pitch_scale = randf_range(0.97, 1.03)
			jump_sfx.play()
				
	slam()
	
	#bullet time charge
	if charging:
		charge_power += charge_speed * delta
		charge_power = clamp(charge_power, 0, max_charge)
		linear_velocity *= 0.999


func bullet_time_launch():
	if energy <= 1:
		return

	var direction = -cam.global_transform.basis.z
	direction =direction.normalized()
	apply_central_impulse(direction * charge_power)
	use_energy(2)


func charge_input(event):
	if event.is_action_pressed("charge ball"):
		charging = true
		charge_power = 0.0
		Engine.time_scale = 0.2
	
	if event.is_action_released("charge ball"):
		bullet_time_launch()
		charging = false
		Engine.time_scale = 1.0


func slam_impact():
	var fall_distance = slam_height - global_position.y
	fall_distance = max(fall_distance, 0)
	
	if slam_sfx and slam_sfx.stream:
		slam_sfx.pitch_scale = randf_range(0.95, 1.05)
		slam_sfx.play()
	
	var damage = (slam_damage + fall_distance) * 5.0
	var launch_power = clamp(fall_distance * 20.0, 16.0, 12.0)
	
	for body in $damageAura.get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			body.take_damage(damage)
			
			body.launch(global_position, launch_power)


func slam():
	var onFloor = $touchingFloor.is_colliding()
	
	if !onFloor:
		was_in_air = true
		
	if onFloor and was_in_air:
		if is_slamming:
			slam_impact()  
		is_slamming = false
		was_in_air = false
	
	if !onFloor:
		was_in_air = true
		if Input.is_action_just_pressed("slam"):
			try_slam()
		if Input.is_action_pressed("slam"):
			apply_central_force(Vector3.DOWN * slam_speed)

func try_slam():
	if energy <= 0:
		return
	
	use_energy(1)
	is_slamming = true
	slam_height = global_position.y
	apply_central_force(Vector3.DOWN * slam_speed)

	

func use_energy(amount):
	energy -= amount
	energy = max(energy, 0)

	# Optional: pause regen briefly after use
	can_regen = false
	await get_tree().create_timer(regen_time).timeout
	can_regen = true


func energy_loop():
	while is_inside_tree():
		await get_tree().create_timer(regen_time).timeout

		if can_regen and energy < max_energy:
			energy += energy_regen
			energy = min(energy, max_energy)


func _on_body_entered(body):
	if body.is_in_group("Enemies"):
		if int(linear_velocity.length()) < 10:
			body.launch(global_position, 10.0)
			take_damage(body.enemy_damage)


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
	
	max_hp += 200
	energy = max_energy
	
	if level_up_sfx and level_up_sfx.stream:
		level_up_sfx.pitch_scale = randf_range(0.97, 1.03)
		level_up_sfx.play()
	emit_signal("leveled_up")
	
		
func player_death():
	death_plane()
	if curr_hp <= 0 and not _death_shown:
		_death_shown = true
		var dm: Node = get_node_or_null("gui/death_menu")
		if dm and dm.has_method("open"):
			dm.open()
		else:
			get_tree().reload_current_scene()
	
	
func death_plane():
	var deathBarrierDepth = -25
	if global_position.y < deathBarrierDepth:
		#set player spawn point and respawn with reduced hp
		take_damage(10)
		
			
@export var projectile_scene: PackedScene
@export var fire_rate := 1.0
@export var projectile_count = 1
var fire_timer := 0.0

func handle_projectile_fire(delta: float) -> void:
	if projectile_scene == null:
		return

	fire_timer += delta
	if fire_timer >= fire_rate:
		fire_timer = 0.0
		spawn_projectile()


func spawn_projectile() -> void:
	for i in projectile_count:
		var p = projectile_scene.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		
		#disables collision on player and camerarig
		p.add_collision_exception_with(self)
		
		p.global_transform.basis = cam.global_transform.basis


@export var spin_force := 10.0
@export var max_spin := 50.0
@export var spin_accel := 20.0
@export var spin_damage := 100.0
@export var spin_knockback := 1.0
@export var spin_initial_energy = 0.5
var spinning := false
var spin_cooldown := false


func spin_attack(delta):
	if energy <= 0:
		spinning = false
		$spinAttack.visible = false
		angular_velocity.y = lerp(angular_velocity.y, 0.0, 5.0 * delta)
		return
		
	if Input.is_action_just_pressed("spin"):
		use_energy(spin_initial_energy)
		
	if Input.is_action_pressed("spin"):
		use_energy(0.01)
		spinning = true

		$spinAttack.visible = true

		# rotate hitbox visually (optional)
		$spinAttack.rotate_y(angular_velocity.y * delta)

		angular_velocity.y += spin_accel * delta
		angular_velocity.y = clamp(angular_velocity.y, -max_spin, max_spin)

	elif Input.is_action_just_released("spin"):
		spinning = false
		$spinAttack.visible = false

		angular_velocity.y = lerp(angular_velocity.y, 0.0, 5.0 * delta)



func _on_spin_attack_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemies"):
		if Input.is_action_pressed("spin"):
			body.launch(global_position, spin_knockback)
		
	if body.is_in_group("Enemies") and body.has_method("take_damage"):
		body.take_damage(spin_damage)
