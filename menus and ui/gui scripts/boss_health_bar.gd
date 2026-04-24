extends CanvasLayer

@export var boss_group: StringName = &"Boss"
@export var boss_display_name: String = "ABSOLUTE SPHERE"

## Fill / track colors while the boss still has its shield rings (not yet vulnerable).
@export var fill_color_normal: Color = Color(0.9, 0.05, 0.1, 1.0)
@export var background_color_normal: Color = Color(0.08, 0.02, 0.02, 1.0)
## Colors once the boss enters the vulnerable / "weak" phase (shields dropped).
@export var fill_color_weak: Color = Color(0.25, 0.55, 1.0, 1.0)
@export var background_color_weak: Color = Color(0.04, 0.08, 0.18, 1.0)

@export_group("Title scaling")
@export var reference_viewport_height: float = 1080.0
@export var base_title_font_size: int = 42
@export var min_title_font_size: int = 16
@export var max_title_font_size: int = 72
@export var base_timer_font_size: int = 56
@export var min_timer_font_size: int = 20
@export var max_timer_font_size: int = 120

@onready var root: Control = $Root
@onready var name_label: Label = $Root/Name
@onready var bar: ProgressBar = $Root/Bar
@onready var weak_timer_label: Label = $TimerLabel

var _boss: Node = null
var _boss_is_weak: bool = false
## True when the boss is alive and should show the bar; hidden if a modal blocks the HUD.
var _wants_boss_hud: bool = false
var _fill_style: StyleBoxFlat
var _bg_style: StyleBoxFlat
var _label_settings_template: LabelSettings
var _timer_label_settings_template: LabelSettings


func _ready() -> void:
	_cache_theme_resources()
	_cache_timer_label_settings()
	_set_visible(false)
	_connect_overlay_hud_listeners()
	_try_bind_to_boss()
	_apply_title_scale()
	_apply_timer_label_scale()
	_apply_bar_layout()
	_apply_timer_corner_layout()
	get_viewport().size_changed.connect(_on_viewport_resized)
	if weak_timer_label:
		weak_timer_label.visible = false
	_refresh_boss_layer_visible()


func _on_viewport_resized() -> void:
	_apply_title_scale()
	_apply_timer_label_scale()
	_apply_bar_layout()
	_apply_timer_corner_layout()
	_refresh_boss_layer_visible()


func _connect_overlay_hud_listeners() -> void:
	var g: Node = get_parent()
	if not g:
		return
	for p: String in ["pause menu", "death_menu", "upgrades_screen"]:
		var n: Node = g.get_node_or_null(p)
		if n and not n.visibility_changed.is_connected(Callable(self, &"_on_overlay_hud_changed")):
			n.visibility_changed.connect(Callable(self, &"_on_overlay_hud_changed"))


func _on_overlay_hud_changed() -> void:
	_refresh_boss_layer_visible()


func _is_modal_blocking_boss_hud() -> bool:
	var g: Node = get_parent()
	if not g:
		return false
	var pause_n: Node = g.get_node_or_null("pause menu")
	if pause_n and pause_n.visible:
		return true
	var death_n: Node = g.get_node_or_null("death_menu")
	if death_n and death_n.visible:
		return true
	var upgrade_n: Node = g.get_node_or_null("upgrades_screen")
	if upgrade_n and upgrade_n.visible:
		return true
	return false


func _refresh_boss_layer_visible() -> void:
	var can_show: bool = _wants_boss_hud and not _is_modal_blocking_boss_hud()
	visible = can_show
	if not can_show and weak_timer_label:
		weak_timer_label.visible = false


func _apply_bar_layout() -> void:
	var vp := get_viewport()
	var h: float = vp.get_visible_rect().size.y
	if h <= 1.0:
		return
	# Centered bottom band (name + bar) across full width.
	var band: float = clampf(168.0 / h, 0.09, 0.26)
	root.anchor_left = 0.0
	root.anchor_top = 1.0 - band
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	bar.custom_minimum_size.y = float(UiResponsive.scale_i_clamped(vp, 26.0, 10, 48))


## Weak-phase countdown only: bottom-left of the screen, scales with resolution.
func _apply_timer_corner_layout() -> void:
	if not weak_timer_label:
		return
	var vp := get_viewport()
	var s: Vector2 = vp.get_visible_rect().size
	if s.y <= 1.0 or s.x <= 1.0:
		return
	var m: float = float(UiResponsive.scale_i_clamped(vp, 10.0, 4, 28))
	var w_ratio: float = clampf(200.0 / s.x, 0.12, 0.26)
	weak_timer_label.anchor_left = 0.0
	weak_timer_label.anchor_top = 0.52
	weak_timer_label.anchor_right = w_ratio
	weak_timer_label.anchor_bottom = 0.98
	weak_timer_label.offset_left = m
	weak_timer_label.offset_top = 0.0
	weak_timer_label.offset_right = 0.0
	weak_timer_label.offset_bottom = 0.0


func _cache_theme_resources() -> void:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	var bg := bar.get_theme_stylebox("background") as StyleBoxFlat
	if fill:
		_fill_style = fill.duplicate() as StyleBoxFlat
		_fill_style.bg_color = fill_color_normal
		bar.add_theme_stylebox_override("fill", _fill_style)
	if bg:
		_bg_style = bg.duplicate() as StyleBoxFlat
		_bg_style.bg_color = background_color_normal
		bar.add_theme_stylebox_override("background", _bg_style)
	if name_label.label_settings:
		_label_settings_template = name_label.label_settings.duplicate() as LabelSettings


func _cache_timer_label_settings() -> void:
	if weak_timer_label and weak_timer_label.label_settings:
		_timer_label_settings_template = weak_timer_label.label_settings.duplicate() as LabelSettings


func _apply_timer_label_scale() -> void:
	if not weak_timer_label or not _timer_label_settings_template:
		return
	var h: float = get_viewport().get_visible_rect().size.y
	if h <= 1.0:
		return
	var factor: float = h / reference_viewport_height
	var sz: int = clampi(int(round(float(base_timer_font_size) * factor)), min_timer_font_size, max_timer_font_size)
	var ls: LabelSettings = _timer_label_settings_template.duplicate() as LabelSettings
	ls.font_size = sz
	ls.font_color = fill_color_weak
	weak_timer_label.label_settings = ls


func _apply_title_scale() -> void:
	if not _label_settings_template:
		return
	var h: float = get_viewport().get_visible_rect().size.y
	if h <= 1.0:
		return
	var factor: float = h / reference_viewport_height
	var sz: int = clampi(int(round(float(base_title_font_size) * factor)), min_title_font_size, max_title_font_size)
	var ls: LabelSettings = _label_settings_template.duplicate() as LabelSettings
	ls.font_size = sz
	name_label.label_settings = ls


func _process(_delta: float) -> void:
	if not is_instance_valid(_boss):
		_try_bind_to_boss()
	if _wants_boss_hud:
		_refresh_boss_layer_visible()
	_update_weak_timer_display()


func _disconnect_boss_signals() -> void:
	if not is_instance_valid(_boss):
		return
	if _boss.health_changed.is_connected(_on_boss_health_changed):
		_boss.health_changed.disconnect(_on_boss_health_changed)
	if _boss.has_signal("died") and _boss.died.is_connected(_on_boss_died):
		_boss.died.disconnect(_on_boss_died)
	if _boss.has_signal("weakness_changed") and _boss.weakness_changed.is_connected(_on_boss_weakness_changed):
		_boss.weakness_changed.disconnect(_on_boss_weakness_changed)


func _try_bind_to_boss() -> void:
	var candidate := get_tree().get_first_node_in_group(boss_group)
	if not is_instance_valid(candidate):
		_disconnect_boss_signals()
		_boss = null
		_set_visible(false)
		return
	if candidate == _boss:
		return
	if not candidate.has_signal("health_changed"):
		return

	_disconnect_boss_signals()
	_boss = candidate
	_boss.health_changed.connect(_on_boss_health_changed)
	if _boss.has_signal("died"):
		_boss.died.connect(_on_boss_died)
	if _boss.has_signal("weakness_changed"):
		_boss.weakness_changed.connect(_on_boss_weakness_changed)

	var max_hp := 100.0
	var curr_hp := 100.0
	if "max_hp" in _boss:
		max_hp = _boss.max_hp
	if "curr_hp" in _boss:
		curr_hp = _boss.curr_hp
	_boss_is_weak = false
	if _boss.has_method("is_boss_weak"):
		_boss_is_weak = _boss.is_boss_weak()
	_on_boss_health_changed(curr_hp, max_hp)
	_apply_phase_bar_colors()
	_update_weak_timer_display()


func _on_boss_weakness_changed(is_weak: bool) -> void:
	_boss_is_weak = is_weak
	_apply_phase_bar_colors()


func _on_boss_health_changed(current_hp: float, max_hp: float) -> void:
	bar.min_value = 0.0
	bar.max_value = max_hp
	bar.value = current_hp
	_apply_phase_bar_colors()
	_set_visible(current_hp > 0.0)


func _apply_phase_bar_colors() -> void:
	if not _fill_style:
		return
	if _boss_is_weak:
		name_label.text = boss_display_name + " (weak)"
		_fill_style.bg_color = fill_color_weak
		if _bg_style:
			_bg_style.bg_color = background_color_weak
	else:
		name_label.text = boss_display_name + " (sheilded)"
		_fill_style.bg_color = fill_color_normal
		if _bg_style:
			_bg_style.bg_color = background_color_normal
	bar.queue_redraw()


func _on_boss_died() -> void:
	_disconnect_boss_signals()
	_boss = null
	_set_visible(false)
	if weak_timer_label:
		weak_timer_label.visible = false


func _set_visible(is_visible: bool) -> void:
	_wants_boss_hud = is_visible
	root.visible = is_visible
	if not is_visible and weak_timer_label:
		weak_timer_label.visible = false
	_refresh_boss_layer_visible()


func _update_weak_timer_display() -> void:
	if not weak_timer_label:
		return
	if not is_instance_valid(_boss) or not _boss_is_weak or not _boss.has_method("get_weak_time_remaining"):
		weak_timer_label.visible = false
		return
	var t: float = _boss.get_weak_time_remaining()
	weak_timer_label.text = str(ceili(t)) + "s"
	weak_timer_label.visible = t > 0.0
