shader_type canvas_item;

// --- Controls ---
uniform float stretch : hint_range(0.0, 100.0, 0.1) = 0.8;
uniform float thing1  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing2  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing3  : hint_range(0.0, 100.0, 0.1) = 0.8;

uniform float scale   : hint_range(0.000, 100.0, 0.001) = 1.0;
uniform float speed   : hint_range(0.0, 5.0, 0.01) = 1.0;

// --- Custom black/gray colormap ---
vec3 colormap(float x) {
    float t = clamp(x, 0.0, 1.0);

    // ultra-dark gradient
    vec3 near_black   = vec3(0.0, 0.0, 0.0);      // pure black
    vec3 deep_gray    = vec3(0.05, 0.05, 0.05);   // almost black
    vec3 darker_gray  = vec3(0.15, 0.15, 0.15);   // dark gray
    vec3 mid_gray     = vec3(0.25, 0.25, 0.25);   // slightly lighter gray

    if (t < 0.33) {
        return mix(near_black, deep_gray, t / 0.33);
    } else if (t < 0.66) {
        return mix(deep_gray, darker_gray, (t - 0.33) / 0.33);
    } else {
        return mix(darker_gray, mid_gray, (t - 0.66) / 0.34);
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
    vec3 color = colormap(shade);
    COLOR = vec4(color, 1.0);
}
