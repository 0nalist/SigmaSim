shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform int iterations : hint_range(1, 128) = 77;
uniform float normal_eps : hint_range(0.0001, 0.01) = 0.001;
uniform float spec_power : hint_range(1.0, 128.0) = 32.0;

float sdf_map(vec3 p) {
    p = abs(fract(p) - 0.5);
    return abs(min(length(p.xy) - 0.175, min(p.x, p.y) + 1e-3)) + 1e-3;
}

vec3 estimate_normal(vec3 p) {
    float eps = normal_eps;
    float dx = sdf_map(p + vec3(eps, 0.0, 0.0)) - sdf_map(p - vec3(eps, 0.0, 0.0));
    float dy = sdf_map(p + vec3(0.0, eps, 0.0)) - sdf_map(p - vec3(0.0, eps, 0.0));
    float dz = sdf_map(p + vec3(0.0, 0.0, eps)) - sdf_map(p - vec3(0.0, 0.0, eps));
    return normalize(vec3(dx, dy, dz));
}

mat2 mat2_from_vec4(vec4 v) {
    // Godot expects mat2 constructed from 2 column vec2s (column-major).
    return mat2(vec2(v.x, v.y), vec2(v.z, v.w));
}

void fragment() {
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;    // viewport size in pixels
    vec2 C = UV * res;                      // pixel coords like Shadertoy
    vec2 r = res;
    vec2 uv = (C - 0.5 * r) / r.y;

    float t = TIME * speed;
    float z = fract(dot(C, sin(C))) - 0.5;

    vec3 col_accum = vec3(0.0);

    for (int i = 0; i < 128; i++) {
        if (i >= iterations) {
            break;
        }

        vec4 p = vec4(z * normalize(vec3(C - 0.7 * r, r.y)), 0.1 * t);
        p.z += t;

        vec4 q = p;

        // Replace mat2(vec4) with explicit columns:
        vec4 k1 = cos(2.0 + q.z + vec4(0.0, 11.0, 33.0, 0.0));
        p.xy *= mat2_from_vec4(k1);

        vec4 k2 = cos(q + vec4(0.0, 11.0, 33.0, 0.0));
        p.xy *= mat2_from_vec4(k2);

        float d = sdf_map(p.xyz);

        vec3 pos = p.xyz;
        vec3 light_dir = normalize(vec3(0.3, 0.5, 1.0));
        vec3 view_dir  = normalize(vec3(uv, 1.0));
        vec3 n = estimate_normal(pos);
        vec3 reflect_dir = reflect(view_dir, n);

        vec3 env_color = mix(vec3(0.8, 0.4, 0.8), vec3(1.0), 0.5 + 0.5 * reflect_dir.y);
        float spec = pow(max(dot(reflect_dir, light_dir), 0.0), spec_power);

        vec4 base_color = (1.0 + sin(0.5 * q.z + length(p.xyz - q.xyz) + vec4(0.0, 4.0, 3.0, 6.0)))
                        / (0.5 + 2.0 * dot(q.xy, q.xy));

        vec3 final_color = base_color.rgb * 0.1 + env_color * 0.9 + vec3(spec) * 1.2;

        col_accum += final_color / max(d, 1e-4); // guard against div-by-zero
        z += 0.6 * d;
    }

    vec3 out_col = tanh(col_accum / 20000.0);
    COLOR = vec4(out_col, 1.0);
}
