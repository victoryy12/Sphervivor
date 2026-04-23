extends AudioStreamPlayer3D


@onready var music = $AudioStreamPlayer

func _ready():
	music.finished.connect(_on_music_finished)
	music.play()

func _on_music_finished():
	music.play()
