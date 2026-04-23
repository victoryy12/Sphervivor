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
		"apply": func(player): player.rolling_force += 150
	}, {
		"name": "Rocket Jump",
		"desc": "Jump higher",
		"apply": func(player): player.jump_force += 15
	}, {
		"name": "slam",
		"desc": "increase slam damage and radius",
		"apply": func(player): player.slam_damage += 50
	}, {
		"name": "Slo-mo glasses",
		"desc": 'glasses that improves your launch',
		"apply": func(player): slow_mo_glassse(player)
	}, {
		"name": "Candy heart",
		"desc": 'Increases health and regen',
		"apply": func(player): candy_heart(player)
	}, {
		"name": "Automatic Missiles",
		"desc": 'Increases missile potency',
		"apply": func(player): automatic_missiles(player)
	}, {
		"name": "Spinning Jimmy",
		"desc": 'Increases spin attack potency',
		"apply": func(player): spinning_jimmy(player)
	}, {
		"name": "Aerobics Training",
		"desc": 'Increases engery',
		"apply": func(player): aerobics_training(player)
	}
]

func aerobics_training(player):
	player.max_energy += 1
	player.regen_time -= 0.05
	
func spinning_jimmy(player):
	player.spin_damage += 50
	player.spin_force += 10
	player.max_spin += 10
	player.spin_accel += 5
	
func automatic_missiles(player):
	player.projectile_count += 1
	player.projectile_damage *= 1.2
	
func candy_heart(player):
	player.hp_regen += 0.15
	player.max_hp += 200
	
func slow_mo_glassse(player):
	player.max_charge += 750
	player.charge_speed += 333


func refresh_upgrades():
	var allowed_refresh = 1
	$refreshButton.text = "str(allowed_refresh)"
	current_choices = get_random_upgrades()

	for i in range(len(upgrade_buttons)):
		upgrade_buttons[i].text = "%s\n%s" % [current_choices[i].name, current_choices[i].desc]
		upgrade_buttons[i].add_theme_constant_override("h_separation", 8)
	
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


func _on_refresh_button_pressed() -> void:
	refresh_upgrades()


func _update_upgrade_ui_scale() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var base_size: float = min(viewport_size.x, viewport_size.y)
	var font_size: int = int(clampf(base_size * 0.035, 16.0, 44.0))
	var min_height: float = clampf(base_size * 0.22, 160.0, 360.0)

	for button in upgrade_buttons:
		button.custom_minimum_size.y = min_height
		button.add_theme_font_size_override("font_size", font_size)
