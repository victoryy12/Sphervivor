extends CanvasLayer

const CANDY_HEART_ICON: Texture2D = preload("res://assets/candy-heart.png")
const MISSILES_ICON: Texture2D = preload("res://assets/bouncy-ball2.png")
const SPINNING_JIMMY_ICON: Texture2D = preload("res://assets/spinning-wings.png")
const ROCKET_JUMP_ICON: Texture2D = preload("res://assets/rocket-jump.png")
const ROLLING_GREASE_ICON: Texture2D = preload("res://assets/rolling-grease.png")
const SLAM_ICON: Texture2D = preload("res://assets/slam.png")
const SLO_MO_GLASSES_ICON: Texture2D = preload("res://assets/slo-mo-glasses.png")
const ENERGY_ICON: Texture2D = preload("res://assets/energy2.png")
const REFRESH_ICON: Texture2D = preload("res://assets/refresh2.png")
const KOMIKAX_FONT: FontFile = preload("res://assets/KOMIKAX_.ttf")
const MAX_UPGRADE_REFRESHES_PER_GAME := 5

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

var _refresh_layout_size: Vector2 = Vector2.ZERO
var _upgrade_refreshes_remaining: int = MAX_UPGRADE_REFRESHES_PER_GAME
var current_choices = []	
static var upgrades_open := false


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
		"name": "Slam",
		"desc": "increase slam damage and radius",
		"icon": SLAM_ICON,
		"apply": func(player): player.slam_damage += 100
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
		"name": "Bouncy balls",
		"desc": 'Increases projectile potency',
		"icon": MISSILES_ICON,
		"apply": func(player): automatic_missiles(player)
	}, {
		"name": "Spinning wings",
		"desc": 'Increases spin attack potency',
		"icon": SPINNING_JIMMY_ICON,
		"apply": func(player): spinning_wings(player)
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
	
func spinning_wings(player):
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


func refresh_upgrades() -> void:
	current_choices = get_random_upgrades()
	_apply_upgrade_button_labels()
	call_deferred("_position_refresh_against_upgrades")


func _sync_refresh_button() -> void:
	var left: int = _upgrade_refreshes_remaining
	_refresh_button.disabled = left <= 0
	_refresh_button.modulate = Color(1, 1, 1, 0.5) if left <= 0 else Color.WHITE
	_refresh_button.text = "Refresh (%d)" % left
	
func showUpgrades():
	
	upgrades_open = !upgrades_open
	self.upgrades_open = upgrades_open
	GameState.state = GameState.State.UPGRADE if upgrades_open else GameState.State.PLAY
	get_tree().paused = upgrades_open
	self.visible = upgrades_open

	if speedometer:
		speedometer.visible = !upgrades_open

	if upgrades_open:
		current_choices = get_random_upgrades()
		_apply_upgrade_button_labels()
		_sync_refresh_button()
		call_deferred("_position_refresh_against_upgrades")
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
	_refresh_button.icon = REFRESH_ICON
	_sync_refresh_button()
	get_viewport().size_changed.connect(_update_upgrade_ui_scale)
	_upgrade_row.resized.connect(_on_upgrade_row_resized)
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
	if _upgrade_refreshes_remaining <= 0:
		return
	_upgrade_refreshes_remaining -= 1
	refresh_upgrades()
	_sync_refresh_button()


func _on_upgrade_row_resized() -> void:
	call_deferred("_position_refresh_against_upgrades")


## Floats above the upgrade row without participating in the VBox (avoids squishing the three cards).
func _position_refresh_against_upgrades() -> void:
	if not is_instance_valid(_refresh_button) or not is_instance_valid(_upgrade_row):
		return
	if _refresh_layout_size == Vector2.ZERO:
		return
	var vp := get_viewport()
	var vp_rect: Rect2 = vp.get_visible_rect()
	var r: float = UiResponsive.ratio(vp)
	var margin: float = clampf(12.0 * r, 6.0, 28.0)
	var gap: float = clampf(10.0 * r, 6.0, 22.0)
	var sz: Vector2 = _refresh_layout_size
	var row_rect: Rect2 = _upgrade_row.get_global_rect()
	if row_rect.size.y < 1.0:
		return
	_refresh_button.custom_minimum_size = sz
	_refresh_button.size = sz
	var x: float = row_rect.position.x + row_rect.size.x - sz.x
	var y: float = row_rect.position.y - gap - sz.y
	x = clampf(x, vp_rect.position.x + margin, vp_rect.position.x + vp_rect.size.x - margin - sz.x)
	y = clampf(y, vp_rect.position.y + margin, vp_rect.position.y + vp_rect.size.y - margin - sz.y)
	_refresh_button.global_position = Vector2(x, y)


func _update_upgrade_ui_scale() -> void:
	var vp := get_viewport()
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

	# Scale with short side (same idea as upgrade cards) so size tracks resolution; caps keep extremes readable.
	var ref_h: float = clampf(base_size * 0.14, 54.0 * r, 180.0 * r)
	var ref_w: float = clampf(base_size * 0.44, 178.0 * r, 520.0 * r)
	var ref_gap: int = int(clampf(base_size * 0.022, 8.0 * r, 24.0 * r))
	var ref_font: int = int(clampf(base_size * 0.046, 16.0 * r, 54.0 * r))
	# Icon scales with the button so it fills most of the height; width ~half the inner area beside "Refresh".
	var icon_side: int = int(minf(ref_h * 0.82, (ref_w - float(ref_gap)) * 0.48))
	icon_side = maxi(icon_side, 28)
	_refresh_button.expand_icon = false
	_refresh_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refresh_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_refresh_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_refresh_button.clip_text = false
	_refresh_button.add_theme_font_override("font", KOMIKAX_FONT)
	_refresh_button.add_theme_font_size_override("font_size", ref_font)
	_refresh_button.add_theme_constant_override("h_separation", ref_gap)
	_refresh_button.add_theme_constant_override("icon_max_width", icon_side)
	_refresh_button.add_theme_constant_override("icon_max_height", icon_side)
	_refresh_layout_size = Vector2(ref_w, ref_h)
	_refresh_button.custom_minimum_size = _refresh_layout_size
	_sync_refresh_button()
	call_deferred("_position_refresh_against_upgrades")
