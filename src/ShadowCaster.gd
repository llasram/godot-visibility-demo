class_name ShadowCaster
extends Reference

const OCTANTS: Array = [
    Transform2D(Vector2.RIGHT, Vector2.DOWN,  Vector2.ZERO),
    Transform2D(Vector2.DOWN,  Vector2.RIGHT, Vector2.ZERO),
    Transform2D(Vector2.DOWN,  Vector2.LEFT,  Vector2.ZERO),
    Transform2D(Vector2.LEFT,  Vector2.DOWN,  Vector2.ZERO),
    Transform2D(Vector2.LEFT,  Vector2.UP,    Vector2.ZERO),
    Transform2D(Vector2.UP,    Vector2.LEFT,  Vector2.ZERO),
    Transform2D(Vector2.UP,    Vector2.RIGHT, Vector2.ZERO),
    Transform2D(Vector2.RIGHT, Vector2.UP,    Vector2.ZERO),
    ]

const SQUARE_TOP_RIGHT: Vector2 = Vector2(0.5, -0.5)
const SQUARE_BOTTOM_LEFT: Vector2 = Vector2(-0.5, 0.5)

const EPSILON: float = 1e-3

var _opaqueness: FuncRef

func _init(opaqueness: FuncRef):
    _opaqueness = opaqueness

func find_visible(max_range: float, origin) -> Dictionary:
    var cell: Vector2
    var offset: Vector2
    if origin is Vector2:
        cell = origin as Vector2
        offset = Vector2.ZERO
    else:
        cell = origin[0]
        offset = origin[1]
    return _find_visible(max_range, cell, offset)

func _find_visible(
        max_range: float,
        origin: Vector2,
        offset: Vector2
        ) -> Dictionary:
    var casting := ShadowCasting.new(self, max_range, origin, offset)
    var visible := casting.find_visible()
    casting.free()
    return visible

func _is_opaque_cellv(v: Vector2) -> bool:
    return _opaqueness.call_func(v)

class ShadowCasting:
    extends Object

    var _sself: ShadowCaster
    var _max_range: float
    var _max_range_sq: float
    var _origin: Vector2
    var _offset: Vector2
    var _beams: BeamList
    var _visible: Dictionary

    func _init(
            sself: ShadowCaster,
            max_range: float,
            origin: Vector2,
            offset: Vector2
            ):
        _sself = sself
        _max_range = max_range
        _max_range_sq = max_range * max_range
        _origin = origin
        _offset = offset
        _beams = BeamList.new()
        _visible = {origin: true}

    func free():
        _beams.free()
        .free()

    func find_visible() -> Dictionary:
        for t_octant in OCTANTS:
            _add_visible_octant(t_octant)
        return _visible

    # Find visible tiles in an octant and add them to the visible set.
    #
    # For performance reasons, this implementation represents slopes as `float`
    # and light/shadow beams as `Vector2`.  Using these built-in types yields a
    # ~16x speedup over an implementation representing rational slopes and beams
    # with custom Reference types.
    func _add_visible_octant(t_octant: Transform2D):
        var t_mapping := Transform2D().translated(_origin) * t_octant
        var offset: Vector2 = t_octant.inverse().xform(_offset)
        _beams.begin_octant()
        for x in range(1, _max_range + 1):
            var beam: Vector2 = _beams.pop()
            var max_y := min(x, int(sqrt(_max_range_sq - x*x)))
            for y in range(max_y + 1):
                var v := Vector2(x, y)
                var shadow := _tile_shadow(v, offset)
                # Is current beam end before tile shadow start?
                if beam.y <= shadow.x:
                    beam = _beams.push_pop(beam)
                    if beam == Vector2.ZERO:
                        break
                # Is tile shadow end before current beam start?
                if shadow.y <= beam.x:
                    continue
                # Beam touches tile -- check visibility
                var w: Vector2 = t_mapping.xform(v)
                var is_opaque := _sself._is_opaque_cellv(w)
                var is_needle := beam.x >= beam.y
                if (not is_needle) or is_opaque:
                    _visible[w] = true
                # Do not propagate needle beams
                if is_needle:
                    beam = _beams.pop()
                    if beam == Vector2.ZERO:
                        break
                    continue
                # Modify beam(s) to exclude shadows if necessary
                if not is_opaque:
                    # (1) Tile not opaque; do nothing
                    pass
                elif shadow.x < beam.x and beam.y < shadow.y:
                    # (2) Shadow encompasses beam; drop beam
                    beam = _beams.pop()
                    if beam == Vector2.ZERO:
                        break
                elif shadow.x < beam.x and beam.x < shadow.y:
                    # (3) Shadow encroaches upon beam begin
                    beam.x = shadow.y
                elif shadow.x < beam.y and beam.y < shadow.y:
                    # (4) Shadow encroaches upon beam end
                    beam.y = shadow.x
                    beam = _beams.push_pop(beam)
                    if beam == Vector2.ZERO:
                        break
                else:
                    # (5) Shadow splits beam into two sub-beams
                    _beams.push(Vector2(beam.x, shadow.x))
                    beam.x = shadow.y
            if beam != Vector2.ZERO:
                _beams.push(beam)
            if not _beams.try_next():
                break

    static func _tile_shadow(v: Vector2, offset: Vector2) -> Vector2:
        # We need to take the offset as an additional parameter in order to
        # reduce floating point differences when offsetting from the same point
        # derived from different tile centers
        return Vector2(_slope((v + SQUARE_TOP_RIGHT) - offset),
                       _slope((v + SQUARE_BOTTOM_LEFT) - offset))

    static func _slope(v: Vector2) -> float:
        # Treat values arbitrarily close to zero as zero in order to avoid
        # catastrophic precision loss at offsets very close to tile edges
        if v.y < EPSILON and -EPSILON < -v.y:
            return 0.0
        elif v.x < EPSILON and -EPSILON < -v.x:
            return sign(v.y) * INF
        else:
            return v.y / v.x

class BeamList:
    extends Object

    var _beams: Array = []
    var _beams_next: Array = []
    var _i: int = 0

    func begin_octant():
        _beams.clear()
        _beams_next.clear()
        _i = 0
        _beams.push_back(Vector2(0.0, 1.0))

    func pop() -> Vector2:
        if _i >= _beams.size():
            return Vector2.ZERO
        var result := _beams[_i] as Vector2
        _i += 1
        return result

    func push(beam: Vector2) -> void:
        _beams_next.push_back(beam)

    func push_pop(beam: Vector2) -> Vector2:
        push(beam)
        return pop()

    func try_next() -> bool:
        if _beams_next.empty():
            return false
        var beams := _beams
        beams.clear()
        _beams = _beams_next
        _beams_next = beams
        _i = 0
        return true
