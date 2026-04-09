extends Marker3D

@export var enemy_scene: PackedScene

@onready var timer: Timer = $Timer
@onready var spawn_point: Marker3D = $SpawnPoint

func _ready():
	if enemy_scene == null:
		push_error("Enemy scene not assigned!")
		return

	# Set timer to 3 seconds
	timer.wait_time = 3.0
	timer.one_shot = false
	timer.autostart = true

	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	enemy.global_position = spawn_point.global_position

	print("Enemy spawned")  # DEBUG
