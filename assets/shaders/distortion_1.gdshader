shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D noise;
uniform float distortion_intensity = 0.1;
uniform vec2  distortion_tiling    = vec2(1.0);
uniform vec2  distortion_offset_speed = vec2(0.2, 0.0);

void fragment() {
    vec2 uv   = UV;
    vec2 nuv  = uv * distortion_tiling + distortion_offset_speed * TIME;
    float n   = texture(noise, nuv).r;

    vec2 dist_uv = uv + n * distortion_intensity;

    vec4 tex = texture(texture_albedo, dist_uv);
    COLOR    = tex * COLOR;          // vertex‐color tint if any
}
