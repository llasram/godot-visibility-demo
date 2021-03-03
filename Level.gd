class_name Level
extends Node2D

onready var _terrain := $Terrain as Terrain
onready var _visibility := \
    ShadowCaster.new(funcref(_terrain, "is_opaque_cellv"))

var _objects: Dictionary = {}
var _entities: Dictionary = {}

func _ready():
    $Terrain/CanvasModulate.visible = true
    $TerrainOccluder.initialize(_terrain)
    for node in $Entities.get_children():
        _entities[map_position(node)] = node
    for node in $Entities.get_children():
        node.initialize(self)
    _turn_loop()

func _turn_loop():
    while true:
        for node in $Entities.get_children():
            yield(node.act(), "completed")

func map_position(entity: Node2D) -> Vector2:
    return _terrain.world_to_map(entity.position)

func map_position_offset(entity: Node2D, offset: Vector2) -> PoolVector2Array:
    return _terrain.world_to_map_offset(entity.position + offset)

func try_move(entity: Node2D, step: Vector2) -> bool:
    var src := map_position(entity)
    var dst := src + step
    if dst in _entities:
        return false
    if _terrain.is_barrier_cellv(dst):
        return false
    assert(_entities.erase(src))
    _entities[dst] = entity
    entity.position = _terrain.map_to_world(dst)
    return true

func find_visible(entity: Node2D, offset: Vector2 = Vector2.ZERO) -> Dictionary:
    return _visibility.find_visible(
        entity.visibility_range,
        map_position_offset(entity, offset))
