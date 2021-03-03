tool
extends ImageTexture
class_name CustomGradientTexture

enum GradientType {LINEAR, RADIAL, RECTANGULAR, RADIAL_SQUARED}

# Workaround for manual texture update
# because updating it while editing the gradient doesn't work well
enum Btn {ClickToUpdateTexture}
export(bool) var click_to_update_texture = null setget _update_texture

export(GradientType) var type = GradientType.LINEAR setget set_type
export var size = Vector2(256, 256) setget set_size
export(Gradient) var gradient: Gradient setget set_gradient

var data

func _init():
    data = Image.new()
    data.create(size.x, size.y, false, Image.FORMAT_RGBA8)

func _update():
    if not gradient:
        return

    data.lock()
    var radius = (size - Vector2(1.0, 1.0)) / 2
    var ratio = size.x / size.y

    if type == GradientType.LINEAR:
        for x in range(size.x):
            var ofs = float(x) / (size.x - 1)
            var color = gradient.interpolate(ofs)

            for y in range(size.y):
                data.set_pixel(x, y, color)

    elif type == GradientType.RADIAL:
        for x in range(size.x):
            for y in range(size.y):
                var dist = Vector2(x / ratio, y).distance_to(Vector2(radius.x / ratio, radius.y))
                var ofs = dist / radius.y
                var color = gradient.interpolate(ofs)
                data.set_pixel(x, y, color)

    elif type == GradientType.RADIAL_SQUARED:
        for x in range(size.x):
            for y in range(size.y):
                var dist = Vector2(x / ratio, y).distance_to(Vector2(radius.x / ratio, radius.y))
                var ofs = dist / radius.y
                var color: Color = gradient.interpolate(ofs * ofs)
                data.set_pixel(x, y, color)

    # Rectangular
    else:
        for x in range(size.x):
            for y in range(size.y):
                var dist_x = Vector2(x, 0).distance_to(Vector2(radius.x, 0))
                var dist_y = Vector2(0, y).distance_to(Vector2(0, radius.y))
                var ofs

                if dist_x > dist_y * ratio:
                    ofs = dist_x / radius.x
                else:
                    ofs = dist_y / radius.y

                var color = gradient.interpolate(ofs)
                data.set_pixel(x, y, color)

    data.unlock()
    create_from_image(data)

# Workaournd that allow to manual update the texture
#warning-ignore:unused_argument
func _update_texture(value):
    _update();

func set_type(value):
    type = value
    _update()

func set_size(value):
    size = value

    if size.x > 4096:
        size.x = 4096
    if size.y > 4096:
        size.y = 4096

    data.resize(size.x, size.y)
    _update()

func set_gradient(value):
    gradient = value
    _update()
