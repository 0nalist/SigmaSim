shader_type canvas_item;

// --- Controls ---
uniform float stretch : hint_range(0.0, 100.0, 0.1) = 0.8;
uniform float thing1  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing2  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing3  : hint_range(0.0, 100.0, 0.1) = 0.8;

uniform float scale   : hint_range(0.000, 100.0, 0.001) = 1.0;
uniform float speed   : hint_range(0.0, 5.0, 0.01) = 1.0;

// --- Custom dark brown colormap ---
vec3 colormap(float x) {
    float t = clamp(x, 0.0, 1.0);

    // Near-black → deep umber → walnut → chestnut highlights
    vec3 near_black = vec3(0.03, 0.02, 0.02);
    vec3 espresso   = vec3(0.07, 0.05, 0.04);
    vec3 dark_umber = vec3(0.12, 0.08, 0.05);
    vec3 walnut     = vec3(0.20, 0.14, 0.09);
    vec3 chestnut   = vec3(0.30, 0.22, 0.15);

    // Smooth segmented ramp to avoid banding and keep it subdued
    if (t < 0.25) {
        return mix(near_black, espresso, t / 0.25);
    } else if (t < 0.50) {
        return mix(espresso, dark_umber, (t - 0.25) / 0.25);
    } else if (t < 0.75) {
        return mix(dark_umber, walnut, (t - 0.50) / 0.25);
    } else {
        return mix(walnut, chestnut, (t - 0.75) / 0.25);
    }
}

// --- Noise helpers ---
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);

    float res = mix(
        mix(rand(ip), rand(ip+vec2(1.0,0.0)), u.x),
        mix(rand(ip+vec2(0.0,1.0)), rand(ip+vec2(1.0,1.0)), u.x),
        u.y
    );
    return res*res;
}

// --- Core patterns ---
float fbm(vec2 p) {
    float t = TIME * speed;
    float f = 0.0;
    mat2 mtx = mat2(vec2(stretch, thing1), vec2(-thing2, thing3));
    f += 0.500000*noise(p + t); p = mtx*p*2.02;
    f += 0.031250*noise(p);     p = mtx*p*2.01;
    f += 0.250000*noise(p);     p = mtx*p*2.03;
    f += 0.125000*noise(p);     p = mtx*p*2.01;
    f += 0.062500*noise(p);     p = mtx*p*2.04;
    f += 0.015625*noise(p + sin(t));
    return f/0.96875;
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
