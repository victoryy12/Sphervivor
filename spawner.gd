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

# Boss system
var boss_instance: Node = null
var boss_alive := false
var boss_dead_time := 0.0
var boss_has_spawned := false
var last_boss_time: float = 0.0
# enemy costs
var enemy_costs := {
	0: 1.0,
	1: 2.0,
	2: 3.5,
	3: 5.0
}

# ----------------------------
# READY
# ----------------------------
func _ready():
	print("SPAWNER READY")
	await wait_for_player()
	print("PLAYER FOUND:", player)

	current_difficulty = base_difficulty
	start_director()


# ----------------------------
# PLAYER FIND
# ----------------------------
func wait_for_player():
	while player == null:
		player = get_tree().get_first_node_in_group("player")
		await get_tree().process_frame

	print("PLAYER LOCKED:", player)


# ----------------------------
# MAIN LOOP
# ----------------------------
func start_director():
	print("DIRECTOR STARTED")

	var accumulator := 0.0

	while true:
		await get_tree().process_frame

		var tree := get_tree()
		if tree == null or not is_instance_valid(tree):
			return

		# HARD PAUSE / STATE BLOCK
		if tree.paused:
			continue

		if pause_menu != null and is_instance_valid(pause_menu) and pause_menu.game_paused:
			continue

		if player == null or !is_instance_valid(player):
			continue

		var delta := get_process_delta_time()
		accumulator += delta

		if accumulator < spawn_interval:
			continue

		accumulator = 0.0

		# difficulty scaling
		time_alive += spawn_interval
		current_difficulty = base_difficulty * pow(difficulty_growth, time_alive / 30.0)

		# boss logic
		if not boss_alive and time_alive - last_boss_time >= boss_interval_seconds:
			last_boss_time = time_alive
			spawn_boss()

		# enemy spawn
		spawn_from_budget()

		update_ui()

# ----------------------------
# ENEMY SPAWNING
# ----------------------------
func spawn_from_budget():
	var budget = current_difficulty
	var safety = 0

	while budget > 0.5 and safety < 100:
		safety += 1

		var index = pick_enemy_by_weight()

		if index == -1:
			break

		spawn_enemy(index)
		budget -= enemy_costs.get(index, 1.0)


func pick_enemy_by_weight() -> int:
	var weights := {
		0: 100,
		1: 25,
		2: 10,
		3: 5
	}

	var total := 0
	for i in enemy_scenes.size():
		total += weights.get(i, 1)

	var roll := randi() % total
	var running := 0

	for i in enemy_scenes.size():
		running += weights.get(i, 1)
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
	
	var difficulty_mult = get_difficulty_multiplier()

	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(difficulty_mult)


func get_difficulty_multiplier() -> float:
	return current_difficulty / base_difficulty * (1.0 + time_alive / 30.0)

# ----------------------------
# BOSS SYSTEM (FIXED RESPAWN)
# ----------------------------
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

	# boss death tracking
	boss_instance.tree_exited.connect(func():
		boss_alive = false
		boss_instance = null
		boss_dead_time = time_alive
	)


# ----------------------------
# SPAWN POSITION
# ----------------------------
func get_spawn_position() -> Vector3:
	var angle = randf() * TAU
	var distance = randf_range(min_spawn_radius, spawn_radius)

	var dir = Vector3(cos(angle), 0, sin(angle))

	var pos = player.global_position + dir * distance
	pos.y = player.global_position.y

	return pos


# ----------------------------
# UI
# ----------------------------
func update_ui():
	if wave_label:
		wave_label.text = "Time: " + str(int(time_alive)) + "s | Difficulty: " + str(int(current_difficulty))
