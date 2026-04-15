extends CanvasLayer

@onready var player_stats = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	playerHealthBar()	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	speedometer()
	playerHealthBar() 
	
	
func playerHealthBar():
	$playerHealth.max_value = player_stats.max_hp
	$playerHealth.value = player_stats.curr_hp
	
	
func speedometer():
	var speed_mph = int(player_stats.linear_velocity.length())
	$speedometer.text = str(speed_mph) + " MPH"
