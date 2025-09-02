shader_type canvas_item;

uniform sampler2D noise_tex;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    // Get pixel resolution
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;

    // Normalized fragment coordinates
    vec2 fragCoord = FRAGCOORD.xy;
    vec2 u = fragCoord;
    vec2 res = iResolution;

    vec4 o = vec4(0.0);
    float t = TIME * 0.7;

    // Random offset from noise texture
    float d = 0.125 * texture(noise_tex, fract(u / 1024.0)).a;

    // Adjust UVs similar to Shadertoy
    u = (u + u - res) / res.y;

    float i = 0.0;
    while (i < 100.0) {
        vec3 p = vec3(u * d, d + t);

        for (float s = 1.0; s < 6.0; s++) {
            p += sin(t + p.yzx * s) * 0.25;
        }

        float radius = tanh(cos(0.3 * t + sin(t * 0.5))) * 0.6 + 0.3;
        float tunnel = length(p.xy - u);

        float step_size = 0.005 + abs(radius - tunnel) * 0.15;
        d += step_size;

        o += (1.0 + cos(p.z + vec4(4.0, 2.0, 1.0, 0.0))) / step_size;

        i += 1.0;
    }

    // Tonemap
    o = tanh(o / 8000.0 / max(length(u), 0.5));

    // Feedback blend with previous frame
    vec3 prev = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
    o.rgb = mix(prev, o.rgb, 0.5);

    COLOR = o;
}
