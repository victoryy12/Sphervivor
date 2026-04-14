extends RigidBody3D

@export var speed = 4.0
@export var accel = 10.0
@export var enemy_damage = 100.0
@export var enemy_hp = 1000.0 #not sure how we're gonna deal with hp but this is for testing


@onready var player = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10
	#locks the rigidbody upright
	axis_lock_angular_x = true
	axis_lock_angular_z = true
	
	
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
	if body.is_in_group("Player"):
		take_damage(body.deal_damage())
		
		
func take_damage(amount):
	enemy_hp -= amount
	
	print("Enemy HP:", enemy_hp)

	if enemy_hp <= 0:
		die()


func deal_damage():
	return enemy_damage

		
func _on_hitbox_body_entered(body):
	if body.is_in_group("Player"):
		take_damage(body.deal_damage())
		
				
func die():
	queue_free() 
