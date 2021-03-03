extends TextureRect

const MASK_LAYERS: int = 2
const LAYER_SEEN: int = 0
const LAYER_SEEN_OLD: int = 1

var map_origin: Vector2
var map_size: Vector2
var scale_transform: Transform2D
var map_transform: Transform2D

var _seen_image: Image
var _seen_texture: TextureArray
var _visibility_light: Light2D

onready var _world_viewport: Viewport = $WorldViewport
onready var _fog_viewport: Viewport = $FogViewport
onready var _visibility_viewport: Viewport = $VisibilityViewport
onready var _terrain: Terrain = $WorldViewport/Level/Terrain
onready var _player_light: Light2D = \
    $WorldViewport/Level/Entities/Player/Pivot/Center/Light2D

func _init():
    VisualServer.set_default_clear_color(Color.black)

func _ready():
    _init_terrain_params()
    _init_viewports()
    _init_seen_textures()
    _init_shader_params()
    _init_connect_events()
    _init_track_world_camera()

func _unhandled_input(event):
    _world_viewport.unhandled_input(event)

func _init_viewports():
    var viewport_size := _world_viewport.size
    scale_transform = Transform2D().scaled(viewport_size / rect_size)
    _fog_viewport.size = viewport_size
    _fog_viewport.add_child(_terrain.duplicate())
    _visibility_light = _player_light.duplicate()
    _visibility_light.range_layer_min = -1
    _visibility_light.color = Color.white
    _visibility_light.mode = Light2D.MODE_MIX
    _visibility_viewport.size = viewport_size
    _visibility_viewport.add_child(_visibility_light)

func _init_terrain_params():
    $VisibilityViewport/TerrainOccluder.initialize(_terrain)
    var used_rect := _terrain.get_used_rect()
    map_origin = used_rect.position - Vector2.ONE
    map_size = used_rect.size + Vector2(2, 2)
    map_transform = \
        Transform2D().translated(-map_origin) \
        * Transform2D().scaled(_terrain.cell_size).affine_inverse()

func _init_seen_textures():
    var size_x := int(map_size.x)
    var size_y := int(map_size.y)
    _seen_image = Image.new()
    _seen_image.create(size_x, size_y, false, Image.FORMAT_R8);
    _seen_texture = TextureArray.new()
    _seen_texture.create(size_x, size_y, MASK_LAYERS, Image.FORMAT_R8, 0);
    for i in range(MASK_LAYERS):
        _seen_texture.set_layer_data(_seen_image, i)

func _init_shader_params():
    material.set_shader_param("seen", _seen_texture)

func _init_connect_events():
    # warning-ignore:return_value_discarded
    Events.connect("player_move_began", self, "_on_player_move_began")
    # warning-ignore:return_value_discarded
    Events.connect("player_move_progressed", self, "_on_player_move_progressed")

func _init_track_world_camera():
    var id := _world_viewport.get_viewport_rid().get_id();
    var group_name := "__cameras_" + str(id);
    add_to_group(group_name)

func _camera_moved(t_camera: Transform2D, _screen_offset: Vector2):
    _fog_viewport.canvas_transform = t_camera
    _fog_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
    _visibility_viewport.canvas_transform = t_camera
    _visibility_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
    var t_corner := t_camera.affine_inverse()
    var t_seen := map_transform * t_corner * scale_transform
    material.set_shader_param("seen_transform", t_seen)

func _on_player_move_began(src: Vector2, dst: Vector2, visible: Dictionary):
    material.set_shader_param("move_progress", 0.0)
    _update_visible_transform("visible_old_transform", src)
    _update_visible_transform("visible_new_transform", dst)
    _update_mask_contents(visible)
    _seen_texture.set_layer_data(_seen_image, LAYER_SEEN)
    yield(Events, "player_move_completed")
    _seen_texture.set_layer_data(_seen_image, LAYER_SEEN_OLD)
    var t = material.get_shader_param("visible_new_transform")
    material.set_shader_param("visible_old_transform", t)
    material.set_shader_param("move_progress", 0.0)

func _update_visible_transform(param: String, m_position: Vector2):
    var pos := _terrain.map_to_world_offset(m_position)
    var t := Transform2D().translated(pos - 0.5 * _world_viewport.size)
    material.set_shader_param(param, map_transform * t * scale_transform)

func _update_mask_contents(visible: Dictionary):
    _seen_image.lock()
    for m_pos in visible:
        var v: Vector2 = m_pos - map_origin
        _seen_image.set_pixelv(v, Color.white)
    _seen_image.unlock()

func _on_player_move_progressed(p: float, pos: Vector2):
    material.set_shader_param("move_progress", p)
    _visibility_light.global_position = pos
    _visibility_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
