# Habillage d'interface par KIE (Seedream 5 Pro) : cadres de cartes par type, cadres d'orbe de mana par classe,
# cartes d'étage voxel par biome. Les cadres sont peints sur un vert #00FF00 uni, détourés ensuite par cut_ui.py.
# python gen_ui.py cadres | orbes | etages [biome...]
import os, sys, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
GREEN = ("Every empty area — the whole background outside the frames AND the whole inside of each frame — is flat uniform pure chroma green #00FF00, "
         "no gradient, no texture, no shadow on the green. The frames themselves contain no green at all.")


def still(prompt, out, ar, refs=(), extra=()):
	if os.path.exists(out):
		print("déjà là", out)
		return
	cmd = ["node", K, "still", prompt, out, "--ar", ar] + list(extra)
	for ref in refs:
		cmd += ["--ref", ref]
	r = subprocess.run(cmd, capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
	print(os.path.basename(out), "ok" if os.path.exists(out) else r.stderr[-400:], flush=True)


CADRES = [
	("attaque", "weathered dark iron with crimson enamel inlays, crossed blade and spearhead ornaments at the top corners"),
	("technique", "blued steel with cool azure enamel, small round shield studs and rivets along the edges"),
	("mouvement", "pale bronze with teal enamel, feather and wind-swirl ornaments at the corners"),
	("pouvoir", "dark bronze with violet enamel and gold filigree, a small glowing rune gem at the top center"),
]

ORBES = [
	("garde", "heavy iron shield rim with round bosses and a small helmet crest on top, royal blue enamel"),
	("lame", "thin black steel ring with two crossed curved daggers and a crescent moon, crimson accents"),
	("oracle", "bronze ring wreathed in small stylized ember flames, violet enamel, a tiny eye on top"),
	("artificier", "copper ring made of cogs and rivets with a small powder keg and fuse on top, teal enamel"),
	("moine", "ring of wooden prayer beads over a jade circle with little wave crests, green enamel"),
	("trappeur", "ring of knotted rope and bone with two small antlers and arrowheads, ochre enamel"),
	("tidiane", "porcelain-white ring with a small cracked porcelain mask on top and three gems blue black red, magenta accents"),
	("receleur", "tarnished silver ring hung with little keys, lockpicks and coins, slate grey enamel"),
]


# Un cadre par classe (26/09) : le style de la classe, la mise en page des cadres d'origine (planche cadres.png en référence).
CLASSES = [
	("garde", "a fortress rampart: heavy royal-blue enamelled iron plates, round shield bosses along the sides, a small helmet crest at the top, tower battlements in the corners"),
	("lame", "an assassin's frame: thin blackened steel with crimson lacquer, crossed curved daggers at the top, crescent moons and smoke wisps in the corners, sharp and elegant"),
	("oracle", "a seer's frame: dark bronze with violet enamel, stylized ember flames licking the border, a small open eye at the top, starry filigree"),
	("artificier", "an engineer's frame: riveted copper and brass pipes, gears and cogs in the corners, a small powder keg with a lit fuse at the top, teal enamel gauges"),
	("moine", "a monk's frame: carved light wood and jade, prayer beads along the border, rolling wave crests in the corners, green silk ribbon, serene"),
	("trappeur", "a hunter's frame: knotted rope and bone, small antlers at the top, arrowheads and snare loops in the corners, ochre leather straps"),
	("tidiane", "a chaotic painter's frame: gilded wood covered in bold brush strokes and splatters of magenta, blue, red and black paint, paintbrushes and a palette knife crossed at the top, a cracked white porcelain mask on the title, clever little brass mechanisms, deliberately asymmetrical drips yet readable"),
	("receleur", "a fence's frame: tarnished silver with slate grey enamel, hanging keys, lockpicks and coins along the border, a small padlock at the top, a hidden drawer in the corner"),
	("objet", "a merchant's item frame: warm polished brass and leather, small pouches and buckles in the corners, a tiny coin at the top"),
]


def classes():
	parts = []
	for i, (k, look) in enumerate(CLASSES):
		parts.append("Panel %d (row %d, column %d): %s." % (i + 1, i // 3 + 1, i % 3 + 1, look))
	still("A single image divided into a 3x3 grid of nine ornate trading card frames for a fantasy tactics card game, each frame portrait, "
		"centered in its cell, all the same size and EXACTLY the same layout as the frames of the reference image: a decorated outer border "
		"about 4 percent of the width thick, a slightly wider title plate band across the top, ornamented corners, a large empty picture window "
		"in the upper two thirds and an empty text box in the lower third, separated by a thin divider. The picture window and the text box must "
		"be large, clean rectangles at the same place in every frame. Game UI asset, clean readable silhouette, stylized hand-painted materials, "
		"front view. No text, no letters, no picture inside. " + " ".join(parts) + " " + GREEN,
		os.path.join(HERE, "cadres_classes.png"), "3:4", [os.path.join(HERE, "cadres.png")])


def cadres():
	parts = []
	for i, (k, look) in enumerate(CADRES):
		parts.append("Panel %d (row %d, column %d): a %s card frame made of %s." % (i + 1, i // 2 + 1, i % 2 + 1, k, look))
	still("A single image divided into a 2x2 grid of four ornate trading card frames for a fantasy tactics card game, each frame portrait, "
		"centered in its cell, same size and same layout: a decorated outer border about 4 percent of the width thick, a slightly wider "
		"title plate band across the top, ornamented corners, a thin divider line two thirds of the way down separating the picture window "
		"from the text box. Game UI asset, clean readable silhouette, stylized hand-painted metal, front view, perfectly symmetrical. "
		"No text, no letters, no picture inside. " + " ".join(parts) + " " + GREEN,
		os.path.join(HERE, "cadres.png"), "3:4")


def orbes():
	parts = []
	for i, (k, look) in enumerate(ORBES):
		parts.append("Panel %d (row %d, column %d): %s." % (i + 1, i // 3 + 1, i % 3 + 1, look))
	parts.append("Panel 9 (row 3, column 3): a plain simple gold ring, no ornaments.")
	still("A single image divided into a 3x3 grid of nine circular ornamental frames for a video game energy orb, each a ring around an "
		"empty circle, the circle hole is exactly round and takes half of the cell width, the ornaments stick out around the ring. "
		"Game UI asset, stylized hand-painted metal and enamel, front view, symmetrical, bold readable silhouettes. No text. "
		+ " ".join(parts) + " " + GREEN, os.path.join(HERE, "orbes.png"), "1:1")


ETAGES = {
	"automne": "autumn ruins of a flooded lock city, orange and red autumn trees, grey stone slabs, turquoise water canals",
	"mousse": "mossy stone arches at dusk, green trees, blue evening light, lanterns",
	"braise": "earthen ruins with glowing ember cracks, autumn trees, warm sunset haze",
	"lilas": "lilac stone sanctuary with giant statues, green trees, bright sun",
	"tours": "red brick towers standing in round water basins, green trees",
	"cristal": "white marble city with crystal spires, green trees, clear light",
	"epilobes": "white stone meadow full of pink fireweed flowers and pine trees",
	"emeraude": "emerald grove of teal-leaved trees over grey stone ruins",
	"jade": "jade green temple terraces, green trees, misty",
	"crypte": "dark crypt ruins with bone-white stone and teal ghost lights, night but readable",
	"quartz": "pink quartz crystal outcrops over pale stone ruins, soft light",
	"teal": "teal-leaved jungle over sunken ruins, humid green light",
	"altiplano": "high grassy plateau of red earth and green grass tufts, no trees, a few standing stones, wide sky, windswept",
}


def etages(only):
	for k, look in ETAGES.items():
		if only and k not in only:
			continue
		still("Voxel art diorama of a whole floating island seen from high above in three-quarter isometric view, like a game world map: "
			"%s. The island is long and fills the image from left to right, surrounded by deep blue water with soft light shafts. "
			"Chunky cubic voxels, clean readable shapes, soft warm lighting, stylized video game. Leave the middle of the island fairly open and "
			"walkable (plazas, bridges, small clearings) so markers can be placed on it. No text, no UI, no characters, no path markers." % look,
			os.path.join(HERE, "etage_%s.png" % k), "16:9")


# Un cadre par paire de classes (26/09) : les deux styles fondus sur tout le pourtour, pas deux moitiés recollées.
# 4 planches 3x3 : les 28 paires, puis 8 secondes prises des premières (on garde la meilleure au découpage).
FUSE = {
	"garde": "royal-blue enamelled iron, round shield bosses, small battlements",
	"lame": "blackened steel with crimson lacquer, crossed curved daggers, crescent moons, smoke wisps",
	"oracle": "dark bronze with violet enamel, licking ember flames, a small open eye",
	"artificier": "riveted copper and brass pipes, gears, a tiny powder keg with lit fuse, teal gauges",
	"moine": "carved light wood and jade, prayer beads, wave crests, green silk ribbon",
	"trappeur": "knotted rope and bone, small antlers, arrowheads, ochre leather straps",
	"tidiane": "gilded wood splattered with magenta, blue, red and black paint, paintbrushes, a cracked porcelain mask",
	"receleur": "tarnished silver with slate enamel, hanging keys, coins, a small padlock",
}
PAIRS = [("garde", "lame"), ("garde", "oracle"), ("garde", "artificier"), ("garde", "moine"), ("garde", "trappeur"), ("garde", "tidiane"), ("garde", "receleur"),
	("lame", "oracle"), ("lame", "artificier"), ("lame", "moine"), ("lame", "trappeur"), ("lame", "tidiane"), ("lame", "receleur"),
	("oracle", "artificier"), ("oracle", "moine"), ("oracle", "trappeur"), ("oracle", "tidiane"), ("oracle", "receleur"),
	("artificier", "moine"), ("artificier", "trappeur"), ("artificier", "tidiane"), ("artificier", "receleur"),
	("moine", "trappeur"), ("moine", "tidiane"), ("moine", "receleur"), ("trappeur", "tidiane"), ("trappeur", "receleur"), ("tidiane", "receleur")]
EMB = {"garde": "the helmet crest", "lame": "the crossed curved daggers", "oracle": "the small open eye", "artificier": "the tiny powder keg",
	"moine": "the jade gem with prayer beads", "trappeur": "the small antlers", "tidiane": "the cracked porcelain mask", "receleur": "the small padlock"}


def guildes(only=()):
	"""Un cadre par image (qualité basic, 7,5 crédits) avec les deux cadres de classe en référence : à quatre par planche,
	le modèle recopiait un des deux cadres au lieu de les fondre."""
	from concurrent.futures import ThreadPoolExecutor
	def one(p):
		a, b = p
		still("One ornate trading card frame for a fantasy tactics card game, portrait, centered, same layout as the two reference frames: "
			"decorated outer border about 4 percent of the width thick, a slightly wider title plate band across the top, ornamented corners, a large "
			"empty picture window in the upper two thirds and an empty text box in the lower third, separated by a thin divider. The frame is ONE "
			"harmonious hybrid of the two reference frames: %s (first reference) interlaced along the WHOLE border with %s (second reference); "
			"colours blend smoothly all around, motifs of both in every corner, %s and %s merged into a single new emblem at the top. Not split into "
			"halves, not a copy of either reference. Game UI asset, stylized hand-painted materials, front view. No text, no picture inside. "
			"The background and the inside of the frame are flat uniform pure chroma green #00FF00, the frame contains no green." % (FUSE[a], FUSE[b], EMB[a], EMB[b]),
			os.path.join(HERE, "guildes", "%s_%s.png" % (a, b)), "3:4",
			[os.path.join(HERE, "ref_c_%s.png" % a), os.path.join(HERE, "ref_c_%s.png" % b)], ["--quality", "basic"])
	os.makedirs(os.path.join(HERE, "guildes"), exist_ok=True)
	with ThreadPoolExecutor(4) as ex:
		list(ex.map(one, [p for p in PAIRS if not only or "%s_%s" % p in only]))


if __name__ == "__main__":
	what = sys.argv[1]
	{"cadres": cadres, "orbes": orbes, "classes": classes, "guildes": lambda: guildes(sys.argv[2:])}.get(what, lambda: etages(sys.argv[2:]))()
