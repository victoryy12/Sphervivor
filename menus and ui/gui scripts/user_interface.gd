extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
@onready var _speed: Label = $speedometer
@onready var _player_health: ProgressBar = $playerHealth
@onready var _exp_bar: ProgressBar = $expBar
@onready var _energy_bar: ProgressBar = $energyBar
@onready var _xp_label: Label = $XPLabel
@onready var _health_label: Label = $HealthLabel
@onready var _energy_label: Label = $energyLabel

var _speed_ls_base: LabelSettings
var _small_label_base: LabelSettings
var _health_label_base: LabelSettings


func _ready() -> void:
	_cache_label_settings()
	player_health_bar()
	experience_bar()
	energy_bar()
	_apply_hud_layout()
	get_viewport().size_changed.connect(_apply_hud_layout)


func _cache_label_settings() -> void:
	if _speed.label_settings:
		_speed_ls_base = _speed.label_settings.duplicate() as LabelSettings
	if _xp_label.label_settings:
		_small_label_base = _xp_label.label_settings.duplicate() as LabelSettings
	if _health_label.label_settings:
		_health_label_base = _health_label.label_settings.duplicate() as LabelSettings


func _apply_hud_layout() -> void:
	var vp := get_viewport()
	var s: Vector2 = vp.get_visible_rect().size
	var m: float = UiResponsive.scale_px_clamped(vp, 8.0, 4.0, 36.0)
	var gap: float = UiResponsive.scale_px_clamped(vp, 8.0, 3.0, 20.0)
	var bar_w: float = clampf(s.x * 0.36, UiResponsive.scale_px(vp, 140.0), s.x * 0.54)
	var bar_h: float = UiResponsive.scale_px_clamped(vp, 34.0, 12.0, 56.0)
	var caption_h: float = UiResponsive.scale_px_clamped(vp, 30.0, 18.0, 52.0)

	var x: float = m
	var y: float = m

	_pin_top_left(_health_label, x, y, bar_w * 0.55, caption_h)
	_apply_label_fonts(vp)
	y += caption_h + 2.0
	_pin_top_left(_player_health, x, y, bar_w, bar_h)
	y += bar_h + gap

	_pin_top_left(_xp_label, x, y, bar_w * 0.55, caption_h)
	y += caption_h + 2.0
	_pin_top_left(_exp_bar, x, y, bar_w, bar_h)
	y += bar_h + gap

	_pin_top_left(_energy_label, x, y, bar_w * 0.55, caption_h)
	y += caption_h + 2.0
	_pin_top_left(_energy_bar, x, y, bar_w, bar_h)

	var edge: float = UiResponsive.scale_px_clamped(vp, 10.0, 4.0, 36.0)
	var spd_w: float = UiResponsive.scale_px_clamped(vp, 175.0, 96.0, 360.0)
	var spd_h: float = UiResponsive.scale_px_clamped(vp, 149.0, 52.0, 260.0)
	_speed.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_speed.offset_left = -spd_w - edge
	_speed.offset_top = -spd_h - edge
	_speed.offset_right = -edge
	_speed.offset_bottom = -edge


func _apply_label_fonts(vp: Viewport) -> void:
	if _speed_ls_base:
		var ls_spd := _speed_ls_base.duplicate() as LabelSettings
		ls_spd.font_size = UiResponsive.scale_i_clamped(vp, 90.0, 22, 160)
		ls_spd.outline_size = UiResponsive.scale_i_clamped(vp, 15.0, 2, 28)
		ls_spd.shadow_size = maxi(UiResponsive.scale_i_clamped(vp, 5.0, 0, 16), 0)
		_speed.label_settings = ls_spd

	var sm: int = UiResponsive.scale_i_clamped(vp, 25.0, 10, 44)
	if _small_label_base:
		var ls_xp := _small_label_base.duplicate() as LabelSettings
		ls_xp.font_size = sm
		_xp_label.label_settings = ls_xp
		var ls_en := _small_label_base.duplicate() as LabelSettings
		ls_en.font_size = sm
		_energy_label.label_settings = ls_en

	if _health_label_base:
		var ls_hp := _health_label_base.duplicate() as LabelSettings
		ls_hp.font_size = UiResponsive.scale_i_clamped(vp, 40.0, 12, 64)
		_health_label.label_settings = ls_hp


func _pin_top_left(c: Control, x: float, y: float, w: float, h: float) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.offset_left = x
	c.offset_top = y
	c.offset_right = x + w
	c.offset_bottom = y + h


func _process(_delta: float) -> void:
	speedometer()
	player_health_bar()
	experience_bar()
	energy_bar()


func player_health_bar() -> void:
	_player_health.max_value = player_stats.max_hp
	_player_health.value = player_stats.curr_hp
	
	$HealthLabel.text = "Health"


func experience_bar() -> void:
	_exp_bar.max_value = player_stats.exp_to_lvl
	_exp_bar.value = player_stats.curr_exp


func energy_bar() -> void:
	_energy_bar.max_value = player_stats.max_energy
	_energy_bar.value = player_stats.energy


func speedometer() -> void:
	var speed_mph := int(player_stats.linear_velocity.length())
	_speed.text = str(speed_mph) + " MPH"
