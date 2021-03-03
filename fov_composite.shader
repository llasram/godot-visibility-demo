shader_type canvas_item;
render_mode unshaded;

const int LAYER_SEEN = 0;
const int LAYER_SEEN_OLD = 1;
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D fog_of_war;
uniform sampler2D visible;
uniform sampler2DArray seen;

uniform mat4 visible_old_transform;
uniform mat4 visible_new_transform;
uniform mat4 seen_transform;
uniform float move_progress;

varying vec4 vertex4;

void vertex() {
    vertex4 = vec4(VERTEX, 0.0, 1.0);
}

void fragment() {
    ivec2 seen_uv = ivec2((seen_transform * vertex4).xy);
    ivec2 visible_new_uv = ivec2((visible_new_transform * vertex4).xy);
    ivec2 visible_old_uv = ivec2((visible_old_transform * vertex4).xy);
    float ssn = texelFetch(seen, ivec3(seen_uv, LAYER_SEEN), 0).r;
    float sso = texelFetch(seen, ivec3(seen_uv, LAYER_SEEN_OLD), 0).r;
    float svn = texelFetch(seen, ivec3(visible_new_uv, LAYER_SEEN), 0).r;
    float svo = texelFetch(seen, ivec3(visible_old_uv, LAYER_SEEN_OLD), 0).r;
    float s_slide = (seen_uv == visible_new_uv) ? ssn : sso;
    float s_fade = mix(sso, ssn, move_progress);
    float s = (svo == svn) ? s_slide : s_fade;
    float v = texture(visible, UV).r;
    vec4 real = texture(TEXTURE, UV);
    vec4 fog = texture(fog_of_war, UV);
    COLOR = mix(mix(BLACK, fog, s), real, v);
}
