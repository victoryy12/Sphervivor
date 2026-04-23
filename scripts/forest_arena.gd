extends Node3D

@onready var _sun: DirectionalLight3D = $DirectionalLight3D

const _ENERGY_NIGHT := 0.12
const _ENERGY_DAY := 1.25
const _COLOR_NIGHT := Color(0.45, 0.55, 0.85)
const _COLOR_DAY := Color(1.0, 0.98, 0.92)


func _ready() -> void:
	GameSettings.day_night_changed.connect(_apply_day_night)
	_apply_day_night(GameSettings.day_night)


func _apply_day_night(t: float) -> void:
	if not _sun:
		return
	var u := clampf(t, 0.0, 1.0)
	_sun.light_energy = lerpf(_ENERGY_NIGHT, _ENERGY_DAY, u)
	_sun.light_color = _COLOR_NIGHT.lerp(_COLOR_DAY, u)
