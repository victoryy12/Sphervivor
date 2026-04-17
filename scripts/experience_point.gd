extends Area3D

var exp_amount = 20

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("add_exp"):
		body.add_exp(exp_amount)
		queue_free()
