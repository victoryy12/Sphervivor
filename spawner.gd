extends Marker3D

@export var enemy_scenes: Array[PackedScene]
@export var unlock_waves: Array[int]
@export var max_per_type: Array[int]

@export var wave_size: int = 5
@export var time_between_spawns: float = 0.5
@export var time_between_waves: float = 5.0

# Spawn around player
@export var spawn_radius: float = 15.0
@export var min_spawn_radius: float = 10.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var wave_label: Label = get_tree().current_scene.get_node("CanvasLayer/WaveLabel")

var current_counts: Array[int] = []
var wave: int = 1


func _ready():
	# Initialize counts
	current_counts.resize(enemy_scenes.size())
	for i in current_counts.size():
		current_counts[i] = 0

	start_waves()


func start_waves():
	while true:
		update_wave_ui()
		print("Wave:", wave)

		# Show unlock messages
		for i in enemy_scenes.size():
			if wave == unlock_waves[i]:
				print("Unlocked:", enemy_scenes[i].resource_path)

		await spawn_wave()

		wave += 1
		await get_tree().create_timer(time_between_waves).timeout


func spawn_wave():
	var spawned = 0

	while spawned < wave_size:
		await get_tree().create_timer(time_between_spawns).timeout

		var index = get_valid_enemy_index()
		if index == -1:
			print("No valid enemies available")
			return

		spawn_enemy(index)
		spawned += 1


func get_valid_enemy_index() -> int:
	var valid_indices = []

	for i in enemy_scenes.size():
		if wave >= unlock_waves[i] and current_counts[i] < max_per_type[i]:
			valid_indices.append(i)

	if valid_indices.is_empty():
		return -1

	return valid_indices.pick_random()


func spawn_enemy(index: int):
	var enemy = enemy_scenes[index].instantiate()
	get_tree().current_scene.add_child(enemy)

	# Spawn around player
	var pos = get_random_position_around_player()
	enemy.global_position = pos

	# Scale with wave
	if enemy.has_method("set_wave"):
		enemy.set_wave(wave)

	current_counts[index] += 1
	enemy.tree_exited.connect(func():
		current_counts[index] -= 1
	)


func get_random_position_around_player() -> Vector3:
	if not player:
		return global_position

	var angle = randf() * TAU
	var distance = randf_range(min_spawn_radius, spawn_radius)

	var offset = Vector3(
		cos(angle) * distance,
		0,
		sin(angle) * distance
	)

	return player.global_position + offset


func update_wave_ui():
	get_tree().current_scene.get_node("CanvasLayer/WaveLabel")
	if wave_label:
		wave_label.text = "Wave: " + str(wave)
