tool
class_name VisibilityTester
extends Node2D

export var is_locked := false

var _entity_center_position := Vector2.ZERO
var _entity_visibility_range := 0.0
var _walls_tile_data_size: int = 0
var _caster := ShadowCaster.new(funcref(self, "_is_opaque_cellv"))

func _ready():
    if not Engine.editor_hint:
        set_process(false)

func _process(_delta: float):
    if is_locked or not Engine.editor_hint:
        return
    var is_changed: bool = \
        _entity_center_position != _get_entity_center_position() \
        or _entity_visibility_range != $Entity.visibility_range \
        or _walls_tile_data_size != $Walls.tile_data.size()
    if not is_changed:
        return
    _update_visible()

func _update_visible():
    print_debug("VisibilityTester: updating visibility tiles")
    _entity_center_position = _get_entity_center_position()
    _entity_visibility_range = $Entity.visibility_range
    _walls_tile_data_size = $Walls.tile_data.size()
    $Visibility.clear()
    for v in actual_visible():
        $Visibility.set_cellv(v, 0)

func _get_entity_center_position():
    return $Entity.position + $Entity/Center.position

func actual_visible() -> Dictionary:
    var v := _world_to_map_offset(_get_entity_center_position())
    return _caster.find_visible($Entity.visibility_range, v)

func expected_visible() -> Dictionary:
    var visible := {}
    for v in $Visibility.get_used_cells():
        visible[v] = true
    return visible

func _is_opaque_cellv(v: Vector2) -> bool:
    return $Walls.get_cellv(v) != -1

func _current_entity_center_position():
    return _get_entity_center_position()

# Find cell + offset relative to cell _center_
func _world_to_map_offset(pos: Vector2) -> PoolVector2Array:
    var cell_size: Vector2 = $Walls.cell_size
    var cell: Vector2 = $Walls.world_to_map(pos)
    var cell_origin: Vector2 = $Walls.map_to_world(cell) + cell_size / 2
    var offset: Vector2 = (pos - cell_origin) / cell_size
    return PoolVector2Array([cell, offset])
