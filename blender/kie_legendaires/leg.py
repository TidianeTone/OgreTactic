import json, subprocess, sys, os
S = os.path.dirname(os.path.abspath(__file__))
K = r"C:\Users\Skill RTX\.claude\plugins\cache\nateherk\nateherk-design\0.2.0\skills\scroll-craft\scripts\kie.mjs"
C = {
 "garde": "a knight in blue-steel plate armor with a tower shield",
 "lame": "a hooded assassin in black with a red scarf and a curved blade",
 "oracle": "a purple-robed mage with a wide pointed hat and a golden lantern staff",
 "artificier": "a teal-clad engineer with powder barrels and bombs",
 "moine": "a green-robed martial monk fighting bare-handed",
 "trappeur": "an ochre-leather hunter with a harpoon and nets",
 "tidiane": "a magenta-clad artisan duelist wielding a brush-shaped blade, blue black and red sparks",
 "receleur": "a grey-blue cloaked fence with many pockets and a loot sack",
}
L = [
 ("g_enclume", "an oath sworn on a glowing anvil: {garde} stands firm while {lame} teleports behind an attacking brute"),
 ("g_ysolde", "Ysolde, a radiant saint in white and gold at dawn, raising fallen heroes from the water with a halo of light"),
 ("g_varn", "a massive iron battering ram shaped like a ram's head, pushed by {garde} and {artificier}, smashing enemies back"),
 ("g_korin", "Korin, a colossal monk in heavy stone-grey armor walking like a mountain, fists glowing"),
 ("g_maelle", "Maelle, a huntress blowing a horn while {garde} shoves a beast into a spiked trap"),
 ("g_quarante", "a wounded warrior refusing to fall at dawn, one knee down, surrounded by a shield of red light, gritted teeth"),
 ("g_octroi", "Mother Bastide, a stern toll-keeper matron in armor at a river gate, taking an item from a bandit"),
 ("g_nyxa", "Nyxa, a giant unblinking purple eye in the dark sky above a ruined city, dripping green poison"),
 ("g_zaida", "Zaida, a grinning pyrotechnician woman throwing lit barrels, fireworks bursting behind enemies"),
 ("g_kaede", "Kaede, a masked shadow ninja woman dashing through the wind, leaving no shadow, cherry-red scarf"),
 ("g_vesk", "Vesk, a bounty hunter nailing a wanted poster, poisoned target marked with a red sigil"),
 ("g_justframe", "a frozen instant of a perfect counter-strike, two blades meeting, time stopped, shards of light"),
 ("g_cador", "Cador, a flamboyant prince of thieves on moonlit docks, stealing a jewel from behind a guard"),
 ("g_ignar", "Ignar, a huge ember dragon coiled around canal locks, raining fire"),
 ("g_suien", "Master Suien, an ancient serene monk breathing green healing mist, a hundred ghostly lives around him"),
 ("g_aelis", "Aelis, a river seer woman with a glowing eye piercing through mist, aiming a harpoon"),
 ("g_journal", "a giant open leather journal floating, pages turning into glowing cards, {oracle} and {tidiane} reading it"),
 ("g_oriel", "Lady Oriel, an elegant museum curator restoring broken magical relics on velvet"),
 ("g_hazan", "Hazan, a muscular monk whose punches explode in gunpowder blasts"),
 ("g_torvald", "Torvald, a bearded engineer firing a giant ballista from a tower at a far target"),
 ("g_oeuvre", "a masterpiece being forged: an artisan's hands hammering a glowing weapon at night, sparks everywhere"),
 ("g_pip", "Pip, a tiny goblin merchant surrounded by an absurd bazaar of junk and exploding barrels"),
 ("g_tetsu", "Tetsu, a wolf-like river warrior pinning a netted beast to the shore"),
 ("g_zero", "a combo to the death: {moine} and {tidiane} unleashing a flurry of hits, motion trails"),
 ("g_linfei", "Lin Fei, an acrobatic monk thief with a hundred pockets, gadgets flying around"),
 ("g_decoupe", "a hunter butchering a giant fallen beast, trophy glowing, blood-red sunset"),
 ("g_crane", "the old skull of the shallows, a giant skull reef in the water full of traps and treasures"),
 ("g_grand_braquage", "the grand heist: {tidiane} and {receleur} cracking a vault of glowing cards at night, three loot bags, blue black and red light"),
]
L = [x for x in L if x[1]]
STYLE = ("A single image divided into a 2x2 grid of four separate square-cornered fantasy trading-card illustrations, "
         "separated by thin pure black gutters, each panel a complete scene. Same style in all four panels: painterly dark fantasy, "
         "rich chiaroscuro, warm glowing light against deep shadows, legendary epic mood, ruined flooded stone city of autumn tones, "
         "chunky voxel-inspired shapes. No text, no letters, no frames, no borders except the black gutters.")
pos = ["Top-left panel", "Top-right panel", "Bottom-left panel", "Bottom-right panel"]
batches = [L[i:i + 4] for i in range(0, len(L), 4)]
json.dump(batches, open(os.path.join(S, "batches.json"), "w"))
only = sys.argv[1:] 
for k, b in enumerate(batches):
    if only and str(k) not in only:
        continue
    out = os.path.join(S, "sheet_%d.png" % k)
    if os.path.exists(out):
        continue
    desc = " ".join("%s: %s." % (pos[i], d.format(**C)) for i, (_, d) in enumerate(b))
    r = subprocess.run(["node", K, "still", STYLE + " " + desc, out, "--ar", "3:2"], capture_output=True, text=True, cwd=r"G:\Mes APP\scrollcraft")
    print(k, r.stdout.strip()[-120:], r.stderr.strip()[-300:])
