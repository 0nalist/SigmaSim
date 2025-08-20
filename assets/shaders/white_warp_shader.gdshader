shader_type canvas_item;

// --- Controls ---
uniform float stretch : hint_range(0.0, 100.0, 0.1) = 0.8;
uniform float thing1  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing2  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing3  : hint_range(0.0, 100.0, 0.1) = 0.8;

uniform float scale   : hint_range(0.000, 100.0, 0.001) = 1.0;
uniform float speed   : hint_range(0.0, 5.0, 0.01) = 1.0;

// --- Colormap: Bridal white tones ---
vec3 bridal_colormap(float x) {
    float t = clamp(x, 0.0, 1.0);

    // Interpolated palette:
    // t = 0.0: warm ivory
    // t = 0.5: pearl white
    // t = 1.0: cool silvery white
    vec3 ivory = vec3(1.0, 0.98, 0.94);
    vec3 pearl = vec3(1.0, 0.99, 0.99);
    vec3 silver = vec3(0.95, 0.95, 0.96);

    if (t < 0.5) {
        return mix(ivory, pearl, t * 2.0);
    } else {
        return mix(pearl, silver, (t - 0.5) * 2.0);
    }
}

// --- Noise helpers ---
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x),
        u.y
    );
    return res * res;
}

// --- Core patterns ---
float fbm(vec2 p) {
    float t = TIME * speed;
    float f = 0.0;
    mat2 mtx = mat2(vec2(stretch, thing1), vec2(-thing2, thing3));
    f += 0.500000 * noise(p + t); p = mtx * p * 2.02;
    f += 0.031250 * noise(p);     p = mtx * p * 2.01;
    f += 0.250000 * noise(p);     p = mtx * p * 2.03;
    f += 0.125000 * noise(p);     p = mtx * p * 2.01;
    f += 0.062500 * noise(p);     p = mtx * p * 2.04;
    f += 0.015625 * noise(p + sin(t));
    return f / 0.96875;
}

float pattern(vec2 p) {
    return fbm(p + fbm(p + fbm(p)));
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / (scale / SCREEN_PIXEL_SIZE).y;
    float shade = pattern(uv);
    COLOR = vec4(bridal_colormap(shade), shade);
}
