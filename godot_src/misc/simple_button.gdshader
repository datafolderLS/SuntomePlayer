shader_type canvas_item;

uniform vec4 color_top;
uniform vec4 color_bottom;

void vertex() {
}

void fragment() {
	vec4 relcolor = mix(color_top, color_bottom, UV.g);
	COLOR = relcolor * texture(TEXTURE, UV);
}
