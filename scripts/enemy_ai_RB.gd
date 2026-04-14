extends RigidBody3D

@export var speed = 4.0
@export var accel = 10.0
@export var enemy_damage = 10.0
@export var enemy_hp = 1000.0 #not sure how we're gonna deal with hp but this is just for testing
@export var current_hp = 1000.0
@export var head_offset: Vector3 = Vector3(0, 2.0, 0)

signal health_changed(current_hp: float, max_hp: float)
signal died

@onready var player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	#locks the rigidbody upright
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	add_to_group("Enemies")
	
	current_hp = clamp(current_hp, 0.0, enemy_hp)
	health_changed.emit(current_hp, enemy_hp)
	
func _physics_process(delta):
	movement_tracking(delta)

func movement_tracking(delta):
	if not player:
		return
	
	var direction = player.global_position - global_position
	direction.y = 0

	if direction.length() > 0.001:
		direction = direction.normalized()
		
		# rotate toward player
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)

		# desired velocity
		var target_velocity = direction * speed
		
		# smooth acceleration
		linear_velocity.x = lerp(linear_velocity.x, target_velocity.x, accel * delta)
		linear_velocity.z = lerp(linear_velocity.z, target_velocity.z, accel * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("deal_damage"):
		take_damage(body.deal_damage())
		
func take_damage(amount):
	enemy_hp -= amount
	if amount <= 0.0:
		return
	
	current_hp = maxf(current_hp - amount, 0.0)
	health_changed.emit(current_hp, enemy_hp)
	print("Enemy HP:", current_hp)

	if current_hp <= 0:
		die()


func deal_damage():
	return enemy_damage

		
func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body.has_method("deal_damage"):
		take_damage(body.deal_damage())
		
				
func die():
	died.emit()
	queue_free() 
