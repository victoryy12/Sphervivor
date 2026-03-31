extends Control

@onready var player_stats = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var speed_mph = int(player_stats.linear_velocity.length())
	$speedometer.text = str(speed_mph)
