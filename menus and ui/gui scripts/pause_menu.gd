extends CanvasLayer

#onready var player_stats = get_parent().get_parent()
var pausedCheck = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_and_unpause()
		
		
func _ready() -> void:
	self.visible = false
			
			
func pause_and_unpause():
	pausedCheck = !pausedCheck
	get_tree().paused = pausedCheck
	self.visible = pausedCheck
	
	if pausedCheck:
		#display_stats()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#func display_stats():
#	$stats/displayStats.text = ("Speed " + str(int(player_stats.rolling_force))+ "\n" + 
#	" Jump " + str(int(player_stats.jump_force)))


func _on_resume_button_pressed() -> void:
	pause_and_unpause()


func _on_restart_button_pressed() -> void:
	pause_and_unpause()
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
