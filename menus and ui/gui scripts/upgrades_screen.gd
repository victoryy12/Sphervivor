extends CanvasLayer

@onready var player_stats = get_parent().get_parent()
var current_choices = []	
var upgrades_open = false

var upgrades = [
	{
		"name": "Rolling Greese",
		"desc": "roll faster",
		"apply": func(player): player.rolling_force += 10
	}, {
		"name": "Rocket Jump",
		"desc": "Jump higher",
		"apply": func(player): player.jump_force += 10
	}, {
		"name": "Wumbo beam",
		"desc": "increase your mass",
		"apply": func(player): player.jump_force += 10
	}, {
		"name": "Slo-mo glasses",
		"desc": 'Press and hold the "E" key to use a bullet-time ability',
		"apply": func(player): player.jump_force += 10
	}, {
		"name": "Candy heart",
		"desc": 'Increases health regen',
		"apply": func(player): player.hp_regen += 0.15
	}
]

func showUpgrades():
	upgrades_open = !upgrades_open
	get_tree().paused = upgrades_open
	self.visible = upgrades_open
	
	if upgrades_open:
		current_choices = get_random_upgrades()
		
		var upgrade_buttons = [$HBoxContainer/upgrade1, $HBoxContainer/upgrade2, $HBoxContainer/upgrade3]
		
		for i in range(len(upgrade_buttons)):
			upgrade_buttons[i].text = current_choices[i].name + "\n\n" + current_choices[i].desc

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	
func get_random_upgrades():
	var copy = upgrades.duplicate()
	copy.shuffle()
	return copy.slice(0, 3)
	
	
func applyUpgrade(index): 
	var upgrade = current_choices[index]  
	if player_stats: 
		upgrade.apply.call(player_stats)  
		showUpgrades()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shop test"):
		showUpgrades()
		
		
func _ready() -> void:
	self.visible = false
	
	
func _process(delta: float) -> void:
	pass
		
			
func _on_upgrade_1_pressed() -> void:
	applyUpgrade(0)
	print(current_choices[0])


func _on_upgrade_2_pressed() -> void:
	applyUpgrade(1)
	print(current_choices[1])


func _on_upgrade_3_pressed() -> void:
	applyUpgrade(2)
	print(current_choices[2])
