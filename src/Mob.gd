extends Node2D

const MOVE_DURATION := 0.2

const STEPS: Array = [
    Vector2.UP,
    Vector2.RIGHT,
    Vector2.DOWN,
    Vector2.LEFT,
    ]

var _level: Level = null

func initialize(level: Level):
    _level = level

func act():
    while $Tween.is_active():
        yield($Tween, "tween_all_completed")
    var step := STEPS[randi() % STEPS.size()] as Vector2
    var src := position
    if not _level.try_move(self, step):
        yield(get_tree(), "idle_frame")
        return
    _animate_move(src)
    yield(get_tree(), "idle_frame")

func _animate_move(src: Vector2):
    $Sprite.position = src - position
    # warning-ignore:return_value_discarded
    $Tween.interpolate_property($Sprite, "position",
                                $Sprite.position, Vector2.ZERO, MOVE_DURATION,
                                Tween.TRANS_SINE, Tween.EASE_OUT)
    # warning-ignore:return_value_discarded
    $Tween.start()
