shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D concrete_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D drainage_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D armored_steel_texture : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec2 tile_count = vec2(15.0, 10.0);

float cell_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 rotate_tile_uv(vec2 tile_uv, float quarter_turns) {
	if (quarter_turns < 1.0) {
		return tile_uv;
	}
	if (quarter_turns < 2.0) {
		return vec2(1.0 - tile_uv.y, tile_uv.x);
	}
	if (quarter_turns < 3.0) {
		return vec2(1.0 - tile_uv.x, 1.0 - tile_uv.y);
	}
	return vec2(tile_uv.y, 1.0 - tile_uv.x);
}

void fragment() {
	vec2 tiled_uv = UV * tile_count;
	vec2 cell = floor(tiled_uv);
	vec2 tile_uv = fract(tiled_uv);
	float quarter_turns = floor(cell_hash(cell + vec2(19.0, 7.0)) * 4.0);
	tile_uv = rotate_tile_uv(tile_uv, quarter_turns);

	float selection = cell_hash(cell);
	vec4 tile_color;
	float tile_metallic;
	if (selection < 0.07) {
		tile_color = texture(drainage_texture, tile_uv);
		tile_metallic = 0.22;
	} else if (selection < 0.45) {
		tile_color = texture(armored_steel_texture, tile_uv);
		tile_metallic = 0.16;
	} else {
		tile_color = texture(concrete_texture, tile_uv);
		tile_metallic = 0.0;
	}

	ALBEDO = tile_color.rgb * 0.52;
	ROUGHNESS = 0.88;
	METALLIC = tile_metallic;
	ALPHA = tile_color.a;
}
