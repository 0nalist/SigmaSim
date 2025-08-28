shader_type canvas_item;

// Animate from 0 to 1, result in 0 should be the same as in 1, a loop
// If you want manual control, still use progress
uniform float progress: hint_range(0.0, 1.0) = 0.0;

// Speed multiplier (0 = frozen, 1 = normal speed, higher = faster)
uniform float speed: hint_range(0.0, 10.0) = 1.0;

// How jagged each band of melting pixels are
// This is also the amplitude of the wave
uniform float meltness: hint_range(0.0, 3.0) = 1.0;

// If it should affect only lower parts of the shader, it also increases the meltness
uniform float how_low: hint_range(0.0, 5.0) = 1.0;

// How wavy. 
uniform float wave_frequency: hint_range(0.0, 30.0) = 20.0;

// Number of letters in the label to color
uniform float letter_count: hint_range(1.0, 100.0) = 10.0;

// Speed of the rainbow hue shift
uniform float hue_shift_speed: hint_range(0.0, 10.0) = 0.2;

float wave(float x, float phase) {
	return x - 2.5 + cos(2.0 * PI * phase + wave_frequency * x);
}

void fragment() {
        vec2 uv = UV;

	// Animate phase: if speed == 0, fall back to manual progress
	float phase = (speed > 0.0) ? fract(TIME * speed) : progress;

	uv.y -= pow(uv.y, how_low) * 0.02 * meltness * wave(UV.x - mod(UV.x, TEXTURE_PIXEL_SIZE.x), phase);

        vec4 base_color = texture(TEXTURE, uv);

        // Determine a constant hue for each letter and animate it over time
        float letter_index = floor(UV.x * letter_count);
        float hue = fract(letter_index / letter_count + TIME * hue_shift_speed);

        // Convert HSV (with S=1, V=1) to RGB
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(vec3(hue) + K.xyz) * 6.0 - K.www);
        vec3 rgb = clamp(p - K.xxx, 0.0, 1.0);

        COLOR = vec4(base_color.rgb * rgb, base_color.a);

	// "delete" pixels out of range
	if (uv.y <= 0.0 || uv.y >= 1.0) {
		COLOR.a = 0.0;
	}
}
