extends Area3D

@export var speed := 10.0
@export var lifetime := 5.0
@export var damage := 200.0

var target: Node3D = null
var _time := 0.0
var forward_dir := Vector3.ZERO


func _ready() -> void:
	forward_dir = -global_transform.basis.z
	_find_nearest_enemy()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return

	if is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		global_position += dir * speed * delta
	else:
		_find_nearest_enemy()
		global_position += forward_dir * speed * delta


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
