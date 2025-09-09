shader_type canvas_item;
render_mode unshaded;

uniform float speed : hint_range(0.0, 5.0) = 0.5;

void fragment() {
    // Derive resolution and aspect from pixel size
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    float aspect = resolution.x / resolution.y;

    // Normalized coords centered at (0,0)
    vec2 uv = (SCREEN_UV * 2.0 - 1.0);
    uv.x *= aspect;

    float time = TIME * speed;
    vec3 col = vec3(0.0);

    const int STAR_COUNT = 100;

    for (int i = 0; i < STAR_COUNT; i++) {
        float seed = float(i);
        float angle = fract(sin(seed * 12.9898) * 43758.5453) * 6.28318530718;
        float radius = fract(sin(seed * 78.233) * 12345.6789);
        vec2 star_pos = vec2(cos(angle), sin(angle)) * radius;

        float depth = fract(sin(seed * 0.812) * 3456.789 + time);
        float z = 0.1 + depth * 2.0;

        vec2 pos = star_pos / z;
        float brightness = pow(1.0 - depth, 0.3);

        float d = length(uv - pos);
        col += vec3(1.0) * smoothstep(0.005, 0.0005, d) * brightness;
    }

    COLOR = vec4(col, 1.0);
}
