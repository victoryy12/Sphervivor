extends CanvasLayer

@onready var player_stats = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_health_bar()
	experience_bar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	speedometer()
	player_health_bar()
	experience_bar()
	energy_bar()
	
	
func player_health_bar():
	$playerHealth.max_value = player_stats.max_hp
	$playerHealth.value = player_stats.curr_hp


func experience_bar():
	$expBar.max_value = player_stats.exp_to_lvl
	$expBar.value = player_stats.curr_exp


func energy_bar():
	$energyBar.max_value = player_stats.max_energy
	$energyBar.value = player_stats.energy
	
	
func speedometer():
	var speed_mph = int(player_stats.linear_velocity.length())
	$speedometer.text = str(speed_mph) + " MPH"
