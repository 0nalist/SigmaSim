shader_type canvas_item;

uniform float speed: hint_range(0.1, 10.0) = 1.0;

void fragment() {
    // Create a ping-pong fade between 0 and 1
    float fade = 0.5 + 0.5 * sin(TIME * speed);
    
    // Sample base texture if it exists
    vec4 tex = texture(TEXTURE, UV);
    
    // Multiply alpha by fade
    COLOR = tex;
    COLOR.a *= fade;
}
