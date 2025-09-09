shader_type canvas_item;

/*
    Shadertoy → Godot 4 (canvas_item)
    - iResolution.xy -> (1.0 / SCREEN_PIXEL_SIZE)
    - iTime          -> TIME
*/

uniform vec2 tex_size = vec2(256.0, 256.0); // matches your "resolution"
uniform float grid_size = 0.79;
uniform float alpha : hint_range(0.0, 1.0) = 1.0; // new alpha parameter

void fragment() {
    // Recreate Shadertoy's fragCoord/iResolution setup
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 fragCoord  = SCREEN_UV * resolution;
    vec2 uv         = fragCoord / resolution;

    // Keep these for parity with original (not strictly needed later)
    vec2 adjusted_uv = (uv - 0.5) * vec2(tex_size.x / tex_size.y, 1.0);

    // Holo input/time
    vec2 holo = vec2(TIME * 0.75, TIME);
    float t = holo.y * 7.221 + TIME;

    vec2 uv_scaled_centered = (uv - 0.5) * 250.0;

    vec2 field_part1 = uv_scaled_centered + 50.0 * vec2(sin(-t / 143.6340), cos(-t / 99.4324));
    vec2 field_part2 = uv_scaled_centered + 50.0 * vec2(cos( t / 53.1532),  cos( t / 61.4532));
    vec2 field_part3 = uv_scaled_centered + 50.0 * vec2(sin(-t / 87.53218), sin(-t / 49.0000));

    float field = (1.0 + (
        cos(length(field_part1) / 19.483) +
        sin(length(field_part2) / 33.155) * cos(field_part2.y / 15.73) +
        cos(length(field_part3) / 27.193) * sin(field_part3.x / 21.92)
    )) / 2.0;

    float res = 0.5 + 0.5 * cos(holo.x * 2.612 + (field - 0.5) * 3.14);

    float fac = 0.5 * max(
        max(0.0, 7.0 * abs(cos(uv.x * grid_size * 20.0)) - 6.0),
        max(0.0, 7.0 * cos(uv.y * grid_size * 45.0 + uv.x * grid_size * 20.0) - 6.0)
    );
    fac = max(fac, max(0.0, 7.0 * cos(uv.y * grid_size * 45.0 - uv.x * grid_size * 20.0) - 6.0));

    float hueShift = res + fac;
    float baseHue = mod(hueShift * 0.25 + 0.5, 1.0);
    float sat = 0.7 + 0.3 * sin(TIME * 0.3 + hueShift * 3.0);
    float light = 0.6 + 0.4 * res;

    // HSL → RGB
    float h = baseHue;
    float s = sat;
    float l = light;

    float c = (1.0 - abs(2.0 * l - 1.0)) * s;
    float x = c * (1.0 - abs(mod(h * 6.0, 2.0) - 1.0));
    float m = l - 0.5 * c;

    vec3 rgb;
    if (h < 1.0 / 6.0)      rgb = vec3(c, x, 0.0);
    else if (h < 2.0 / 6.0) rgb = vec3(x, c, 0.0);
    else if (h < 3.0 / 6.0) rgb = vec3(0.0, c, x);
    else if (h < 4.0 / 6.0) rgb = vec3(0.0, x, c);
    else if (h < 5.0 / 6.0) rgb = vec3(x, 0.0, c);
    else                    rgb = vec3(c, 0.0, x);

    rgb += m;

    COLOR = vec4(rgb, alpha);
}
