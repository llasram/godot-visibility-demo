extends Node2D

const FACE_COUNT := 4
const FACE_STEPS: Array = [
    Vector2.UP,
    Vector2.RIGHT,
    Vector2.DOWN,
    Vector2.LEFT,
    ]

var _face_polygons: Array = []

var _terrain: Terrain
var _scale: Transform2D
var _occluders: Array = []
var _visible: Dictionary = {}

func _init():
    var v: Vector2 = Vector2.ZERO
    for i in range(1, FACE_COUNT + 1):
        var v1: Vector2 = v + FACE_STEPS[i % FACE_COUNT]
        var polygon := VisualServer.canvas_occluder_polygon_create()
        VisualServer.canvas_occluder_polygon_set_cull_mode(
            polygon, VisualServer.CANVAS_OCCLUDER_POLYGON_CULL_CLOCKWISE)
        VisualServer.canvas_occluder_polygon_set_shape(
            polygon, PoolVector2Array([v, v1]), false)
        _face_polygons.append(polygon)
        v = v1

func _exit_tree():
    _free_occluders()

func initialize(terrain: Terrain):
    _terrain = terrain
    _scale = Transform2D().scaled(terrain.cell_size)
    # warning-ignore:return_value_discarded
    Events.connect("player_visible_changed", self, "_on_player_visible_changed")
    _free_occluders()
    _visible = {}

func _on_player_visible_changed(visible: Dictionary):
    if _has_all_same_keys(visible, _visible):
        return
    _visible = visible
    _update_occluders(visible)

static func _has_all_same_keys(a: Dictionary, b: Dictionary) -> bool:
    if a.size() != b.size():
        return false
    if a.hash() == b.hash():
        # Only probably, but good enough
        return true
    for k in a:
        if not k in b:
            return false
    return true

func _update_occluders(visible: Dictionary):
    # We could try to track which occluders need to change and update them
    # accordingly, but my intuition is that the GDScript performance of the
    # tracking logic would be worse than the engine performance of just freeing
    # and recreating the occluders every few frames.
    _free_occluders()
    for v in visible:
        if not _terrain.is_opaque_cellv(v):
            continue
        for i in range(FACE_COUNT):
            var v1: Vector2 = v + FACE_STEPS[i]
            if not v1 in visible or not _terrain.is_opaque_cellv(v1):
                _occluders.append(_create_occluder(v, _face_polygons[i]))

func _free_occluders():
    for rid in _occluders:
        VisualServer.free_rid(rid)
    _occluders.clear()

func _create_occluder(v: Vector2, polygon: RID):
    var occluder := VisualServer.canvas_light_occluder_create()
    VisualServer.canvas_light_occluder_set_polygon(occluder, polygon)
    var t := Transform2D().translated(_terrain.map_to_world(v)) * _scale
    VisualServer.canvas_light_occluder_set_transform(occluder, t)
    VisualServer.canvas_light_occluder_attach_to_canvas(occluder, get_canvas())
    VisualServer.canvas_light_occluder_set_light_mask(occluder, light_mask)
    return occluder
