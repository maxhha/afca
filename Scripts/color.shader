shader_type canvas_item;

uniform float k;
uniform vec4 color : hint_color;

void fragment(){
	vec4 c = texture(TEXTURE, UV);
	COLOR.rgb = mix(c.rgb, color.rgb, k);
	COLOR.a = mix(c.a, c.a*color.a, k);
}