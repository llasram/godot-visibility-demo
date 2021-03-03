class_name Terrain
extends TileMap

func world_to_map_offset(pos: Vector2) -> PoolVector2Array:
    var cell := world_to_map(pos + (cell_size / 2))
    var offset := (pos - map_to_world(cell)) / cell_size
    return PoolVector2Array([cell, offset])

func map_to_world_offset(pos, offset: Vector2 = Vector2.ZERO) -> Vector2:
    var cell: Vector2
    if pos is Vector2:
        cell = pos
    else:
        cell = pos[0]
        offset = pos[1]
    return map_to_world(cell) + (cell_size / 2) + (offset * cell_size)

func is_opaque_cell(x: int, y: int) -> bool:
    return tile_set.is_opaque(get_cell(x, y))

func is_opaque_cellv(v: Vector2) -> bool:
    return tile_set.is_opaque(get_cellv(v))

func is_barrier_cell(x: int, y: int) -> bool:
    return tile_set.is_barrier(get_cell(x, y))

func is_barrier_cellv(v: Vector2) -> bool:
    return tile_set.is_barrier(get_cellv(v))
