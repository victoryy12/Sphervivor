extends Node3D

@export var ring_a_speed := 0.6
@export var ring_b_speed := -0.9
@export var ring_c_speed := 1.2
@onready var a := $RingRoot/RingA
@onready var b := $RingRoot/RingB
@onready var c := $RingRoot/RingC


func _process(delta: float) -> void:
	if a:
		a.rotate_y(ring_a_speed * delta)
	if b:
		b.rotate_x(ring_b_speed * delta)
	if c:
		c.rotate_z(ring_c_speed * delta)
