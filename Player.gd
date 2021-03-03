extends Node2D

signal input_queued

const MOVE_DURATION := 0.2

var visibility_range: float = 5.75

var _level: Level = null
var _move_step: Vector2 = Vector2.ZERO

var _animate_move_offset: Vector2 = Vector2.ZERO

onready var _center: Node2D = $Pivot/Center
onready var _camera: Camera2D = $Pivot/Center/Camera2D

func _unhandled_input(event: InputEvent):
    if event.is_action_pressed("ui_up", true):
        _request_move(Vector2.UP)
    elif event.is_action_pressed("ui_down", true):
        _request_move(Vector2.DOWN)
    elif event.is_action_pressed("ui_left", true):
        _request_move(Vector2.LEFT)
    elif event.is_action_pressed("ui_right", true):
        _request_move(Vector2.RIGHT)

func initialize(level: Level):
    _level = level
    call_deferred("_force_update_visibility")

func act():
    while $Tween.is_active():
        yield($Tween, "tween_all_completed")
    while _move_step == Vector2.ZERO:
        yield(self, "input_queued")
    var step := _move_step
    _move_step = Vector2.ZERO
    _try_move(step)
    yield(get_tree(), "idle_frame")

func _force_update_visibility():
    var m_pos := _level.map_position(self)
    var visible := _level.find_visible(self)
    Events.emit_signal("player_move_began", m_pos, m_pos, visible)
    Events.emit_signal("player_move_progressed", 1.0, _center.global_position)
    Events.emit_signal("player_move_completed")
    Events.emit_signal("player_visible_changed", visible)

func _request_move(step: Vector2):
    _move_step = step
    get_tree().set_input_as_handled()
    emit_signal("input_queued")

func _try_move(step: Vector2):
    var m_src := _level.map_position(self)
    var src := position
    if not _level.try_move(self, step):
        yield(get_tree(), "idle_frame")
        return
    var m_dst := _level.map_position(self)
    var visible := _find_visible()
    Events.emit_signal("player_move_began", m_src, m_dst, visible)
    _animate_move(src, visible)

func _animate_move(src: Vector2, visible: Dictionary):
    _animate_move_offset = src - position
    $Pivot.position = _animate_move_offset
    _camera.force_update_scroll()
    var tween: Tween = $Tween
    # warning-ignore:return_value_discarded
    tween.interpolate_method(self, "_animate_move_progress", 0.0, 1.0,
                             MOVE_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
    # warning-ignore:return_value_discarded
    tween.start()
    yield(tween, "tween_all_completed")
    Events.emit_signal("player_visible_changed", visible)
    Events.emit_signal("player_move_completed")

func _animate_move_progress(p: float):
    $Pivot.position = _animate_move_offset.linear_interpolate(Vector2.ZERO, p)
    Events.emit_signal("player_visible_changed", _find_visible())
    Events.emit_signal("player_move_progressed", p, _center.global_position)
    _camera.force_update_scroll()

func _find_visible() -> Dictionary:
    return _level.find_visible(self, $Pivot.position)
