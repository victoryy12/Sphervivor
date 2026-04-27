extends Control

@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var start_button: Button = $CenterContainer/VBoxContainer/startButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/settingButton
@onready var help_button: Button = $CenterContainer/VBoxContainer/helpButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/exitButton

# Update these paths if you moved HelpPanel to the root Main menu node
@onready var help_panel: Control = $HelpPanel 
@onready var help_label: Label = $HelpPanel/Label

func _ready():
	help_panel.visible = false
	_update_ui_layout()
	get_viewport().size_changed.connect(_update_ui_layout)
	
	help_label.text = """CONTROLS:

Movement: 
		  W / Up Arrow      - Move Forward
		  S / Down Arrow    - Move Backward
		  A / Left Arrow    - Move Left
		  D / Right Arrow   - Move Right

Jump:	  
		  Space             - Jump

Slam:	  Hold S + Jump     - Charge Slam Downward

Spin Attack:
		Hold Left Mouse   - Spin Attack

Charge Shot:
Hold Right Mouse  - Charge
Release           - Launch

Mouse:
Move Mouse        - Look Around"""

# --- Signals ---


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")

func _on_setting_button_pressed():
	get_tree().change_scene_to_file("res://menus and ui/options_menu.tscn")

func _on_help_button_pressed():
	help_panel.visible = true

func _on_exit_button_pressed():
	get_tree().quit()

# Connect your new back button's 'pressed' signal to this!
func _on_help_back_button_pressed():
	help_panel.visible = false

# --- Layout & Scaling ---

func _update_ui_layout() -> void:
	var vp := get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var base_size: float = UiResponsive.short_side(vp)
	var r: float = UiResponsive.ratio(vp)
	
	# Menu Button Scaling
	var button_width: float = clampf(viewport_size.x * 0.24, 200.0 * r, 560.0 * r)
	var button_height: float = clampf(base_size * 0.095, 44.0 * r, 120.0 * r)
	var font_size: int = int(clampf(base_size * 0.05, 20.0 * r, 64.0 * r))
	var spacing: int = int(clampf(base_size * 0.018, 8.0 * r, 28.0 * r))

	vbox.add_theme_constant_override("separation", spacing)
	for button in [start_button, settings_button, help_button, exit_button]:
		button.custom_minimum_size = Vector2(button_width, button_height)
		button.add_theme_font_size_override("font_size", font_size)

	# Pop-up Panel Scaling & Centering
	help_panel.custom_minimum_size = Vector2(viewport_size.x * 0.8, viewport_size.y * 0.9)
	# This forces the panel to stay centered regardless of screen size
	help_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
