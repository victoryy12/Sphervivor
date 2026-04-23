extends Control

@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var start_button: Button = $CenterContainer/VBoxContainer/startButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/settingButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/exitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().size_changed.connect(_update_button_scale)
	_update_button_scale()


func _update_button_scale() -> void:
	var vp := get_viewport()
	var viewport_size: Vector2 = vp.get_visible_rect().size
	var base_size: float = UiResponsive.short_side(vp)
	var r: float = UiResponsive.ratio(vp)
	var button_width: float = clampf(viewport_size.x * 0.24, 200.0 * r, 560.0 * r)
	var button_height: float = clampf(base_size * 0.095, 44.0 * r, 120.0 * r)
	var font_size: int = int(clampf(base_size * 0.05, 20.0 * r, 64.0 * r))
	var spacing: int = int(clampf(base_size * 0.018, 8.0 * r, 28.0 * r))

	vbox.add_theme_constant_override("separation", spacing)
	for button in [start_button, settings_button, exit_button]:
		button.custom_minimum_size = Vector2(button_width, button_height)
		button.add_theme_font_size_override("font_size", font_size)




func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_setting_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus and ui/options_menu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
