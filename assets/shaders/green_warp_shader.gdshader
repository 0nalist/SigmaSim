shader_type canvas_item;

// --- Controls ---
uniform float stretch : hint_range(0.0, 100.0, 0.1) = 0.8;
uniform float thing1  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing2  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing3  : hint_range(0.0, 100.0, 0.1) = 0.8;

uniform float scale   : hint_range(0.000, 100.0, 0.001) = 1.0;
uniform float speed   : hint_range(0.0, 5.0, 0.01) = 1.0;

// --- Custom dark green colormap ---
vec3 colormap(float x) {
    // clamp shade
    float t = clamp(x, 0.0, 1.0);

    // define a tasteful gradient of dark greens
    vec3 dark_forest = vec3(0.05, 0.10, 0.05);  // near-black green
    vec3 deep_green  = vec3(0.05, 0.25, 0.08);  // deep moss
    vec3 mid_green   = vec3(0.10, 0.40, 0.15);  // richer green
    vec3 bright_green= vec3(0.25, 0.65, 0.30);  // highlight

    // blend in two steps to get a smooth ramp
    if (t < 0.33) {
        return mix(dark_forest, deep_green, t / 0.33);
    } else if (t < 0.66) {
        return mix(deep_green, mid_green, (t - 0.33) / 0.33);
    } else {
        return mix(mid_green, bright_green, (t - 0.66) / 0.34);
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
