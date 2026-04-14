extends RigidBody3D

@export var spikes_damage = 100.0


func spikes_deal_damage():
	return spikes_damage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
