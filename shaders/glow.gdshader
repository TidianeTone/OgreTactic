shader_type spatial;
render_mode unshaded;
// Braises, fenêtres éclairées, yeux : couleur des sommets poussée en HDR pour le bloom.

uniform float energy = 3.0;
uniform float flicker = 0.15;
uniform float pulse = 0.0;        // battement lent (fissures des ennemis)
uniform float cut = 1.0;          // même découpe côté caméra que la pierre qui les porte
global uniform vec2 cut_dir;
global uniform vec2 cut_center;
global uniform float cut_half;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (cut > 0.0) {
		vec2 rel = wpos.xz - cut_center;
		float outside = max(abs(rel.x), abs(rel.y));
		float along = dot(rel, cut_dir);
		if (smoothstep(cut_half + 0.6, cut_half + 1.1, outside) * smoothstep(2.5, 3.5, along) > 0.5) {
			discard;
		}
	}
	float f = 1.0 - flicker + flicker * sin(TIME * 7.0 + wpos.x * 3.0 + wpos.z * 5.0) * sin(TIME * 3.1 + wpos.y * 4.0);
	f *= 1.0 + pulse * sin(TIME * 2.2 + wpos.y * 2.5);
	ALBEDO = COLOR.rgb * energy * f;
}
