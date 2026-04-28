extends Control

@onready var _margin: MarginContainer = $MarginContainer
@onready var _vbox: VBoxContainer = $MarginContainer/CenterContainer/VBox
@onready var _title: Label = $MarginContainer/CenterContainer/VBox/Title
@onready var _back: Button = $MarginContainer/CenterContainer/VBox/BackButton
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _volume_value: Label = %VolumeValue
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _fov_slider: HSlider = %FovSlider
@onready var _fov_value: Label = %FovValue
@onready var _day_slider: HSlider = %DayNightSlider
@onready var _day_value: Label = %DayNightValue
@onready var _mouse_slider: HSlider = %MouseSlider
@onready var _mouse_value: Label = %MouseValue


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_viewport_scale)
	_apply_viewport_scale()
	_sync_sliders_from_settings()
	_volume_slider.value_changed.connect(_on_volume_slider_changed)
	_music_slider.value_changed.connect(_on_music_slider_changed)
	_fov_slider.value_changed.connect(_on_fov_slider_changed)
	_day_slider.value_changed.connect(_on_day_slider_changed)
	_mouse_slider.value_changed.connect(_on_mouse_slider_changed)
	_refresh_all_labels()


const _MOUSE_SENS_MIN := 0.00025
const _MOUSE_SENS_MAX := 0.012


func _apply_viewport_scale() -> void:
	var vp := get_viewport()
	var vw: float = vp.get_visible_rect().size.x

	var mg: int = UiResponsive.scale_i_clamped(vp, 24.0, 6, 56)
	_margin.add_theme_constant_override("margin_left", mg)
	_margin.add_theme_constant_override("margin_top", UiResponsive.scale_i_clamped(vp, 20.0, 4, 48))
	_margin.add_theme_constant_override("margin_right", mg)
	_margin.add_theme_constant_override("margin_bottom", UiResponsive.scale_i_clamped(vp, 20.0, 4, 48))

	_vbox.add_theme_constant_override("separation", UiResponsive.scale_i_clamped(vp, 36.0, 10, 72))

	_title.add_theme_font_size_override("font_size", UiResponsive.scale_i_clamped(vp, 78.0, 26, 120))
	_title.add_theme_constant_override("outline_size", UiResponsive.scale_i_clamped(vp, 10.0, 2, 18))

	var slider_w: float = clampf(vw * 0.42, UiResponsive.scale_px(vp, 200.0), vw * 0.62)
	var slider_h: float = UiResponsive.scale_px_clamped(vp, 54.0, 28.0, 88.0)
	var label_w: float = UiResponsive.scale_px_clamped(vp, 340.0, 160.0, 480.0)
	var value_w_default: float = UiResponsive.scale_px_clamped(vp, 160.0, 72.0, 240.0)
	var value_w_mouse: float = UiResponsive.scale_px_clamped(vp, 200.0, 88.0, 280.0)
	var row_sep: int = UiResponsive.scale_i_clamped(vp, 24.0, 6, 40)
	var body_fs: int = UiResponsive.scale_i_clamped(vp, 40.0, 14, 58)
	var outline: int = UiResponsive.scale_i_clamped(vp, 6.0, 2, 12)

	for child in _vbox.get_children():
		if child is HBoxContainer:
			var row_node := child as Node
			var row_value_w: float = value_w_mouse if row_node.get_node_or_null("MouseValue") else value_w_default
			_scale_option_row(
				child as HBoxContainer,
				vp,
				slider_w,
				slider_h,
				label_w,
				row_value_w,
				row_sep,
				body_fs,
				outline
			)

	_back.custom_minimum_size = Vector2(
		UiResponsive.scale_px_clamped(vp, 400.0, 200.0, 560.0),
		UiResponsive.scale_px_clamped(vp, 86.0, 44.0, 120.0)
	)
	_back.add_theme_font_size_override("font_size", UiResponsive.scale_i_clamped(vp, 44.0, 18, 64))
	_back.add_theme_constant_override("outline_size", outline)


func _scale_option_row(
	row: HBoxContainer,
	vp: Viewport,
	slider_w: float,
	slider_h: float,
	label_w: float,
	value_w: float,
	row_sep: int,
	font_sz: int,
	outline_sz: int
) -> void:
	row.add_theme_constant_override("separation", row_sep)
	for node in row.get_children():
		if node is Label:
			var lab := node as Label
			if lab.name.ends_with("Label"):
				lab.custom_minimum_size = Vector2(label_w, slider_h)
			else:
				lab.custom_minimum_size = Vector2(value_w, slider_h)
			lab.add_theme_font_size_override("font_size", font_sz)
			lab.add_theme_constant_override("outline_size", outline_sz)
		elif node is Range:
			var sli := node as Range
			sli.custom_minimum_size = Vector2(slider_w, slider_h)


func _sync_sliders_from_settings() -> void:
	_volume_slider.set_value_no_signal(GameSettings.master_volume_linear * 100.0)
	_music_slider.set_value_no_signal(GameSettings.music_volume_linear * 100.0)
	_fov_slider.set_value_no_signal(GameSettings.fov_degrees)
	_day_slider.set_value_no_signal(GameSettings.day_night * 100.0)
	var ms := GameSettings.mouse_sensitivity
	var t := inverse_lerp(_MOUSE_SENS_MIN, _MOUSE_SENS_MAX, ms)
	_mouse_slider.set_value_no_signal(lerpf(0.0, 100.0, clampf(t, 0.0, 1.0)))


func _refresh_all_labels() -> void:
	_volume_value.text = str(int(round(_volume_slider.value))) + "%"
	_music_value.text = str(int(round(_music_slider.value))) + "%"
	_fov_value.text = str(int(round(_fov_slider.value))) + "°"
	if _day_slider.value < 15.0:
		_day_value.text = "Night"
	elif _day_slider.value > 85.0:
		_day_value.text = "Day"
	else:
		_day_value.text = str(int(round(_day_slider.value))) + "%"
	_mouse_value.text = String.num(GameSettings.mouse_sensitivity, 4)


func _on_volume_slider_changed(v: float) -> void:
	GameSettings.set_master_volume_linear(v / 100.0)
	_refresh_all_labels()


func _on_music_slider_changed(v: float) -> void:
	GameSettings.set_music_volume_linear(v / 100.0)
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
