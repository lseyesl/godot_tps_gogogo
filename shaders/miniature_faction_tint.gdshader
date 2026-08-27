shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_albedo_texture = false;
uniform vec4 faction_color : source_color = vec4(0.08, 0.48, 0.46, 1.0);

void fragment() {
	vec4 source = has_albedo_texture ? texture(albedo_texture, UV) : vec4(1.0);
	float maximum = max(source.r, max(source.g, source.b));
	float minimum = min(source.r, min(source.g, source.b));
	float chroma = maximum - minimum;
	float cyan_bias = min(source.g, source.b) - source.r;
	float armor_mask = smoothstep(0.001, 0.035, cyan_bias) * smoothstep(0.005, 0.06, chroma);
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	float paint_value = mix(0.42, 1.28, smoothstep(0.015, 0.72, luminance));
	vec3 painted_armor = faction_color.rgb * paint_value;

	ALBEDO = mix(source.rgb, painted_armor, armor_mask);
	ROUGHNESS = 0.82;
	METALLIC = 0.0;
	ALPHA = source.a;
}
