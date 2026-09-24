shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Cases : grille discrète ou surbrillance. Cadre lumineux + voile léger, couleur par instance.

void fragment() {
	vec2 d = abs(UV - 0.5) * 2.0;
	float e = max(d.x, d.y);
	float frame = smoothstep(0.8, 0.92, e) * (1.0 - smoothstep(0.97, 1.0, e));
	// alpha < 0.5 : contour seul (portée) ; sinon case pleine qui pulse (cible, déplacement)
	bool outline = COLOR.a < 0.5;
	float fill = outline ? 0.0 : 0.22 + 0.08 * sin(TIME * 5.0);
	ALBEDO = COLOR.rgb * (1.0 + frame * 0.5);
	ALPHA = (frame * 0.9 + fill) * min(1.0, COLOR.a * (outline ? 2.2 : 1.0));
}
