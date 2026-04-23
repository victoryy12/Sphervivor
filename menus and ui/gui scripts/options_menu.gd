extends Control

@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _fov_slider: HSlider = %FovSlider
@onready var _fov_value: Label = %FovValue
@onready var _day_slider: HSlider = %DayNightSlider
@onready var _day_value: Label = %DayNightValue
@onready var _mouse_slider: HSlider = %MouseSlider
@onready var _mouse_value: Label = %MouseValue


func _ready() -> void:
	_sync_sliders_from_settings()
	_volume_slider.value_changed.connect(_on_volume_slider_changed)
	_fov_slider.value_changed.connect(_on_fov_slider_changed)
	_day_slider.value_changed.connect(_on_day_slider_changed)
	_mouse_slider.value_changed.connect(_on_mouse_slider_changed)
	_refresh_all_labels()


const _MOUSE_SENS_MIN := 0.00025
const _MOUSE_SENS_MAX := 0.012


func _sync_sliders_from_settings() -> void:
	_volume_slider.set_value_no_signal(GameSettings.master_volume_linear * 100.0)
	_fov_slider.set_value_no_signal(GameSettings.fov_degrees)
	_day_slider.set_value_no_signal(GameSettings.day_night * 100.0)
	var ms := GameSettings.mouse_sensitivity
	var t := inverse_lerp(_MOUSE_SENS_MIN, _MOUSE_SENS_MAX, ms)
	_mouse_slider.set_value_no_signal(lerpf(0.0, 100.0, clampf(t, 0.0, 1.0)))


func _refresh_all_labels() -> void:
	_volume_value.text = str(int(round(_volume_slider.value))) + "%"
	_fov_value.text = str(int(round(_fov_slider.value))) + "°"
	if _day_slider.value < 15.0:
		_day_value.text = "Night"
	elif _day_slider.value > 85.0:
		_day_value.text = "Day"
	else:
		_day_value.text = str(int(round(_day_slider.value))) + "%"
	# Show clamped stored value so the label matches what the game uses.
	_mouse_value.text = String.num(GameSettings.mouse_sensitivity, 4)


func _on_volume_slider_changed(v: float) -> void:
	GameSettings.set_master_volume_linear(v / 100.0)
	_refresh_all_labels()


func _on_fov_slider_changed(v: float) -> void:
	GameSettings.set_fov_degrees(v)
	_refresh_all_labels()


func _on_day_slider_changed(v: float) -> void:
	GameSettings.set_day_night(v / 100.0)
	_refresh_all_labels()


func _on_mouse_slider_changed(v: float) -> void:
	GameSettings.set_mouse_sensitivity(_sensitivity_from_slider(v))
	_refresh_all_labels()


func _sensitivity_from_slider(slider_v: float) -> float:
	return lerpf(_MOUSE_SENS_MIN, _MOUSE_SENS_MAX, clampf(slider_v / 100.0, 0.0, 1.0))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://menus and ui/main_menu.tscn")
