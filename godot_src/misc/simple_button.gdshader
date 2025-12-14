shader_type canvas_item;

instance uniform vec4 color_top : source_color = vec4(1.0, 0.5, 0.0, 1.0);
instance uniform vec4 color_bottom : source_color = vec4(1.0, 0.5, 0.0, 1.0);

void vertex() {
}

void fragment() {
	vec4 relcolor = mix(color_top, color_bottom, UV.g);
	COLOR = relcolor * texture(TEXTURE, UV);
}
