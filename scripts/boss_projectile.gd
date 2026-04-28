extends RigidBody3D

## Homing hazard spawned by the Absolute Sphere boss.

@export var speed := 14.0
@export var homing_accel := 28.0
@export var damage_to_player := 100.0
@export var max_hp := 1000.0
@export var lifetime := 10.0

var current_hp: float
var _lifetime_left: float


func _ready() -> void:
	current_hp = max_hp
	_lifetime_left = lifetime

	gravity_scale = 0.0
	linear_damp = 0.35
	angular_damp = 4.0
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

	add_to_group("BossProjectile")


func setup_after_spawn(_sphere_root: Node3D, boss_body: PhysicsBody3D) -> void:
	add_collision_exception_with(boss_body)
	for n in get_tree().get_nodes_in_group("BossShield"):
		if n is CollisionObject3D:
			add_collision_exception_with(n as CollisionObject3D)


func _physics_process(delta: float) -> void:
	_lifetime_left -= delta
	if _lifetime_left <= 0.0:
		queue_free()
		return

	var player: Node3D = get_tree().get_first_node_in_group("Player") as Node3D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	var to_player: Vector3 = player.global_position - global_position
	if to_player.length_squared() < 0.0001:
		return
	var dir: Vector3 = to_player.normalized()
	linear_velocity = linear_velocity.move_toward(dir * speed, homing_accel * delta)


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp -= amount
	if current_hp <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("take_damage"):
		body.take_damage(damage_to_player)
		queue_free()
