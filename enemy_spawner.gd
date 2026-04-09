extends Marker3D

@export var enemy_scene: PackedScene
@onready var timer = $Timer
@onready var spawn_point = $SpawnPoint   # rename node

func _ready():
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(enemy)
		enemy.global_position = spawn_point.global_position
