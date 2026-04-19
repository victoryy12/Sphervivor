extends RigidBody3D

var exp_amount = 20

@onready var area = $collectionRange

func _ready():
	area.body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_exp(exp_amount)
		queue_free()
