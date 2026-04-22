extends Node3D

const _RingDamageAreaScript = preload("res://scripts/boss_ring_damage_area.gd")

@export var ring_a_speed := 0.6
@export var ring_b_speed := -0.9
@export var ring_c_speed := 1.2

## Seconds of fast spinning shield phase before the boss opens up.
@export var shield_phase_duration := 30.0
## Rotation speed multiplier once the vulnerable phase begins (lerps from 1.0 to this).
@export var vulnerable_ring_speed_mult := 0.12
## How long (seconds) to ease ring rotation down after the shield drops.
@export var ring_slow_blend_duration := 2.5
@export var ring_contact_damage := 75.0
@export var ring_damage_cooldown_sec := 0.45

@onready var boss_body: Node = $BossBody
@onready var ring_a_node: MeshInstance3D = $BossBody/RingRoot/RingA
@onready var ring_b_node: MeshInstance3D = $BossBody/RingRoot/RingB
@onready var ring_c_node: MeshInstance3D = $BossBody/RingRoot/RingC

var _phase_elapsed := 0.0
var _vulnerable_phase := false
var _slow_blend := 0.0


func _ready() -> void:
	_attach_ring_shield(ring_a_node)
	_attach_ring_shield(ring_b_node)
	_attach_ring_shield(ring_c_node)
	if boss_body and boss_body.has_method("set_shields_active"):
		boss_body.set_shields_active(true)


func _attach_ring_shield(ring: MeshInstance3D) -> void:
	var shield := StaticBody3D.new()
	shield.name = String(ring.name) + "Shield"
	shield.add_to_group("BossShield")
	ring.add_child(shield)
	var col := CollisionShape3D.new()
	var src_mesh: Mesh = ring.mesh
	if src_mesh:
		col.shape = src_mesh.create_trimesh_shape()
	shield.add_child(col)

	var dmg_area: BossRingDamageArea = _RingDamageAreaScript.new() as BossRingDamageArea
	dmg_area.name = "RingDamage"
	dmg_area.damage = ring_contact_damage
	dmg_area.hit_cooldown_sec = ring_damage_cooldown_sec
	dmg_area.collision_layer = 0
	dmg_area.collision_mask = 0xFFFFFFFF
	shield.add_child(dmg_area)
	if col.shape:
		var area_col := CollisionShape3D.new()
		area_col.shape = col.shape
		dmg_area.add_child(area_col)


func _process(delta: float) -> void:
	if not _vulnerable_phase:
		_phase_elapsed += delta
		if _phase_elapsed >= shield_phase_duration:
			_begin_vulnerable_phase()

	var sa := ring_a_speed
	var sb := ring_b_speed
	var sc := ring_c_speed
	if _vulnerable_phase:
		_slow_blend = minf(_slow_blend + delta / ring_slow_blend_duration, 1.0)
		var slow_t := lerpf(1.0, vulnerable_ring_speed_mult, _slow_blend)
		sa *= slow_t
		sb *= slow_t
		sc *= slow_t

	if ring_a_node:
		ring_a_node.rotate_y(sa * delta)
	if ring_b_node:
		ring_b_node.rotate_x(sb * delta)
	if ring_c_node:
		ring_c_node.rotate_z(sc * delta)


func _begin_vulnerable_phase() -> void:
	if _vulnerable_phase:
		return
	_vulnerable_phase = true
	_slow_blend = 0.0
	if boss_body and boss_body.has_method("set_shields_active"):
		boss_body.set_shields_active(false)
	_remove_ring_shields()


func _remove_ring_shields() -> void:
	for ring in [ring_a_node, ring_b_node, ring_c_node]:
		if not ring:
			continue
		var n: Node = ring.get_node_or_null(String(ring.name) + "Shield")
		if n:
			n.queue_free()
