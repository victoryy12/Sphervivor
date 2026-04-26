extends CanvasLayer

@onready var _main_layout: MarginContainer = $MainLayout
@onready var _root_vbox: VBoxContainer = $MainLayout/RootVBox
@onready var _button_row: VBoxContainer = $MainLayout/RootVBox/ButtonsCenter/deathOptions/VBoxContainer
@onready var _death_label: Label = $MainLayout/RootVBox/DeathLabel
@onready var _death_options: PanelContainer = $MainLayout/RootVBox/ButtonsCenter/deathOptions
@onready var _restart: Button = %restartButton
@onready var _main_menu: Button = %mainMenuButton
@onready var _quit: Button = %quitButton
@onready var _help: Button = %helpButton

# Help UI References
@onready var help_panel: Control = $HelpPanel 
@onready var help_label: Label = $HelpPanel/Label

var _label_settings_base: LabelSettings

func _ready() -> void:
	visible = false
	help_panel.visible = false # Keep hidden initially
	
	if _death_label.label_settings:
		_label_settings_base = _death_label.label_settings.duplicate() as LabelSettings
	
	get_viewport().size_changed.connect(_update_ui_scale)
	_update_ui_scale()
	
	# Set your help text
	help_label.text = """CONTROLS:
Movement: W,A,S,D

Jump: Space

Slam: Jump + Shift

Spin: Left Mouse or E

Charge: Right Mouse

Defeat Enemies to obtain expierence points that you can use to level up!
The Boss is shielded! You have to wait for the shield to go away for you to do damage!"""

func _update_ui_scale() -> void:
	var vp := get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var base_size: float = UiResponsive.short_side(vp)
	var r: float = UiResponsive.ratio(vp)

	# --- Existing Layout Scaling ---
	var mg: int = UiResponsive.scale_i_clamped(vp, 40.0, 10, 96)
	_main_layout.add_theme_constant_override("margin_left", mg)
	_main_layout.add_theme_constant_override("margin_top", UiResponsive.scale_i_clamped(vp, 24.0, 6, 64))
	_main_layout.add_theme_constant_override("margin_right", mg)
	_main_layout.add_theme_constant_override("margin_bottom", UiResponsive.scale_i_clamped(vp, 24.0, 6, 64))
	_root_vbox.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 14.0, 6, 32))
	_button_row.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 10.0, 4, 24))

	var button_font_size: int = int(clampf(base_size * 0.0355, 14.0 * r, 43.0 * r))
	var button_height: float = clampf(base_size * 0.094, 44.0 * r, 142.0 * r)
	var panel_width: float = clampf(viewport_size.x * 0.58, 320.0 * r, 1280.0 * r)
	var title_size: int = UiResponsive.scale_i_clamped(vp, 100.0, 40, 160)
	var help_sep: int = UiResponsive.scale_i_clamped(vp, 10.0, 4, 24)
	var buttons_tall: float = 4.0 * button_height + 3.0 * float(help_sep)

	_death_label.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.12, 64.0 * r, 180.0 * r))
	_death_options.custom_minimum_size = Vector2(panel_width, buttons_tall)

	if _label_settings_base:
		var ls: LabelSettings = _label_settings_base.duplicate() as LabelSettings
		ls.font_size = title_size
		_death_label.label_settings = ls

	for b in [_restart, _main_menu, _quit, _help]:
		b.custom_minimum_size.y = button_height
		b.add_theme_font_size_override("font_size", button_font_size)

	# --- Help Panel Scaling ---
	help_panel.custom_minimum_size = Vector2(viewport_size.x * 0.8, viewport_size.y * 0.8)
	var help_font_size: int = int(clampf(base_size * 0.04, 16.0, 36.0))
	help_label.add_theme_font_size_override("font_size", help_font_size)
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func open() -> void:
	visible = true
	help_panel.visible = false # Ensure help is hidden when the screen first appears
	_main_layout.visible = true
	get_tree().paused = true
	AudioServer.playback_speed_scale = 1.0
	Engine.time_scale = 1.0
	_update_ui_scale()
	
	if get_parent():
		for n in ["userInterface", "pause menu"]:
			var node: Node = get_parent().get_node_or_null(n)
			if node:
				node.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# --- Button Signal Connections ---

func _on_help_button_pressed() -> void:
	help_panel.visible = true
	_main_layout.visible = false # Hide death options while reading help

func _on_help_back_button_pressed() -> void:
	help_panel.visible = false
	_main_layout.visible = true # Bring back death options

func _on_restart_button_pressed() -> void:
	_restore_hud_before_scene_change()
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://menus and ui/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

# --- Helper Logic ---

func _restore_hud_before_scene_change() -> void:
	get_tree().paused = false
	visible = false
	if get_parent():
		for n in ["userInterface"]:
			var node: Node = get_parent().get_node_or_null(n)
			if node:
				node.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
