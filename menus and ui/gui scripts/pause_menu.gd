extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
@onready var upgrades = get_parent().get_node("upgrades_screen")
@onready var player_ui = get_parent().get_node("userInterface")

@onready var pause_panel: PanelContainer = $MainLayout/RootVBox/ButtonsCenter/pauseOptions
@onready var logo: TextureRect = $MainLayout/RootVBox/Logo
@onready var stats_panel: HBoxContainer = $MainLayout/RootVBox/stats

@onready var resume_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/resumeButton
@onready var restart_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/restartButton
@onready var help_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/helpButton
@onready var quit_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/quitButton

@onready var _main_layout: MarginContainer = $MainLayout
@onready var _root_vbox: VBoxContainer = $MainLayout/RootVBox
@onready var _pause_vbox: VBoxContainer = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer

@onready var help_panel: Control = $HelpPanel 
@onready var help_label: Label = $HelpPanel/Label


# ------------------------------------------------
# GLOBAL PAUSE STATE
# ------------------------------------------------
static var game_paused := false

var pausedCheck := false


# ------------------------------------------------
# READY
# ------------------------------------------------
func _ready() -> void:
	self.visible = false
	help_panel.visible = false
	stats_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	statsImages()

	get_viewport().size_changed.connect(_update_ui_scale)
	_update_ui_scale()

	help_label.text = """CONTROLS:
Movement: W,A,S,D
Jump: Space
Slam: Jump + Shift
Spin: Left Mouse or E
Charge: Right Mouse

Defeat enemies to gain XP and level up!
Bosses are shielded until their phase ends!"""


# ------------------------------------------------
# INPUT
# ------------------------------------------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if help_panel.visible:
			help_panel.visible = false
			_main_layout.visible = true
		else:
			pause_and_unpause()


# ------------------------------------------------
# PAUSE TOGGLE
# ------------------------------------------------
func pause_and_unpause():
	pausedCheck = !pausedCheck

	if pausedCheck:
		if upgrades.upgrades_open:
			upgrades.visible = false
		GameState.state = GameState.State.PAUSED
		game_paused = true
		get_tree().paused = true
		self.visible = true
		player_ui.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		statsLabels()
		return

	if upgrades.upgrades_open:
		GameState.state = GameState.State.UPGRADE
		game_paused = false
		get_tree().paused = true
		self.visible = false
		upgrades.visible = true
		upgrades.refresh_upgrade_hud_visibility()
		player_ui.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	GameState.state = GameState.State.PLAY
	game_paused = false
	get_tree().paused = false
	self.visible = false
	player_ui.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ------------------------------------------------
# STATS
# ------------------------------------------------
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
const PR_CONFIDENTIAL_FONT: FontFile = preload("res://assets/PR Confidential.otf")

@onready var label_rolling_greese = $MainLayout/RootVBox/stats/rollingGreese/Label
@onready var label_jump = $MainLayout/RootVBox/stats/RocketJump/Label
@onready var label_slam  = $MainLayout/RootVBox/stats/Slam/Label
@onready var label_slomo = $MainLayout/RootVBox/stats/SloMo/Label
@onready var label_candy_heart = $MainLayout/RootVBox/stats/CandyHeart/Label
@onready var label_Bouncy_ball = $MainLayout/RootVBox/stats/BouncyBalls/Label
@onready var label_spinning = $MainLayout/RootVBox/stats/SpinningWings/Label
@onready var label_aerobics = $MainLayout/RootVBox/stats/AerobicTraining/Label

@onready var img_rolling_greese = $MainLayout/RootVBox/stats/rollingGreese/TextureRect
@onready var img_jump = $MainLayout/RootVBox/stats/RocketJump/TextureRect
@onready var img_slam = $MainLayout/RootVBox/stats/Slam/TextureRect
@onready var img_slomo = $MainLayout/RootVBox/stats/SloMo/TextureRect
@onready var img_candy_heart = $MainLayout/RootVBox/stats/CandyHeart/TextureRect
@onready var img_Bouncy_ball = $MainLayout/RootVBox/stats/BouncyBalls/TextureRect
@onready var img_spinning = $MainLayout/RootVBox/stats/SpinningWings/TextureRect
@onready var img_aerobics = $MainLayout/RootVBox/stats/AerobicTraining/TextureRect

func statsLabels():
	label_rolling_greese.text = str(upgrades.rolling_count)
	label_jump.text = str(upgrades.jump_force_count)
	label_slam.text = str(upgrades.slam_count)
	label_slomo.text = str(upgrades.slo_mo_count)
	label_candy_heart.text = str(upgrades.candy_heart_count)
	label_Bouncy_ball.text = str(upgrades.bounce_ball_count)
	label_spinning.text = str(upgrades.spin_force_count)
	label_aerobics.text = str(upgrades.energy_count)

func statsImages():
	img_rolling_greese.texture = ROLLING_GREASE_ICON
	img_jump.texture = ROCKET_JUMP_ICON
	img_slam.texture = SLAM_ICON
	img_slomo.texture = SLO_MO_GLASSES_ICON
	img_candy_heart.texture = CANDY_HEART_ICON
	img_Bouncy_ball.texture = MISSILES_ICON
	img_spinning.texture = SPINNING_JIMMY_ICON
	img_aerobics.texture = ENERGY_ICON


# ------------------------------------------------
# UI SCALE
# ------------------------------------------------
func _update_ui_scale() -> void:
	var vp := get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var base_size: float = UiResponsive.short_side(vp)
	var r: float = UiResponsive.ratio(vp)

	var mg: int = UiResponsive.scale_i_clamped(vp, 40.0, 10, 96)

	_main_layout.add_theme_constant_override("margin_left", mg)
	_main_layout.add_theme_constant_override("margin_top", UiResponsive.scale_i_clamped(vp, 24.0, 6, 64))
	_main_layout.add_theme_constant_override("margin_right", mg)
	_main_layout.add_theme_constant_override("margin_bottom", UiResponsive.scale_i_clamped(vp, 24.0, 6, 64))

	_root_vbox.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 14.0, 6, 32))
	_pause_vbox.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 10.0, 4, 24))

	var button_font_size: int = int(clampf(base_size * 0.0355, 14.0 * r, 43.0 * r))
	var stats_font_size: int = int(clampf(base_size * 0.038, 15.0 * r, 54.0 * r))
	var button_height: float = clampf(base_size * 0.094, 44.0 * r, 142.0 * r)
	var logo_height: float = clampf(viewport_size.y * 0.17, 64.0 * r, 280.0 * r)
	var panel_width: float = clampf(viewport_size.x * 0.58, 320.0 * r, 1280.0 * r)
	var stats_height: float = clampf(base_size * 0.195, 68.0 * r, 248.0 * r)

	logo.custom_minimum_size.y = logo_height
	pause_panel.custom_minimum_size.x = panel_width
	stats_panel.custom_minimum_size.y = stats_height

	var stat_outer_sep: int = UiResponsive.scale_i_clamped(vp, 18.0, 10, 34)
	var stat_inner_sep: int = UiResponsive.scale_i_clamped(vp, 4.0, 2, 8)
	stats_panel.add_theme_constant_override("separation", stat_outer_sep)

	for row in stats_panel.get_children():
		if row is HBoxContainer:
			row.add_theme_constant_override("separation", stat_inner_sep)

	for button in [resume_button, restart_button, help_button, quit_button]:
		button.custom_minimum_size.y = button_height
		button.add_theme_font_size_override("font_size", button_font_size)

	for lbl in [
		label_rolling_greese, label_jump, label_slam, label_slomo,
		label_candy_heart, label_Bouncy_ball, label_spinning, label_aerobics,
	]:
		lbl.add_theme_font_override("font", PR_CONFIDENTIAL_FONT)
		lbl.add_theme_font_size_override("font_size", stats_font_size)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	help_panel.custom_minimum_size = Vector2(viewport_size.x * 0.8, viewport_size.y * 0.8)
	var help_font_size: int = int(clampf(base_size * 0.04, 16.0, 36.0))
	help_label.add_theme_font_size_override("font_size", help_font_size)
	
	#handles images in stats
	var icon_size: int = UiResponsive.scale_i_clamped(vp, 56.0, 30, 92)

	for img in [img_rolling_greese, img_jump, img_slam, img_slomo,
				img_candy_heart, img_Bouncy_ball, img_spinning, img_aerobics]:
		img.custom_minimum_size = Vector2(icon_size, icon_size)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL


# ------------------------------------------------
# BUTTONS
# ------------------------------------------------
func _on_resume_button_pressed() -> void:
	pause_and_unpause()

func _on_restart_button_pressed() -> void:
	# lock game state first
	GameState.state = GameState.State.PLAY

	# hide UI immediately (avoid dangling references)
	self.visible = false
	player_ui = null
	player_stats = null

	# unpause engine FIRST
	get_tree().paused = false

	# defer restart safely
	call_deferred("_do_restart")


func _do_restart():
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_help_button_pressed() -> void:
	help_panel.visible = true
	_main_layout.visible = false

func _on_help_back_button_pressed() -> void:
	help_panel.visible = false
	_main_layout.visible = true
