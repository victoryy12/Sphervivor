extends Control

@onready var bar: ProgressBar = $Bar
@onready var player = get_parent().get_parent()
var enemy_bars: Dictionary = {}
var tracked_enemies: Array = []

const ENEMY_GROUP := "Enemies"
const BAR_SIZE := Vector2(72, 8)
const SCREEN_OFFSET := Vector2(36, 22)
const DEFAULT_HEAD_OFFSET := Vector3(0.0, 2.2, 0.0)
const SHOW_DISTANCE := 20.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_register_existing_enemies()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_track_new_enemies()
	_update_enemy_bars()

func set_health(current_hp: float, max_hp: float) -> void:
	bar.max_value = max_hp
	bar.value = current_hp
	
	
func _register_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		_try_register_enemy(enemy)


func _track_new_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not tracked_enemies.has(enemy):
			_try_register_enemy(enemy)


func _try_register_enemy(enemy: Node) -> void:
	if enemy == null:
		return
	if enemy_bars.has(enemy):
		return
	if not enemy.has_signal("health_changed"):
		return

	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.custom_minimum_size = BAR_SIZE
	bar.size = BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	enemy_bars[enemy] = bar
	tracked_enemies.append(enemy)

	enemy.health_changed.connect(Callable(self, "_on_enemy_health_changed").bind(enemy))
	if enemy.has_signal("died"):
		enemy.died.connect(Callable(self, "_on_enemy_died").bind(enemy))

	var max_hp: float = 100.0
	var curr_hp: float = 100.0
	if "max_hp" in enemy:
		max_hp = enemy.max_hp
	if "curr_hp" in enemy:
		curr_hp = enemy.curr_hp
	_on_enemy_health_changed(curr_hp, max_hp, enemy)


func _on_enemy_health_changed(current_hp: float, max_hp: float, enemy: Node) -> void:
	if not enemy_bars.has(enemy):
		return
	var bar: ProgressBar = enemy_bars[enemy]
	bar.max_value = max_hp
	bar.value = current_hp
	bar.visible = current_hp > 0.0


func _on_enemy_died(enemy: Node) -> void:
	_remove_enemy_bar(enemy)


func _remove_enemy_bar(enemy: Node) -> void:
	if not enemy_bars.has(enemy):
		return
	var bar: ProgressBar = enemy_bars[enemy]
	if is_instance_valid(bar):
		bar.queue_free()
	enemy_bars.erase(enemy)
	tracked_enemies.erase(enemy)


func _update_enemy_bars() -> void:
	var cam := _get_active_camera()
	if cam == null:
		return

	var to_remove: Array = []
	for enemy in enemy_bars.keys():
		if not is_instance_valid(enemy):
			to_remove.append(enemy)
			continue

		var bar: ProgressBar = enemy_bars[enemy]
		#creates a show distance for bars
		if player and enemy.global_position.distance_to(player.global_position) > SHOW_DISTANCE:
			bar.visible = false
			continue
			
		var world_pos: Vector3 = enemy.global_position + _enemy_head_offset(enemy)
		if cam.is_position_behind(world_pos):
			bar.visible = false
			continue

		var screen_pos: Vector2 = cam.unproject_position(world_pos)
		bar.position = screen_pos - SCREEN_OFFSET
		if bar.value > 0.0:
			bar.visible = true

	for enemy in to_remove:
		_remove_enemy_bar(enemy)


func _enemy_head_offset(enemy: Node) -> Vector3:
	if "head_offset" in enemy:
		return enemy.head_offset
	return DEFAULT_HEAD_OFFSET


func _get_active_camera() -> Camera3D:
	return get_viewport().get_camera_3d()
