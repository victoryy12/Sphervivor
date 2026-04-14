extends RigidBody3D

@export var enemy_damage = 200.0

func _ready() -> void:
	# Essential settings for RigidBody collision detection
	contact_monitor = true
	max_contacts_reported = 5
	# Keeps the spikes from moving when the ball hits them
	freeze = true 

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		print("Player hit spikes!")
		if body.has_method("take_damage"):
			body.take_damage(enemy_damage)

func spikes_deal_damage():
	return enemy_damage
