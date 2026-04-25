extends CanvasLayer

const CANDY_HEART_ICON: Texture2D = preload("res://assets/candy-heart.png")
const MISSILES_ICON: Texture2D = preload("res://assets/missiles.png")
const SPINNING_JIMMY_ICON: Texture2D = preload("res://assets/spinning-wings.png")
const ROCKET_JUMP_ICON: Texture2D = preload("res://assets/rocket-jump.png")
const ROLLING_GREASE_ICON: Texture2D = preload("res://assets/rolling-grease.png")
const SLAM_ICON: Texture2D = preload("res://assets/slam.png")
const SLO_MO_GLASSES_ICON: Texture2D = preload("res://assets/slo-mo-glasses.png")
const ENERGY_ICON: Texture2D = preload("res://assets/energy2.png")

@onready var player_stats = get_parent().get_parent()
@onready var speedometer: Label = get_parent().get_node_or_null("userInterface/speedometer")
@onready var upgrade_buttons: Array[Button] = [
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade1,
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade2,
	$CenterContainer/VBoxContainer/HBoxContainer/upgrade3
]
@onready var _center_margin: MarginContainer = $CenterContainer
@onready var _main_vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var _level_banner: TextureRect = $CenterContainer/VBoxContainer/LevelUp
@onready var _upgrade_row: HBoxContainer = $CenterContainer/VBoxContainer/HBoxContainer
@onready var _refresh_button: Button = $refreshButton

var allowed_refresh = 1
var current_choices = []	
var upgrades_open = false

var upgrades = [
	{
		"name": "Rolling Greese",
		"desc": "roll faster",
		"icon": ROLLING_GREASE_ICON,
		"apply": func(player): player.rolling_force += 150
	}, {
		"name": "Rocket Jump",
		"desc": "Jump higher",
		"icon": ROCKET_JUMP_ICON,
		"apply": func(player): player.jump_force += 15
	}, {
		"name": "slam",
		"desc": "increase slam damage and radius",
		"icon": SLAM_ICON,
		"apply": func(player): player.slam_damage += 50
	}, {
		"name": "Slo-mo glasses",
		"desc": 'glasses that improves your launch',
		"icon": SLO_MO_GLASSES_ICON,
		"apply": func(player): slow_mo_glassse(player)
	}, {
		"name": "Candy heart",
		"desc": 'Increases health and regen',
		"icon": CANDY_HEART_ICON,
		"apply": func(player): candy_heart(player)
	}, {
		"name": "Automatic Missiles",
		"desc": 'Increases missile potency',
		"icon": MISSILES_ICON,
		"apply": func(player): automatic_missiles(player)
	}, {
		"name": "Spinning Jimmy",
		"desc": 'Increases spin attack potency',
		"icon": SPINNING_JIMMY_ICON,
		"apply": func(player): spinning_jimmy(player)
	}, {
		"name": "Aerobics Training",
		"desc": 'Increases engery',
		"icon": ENERGY_ICON,
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
	
func candy_heart(player):
	player.hp_regen += 0.15
	player.max_hp += 200
	
func slow_mo_glassse(player):
	player.max_charge += 750
	player.charge_speed += 333


func _style_upgrade_button(button: Button, upgrade: Dictionary) -> void:
	button.text = "%s\n%s" % [upgrade.name, upgrade.desc]
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("h_separation", 8)
	if upgrade.get("icon", null):
		button.icon = upgrade["icon"]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		button.icon = null
		button.expand_icon = false


func _apply_upgrade_button_labels() -> void:
	for i in range(len(upgrade_buttons)):
		_style_upgrade_button(upgrade_buttons[i], current_choices[i])


func refresh_upgrades():
	$refreshButton.text = "str(allowed_refresh)"
	current_choices = get_random_upgrades()
	_apply_upgrade_button_labels()
	
func showUpgrades():
	upgrades_open = !upgrades_open
	get_tree().paused = upgrades_open
	self.visible = upgrades_open
	if speedometer:
		speedometer.visible = !upgrades_open

	if upgrades_open:
		current_choices = get_random_upgrades()
		_apply_upgrade_button_labels()

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
	var vp := get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var base_size: float = UiResponsive.short_side(vp)
	var r: float = UiResponsive.ratio(vp)

	var mg: int = UiResponsive.scale_i_clamped(vp, 64.0, 12, 120)
	_center_margin.add_theme_constant_override("margin_left", mg)
	_center_margin.add_theme_constant_override("margin_top", UiResponsive.scale_i_clamped(vp, 48.0, 8, 100))
	_center_margin.add_theme_constant_override("margin_right", mg)
	_center_margin.add_theme_constant_override("margin_bottom", UiResponsive.scale_i_clamped(vp, 48.0, 8, 100))
	_main_vbox.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 20.0, 8, 44))
	_upgrade_row.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 20.0, 6, 40))

	_level_banner.custom_minimum_size.y = clampf(base_size * 0.48, 140.0 * r, 520.0 * r)

	var font_size: int = int(clampf(base_size * 0.035, 12.0 * r, 52.0 * r))
	var min_height: float = clampf(base_size * 0.22, 120.0 * r, 420.0 * r)

	for button in upgrade_buttons:
		button.custom_minimum_size.y = min_height
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_font_size_override("font_size", font_size)

	var ref: float = UiResponsive.scale_px_clamped(vp, 76.0, 44.0, 120.0)
	_refresh_button.add_theme_font_size_override("font_size", UiResponsive.scale_i_clamped(vp, 22.0, 12, 36))
	_refresh_button.offset_top = UiResponsive.scale_px_clamped(vp, 20.0, 8.0, 48.0)
	_refresh_button.offset_bottom = _refresh_button.offset_top + ref
	_refresh_button.offset_right = UiResponsive.scale_px_clamped(vp, -20.0, -8.0, -36.0)
	_refresh_button.offset_left = _refresh_button.offset_right - ref
