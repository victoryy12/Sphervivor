extends Control

@onready var player_stats = get_parent().get_parent()
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
		"desc": 'Press the "E" key to gain use a bullet-time ability',
		"apply": func(player): player.jump_force += 10
	}
]

func showUpgrades():
	upgrades_open = !upgrades_open
	#get_tree().paused = upgrades_open
	self.visible = upgrades_open
	
	if upgrades_open:
		var upgrade_buttons = [$HBoxContainer/upgrade1, $HBoxContainer/upgrade2, $HBoxContainer/upgrade3]
		
		for i in range(len(upgrade_buttons)):
			upgrade_buttons[i].text = upgrades[i].name + "\n\n" + upgrades[i].desc

		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		
func applyUpgrade(index): 
	var upgrade = upgrades[index]  
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


func _on_upgrade_2_pressed() -> void:
	applyUpgrade(1)


func _on_upgrade_3_pressed() -> void:
	applyUpgrade(2)
