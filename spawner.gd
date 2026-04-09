extends Marker3D

@export var enemy_scene: PackedScene
@export var spawn_rate: float = 2.0
@export var max_enemies: int = 10

var current_enemies = 0

func _ready():
	spawn_loop()

func spawn_loop():
	while true:
		await get_tree().create_timer(spawn_rate).timeout
		
		if current_enemies < max_enemies:
			spawn_enemy()
func spawn_enemy():
	var enemy = snow_man.instantiate()
	
	enemy.global
