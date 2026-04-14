extends Control

@onready var bar: ProgressBar = $Bar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_health(current_hp: float, max_hp: float) -> void:
	bar.max_value = max_hp
	bar.value = current_hp
