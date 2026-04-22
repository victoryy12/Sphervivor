extends Node3D

var exp_amount := 20

@export var move_speed := 8.0
@export var accel := 20.0
@export var collect_distance := 0.8
@export var detect_radius := 6.0

var target: Node3D = null


func _physics_process(delta: float) -> void:
	if target == null:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var dist = global_position.distance_to(player.global_position)
			if dist <= detect_radius:
				target = player
		return

	var to_player = target.global_position - global_position
	var distance = to_player.length()

	if distance <= collect_distance:
		if target.has_method("add_exp"):
			target.add_exp(exp_amount)
		queue_free()
		return

	var dir = to_player / distance

	move_speed += accel * delta

	global_position += dir * move_speed * delta
