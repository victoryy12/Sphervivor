extends RigidBody3D
@export var move_speed: float = 7.5
@export var acceleration: float = 12.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var turn_speed: float = 6.0
@export var detection_radius: float = 35.0
@export var stop_distance: float = 5.0
@export var wander_radius: float = 18.0
@export var wander_interval: float = 2.0
@export var player_path: NodePath
@export var rolling_force: float = 800.0
@export var ball_radius: float = 1.0
@export var attack_range: float = 8.0
@export var attack_cooldown: float = 2.5
@export var telegraph_time: float = 0.4
@export var charge_speed: float = 25.0
@export var charge_duration: float = 0.25
@export var charge_impulse: float = 40.0

var damage = 300.0
var _charge_left: float = 0.0
var _charge_dir: Vector3 = Vector3.ZERO
# In _physics_process, if _charge_left > 0:
#    _charge_left -= delta; if _charge_left <= 0: stop horizontal burst

var _move_dir: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _wander_target: Vector3 = Vector3.ZERO
var _attack_cd: float = 0.0
var _telegraph: float = 0.0
var _wants_attack: bool = false

@onready var _player: RigidBody3D = get_tree().get_first_node_in_group("player")
@onready var _floor_ray: RayCast3D = $FloorRay  # add RayCast3D child, point down

func _ready() -> void:
	_pick_new_wander_target()
	
	
func _physics_process(delta: float) -> void:
	var move_dir := Vector3.ZERO
	
	if move_dir.length() > 0.01:
		# Torque axis: roll around axis perpendicular to movement (in XZ plane)
		var torque_axis := Vector3.UP.cross(move_dir).normalized()
		apply_torque(torque_axis * rolling_force)
		
	var on_floor: bool = _floor_ray.is_colliding()
	var lv := linear_velocity
	
	if not on_floor:
		lv.y -= gravity * delta
	else:
		lv.y = 0.0
		
	var desired_dir := Vector3.ZERO
	
	if is_instance_valid(_player):
		var to_player := _player.global_position - global_position
		var flat_to_player := Vector3(to_player.x, 0.0, to_player.z)
		var dist := flat_to_player.length()
		
		if dist <= detection_radius and dist > stop_distance:
			desired_dir = flat_to_player.normalized()
			
	if desired_dir == Vector3.ZERO:
		_wander_timer -= delta
		
		if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 1.5:
			_pick_new_wander_target()
			
		var to_wander := _wander_target - global_position
		var flat_to_wander := Vector3(to_wander.x, 0.0, to_wander.z)
		if flat_to_wander.length() > 0.1:
			desired_dir = flat_to_wander.normalized()
			
	_move_dir = _move_dir.lerp(desired_dir, clamp(acceleration * delta, 0.0, 1.0))
	lv.x = _move_dir.x * move_speed
	lv.z = _move_dir.z * move_speed
	linear_velocity = lv
	
	if _move_dir.length() > 0.05:
		var target_y := atan2(_move_dir.x, _move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_y, clamp(turn_speed * delta, 0.0, 1.0))
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	
	if not is_instance_valid(_player):
		return
	
	var to_player := _player.global_position - global_position
	var flat := Vector3(to_player.x, 0.0, to_player.z)
	var dist := flat.length()

	if _wants_attack:
		_telegraph -= delta
		if _telegraph > 0.0:
			# Optional: slow down or stop moving while winding up
			_move_dir = Vector3.ZERO
			return  # or skip your normal chase/roll for this frame
			
		if _telegraph <= 0.0:
			_do_attack(flat.normalized())
			_wants_attack = false
			_attack_cd = attack_cooldown
	# In range: start telegraph (or attack immediately if you skip telegraph)
	if dist <= attack_range and dist > 0.5 and _attack_cd <= 0.0 and _telegraph <= 0.0:
		_telegraph = telegraph_time
		_wants_attack = true
		
		
func _pick_new_wander_target() -> void:
	_wander_timer = wander_interval
	var ang := randf() * TAU
	var r := randf_range(4.0, wander_radius)
	var offset := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	_wander_target = global_position + offset
	
	
func _do_attack(dir: Vector3) -> void:
	_charge_dir = dir
	_charge_left = charge_duration
	linear_velocity = Vector3(dir.x * charge_speed, linear_velocity.y, dir.z * charge_speed)
	
	
func _damage_player(amount: float) -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(amount)
# In _physics_process, if _charge_left > 0:
#    _charge_left -= delta; if _charge_left <= 0: stop horizontal burst
