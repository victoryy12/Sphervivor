extends CanvasLayer

@export var boss_group: StringName = &"Boss"
@export var boss_display_name: String = "ABSOLUTE SPHERE"

@onready var root: Control = $Root
@onready var name_label: Label = $Root/Name
@onready var bar: ProgressBar = $Root/Bar

var _boss: Node = null


func _ready() -> void:
	name_label.text = boss_display_name
	_set_visible(false)
	_try_bind_to_boss()


func _process(_delta: float) -> void:
	if not is_instance_valid(_boss):
		_try_bind_to_boss()


func _try_bind_to_boss() -> void:
	var candidate := get_tree().get_first_node_in_group(boss_group)
	if not is_instance_valid(candidate):
		_boss = null
		_set_visible(false)
		return
	if candidate == _boss:
		return
	if not candidate.has_signal("health_changed"):
		return

	_boss = candidate
	_boss.health_changed.connect(_on_boss_health_changed)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)

	# Initialize bar from current values if exposed.
	var max_hp := 100.0
	var curr_hp := 100.0
	if "max_hp" in _boss:
		max_hp = _boss.max_hp
	if "curr_hp" in _boss:
		curr_hp = _boss.curr_hp
	_on_boss_health_changed(curr_hp, max_hp)


func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	bar.min_value = 0.0
	bar.max_value = max_hp
	bar.value = current_hp
	_set_visible(current_hp > 0.0)


func _on_boss_died() -> void:
	_boss = null
	_set_visible(false)


func _set_visible(is_visible: bool) -> void:
	root.visible = is_visible
