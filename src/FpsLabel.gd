extends Label

func _process(_delta):
    text = "fps: " + str(Engine.get_frames_per_second())
