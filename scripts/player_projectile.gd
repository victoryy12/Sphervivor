extends Area3D

@export var speed: float = 10.0
@export var turn_speed: float = 5.0  
@export var damage: float = 250.0
@export var projectile_scene: PackedScene

var target: Node3D = null

func _ready() -> void:
	find_closest_target()
	projectile_life()


func projectile_life():
	var lifetime = 3.0
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	

func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var target_pos = target.global_position
		var target_transform = self.global_transform.looking_at(target_pos, Vector3.UP)
		self.global_transform = self.global_transform.interpolate_with(target_transform, turn_speed * delta)

	var forward_dir = -self.global_transform.basis.z
	global_position += forward_dir * speed * delta


func find_closest_target() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemies")
	var closest_distance: float = INF
	
	for enemy in enemies:
		if enemy is Node3D:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_distance:
				closest_distance = dist
				target = enemy


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Enemies"):
		body.take_damage(damage)
		queue_free() 
