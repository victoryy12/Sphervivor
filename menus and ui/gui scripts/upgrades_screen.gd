extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
@onready var speedometer: Label = get_parent().get_node_or_null("userInterface/speedometer")
@onready var upgrade_buttons: Array[Button] = [
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade1,
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade2,
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade3
]
var current_choices = []	
var upgrades_open = false

var upgrades = [
	{
		"name": "Rolling Greese",
		"desc": "roll faster",
		"apply": func(player): player.rolling_force += 10
	}, {
		"name": "Rocket Jump",
		"desc": "Jump higher",
		"apply": func(player): player.jump_force += 10
	}, {
		"name": "Wumbo beam",
		"desc": "increase your mass",
		"apply": func(player): player.jump_force += 10
	}, {
		"name": "Slo-mo glasses",
		"desc": 'Press and hold the "E" key to use a bullet-time ability',
		"apply": func(player): slow_mo_glassse(player)
	}, {
		"name": "Candy heart",
		"desc": 'Increases health regen',
		"apply": func(player): player.hp_regen += 0.15
	}
]


func slow_mo_glassse(player):
	player.max_charge += 750
	player.charge_speed += 333
	
	
func showUpgrades():
	upgrades_open = !upgrades_open
	get_tree().paused = upgrades_open
	self.visible = upgrades_open
	if speedometer:
		speedometer.visible = !upgrades_open
	
	if upgrades_open:
		current_choices = get_random_upgrades()

		for i in range(len(upgrade_buttons)):
			upgrade_buttons[i].text = "%s\n%s" % [current_choices[i].name, current_choices[i].desc]
			# Give the text breathing room while keeping it in the upper part of each card.
			upgrade_buttons[i].add_theme_constant_override("h_separation", 8)

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	
func get_random_upgrades():
	var copy = upgrades.duplicate()
	copy.shuffle()
	return copy.slice(0, 3)
	
	
func applyUpgrade(index): 
	var upgrade = current_choices[index]  
	if player_stats: 
		upgrade.apply.call(player_stats)  
		showUpgrades()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shop test"):
		showUpgrades()
		
		
func _ready() -> void:
	self.visible = false
	get_viewport().size_changed.connect(_update_upgrade_ui_scale)
	_update_upgrade_ui_scale()
	
	if player_stats:
		player_stats.connect("leveled_up", Callable(self, "showUpgrades"))
	
	
func _process(_delta: float) -> void:
	pass
		
			
func _on_upgrade_1_pressed() -> void:
	applyUpgrade(0)
	print(current_choices[0])


func _on_upgrade_2_pressed() -> void:
	applyUpgrade(1)
	print(current_choices[1])


func _on_upgrade_3_pressed() -> void:
	applyUpgrade(2)
	print(current_choices[2])


func _update_upgrade_ui_scale() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var base_size: float = min(viewport_size.x, viewport_size.y)
	var font_size: int = int(clampf(base_size * 0.035, 16.0, 44.0))
	var min_height: float = clampf(base_size * 0.22, 160.0, 360.0)

	for button in upgrade_buttons:
		button.custom_minimum_size.y = min_height
		button.add_theme_font_size_override("font_size", font_size)
