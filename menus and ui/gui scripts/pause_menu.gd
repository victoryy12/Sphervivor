extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
@onready var player_ui = get_parent().get_node("userInterface")
@onready var boss_health_ui: CanvasLayer = get_parent().get_node_or_null("BossHealthBar") as CanvasLayer
@onready var pause_panel: PanelContainer = $MainLayout/RootVBox/ButtonsCenter/pauseOptions
@onready var logo: TextureRect = $MainLayout/RootVBox/Logo
@onready var stats_panel: PanelContainer = $MainLayout/RootVBox/stats
@onready var stats_label: Label = $MainLayout/RootVBox/stats/displayStats
@onready var resume_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/resumeButton
@onready var restart_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/restartButton
@onready var quit_button: Button = $MainLayout/RootVBox/ButtonsCenter/pauseOptions/VBoxContainer/quitButton
var pausedCheck = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_and_unpause()
		
		
func _ready() -> void:
	self.visible = false
	get_viewport().size_changed.connect(_update_ui_scale)
	_update_ui_scale()
			
			
func pause_and_unpause():
	pausedCheck = !pausedCheck
	get_tree().paused = pausedCheck
	self.visible = pausedCheck
	
	player_ui.visible = !pausedCheck
	if boss_health_ui:
		boss_health_ui.visible = !pausedCheck

	if pausedCheck:
		display_stats()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func display_stats():
	stats_label.text = " Speed: %d\n Jump: %d\n Regen/s: %d" % [
	player_stats.rolling_force,
	player_stats.jump_force,
	player_stats.hp_regen
	]


func _update_ui_scale() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var base_size: float = min(viewport_size.x, viewport_size.y)

	var button_font_size: int = int(clampf(base_size * 0.045, 20.0, 54.0))
	var stats_font_size: int = int(clampf(base_size * 0.032, 16.0, 42.0))
	var button_height: float = clampf(base_size * 0.125, 72.0, 180.0)
	var logo_height: float = clampf(viewport_size.y * 0.2, 90.0, 280.0)
	var panel_width: float = clampf(viewport_size.x * 0.58, 460.0, 1200.0)
	var stats_height: float = clampf(base_size * 0.20, 90.0, 240.0)

	logo.custom_minimum_size.y = logo_height
	pause_panel.custom_minimum_size.x = panel_width
	stats_panel.custom_minimum_size.y = stats_height

	for button in [resume_button, restart_button, quit_button]:
		button.custom_minimum_size.y = button_height
		button.add_theme_font_size_override("font_size", button_font_size)

	stats_label.add_theme_font_size_override("font_size", stats_font_size)


func _on_resume_button_pressed() -> void:
	pause_and_unpause()


func _on_restart_button_pressed() -> void:
	pause_and_unpause()
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
