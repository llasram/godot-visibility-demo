tool
class_name AnnotatedTileSet
extends TileSet

enum {
    TILE_OPAQUE = 1,
    TILE_BARRIER = 2,
    TILE_WATER = 4,
    TILE_POISON = 8,
    }

export var click_to_update: bool = false setget _update_click
export var properties: PoolIntArray

func is_opaque(index: int) -> bool:
    return (properties[index] & TILE_OPAQUE) != 0

func is_barrier(index: int) -> bool:
    return (properties[index] & TILE_BARRIER) != 0

func _update():
    # warning-ignore:shadowed_variable
    var properties: Array = []
    for i in range(get_last_unused_tile_id()):
        properties.push_back(_properties_for_name(tile_get_name(i)))
    self.properties = PoolIntArray(properties)

func _properties_for_name(name: String) -> int:
    if not name:
        return 0
    var index := name.find_last(":")
    if index < 0:
        return 0
    var entry := 0
    for c in name.substr(index + 1).to_lower():
        match c:
            "o": entry |= TILE_OPAQUE
            "b": entry |= TILE_BARRIER
            "w": entry |= TILE_WATER
            "p": entry |= TILE_POISON
            _: push_error(c + ": unknown tile annotation")
    return entry

func _update_click(_value):
    _update()
