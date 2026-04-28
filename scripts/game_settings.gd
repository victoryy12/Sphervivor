extends Node

const CONFIG_PATH := "user://spherevivor_settings.cfg"

## Linear master gain 0–1 (applied to the Master audio bus).
var master_volume_linear: float = 1.0
## Linear gain 0–1 on the Music bus (background music routed there).
var music_volume_linear: float = 1.0
## Vertical field of view in degrees (player camera).
var fov_degrees: float = 75.0
## 0 = night, 1 = day (directional light / ambient feel).
var day_night: float = 1.0
## Mouse look sensitivity (same units as `player.gd` mouse_sensitivity).
var mouse_sensitivity: float = 0.002

signal fov_changed(degrees: float)
signal mouse_sensitivity_changed(value: float)
signal day_night_changed(t: float)


func _ready() -> void:
	load_settings()
	apply_master_volume()
	apply_music_volume()


func set_master_volume_linear(v: float) -> void:
	master_volume_linear = clampf(v, 0.0, 1.0)
	apply_master_volume()
	save_settings()


func set_music_volume_linear(v: float) -> void:
	music_volume_linear = clampf(v, 0.0, 1.0)
	apply_music_volume()
	save_settings()


func set_fov_degrees(v: float) -> void:
	fov_degrees = clampf(v, 55.0, 120.0)
	fov_changed.emit(fov_degrees)
	save_settings()


func set_day_night(v: float) -> void:
	day_night = clampf(v, 0.0, 1.0)
	day_night_changed.emit(day_night)
	save_settings()


func set_mouse_sensitivity(v: float) -> void:
	mouse_sensitivity = clampf(v, 0.00025, 0.012)
	mouse_sensitivity_changed.emit(mouse_sensitivity)
	save_settings()


func apply_master_volume() -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	if master_volume_linear < 0.0001:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume_linear))


func apply_music_volume() -> void:
	var bus: int = AudioServer.get_bus_index("Music")
	if bus < 0:
		return
	if music_volume_linear < 0.0001:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(music_volume_linear))


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CONFIG_PATH) != OK:
		return
	master_volume_linear = float(cf.get_value("audio", "master_linear", master_volume_linear))
	music_volume_linear = float(cf.get_value("audio", "music_linear", music_volume_linear))
	fov_degrees = float(cf.get_value("video", "fov", fov_degrees))
	day_night = float(cf.get_value("video", "day_night", day_night))
	mouse_sensitivity = float(cf.get_value("input", "mouse_sensitivity", mouse_sensitivity))
	apply_master_volume()
	apply_music_volume()


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master_linear", master_volume_linear)
	cf.set_value("audio", "music_linear", music_volume_linear)
	cf.set_value("video", "fov", fov_degrees)
	cf.set_value("video", "day_night", day_night)
	cf.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cf.save(CONFIG_PATH)
