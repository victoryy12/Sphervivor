extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
@onready var player_ui = get_parent().get_node("userInterface")

@onready var pause_panel: PanelContainer = $MainLayout/RootVBox/ButtonsCenter/pauseOptions
@onready var logo: TextureRect = $MainLayout/RootVBox/Logo
@onready var stats_panel: PanelContainer = $MainLayout/RootVBox/stats
@onready var stats_label: Label = $MainLayout/RootVBox/stats/displayStats

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

	# GLOBAL STATE (for spawner + systems)
	GameState.state = GameState.State.PAUSED if pausedCheck else GameState.State.PLAY
	game_paused = pausedCheck

	get_tree().paused = pausedCheck
	self.visible = pausedCheck

	player_ui.visible = !pausedCheck

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if pausedCheck else Input.MOUSE_MODE_CAPTURED
	)
	if pausedCheck:
		display_stats()

# ------------------------------------------------
# STATS
# ------------------------------------------------
func display_stats():
	stats_label.text = " Speed: %d\n Jump: %d\n Regen/s: %d" % [
		player_stats.rolling_force,
		player_stats.jump_force,
		player_stats.hp_regen
	]


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
	var stats_font_size: int = int(clampf(base_size * 0.032, 14.0 * r, 48.0 * r))
	var button_height: float = clampf(base_size * 0.094, 44.0 * r, 142.0 * r)
	var logo_height: float = clampf(viewport_size.y * 0.17, 64.0 * r, 280.0 * r)
	var panel_width: float = clampf(viewport_size.x * 0.58, 320.0 * r, 1280.0 * r)
	var stats_height: float = clampf(base_size * 0.17, 60.0 * r, 230.0 * r)

	logo.custom_minimum_size.y = logo_height
	pause_panel.custom_minimum_size.x = panel_width
	stats_panel.custom_minimum_size.y = stats_height

	for button in [resume_button, restart_button, help_button, quit_button]:
		button.custom_minimum_size.y = button_height
		button.add_theme_font_size_override("font_size", button_font_size)

	stats_label.add_theme_font_size_override("font_size", stats_font_size)

	help_panel.custom_minimum_size = Vector2(viewport_size.x * 0.8, viewport_size.y * 0.8)
	var help_font_size: int = int(clampf(base_size * 0.04, 16.0, 36.0))
	help_label.add_theme_font_size_override("font_size", help_font_size)


# ------------------------------------------------
# BUTTONS
# ------------------------------------------------
func _on_resume_button_pressed() -> void:
	pause_and_unpause()

func _on_restart_button_pressed() -> void:
	pause_and_unpause()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_help_button_pressed() -> void:
	help_panel.visible = true
	_main_layout.visible = false

func _on_help_back_button_pressed() -> void:
	help_panel.visible = false
	_main_layout.visible = true
