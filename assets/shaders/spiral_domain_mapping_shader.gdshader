shader_type canvas_item;

//const float PI  = 3.141592653589793;
//const float TAU = 6.283185307179586;

uniform float sigma_thickness : hint_range(0.02, 0.30) = 0.12; // stroke thickness of the ∑

/* ---------------- Helpers (unchanged) ---------------- */
float mod1(inout float p, float size){
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

float spiralLength(float b, float a){
	return 0.5*b*(a*sqrt(1.0+a*a)+log(a+sqrt(1.0+a*a)));
}

void spiralMod(inout vec2 p, float a){
	vec2 op = p;
	float b = a/TAU;
	float rr = length(op);
	float aa = atan(op.y, op.x);
	rr -= aa*b;
	float nn = mod1(rr, a);
	float sa = aa + TAU*nn;
	float sl = spiralLength(b, sa);
	p = vec2(sl, rr);
}

float sRGB1(float t){ return mix(1.055*pow(t, 1.0/2.4)-0.055, 12.92*t, step(t, 0.0031308)); }
vec3  sRGB(vec3 c){ return vec3(sRGB1(c.x), sRGB1(c.y), sRGB1(c.z)); }
float hash(float co){ return fract(sin(co*12.9898)*13758.5453); }

/* ------- Distance to a line segment (for stroked paths) ------- */
float sdSegment(vec2 p, vec2 a, vec2 b){
	vec2 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba*h);
}

/* ---------------- Proper ∑ glyph (three strokes) ----------------
   Coordinate box ~[-0.9,0.9] horizontally, [-0.7,0.7] vertically.
   Segments:
     1) Top bar:     left -> right
     2) Left diagonal: top-left -> bottom-left (slanted)
     3) Bottom bar:  left -> right
------------------------------------------------------------------*/
float sigma_sum_sdf(vec2 p, float stroke){
	// Control points (tweakable)
	float top_y =  0.60;
	float bot_y = -0.60;
	float right_x =  0.85;
	float left_x  = -0.55;

	// Slight slant of the left “spine” to look like a real ∑
	vec2 tl = vec2(left_x, top_y);                 // top-left
	vec2 bl = vec2(left_x + 0.08, bot_y);          // bottom-left shifted right a bit
	vec2 tr = vec2(right_x, top_y);                // top-right
	vec2 br = vec2(right_x, bot_y);                // bottom-right

	// Distances to the three strokes
	float d_top = sdSegment(p, tl, tr);
	float d_dia = sdSegment(p, tl, bl);
	float d_bot = sdSegment(p, bl, br);

	// Union of strokes, then subtract half stroke for sign
	float d = min(min(d_top, d_dia), d_bot) - stroke*0.5;

	// Soften the inside corners a hair to avoid pinholes when scaled
	float join_top = length(p - tl) - stroke*0.55;
	float join_bot = length(p - bl) - stroke*0.55;
	d = min(d, min(join_top, join_bot));

	return d;
}

/* ---------------- Main (kept from your original) ---------------- */
void fragment(){
	vec2 q = FRAGCOORD.xy / (1.0 / SCREEN_PIXEL_SIZE).xy;
	vec2 p = -1.0 + 2.0 * q;
	p.x *= (1.0 / SCREEN_PIXEL_SIZE).x / (1.0 / SCREEN_PIXEL_SIZE).y;

	float aa = 2.0 / (1.0 / SCREEN_PIXEL_SIZE).y; // pixel AA
	vec3  col = vec3(1.0);

	float a = 0.25;

	vec2 sp = p;
	spiralMod(sp, a);
	sp.x += -TIME * 0.2;
	vec2 msp = sp;
	float nsp = mod1(msp.x, a);

	float z = a * 0.4;

	float _dd = length(msp) - z; // ribbon pos (kept for style)
	float _h  = hash(nsp + 123.4);

	// --- ∑ instead of eyes ---
	// Map the local coords to glyph space (sigma_sum_sdf expects ~unit box)
	float de = sigma_sum_sdf(msp / z, sigma_thickness) * z;

	// Sharpen edges slightly
	de -= 0.25 * aa;

	// Your original band/color logic
	col = mix(vec3(1.0 - abs(2.0 * sp.y / a)), vec3(0.0), smoothstep(aa, -aa, de));
	col *= smoothstep(0.0, 0.4, length(p));

	col = sRGB(col);
	COLOR = vec4(col, 1.0);
}
