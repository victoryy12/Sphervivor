extends Marker3D

@export var enemy_scenes: Array[PackedScene]

@export var base_difficulty: float = 10.0
@export var difficulty_growth: float = 1.15

@export var spawn_interval: float = 0.6

@export var boss_scene: PackedScene
@export var boss_interval_seconds: float = 60.0

@export var min_spawn_radius: float = 10.0
@export var spawn_radius: float = 25.0

@export var pause_menu: CanvasLayer

@onready var wave_label: Label = get_tree().current_scene.find_child("WaveLabel", true, false)

var player: Node3D
var time_alive: float = 0.0
var current_difficulty: float = 0.0
var last_boss_time: float = 0.0

var boss_instance: Node = null
var boss_alive := false

var enemy_costs := {
	0: 1.0,
	1: 2.0,
	2: 3.5,
	3: 5.0
}


func _ready():
	print("SPAWNER READY")
	await wait_for_player()
	print("PLAYER FOUND:", player)

	current_difficulty = base_difficulty
	start_director()


func wait_for_player():
	while player == null:
		print("SEARCHING FOR PLAYER...")
		player = get_tree().get_first_node_in_group("player")
		await get_tree().process_frame

	print("PLAYER LOCKED:", player)


func start_director():
	print("DIRECTOR STARTED")

	var accumulator := 0.0

	while true:
		await get_tree().process_frame

		# HARD GLOBAL GAME STATE GATE
		if GameState.state != GameState.State.PLAY:
			continue

		if player == null:
			continue

		var delta := get_process_delta_time()
		accumulator += delta

		if accumulator < spawn_interval:
			continue

		accumulator = 0.0

		# game progression
		time_alive += spawn_interval

		current_difficulty = base_difficulty * pow(difficulty_growth, time_alive / 30.0)

		# boss logic
		if not boss_alive and time_alive - last_boss_time >= boss_interval_seconds:
			last_boss_time = time_alive
			spawn_boss()

		# enemy spawning
		spawn_from_budget()

		# UI update
		update_ui()


func spawn_from_budget():
	var budget = current_difficulty
	var safety = 0

	while budget > 0.5 and safety < 100:
		safety += 1

		var index = pick_enemy_by_cost(budget)

		if index == -1:
			break

		spawn_enemy(index)
		budget -= enemy_costs.get(index, 1.0)


func pick_enemy_by_cost(_budget: float) -> int:
	var t := time_alive

	# dynamic weights based on time
	var weights := {
		0: 100,
		1: clamp(10 + t * 1.5, 10, 80),
		2: clamp(t * 0.8, 0, 60),
		3: clamp(t * 0.4, 0, 40)
	}

	var total_weight := 0

	for i in enemy_scenes.size():
		total_weight += int(weights.get(i, 1))

	var roll := randi() % total_weight
	var running := 0

	for i in enemy_scenes.size():
		running += int(weights.get(i, 1))
		if roll < running:
			return i

	return 0

func spawn_enemy(index: int):
	if index < 0 or index >= enemy_scenes.size():
		return

	var scene = enemy_scenes[index]
	if scene == null:
		return

	var enemy = scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	enemy.global_position = get_spawn_position()


func spawn_boss():
	if boss_scene == null or player == null:
		return

	if boss_instance != null and is_instance_valid(boss_instance):
		return

	boss_alive = true

	boss_instance = boss_scene.instantiate()
	get_tree().current_scene.add_child(boss_instance)

	var angle = randf() * TAU
	var distance = spawn_radius * 1.6
	var offset = Vector3(cos(angle), 0, sin(angle)) * distance

	boss_instance.global_position = player.global_position + offset

	if boss_instance.has_method("set_wave"):
		boss_instance.set_wave(time_alive)

	boss_instance.tree_exited.connect(func():
		boss_alive = false
		boss_instance = null
	)


func get_spawn_position() -> Vector3:
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_radius, spawn_radius)

	var dir = Vector3(cos(angle), 0, sin(angle))
	var pos = player.global_position + dir * distance
	pos.y = player.global_position.y

	return pos


func update_ui():
	if wave_label:
		wave_label.text = "Time: " + str(int(time_alive)) + "s | Difficulty: " + str(int(current_difficulty))
