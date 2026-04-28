extends Node3D

const _RingDamageAreaScript = preload("res://scripts/boss_ring_damage_area.gd")
const BOSS_PROJECTILE_SCENE := preload("res://boss_projectile.tscn")

@export var projectile_spawn_interval := 5.0
@export var projectiles_per_wave := 2

@export var ring_a_speed := 15
@export var ring_b_speed := -22
@export var ring_c_speed := 15

## Seconds of fast spinning shield phase before the boss opens up.
@export var shield_phase_duration := 30.0
## Rotation speed multiplier once the vulnerable phase begins (lerps from 1.0 to this).
@export var vulnerable_ring_speed_mult := 0.12
## How long (seconds) the boss stays damageable when shields are down, before they return.
@export var weak_phase_duration: float = 15.0
## How long (seconds) to ease ring rotation down after the shield drops.
@export var ring_slow_blend_duration := 2.5
@export var ring_contact_damage := 250.0
@export var ring_damage_cooldown_sec := 0.45

@onready var boss_body: Node = $BossBody
@onready var ring_a_node: MeshInstance3D = $BossBody/RingRoot/RingA
@onready var ring_b_node: MeshInstance3D = $BossBody/RingRoot/RingB
@onready var ring_c_node: MeshInstance3D = $BossBody/RingRoot/RingC

var _phase_elapsed := 0.0
var _weak_elapsed := 0.0
var _vulnerable_phase := false
var _slow_blend := 0.0

var _proj_spawn_elapsed := 0.0


func _ready() -> void:
	_attach_ring_shield(ring_a_node)
	_attach_ring_shield(ring_b_node)
	_attach_ring_shield(ring_c_node)
	if boss_body and boss_body.has_method("set_shields_active"):
		boss_body.set_shields_active(true)
	if is_instance_valid(boss_body) and boss_body.has_signal("died"):
		boss_body.died.connect(_on_boss_body_died, CONNECT_ONE_SHOT)


func _on_boss_body_died() -> void:
	_vulnerable_phase = false
	_weak_elapsed = 0.0
	_clear_boss_projectiles()
	set_process(false)


func _attach_ring_shield(ring: MeshInstance3D) -> void:
	if not is_instance_valid(ring):
		return
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
	if not is_instance_valid(boss_body):
		set_process(false)
		return

	if not _vulnerable_phase:
		_proj_spawn_elapsed += delta
		if _proj_spawn_elapsed >= projectile_spawn_interval:
			_proj_spawn_elapsed = 0.0
			_spawn_boss_projectile_wave()
		_phase_elapsed += delta
		if _phase_elapsed >= shield_phase_duration:
			_begin_vulnerable_phase()
		# Do not clear remaining time the same frame we just entered the weak phase.
		if not _vulnerable_phase and is_instance_valid(boss_body) and boss_body.has_method("set_weak_time_remaining"):
			boss_body.set_weak_time_remaining(0.0)
	else:
		_weak_elapsed += delta
		if is_instance_valid(boss_body) and boss_body.has_method("set_weak_time_remaining"):
			boss_body.set_weak_time_remaining(maxf(0.0, weak_phase_duration - _weak_elapsed))
		if _weak_elapsed >= weak_phase_duration:
			if is_instance_valid(ring_a_node) and is_instance_valid(ring_b_node) and is_instance_valid(ring_c_node):
				_end_vulnerable_phase()

	var sa := ring_a_speed
	var sb := ring_b_speed
	var sc := ring_c_speed
	if _vulnerable_phase:
		_slow_blend = minf(_slow_blend + delta / ring_slow_blend_duration, 1.0)
		var slow_t := lerpf(1.0, vulnerable_ring_speed_mult, _slow_blend)
		sa *= slow_t
		sb *= slow_t
		sc *= slow_t

	if is_instance_valid(ring_a_node):
		ring_a_node.rotate_y(sa * delta)
	if is_instance_valid(ring_b_node):
		ring_b_node.rotate_x(sb * delta)
	if is_instance_valid(ring_c_node):
		ring_c_node.rotate_z(sc * delta)


func _clear_boss_projectiles() -> void:
	for hazard in get_tree().get_nodes_in_group("BossProjectile"):
		if is_instance_valid(hazard):
			hazard.queue_free()


func _spawn_boss_projectile_wave() -> void:
	if _vulnerable_phase:
		return
	if not is_instance_valid(boss_body):
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var origin: Vector3 = (boss_body as Node3D).global_position
	var n: int = maxi(projectiles_per_wave, 1)
	for i in range(n):
		var p: Node = BOSS_PROJECTILE_SCENE.instantiate()
		root.add_child(p)
		if p is Node3D:
			var angle := TAU * float(i) / float(n)
			var ring_off := Vector3(cos(angle), 0.35 + 0.12 * sin(float(i * 2)), sin(angle)) * 16.0
			(p as Node3D).global_position = origin + ring_off
			if p is RigidBody3D:
				(p as RigidBody3D).linear_velocity = ring_off.normalized() * 6.0
		if p.has_method("setup_after_spawn"):
			p.call("setup_after_spawn", self, boss_body as PhysicsBody3D)


func _begin_vulnerable_phase() -> void:
	if _vulnerable_phase:
		return
	_vulnerable_phase = true
	_weak_elapsed = 0.0
	_slow_blend = 0.0
	if is_instance_valid(boss_body) and boss_body.has_method("set_weak_time_remaining"):
		boss_body.set_weak_time_remaining(weak_phase_duration)
	if boss_body and boss_body.has_method("set_shields_active"):
		boss_body.set_shields_active(false)
	_remove_ring_shields()


func _end_vulnerable_phase() -> void:
	if not _vulnerable_phase:
		return
	if not is_instance_valid(boss_body):
		return
	if not (is_instance_valid(ring_a_node) and is_instance_valid(ring_b_node) and is_instance_valid(ring_c_node)):
		return
	_vulnerable_phase = false
	_weak_elapsed = 0.0
	_phase_elapsed = 0.0
	_slow_blend = 0.0
	if is_instance_valid(boss_body) and boss_body.has_method("set_weak_time_remaining"):
		boss_body.set_weak_time_remaining(0.0)
	for ring in [ring_a_node, ring_b_node, ring_c_node]:
		_remove_ring_shield_if_exists(ring)
		_attach_ring_shield(ring)
	if boss_body and boss_body.has_method("set_shields_active"):
		boss_body.set_shields_active(true)


func _remove_ring_shields() -> void:
	for ring in [ring_a_node, ring_b_node, ring_c_node]:
		if not is_instance_valid(ring):
			continue
		_remove_ring_shield_if_exists(ring)


func _remove_ring_shield_if_exists(ring: Node3D) -> void:
	if not is_instance_valid(ring):
		return
	var n: Node = ring.get_node_or_null(String(ring.name) + "Shield")
	if n:
		n.queue_free()
