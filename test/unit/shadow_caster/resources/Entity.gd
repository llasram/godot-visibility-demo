extends Node2D

export var visibility_range: float = 2.0

func center_position() -> Vector2:
    return position + $Center.position
