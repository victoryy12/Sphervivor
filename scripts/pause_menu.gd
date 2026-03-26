extends Control

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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_resume_button_pressed() -> void:
	pause_and_unpause()


func _on_restart_button_pressed() -> void:
	pause_and_unpause()
	get_tree().reload_current_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
