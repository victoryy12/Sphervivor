extends Area3D

@export var speed: float = 10.0
@export var projectile_scene: PackedScene

var target: Node3D = null
var direction: Vector3 = Vector3.ZERO
var shooter: Node = null


func _ready() -> void:
	find_closest_target()

	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	else:
		direction = -global_transform.basis.z

	projectile_life()


func projectile_life():
	var lifetime = 3.0
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


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
	if body.is_in_group("BossShield"):
		queue_free()
		return

	if body.is_in_group("Enemies"):
		if shooter and shooter.has_method("apply_projectile_damage"):
			shooter.apply_projectile_damage(body)

		queue_free()
