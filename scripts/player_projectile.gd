extends RigidBody3D

@export var speed := 10.0
@export var turn_speed := 5.0
@export var lifetime := 5.0
@export var damage := 200.0


var target: Node3D = null
var _time := 0.0


func _ready() -> void:
	# Start moving forward immediately if no target
	if target == null:
		linear_velocity = -global_transform.basis.z * speed
	else:
		_find_nearest_enemy()


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return


	if is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		linear_velocity = linear_velocity.lerp(dir * speed, turn_speed * delta)
	else:
		# Re-acquire or just fly straight
		_find_nearest_enemy()
		linear_velocity = linear_velocity.normalized() * speed


func _find_nearest_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("Enemies")
	var closest_dist := INF
	target = null

	for enemy in enemies:
		if enemy is Node3D:
			var d = global_position.distance_to(enemy.global_position)
			if d < closest_dist:
				closest_dist = d
				target = enemy


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		return 
		
	if body.is_in_group("BossShield"):
		queue_free()
		return
		
	if body.is_in_group("Enemies") and body.has_method("take_damage"):
		body.take_damage(damage)

		queue_free()
