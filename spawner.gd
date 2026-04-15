extends Marker3D

@export var enemy_scenes: Array[PackedScene]
@export var max_per_type: Array[int]      # same size as enemy_scenes
@export var wave_size: int = 5
@export var time_between_spawns: float = 0.5
@export var time_between_waves: float = 5.0

@onready var spawn_point: Marker3D = $SpawnPoint

var current_counts: Array[int] = []

func _ready():
	# initialize counts
	current_counts.resize(enemy_scenes.size())
	for i in current_counts.size():
		current_counts[i] = 0

	start_waves()

func start_waves():
	while true:
		await spawn_wave()
		print("Wave complete")
		await get_tree().create_timer(time_between_waves).timeout

func spawn_wave():
	var spawned = 0

	while spawned < wave_size:
		await get_tree().create_timer(time_between_spawns).timeout

		var index = get_valid_enemy_index()
		if index == -1:
			print("All enemy types at max")
			return

		spawn_enemy(index)
		spawned += 1

func get_valid_enemy_index() -> int:
	var valid_indices = []

	for i in enemy_scenes.size():
		if current_counts[i] < max_per_type[i]:
			valid_indices.append(i)

	if valid_indices.is_empty():
		return -1

	return valid_indices.pick_random()

func spawn_enemy(index: int):
	var enemy = enemy_scenes[index].instantiate()
	get_tree().current_scene.add_child(enemy)

	enemy.global_position = spawn_point.global_position

	current_counts[index] += 1

	# when enemy dies or is removed
	enemy.tree_exited.connect(func():
		current_counts[index] -= 1
	)
	
