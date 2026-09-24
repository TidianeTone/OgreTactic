shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;
// Eau des bassins : le fond de sable se voit dans les hauts-fonds, turquoise qui fonce avec
// la profondeur réelle, écume au contact de la pierre, reflet du ciel en incidence rasante.

uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 shallow : source_color = vec3(0.22, 0.78, 0.72);
uniform vec3 deep : source_color = vec3(0.03, 0.3, 0.34);
uniform vec3 sky : source_color = vec3(0.9, 0.85, 0.7);
uniform vec3 foam : source_color = vec3(0.94, 0.97, 0.92);
uniform float depth_scale = 0.75;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = wpos.xz;
	vec3 na = texture(normal_a, uv * 0.11 + vec2(TIME * 0.012, TIME * 0.008)).rgb;
	vec3 nb = texture(normal_b, uv * 0.23 - vec2(TIME * 0.01, -TIME * 0.015)).rgb;
	NORMAL_MAP = normalize(mix(na, nb, 0.5));
	NORMAL_MAP_DEPTH = 0.45;

#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	// WebGL : pas de profondeur de scène lisible ; une eau d'une teinte, l'écume vient des ondes seules
	float thick = 0.5;
	float t = 0.85;
	vec3 under = shallow;
#else
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	float thick = max(VERTEX.z - v.z, 0.0);
	float t = clamp(thick / depth_scale, 0.0, 1.0);
	vec2 off = (na.rg - 0.5) * 0.025 * t;
	vec3 under = textureLod(screen_tex, SCREEN_UV + off, 1.0).rgb;
#endif
	vec3 body = mix(shallow, deep, smoothstep(0.0, 1.0, t));
	vec3 col = mix(under * shallow * 1.35, body, clamp(0.25 + t * 0.75, 0.0, 1.0));

	float edge = 1.0 - smoothstep(0.0, 0.06, thick);
	float ripple = smoothstep(0.6, 0.95, sin(thick * 38.0 - TIME * 2.2) * 0.5 + 0.5) * (1.0 - smoothstep(0.0, 0.2, thick));
	col = mix(col, foam, clamp(edge * 0.85 + ripple * 0.3, 0.0, 1.0));

	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	col = mix(col, sky, fres * 0.45);
	ALBEDO = col;
	ALPHA = 0.96;
	ROUGHNESS = 0.05;
	SPECULAR = 0.75;
	EMISSION = col * 0.12;
}
