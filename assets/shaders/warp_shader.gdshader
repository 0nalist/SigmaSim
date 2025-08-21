shader_type canvas_item;

// --- Controls ---
uniform float stretch : hint_range(0.0, 100.0, 0.1) = 0.8;
uniform float thing1  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing2  : hint_range(0.0, 100.0, 0.1) = 0.6;
uniform float thing3  : hint_range(0.0, 100.0, 0.1) = 0.8;

uniform float scale   : hint_range(0.000, 100.0, 0.001) = 1.0;
uniform float speed   : hint_range(0.0, 5.0, 0.01) = 1.0;

// --- Exposed colors ---
uniform vec4 color_low  : source_color = vec4(0.21, 0.23, 0.30, 1.0);
uniform vec4 color_mid  : source_color = vec4(0.25, 0.56, 0.98, 1.0);
uniform vec4 color_high : source_color = vec4(0.70, 0.95, 1.00, 1.0);

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

vec3 tri_gradient(float x, vec3 a, vec3 b, vec3 c) {
	// 0..0.5 blend a->b, 0.5..1.0 blend b->c (smoothstep for nicer transitions)
	float m = smoothstep(0.0, 1.0, x);
	if (m < 0.5) {
		float t = smoothstep(0.0, 0.5, m);
		return mix(a, b, t);
	} else {
		float t = smoothstep(0.5, 1.0, m);
		return mix(b, c, t);
	}
}

void fragment() {
	vec2 uv = FRAGCOORD.xy / (scale / SCREEN_PIXEL_SIZE).y;
	float shade = clamp(pattern(uv), 0.0, 1.0);

	vec3 rgb = tri_gradient(shade, color_low.rgb, color_mid.rgb, color_high.rgb);
	COLOR = vec4(rgb, shade);
}
