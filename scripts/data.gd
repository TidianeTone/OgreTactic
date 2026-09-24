class_name Data
## Toutes les données de jeu : héros, ennemis, cartes, reliques, traits, biomes.

const CLASS_COLOR := {
	"garde": Color("#3d63e0"),
	"lame": Color("#e0344f"),
	"oracle": Color("#9b50d8"),
	"artificier": Color("#22b8a6"),
	"moine": Color("#6cc24a"),
	"trappeur": Color("#c9a23a"),
	"tidiane": Color("#d0409a"),
	"receleur": Color("#9fb4c2"),
}
const CLASS_GLYPH := {"garde": "🛡", "lame": "🗡", "oracle": "✺"}

const HEROES := {
	"garde": {"name": "Garde", "title": "Rempart de l'Écluse", "hp": 40, "move": 3, "jump": 2, "role": "Encaisse : armure, charges, provocation."},
	"lame": {"name": "Lame", "title": "Ombre des Arches", "hp": 30, "move": 4, "jump": 4, "role": "Coups de dos, poison, téléportation."},
	"oracle": {"name": "Oracle", "title": "Voix de la Braise", "hp": 28, "move": 3, "jump": 2, "role": "Braise à distance, soins, pioche."},
	"artificier": {"name": "Artificier", "title": "Poudre des Écluses", "hp": 32, "move": 3, "jump": 2, "role": "Barils explosifs, grenades, tourelles."},
	"moine": {"name": "Moine", "title": "Paume du Ressac", "hp": 32, "move": 4, "jump": 3, "role": "Enchaîne au contact, bondit, tourbillonne."},
	"trappeur": {"name": "Trappeur", "title": "Chasseur des Hauts-Fonds", "hp": 28, "move": 4, "jump": 3, "role": "Pièges, marques, filets, harpons."},
	"tidiane": {"name": "Tidiane", "title": "Le Paradoxe du Potentiel", "hp": 30, "move": 4, "jump": 3, "role": "Artisan Grixis : Analyse, Émotion, Ambition. Paie en PV pour frapper fort."},
	"receleur": {"name": "Receleur", "title": "Main leste des Hauts-Quais", "hp": 30, "move": 4, "jump": 3, "role": "Vole les objets des ennemis, bricole et recycle la besace."},
}

const FOES := {
	"husk": {"name": "Moussu", "hp": 14, "move": 3, "jump": 2, "dmg": 6, "range": [1, 1], "ai": "melee"},
	"guetteur": {"name": "Guetteur", "hp": 11, "move": 3, "jump": 2, "dmg": 5, "range": [2, 5], "ai": "ranged"},
	"sentinelle": {"name": "Sentinelle", "hp": 28, "move": 2, "jump": 2, "dmg": 10, "range": [1, 1], "ai": "melee", "armor": 4, "passives": ["contre"]},
	"wisp": {"name": "Feu follet", "hp": 6, "move": 5, "jump": 9, "dmg": 9, "range": [1, 1], "ai": "bomb", "fly": true},
	"gardien": {"name": "Le Gardien des ruines", "hp": 120, "move": 2, "jump": 3, "dmg": 13, "range": [1, 1], "ai": "boss", "armor": 3, "passives": ["contre"]},
	"chaman": {"name": "Chaman de braise", "hp": 12, "move": 3, "jump": 2, "dmg": 3, "range": [2, 4], "ai": "healer", "heal": 6},
	"carapace": {"name": "Carapace", "hp": 20, "move": 2, "jump": 1, "dmg": 7, "range": [1, 1], "ai": "melee", "armor": 8, "heavy": true},
	"rodeur": {"name": "Rôdeur", "hp": 13, "move": 5, "jump": 4, "dmg": 7, "range": [1, 1], "ai": "assassin", "passives": ["reflexe"]},
}

# Ce que chaque ennemi demande au joueur (affiché au survol).
const FOE_TIPS := {
	"husk": "Mêlée simple. Le repousser dans l'eau.",
	"guetteur": "Tire de loin depuis les hauteurs. Aller le chercher.",
	"sentinelle": "Armure chaque tour et riposte. Le noyer ou l'écraser.",
	"wisp": "Explose au contact. Le tuer à distance.",
	"gardien": "Riposte au contact : le frapper de loin ou le noyer de dégâts.",
	"chaman": "Soigne ses alliés. Cible prioritaire.",
	"carapace": "8 d'armure par tour. Coule d'un coup s'il tombe à l'eau.",
	"rodeur": "Rapide, vise les plus faibles, esquive un coup sur quatre.",
}

# kind : atk | skill | move. target : foe (défaut pour atk) | self | ally | tile | line
const CARDS := {
	"frappe": {"name": "Frappe", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "trig": {"on": "grace", "draw": 1}, "text": "Inflige {dmg}."},
	"pavois": {"name": "Pavois", "owner": "garde", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 6, "text": "Gagne {block} d'armure."},
	"charge": {"name": "Charge", "owner": "garde", "rar": 1, "cost": 2, "kind": "atk", "target": "line", "range": [1, 3], "dmg": 8, "push": 1, "trig": {"on": "enchaine", "block": 4}, "text": "Fonce 3 cases en ligne. {dmg} et repousse 1."},
	"defi": {"name": "Défi", "owner": "garde", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "block": 4, "taunt": true, "text": "+{block} armure. Les ennemis le ciblent."},
	"rempart": {"name": "Rempart", "owner": "garde", "rar": 2, "cost": 2, "kind": "skill", "target": "self", "block": 6, "adj": true, "text": "+{block} armure au Garde et aux alliés voisins."},
	"marteau": {"name": "Marteau d'écluse", "owner": "garde", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 11, "push": 2, "trig": {"on": "grace", "block": 6}, "text": "Inflige {dmg} et repousse de 2."},
	"bastion": {"name": "Bastion", "owner": "garde", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "block": 3, "draw": 1, "text": "Gagne {block} d'armure. Pioche 1."},
	"estoc": {"name": "Estoc", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "backstab": 2.0, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}. De dos : ×2."},
	"ombre": {"name": "Pas de l'ombre", "owner": "lame", "rar": 1, "cost": 0, "kind": "move", "target": "tile", "range": [1, 3], "text": "Téléportation à 3 cases, relief ignoré."},
	"double": {"name": "Double lame", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "hits": 2, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg} deux fois."},
	"venin": {"name": "Venin", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 2, "poison": 4, "trig": {"on": "enchaine", "poison": 2}, "text": "Inflige {dmg} et {poison} de poison."},
	"couperet": {"name": "Couperet", "owner": "lame", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 9, "execute": true, "trig": {"on": "mur", "dmg": 6}, "text": "Inflige {dmg}. Doublé sous la moitié des PV."},
	"ricochet": {"name": "Ricochet", "owner": "lame", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 5, "bounce": true, "trig": {"on": "grace", "refund": true}, "text": "Dague : {dmg}, rebondit sur un voisin."},
	"braise": {"name": "Braise", "owner": "oracle", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 6, "trig": {"on": "precision", "dmg": 3}, "text": "Inflige {dmg} à distance."},
	"seve": {"name": "Sève", "owner": "oracle", "rar": 1, "cost": 1, "kind": "skill", "target": "ally", "range": [0, 3], "heal": 7, "trig": {"on": "mur", "heal": 4}, "text": "Soigne {heal} un allié."},
	"colonne": {"name": "Colonne de cendre", "owner": "oracle", "rar": 2, "cost": 2, "kind": "atk", "target": "tile", "range": [2, 5], "dmg": 7, "aoe": true, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} en croix autour d'une case."},
	"maree": {"name": "Marée", "owner": "oracle", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 4], "dmg": 3, "push": 3, "text": "{dmg} et repousse 3. Dans l'eau : noyade."},
	"surveil": {"name": "Surveil", "owner": "oracle", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "draw": 2, "exhaust": true, "text": "Pioche 2. Épuise."},
	"delve": {"name": "Delve", "owner": "oracle", "rar": 3, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 0, "delve": true, "exhaust": true, "text": "2 par carte en défausse, puis l'exile. Épuise."},
	"bouclier": {"name": "Pavois volant", "owner": "garde", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 3], "dmg": 5, "push": 1, "block": 3, "trig": {"on": "mur", "block": 5}, "text": "Lance le pavois : {dmg}, repousse 1, +{block} armure."},
	"crochet": {"name": "Gaffe d'écluse", "owner": "garde", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 3], "dmg": 3, "pull": 2, "text": "Inflige {dmg} et attire l'ennemi de 2 cases."},
	"forteresse": {"name": "Forteresse", "owner": "garde", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "forteresse", "text": "Pouvoir : l'armure des héros ne s'efface plus en début de tour."},
	"fente": {"name": "Fente", "owner": "lame", "rar": 1, "cost": 1, "kind": "atk", "target": "line", "range": [1, 4], "dmg": 7, "trig": {"on": "grace", "refund": true}, "text": "Fonce jusqu'à 4 cases et frappe : {dmg}."},
	"embuscade": {"name": "Embuscade", "owner": "lame", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "ambush": true, "draw": 1, "text": "Le prochain coup de la Lame compte comme de dos. Pioche 1."},
	"coupures": {"name": "Mille coupures", "owner": "lame", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "coupures", "text": "Pouvoir : chaque carte jouée inflige 1 à un ennemi au hasard."},
	"arc": {"name": "Arc de braise", "owner": "oracle", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 4, "chain": 3, "trig": {"on": "precision", "dmg": 2}, "text": "Inflige {dmg}, puis saute sur 2 ennemis proches."},
	"echo": {"name": "Écho", "owner": "oracle", "rar": 3, "cost": 1, "kind": "skill", "target": "self", "echo": true, "exhaust": true, "text": "La prochaine carte jouée ce tour agit deux fois. Épuise."},
	"cendres": {"name": "Pluie de cendres", "owner": "oracle", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "cendres", "text": "Pouvoir : chaque tour, 4 dégâts à l'ennemi le plus proche de l'Oracle."},
	"grenade": {"name": "Grenade", "owner": "artificier", "rar": 1, "cost": 1, "kind": "atk", "target": "tile", "range": [2, 4], "dmg": 5, "aoe": true, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} en croix autour d'une case."},
	"baril": {"name": "Baril de poudre", "owner": "artificier", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "baril", "draw": 1, "text": "Pose un baril : frappé, il explose (7 autour). Pioche 1."},
	"etincelle": {"name": "Étincelle", "owner": "artificier", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 5], "dmg": 0, "detonate": true, "text": "Fait sauter un baril ou un brasero à portée."},
	"rivet": {"name": "Rivet", "owner": "artificier", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "block": 4, "trig": {"on": "mur", "block": 6}, "text": "Inflige {dmg}. +{block} armure."},
	"tourelle": {"name": "Tourelle", "owner": "artificier", "rar": 2, "cost": 2, "kind": "skill", "target": "tile", "range": [1, 2], "place": "tourelle", "text": "Pose une tourelle : 4 au plus proche à chaque fin de tour, 3 tours."},
	"surcharge": {"name": "Surcharge", "owner": "artificier", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "energy": 1, "draw": 1, "exhaust": true, "text": "+1 énergie, pioche 1. Épuise."},
	"mortier": {"name": "Mortier", "owner": "artificier", "rar": 3, "cost": 2, "kind": "atk", "target": "tile", "range": [3, 6], "dmg": 9, "aoe": true, "trig": {"on": "premier", "dmg": 4}, "text": "Obus : {dmg} en croix, de très loin."},
	"atelier": {"name": "Atelier", "owner": "artificier", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "atelier", "text": "Pouvoir : chaque tour, un baril apparaît près d'un ennemi."},
	"paume": {"name": "Paume", "owner": "moine", "rar": 1, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 3, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg}. Nourrit l'enchaînement."},
	"poing": {"name": "Poing-marteau", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "combo": 3, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}, +3 par coup déjà porté ce tour."},
	"tourbillon": {"name": "Tourbillon", "owner": "moine", "rar": 1, "cost": 1, "kind": "atk", "target": "self", "dmg": 5, "around": true, "text": "Inflige {dmg} à chaque ennemi voisin."},
	"bond": {"name": "Bond de grue", "owner": "moine", "rar": 1, "cost": 0, "kind": "move", "target": "tile", "range": [1, 2], "blink": true, "text": "Bondit de 2 cases, relief ignoré."},
	"souffle": {"name": "Souffle calme", "owner": "moine", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "heal": 5, "draw": 1, "text": "Se soigne de {heal}. Pioche 1."},
	"ressac": {"name": "Paume du ressac", "owner": "moine", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "push": 2, "trig": {"on": "surplomb", "dmg": 3}, "text": "Inflige {dmg} et repousse de 2."},
	"cent": {"name": "Cent poings", "owner": "moine", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 2, "hits": 5, "trig": {"on": "mur", "dmg": 1}, "text": "Inflige {dmg} cinq fois."},
	"voie": {"name": "Voie du poing", "owner": "moine", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "voie", "text": "Pouvoir : chaque 3e coup du Moine dans un tour rend 1 énergie et pioche 1."},
	"fleche": {"name": "Flèche lestée", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 6, "trig": {"on": "precision", "dmg": 4}, "text": "Inflige {dmg} à distance."},
	"piege": {"name": "Piège à mâchoires", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "skill", "target": "tile", "range": [1, 3], "place": "piege", "text": "Pose un piège : l'ennemi qui y marche s'arrête, subit 8 et reste entravé."},
	"marque": {"name": "Marque du chasseur", "owner": "trappeur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 5], "dmg": 3, "mark": 2, "trig": {"on": "premier", "draw": 1}, "text": "Inflige {dmg}. Marqué 2 tours : +50 % de dégâts reçus."},
	"filet": {"name": "Filet lesté", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 2, "root": 2, "text": "Inflige {dmg}. Entravé 2 tours : ne bouge plus."},
	"pluie": {"name": "Pluie de flèches", "owner": "trappeur", "rar": 2, "cost": 2, "kind": "atk", "target": "tile", "range": [2, 5], "dmg": 5, "aoe": true, "text": "Inflige {dmg} en croix autour d'une case."},
	"harpon": {"name": "Harpon", "owner": "trappeur", "rar": 2, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 4, "pull": 3, "trig": {"on": "grace", "draw": 1}, "text": "Inflige {dmg} et tire l'ennemi de 3 cases vers soi."},
	"perforant": {"name": "Tir perforant", "owner": "trappeur", "rar": 3, "cost": 2, "kind": "atk", "range": [2, 6], "dmg": 12, "pierce": true, "trig": {"on": "surplomb", "dmg": 5}, "text": "Inflige {dmg}, ignore l'armure."},
	"instinct": {"name": "Instinct du chasseur", "owner": "trappeur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "instinct", "text": "Pouvoir : les pièges infligent +6 et marquent leur proie."},
	"esquisse": {"name": "Esquisse", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 5, "trig": {"on": "enchaine", "dmg": 2}, "text": "Inflige {dmg}."},
	"recul": {"name": "Recul analytique", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "block": 5, "trig": {"on": "premier", "draw": 1}, "text": "+{block} armure."},
	"journal": {"name": "Journal intime", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "draw": 2, "text": "Pioche 2."},
	"pacte": {"name": "Pacte Grixis", "owner": "tidiane", "voix": "N", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 11, "selfdmg": 3, "trig": {"on": "grixis", "heal": 4}, "text": "Inflige {dmg}, perd 3 PV."},
	"arbo": {"name": "Pensée arborescente", "owner": "tidiane", "voix": "B", "rar": 1, "cost": 0, "kind": "skill", "target": "self", "draw": 1, "text": "Pioche 1."},
	"wavedash": {"name": "Wavedash", "owner": "tidiane", "voix": "R", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 5, "block": 4, "text": "Inflige {dmg}, +{block} armure."},
	"punchline": {"name": "Punchline", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 9, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg}."},
	"truecombo": {"name": "True combo", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 3, "hits": 3, "text": "Inflige {dmg} trois fois."},
	"monster": {"name": "Monster Energy", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "energy": 1, "selfdmg": 2, "text": "+1 énergie, perd 2 PV."},
	"nuit": {"name": "Nuit blanche", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "draw": 3, "selfdmg": 4, "exhaust": true, "text": "Pioche 3, perd 4 PV. Épuise."},
	"transmutation": {"name": "Transmutation", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 7, "leech": 3, "text": "Inflige {dmg}, soigne 3."},
	"dette": {"name": "La Dette", "owner": "tidiane", "voix": "N", "rar": 2, "cost": 0, "kind": "atk", "range": [1, 1], "dmg": 11, "selfdmg": 4, "text": "Inflige {dmg}, perd 4 PV."},
	"dsm": {"name": "Analyse DSM", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 4], "dmg": 0, "mark": 2, "draw": 1, "text": "Marqué 2 tours, pioche 1."},
	"contreanalyse": {"name": "Contre-analyse", "owner": "tidiane", "voix": "B", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 3], "dmg": 0, "root": 1, "block": 5, "text": "Entravé 1 tour, +{block} armure."},
	"troisvoix": {"name": "Trois voix", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 2], "dmg": 4, "flow": 2, "text": "Inflige {dmg}, +2 par carte déjà jouée ce tour."},
	"break174": {"name": "Break 174", "owner": "tidiane", "voix": "R", "rar": 2, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 14, "text": "Inflige {dmg}."},
	"purerage": {"name": "Pure rage", "owner": "tidiane", "voix": "R", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 8, "hits": 2, "trig": {"on": "mur", "dmg": 4}, "text": "Inflige {dmg} deux fois."},
	"potentiel": {"name": "Potentiel brut", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 3, "kind": "atk", "range": [1, 1], "dmg": 24, "trig": {"on": "grixis", "dmg": 12}, "text": "Inflige {dmg}."},
	"revelation": {"name": "La Révélation", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 2, "kind": "skill", "target": "self", "heal": 8, "draw": 2, "exhaust": true, "text": "Soigne {heal}, pioche 2. Épuise."},
	"hyperfocus": {"name": "Hyperfocus", "owner": "tidiane", "voix": "R", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "hyperfocus", "text": "Pouvoir : les attaques de Tidiane infligent +3."},
	"dnb": {"name": "Drum & Bass", "owner": "tidiane", "voix": "B", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "dnb", "text": "Pouvoir : pioche 1 carte de plus à chaque tour."},
	"obsession": {"name": "Obsession", "owner": "tidiane", "voix": "N", "rar": 3, "cost": 3, "kind": "power", "target": "self", "power": "obsession", "text": "Pouvoir : +1 énergie à chaque tour."},
	"larcin": {"name": "Larcin", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 4, "steal": true, "trig": {"on": "grace", "draw": 1}, "text": "Vole l'objet de la cible, puis inflige {dmg}."},
	"cle": {"name": "Clé anglaise", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 6, "bricole": 1, "trig": {"on": "mur", "dmg": 3}, "text": "Inflige {dmg}. +1 Bricole."},
	"bricolage": {"name": "Bricolage", "owner": "receleur", "rar": 1, "cost": 1, "kind": "skill", "target": "self", "craft": 1, "block": 3, "text": "Fabrique un objet dans la besace. +{block} armure."},
	"camelote": {"name": "Jet de camelote", "owner": "receleur", "rar": 1, "cost": 1, "kind": "atk", "range": [2, 4], "dmg": 3, "junk": 3, "trig": {"on": "precision", "dmg": 3}, "text": "Inflige {dmg}, +3 par objet en besace."},
	"crochetage": {"name": "Crochetage", "owner": "receleur", "rar": 2, "cost": 0, "kind": "atk", "range": [1, 3], "dmg": 0, "steal": true, "draw": 1, "text": "Vole l'objet d'un ennemi à 3 cases. Pioche 1."},
	"recyclage": {"name": "Recyclage", "owner": "receleur", "rar": 2, "cost": 0, "kind": "skill", "target": "self", "recycle": true, "text": "Détruit le premier objet de la besace : +1 énergie, +1 Bricole."},
	"contrefacon": {"name": "Contrefaçon", "owner": "receleur", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "dupe": true, "exhaust": true, "text": "Copie le dernier objet de la besace. Épuise."},
	"coupdesac": {"name": "Coup de sac", "owner": "receleur", "rar": 2, "cost": 1, "kind": "atk", "range": [1, 1], "dmg": 7, "push": 1, "trig": {"on": "grace", "energy": 1}, "text": "Inflige {dmg} et repousse 1."},
	"etal": {"name": "Étal volant", "owner": "receleur", "rar": 2, "cost": 1, "kind": "skill", "target": "self", "craft": 2, "exhaust": true, "text": "Fabrique deux objets. Épuise."},
	"lecasse": {"name": "Le Casse", "owner": "receleur", "rar": 3, "cost": 2, "kind": "atk", "range": [1, 1], "dmg": 11, "steal": true, "craft_else": true, "text": "Vole l'objet de la cible (sinon en fabrique un), puis inflige {dmg}."},
	"marchenoir": {"name": "Marché noir", "owner": "receleur", "rar": 3, "cost": 1, "kind": "power", "target": "self", "power": "marchenoir", "text": "Pouvoir : chaque objet utilisé inflige 4 à l'ennemi le plus proche."},
	"poches": {"name": "Poches sans fond", "owner": "receleur", "rar": 3, "cost": 2, "kind": "power", "target": "self", "power": "poches", "text": "Pouvoir : besace +2 places, un objet fabriqué à chaque tour."},
	"lotus": {"name": "Lotus", "owner": "oracle", "rar": 3, "cost": 2, "kind": "skill", "target": "self", "heal_all": 5, "text": "Soigne {heal_all} tous les alliés."},
}

const STARTER := {
	"garde": ["frappe", "frappe", "pavois", "charge"],
	"lame": ["estoc", "estoc", "ombre", "double"],
	"oracle": ["braise", "braise", "seve", "surveil"],
	"artificier": ["grenade", "baril", "etincelle", "rivet"],
	"moine": ["paume", "paume", "poing", "tourbillon"],
	"trappeur": ["fleche", "fleche", "piege", "marque"],
	"tidiane": ["esquisse", "recul", "journal", "pacte"],
	"receleur": ["larcin", "cle", "bricolage", "camelote"],
}
const VOIX := {"B": ["Analyse", Color("#4aa3d8")], "R": ["Émotion", Color("#e0483f")], "N": ["Ambition", Color("#9b6dd6")]}
# Difficulté 1 à 5. Le niveau 2 est l'équilibrage courant, le 4 celui d'origine.
# foe : dégâts ennemis par étage · hp : PV des héros · heal / revive : fraction des PV max après un combat
# extra : ennemis en plus (ou en moins) par étage · champ : champions en plus.
const DIFFICULTY := [
	{"name": "Oklm", "text": "Pour découvrir : ennemis mous, soins généreux.", "foe": [0.7, 0.8, 0.9], "hp": 1.15, "heal": 0.3, "revive": 0.6, "extra": [0, -1, -1], "champ": -1},
	{"name": "Aventurier", "text": "L'équilibre conseillé pour une première descente.", "foe": [0.8, 0.9, 1.0], "hp": 1.0, "heal": 0.2, "revive": 0.5, "extra": [0, 0, 0], "champ": 0},
	{"name": "Vétéran", "text": "Moins de soins, les ennemis frappent plein pot dès l'étage 2.", "foe": [0.9, 1.0, 1.05], "hp": 0.92, "heal": 0.1, "revive": 0.35, "extra": [0, 0, 0], "champ": 0},
	{"name": "Éclusier", "text": "L'équilibrage d'origine : aucun soin entre les salles.", "foe": [1.0, 1.0, 1.0], "hp": 0.82, "heal": 0.0, "revive": 0.25, "extra": [1, 0, 0], "champ": 0},
	{"name": "Anathème", "text": "Un ennemi de plus partout, un champion de plus, aucune pitié.", "foe": [1.15, 1.2, 1.25], "hp": 0.8, "heal": 0.0, "revive": 0.15, "extra": [1, 1, 1], "champ": 1},
]
# Déclencheurs : un bonus quand la condition tient (esprit Hearthstone / Runeterra, sans la complexité de Magic).
const TRIGGERS := {
	"grace": {"name": "Coup de grâce", "text": "si la carte tue"},
	"mur": {"name": "Dos au mur", "text": "si le héros est sous 30 % de ses PV"},
	"enchaine": {"name": "Enchaîné", "text": "si une autre carte a déjà été jouée ce tour"},
	"surplomb": {"name": "Surplomb", "text": "si le héros est plus haut que la cible"},
	"precision": {"name": "Précision", "text": "si la cible est à la portée maximale exacte"},
	"premier": {"name": "Premier jet", "text": "si c'est la première carte du tour"},
	"grixis": {"name": "Grixis", "text": "si Tidiane a joué ce tour l'Analyse, l'Émotion et l'Ambition (bleu, rouge, noir)"},
}
# Mots-clés expliqués en infobulle sur les cartes.
const KEYWORDS := {
	"Épuise": "La carte quitte le combat une fois jouée.",
	"Pouvoir": "Effet permanent jusqu'à la fin du combat.",
	"Marqué": "Subit +50 % de dégâts.",
	"Entravé": "Ne peut plus se déplacer.",
	"enchaînement": "Le Moine compte ses coups du tour ; certaines cartes s'en nourrissent.",
	"repousse": "Pousse la cible ; contre un mur ou une unité : 3 dégâts. Dans l'eau : noyade.",
	"attire": "Tire la cible vers le héros.",
	"De dos": "Frapper une unité de dos : dégâts ×1,5 (ou plus selon la carte).",
	"baril": "Explose quand on le frappe : 7 dégâts autour.",
	"piège": "L'ennemi qui y marche s'arrête, subit 8 et reste entravé.",
	"Niveau": "Forge ou fusion de deux doubles : +1 niveau (5 au maximum).",
	"perd": "Coût en PV : ne peut pas tuer le héros (il reste à 1).",
	"Vole": "Prend l'objet que porte l'ennemi et le range dans la besace.",
	"Bricole": "Réserve du Receleur (3 au plus) : chaque Bricole améliore le prochain objet fabriqué, puis se vide.",
	"besace": "Objets à usage unique de l'escouade : clic sur l'objet, puis sur la cible. Sans énergie.",
	"Fabrique": "Ajoute un objet tiré au sort à la besace ; plus de Bricole, plus rare.",
}
# Objets de besace : à usage unique, sans énergie, utilisés par le héros sélectionné.
# target : self | ally | foe | free (case libre) | tile. foe_ai : ce que fait un ennemi qui le porte.
const TOOLS := {
	"fiole": {"name": "Fiole de sève", "glyph": "♥", "rar": 1, "target": "ally", "range": [0, 3], "text": "Soigne 10 un allié.", "foe_ai": "la boit sous la moitié de ses PV"},
	"fumigene": {"name": "Fumigène", "glyph": "☁", "rar": 1, "target": "tile", "range": [0, 3], "text": "Fumée 2 tours sur la case et autour : on n'y vise plus à distance, et tout coup au contact y compte de dos.", "foe_ai": "s'en couvre quand il faiblit"},
	"picots": {"name": "Picots", "glyph": "✶", "rar": 1, "target": "free", "range": [1, 3], "text": "Sème des picots sur la case et autour : l'ennemi qui y marche s'arrête et subit 5."},
	"grappin": {"name": "Grappin", "glyph": "↗", "rar": 1, "target": "free", "range": [2, 5], "text": "Le héros se hisse sur une case libre, relief ignoré."},
	"gland": {"name": "Gland de chêne", "glyph": "♣", "rar": 2, "target": "free", "range": [1, 3], "text": "Plante un chêne : il barre la case, les héros voisins gagnent 3 armure par tour. Une explosion l'embrase (6 autour)."},
	"bombe": {"name": "Bombe à mèche", "glyph": "✹", "rar": 1, "target": "tile", "range": [2, 4], "text": "8 dégâts en croix. Fait sauter barils, chênes et bombes portées.", "foe_ai": "la lance sur un groupe de héros"},
	"tonnelet": {"name": "Tonnelet de poudre", "glyph": "▣", "rar": 1, "target": "free", "range": [1, 2], "text": "Pose un baril de poudre."},
	"filet": {"name": "Filet lesté", "glyph": "⊞", "rar": 1, "target": "foe", "range": [1, 4], "text": "Entrave 2 tours.", "foe_ai": "le jette sur un héros proche"},
	"sels": {"name": "Sels de réveil", "glyph": "✧", "rar": 1, "target": "ally", "range": [0, 3], "text": "Retire poison et entraves, +6 armure.", "foe_ai": "s'en sert s'il est blessé ou entravé"},
	"elixir": {"name": "Élixir de braise", "glyph": "☄", "rar": 2, "target": "self", "text": "+2 énergie."},
	"carnet": {"name": "Carnet de croquis", "glyph": "✎", "rar": 2, "target": "self", "text": "Pioche 3 cartes."},
	"de": {"name": "Dé pipé", "glyph": "⚄", "rar": 2, "target": "self", "text": "Défausse la main et repioche autant de cartes."},
	"sablier": {"name": "Sablier fêlé", "glyph": "⧗", "rar": 3, "target": "self", "text": "Tous les ennemis sont entravés 1 tour."},
}
const FOE_TOOLS := ["fiole", "fiole", "bombe", "bombe", "fumigene", "filet", "sels"]
# Cases spéciales, à la Dofus Arena : des runes au sol qui profitent à qui s'y tient, héros comme ennemis.
const TILES := {
	"force": {"name": "Rune de force", "glyph": "✦", "col": Color("#ff5a3a"), "text": "+3 dégâts aux attaques lancées depuis cette case."},
	"source": {"name": "Source", "glyph": "✚", "col": Color("#6ee07a"), "text": "Soigne 4 au début du tour de qui s'y tient."},
	"garde": {"name": "Rune de garde", "glyph": "🛡", "col": Color("#5aa8ff"), "text": "+5 armure au début du tour de qui s'y tient."},
	"elan": {"name": "Rune d'élan", "glyph": "↯", "col": Color("#ffd23a"), "text": "Un héros qui y commence son tour rapporte +1 énergie."},
	"portail": {"name": "Portail jumeau", "glyph": "◎", "col": Color("#c77dff"), "text": "Finir son déplacement dessus mène au portail jumeau, s'il est libre."},
	"ronces": {"name": "Ronces", "glyph": "✳", "col": Color("#c98a4a"), "text": "4 dégâts à qui s'y arrête ou y est poussé."},
}
# Anciens (esprit Slay the Spire 2) : au seuil de chaque étage, un bienfait parmi trois.
const ANCIENTS := {
	"anatheme": {"name": "L'Anathème", "title": "Ancien de l'ambition", "glyph": "♆", "col": Color("#9b6dd6"),
		"line": "Tout pouvoir se paie. Je fais crédit.", "boons": ["relique_sang", "rare", "epure", "or", "relique"]},
	"sourcier": {"name": "Le Sourcier premier", "title": "Ancien des eaux", "glyph": "≋", "col": Color("#4ad0c0"),
		"line": "Bois, et souviens-toi de ce que tu étais.", "boons": ["soin", "pvmax", "forge2", "racines", "besace"]},
	"chineuse": {"name": "La Chineuse", "title": "Ancienne des marchés engloutis", "glyph": "⚖", "col": Color("#e3b45c"),
		"line": "Tout se revend. Même toi.", "boons": ["besace", "place", "arme", "or", "reflet"]},
	"dojo": {"name": "Le Vieux du Dojo", "title": "Ancien des frames", "glyph": "⚔", "col": Color("#e0483f"),
		"line": "Une frame de trop et tu es mort. Recommence.", "boons": ["forge2", "racines", "rare", "relique", "reflet"]},
}
const BOONS := {
	"relique": {"name": "Relique ancienne", "glyph": "◆", "text": "Une relique au hasard."},
	"relique_sang": {"name": "Relique de sang", "glyph": "♦", "text": "Une relique au choix parmi trois ; chaque héros perd 5 PV max."},
	"rare": {"name": "Savoir interdit", "glyph": "✦", "text": "Une carte rare au choix parmi trois."},
	"epure": {"name": "Oubli", "glyph": "✂", "text": "Retirer jusqu'à deux cartes du paquet."},
	"or": {"name": "Tribut", "glyph": "●", "text": "+100 or."},
	"pvmax": {"name": "Sève ancienne", "glyph": "♥", "text": "Chaque héros gagne 6 PV max."},
	"soin": {"name": "Eau lustrale", "glyph": "✚", "text": "Tous les héros retrouvent leurs PV."},
	"forge2": {"name": "Main de maître", "glyph": "⚒", "text": "Deux cartes du paquet, au hasard, gagnent un niveau."},
	"racines": {"name": "Racines", "glyph": "♣", "text": "Les cartes de départ d'un héros au choix gagnent un niveau."},
	"besace": {"name": "Besace pleine", "glyph": "☁", "text": "Trois objets de besace."},
	"place": {"name": "Poches cousues", "glyph": "▣", "text": "Besace +1 place pour la run, et un objet rare."},
	"arme": {"name": "Arme d'antan", "glyph": "⚔", "text": "Un équipement rare."},
	"reflet": {"name": "Reflet", "glyph": "⧉", "text": "Copie une carte du paquet (la copie n'est pas une carte de départ)."},
}
# Modificateurs de combat : affichés sur les salles marquées (plus de risque, plus de butin).
const MODIFIERS := {
	"brume": {"name": "Brume", "glyph": "≈", "text": "Portée des attaques à distance -1, pour tout le monde."},
	"enrages": {"name": "Enragés", "glyph": "✶", "text": "Les ennemis infligent +2 dégâts."},
	"blindes": {"name": "Carapaces", "glyph": "🛡", "text": "Les ennemis gagnent 4 armure à chaque tour."},
	"renforts": {"name": "Renforts", "glyph": "☖", "text": "Deux Moussus surgissent au tour 3."},
	"poudriere": {"name": "Poudrière", "glyph": "✹", "text": "Quatre barils de poudre en plus sur le terrain."},
	"glissant": {"name": "Sol glissant", "glyph": "↠", "text": "Toutes les poussées portent une case plus loin."},
	"hate": {"name": "Hâte", "glyph": "»", "text": "Les ennemis se déplacent d'une case de plus."},
}
# Pactes : des malus choisis en début de run ; chacun augmente l'or (+25 %) et la chance de cartes rares.
const PACTS := {
	"sang": {"name": "Pacte de sang", "text": "PV max des héros -15 %."},
	"horde": {"name": "Horde", "text": "Un ennemi de plus dans chaque combat."},
	"acier": {"name": "Acier", "text": "Les ennemis gagnent 4 armure à chaque tour."},
	"rage": {"name": "Rage", "text": "Les ennemis infligent +2 dégâts."},
	"main": {"name": "Main courte", "text": "On pioche une carte de moins à chaque tour."},
	"brume": {"name": "Brume éternelle", "text": "Portée des attaques à distance -1 dans tous les combats."},
	"champion": {"name": "Champions", "text": "Un champion de plus dans chaque combat."},
}
const RARITY_COL := {1: Color("#a79d8b"), 2: Color("#6fb0e0"), 3: Color("#ffcf5a")}


static func starter(party: Array) -> Array:
	var out: Array = []
	for k in party:
		for id in STARTER[k]:
			out.append({"id": id, "lvl": 1, "st": true})  # carte de départ : pas de fusion
	return out

const RELICS := {
	"ambre": {"name": "Ambre du Gué", "glyph": "◆", "text": "+1 énergie au premier tour de chaque combat."},
	"feuille": {"name": "Feuille Rouge", "glyph": "❦", "text": "Les attaques de dos infligent +3."},
	"lotus_pale": {"name": "Lotus Pâle", "glyph": "✿", "text": "Soigne 4 chaque héros après un combat."},
	"crochet": {"name": "Crochet d'Écluse", "glyph": "⚓", "text": "Les poussées portent 1 case plus loin."},
	"cendre": {"name": "Cendre Vive", "glyph": "✹", "text": "Un ennemi tué explose : 4 dégâts autour de lui."},
	"tuile": {"name": "Tuile Brisée", "glyph": "▲", "text": "Le bonus de hauteur est doublé."},
	"cloche": {"name": "Cloche Noyée", "glyph": "♒", "text": "La noyade inflige +6."},
	"grimoire": {"name": "Grimoire Humide", "glyph": "▤", "text": "Pioche 6 cartes par tour."},
	"sablier": {"name": "Sablier Vert", "glyph": "⧗", "text": "La première carte de chaque tour coûte 0."},
	"ecaille": {"name": "Écaille de Carpe", "glyph": "◈", "text": "Chaque héros commence le combat avec 6 d'armure."},
	"heron": {"name": "Bottes de Héron", "glyph": "⇶", "text": "+1 déplacement pour tous les héros."},
	"oeil": {"name": "Œil de Surveil", "glyph": "◉", "text": "Choix de 4 cartes au lieu de 3."},
	"sacoche": {"name": "Sacoche de cuir", "glyph": "▣", "text": "Besace +1 place."},
	"alambic": {"name": "Alambic de poche", "glyph": "☄", "text": "Un objet fabriqué au début de chaque combat."},
}

const TRAITS := {
	"gaucher": {"name": "Gaucher", "text": "+2 aux attaques de dos."},
	"vertige": {"name": "Vertige", "text": "Saut -1, PV max +6."},
	"leger": {"name": "Pieds légers", "text": "Déplacement +1."},
	"rancune": {"name": "Rancunier", "text": "+3 dégâts sous la moitié des PV."},
	"colosse": {"name": "Colosse", "text": "PV max +8, déplacement -1."},
	"nageur": {"name": "Nageur", "text": "Insensible à la noyade."},
	"myope": {"name": "Myope", "text": "Portée à distance -1, dégâts +2."},
	"beni": {"name": "Béni", "text": "Soins reçus +50 %."},
}

const ENCOUNTERS := {
	1: [["husk", "guetteur", "wisp"], ["guetteur", "husk", "chaman"], ["husk", "carapace", "guetteur"], ["rodeur", "husk", "wisp"]],
	2: [["husk", "guetteur", "guetteur", "wisp", "chaman"], ["sentinelle", "husk", "husk", "rodeur"], ["carapace", "carapace", "guetteur", "wisp"], ["rodeur", "rodeur", "chaman", "guetteur"]],
	3: [["sentinelle", "guetteur", "guetteur", "chaman", "husk"], ["carapace", "sentinelle", "wisp", "wisp", "rodeur"], ["rodeur", "rodeur", "guetteur", "carapace", "chaman"]],
}
const ELITES := {1: ["sentinelle", "guetteur", "chaman", "wisp"], 2: ["sentinelle", "carapace", "rodeur", "guetteur", "chaman"]}
const BOSS := ["gardien", "chaman", "husk", "husk", "guetteur"]

const ROOMS := {
	"combat": {"name": "Combat", "glyph": "⚔", "text": "Une escouade des ruines. Récompense : une carte."},
	"elite": {"name": "Élite", "glyph": "☠", "text": "Des gardiens plus coriaces. Récompense : carte et relique."},
	"sanctuaire": {"name": "Sanctuaire", "glyph": "✚", "text": "Soigner le groupe ou affûter une carte."},
	"reliquaire": {"name": "Reliquaire", "glyph": "◆", "text": "Une relique parmi trois."},
	"marchand": {"name": "Marchand", "glyph": "⚖", "text": "Équipement, cartes et soins contre de l'or."},
	"boss": {"name": "Le Gardien", "glyph": "♜", "text": "Le colosse qui tient l'Écluse."},
}

# Passifs d'équipement, d'après les capacités de réaction et de soutien de FFTA.
const PASSIVES := {
	"contre": {"name": "Contre", "text": "Riposte 4 quand frappé au contact."},
	"casseur": {"name": "Casse-os", "text": "Riposte 8 au contact sous la moitié des PV."},
	"reflexe": {"name": "Réflexe", "text": "25 % d'esquiver un coup au contact."},
	"parade": {"name": "Parade des flèches", "text": "50 % d'esquiver un tir."},
	"retour": {"name": "Retour de feu", "text": "Renvoie la moitié des dégâts de tir."},
	"bouclier": {"name": "Porte-bouclier", "text": "+3 armure au début de chaque tour."},
	"regen": {"name": "Auto-régén", "text": "Soigne 2 au début de chaque tour."},
	"arme_plus": {"name": "Arme+", "text": "+2 aux attaques au contact."},
	"concentration": {"name": "Concentration", "text": "+1 portée aux attaques à distance."},
	"deux_mains": {"name": "Deux mains", "text": "Première attaque du tour : +50 %."},
	"elan": {"name": "Dernier élan", "text": "Sous 25 % PV : +2 énergie, une fois par combat."},
	"absorbe": {"name": "Absorbe", "text": "Tuer un ennemi rend 1 énergie."},
	"eau": {"name": "Marche sur l'eau", "text": "Peut marcher sur l'eau."},
	"deplacement": {"name": "Déplacement +1", "text": "+1 case de déplacement."},
	"saut": {"name": "Saut +2", "text": "Franchit 2 niveaux de plus."},
	"vigilance": {"name": "Vigilance", "text": "Jamais pris de dos."},
	"economie": {"name": "Demi-coût", "text": "La 1re carte à 2+ du tour coûte 1 de moins."},
	"chasseur": {"name": "Chasseur de trésors", "text": "Les coffres donnent aussi 25 or."},
}

# slot : arme (propre à une classe) ou talisman (tous). dmg : bonus plat. rarity 1-3.
const ITEMS := {
	"epee_ecluse": {"name": "Épée de l'Écluse", "slot": "arme", "owner": "garde", "dmg": 1, "passive": "contre", "rarity": 1},
	"masse_os": {"name": "Masse brise-os", "slot": "arme", "owner": "garde", "dmg": 2, "passive": "casseur", "rarity": 2},
	"hallebarde": {"name": "Hallebarde du héron", "slot": "arme", "owner": "garde", "dmg": 1, "passive": "bouclier", "rarity": 3},
	"dague_ombre": {"name": "Dague d'ombre", "slot": "arme", "owner": "lame", "dmg": 1, "passive": "reflexe", "rarity": 1},
	"kriss": {"name": "Kriss jumeau", "slot": "arme", "owner": "lame", "dmg": 2, "passive": "deux_mains", "rarity": 2},
	"lame_soif": {"name": "Lame de soif", "slot": "arme", "owner": "lame", "dmg": 1, "passive": "absorbe", "rarity": 3},
	"baton_braise": {"name": "Bâton de braise", "slot": "arme", "owner": "oracle", "dmg": 1, "passive": "concentration", "rarity": 1},
	"sceptre_maree": {"name": "Sceptre des marées", "slot": "arme", "owner": "oracle", "dmg": 2, "passive": "economie", "rarity": 2},
	"baton_lotus": {"name": "Bâton de lotus", "slot": "arme", "owner": "oracle", "dmg": 0, "passive": "regen", "rarity": 3},
	"cle_meca": {"name": "Clé de mécanicien", "slot": "arme", "owner": "artificier", "dmg": 1, "passive": "arme_plus", "rarity": 1},
	"canon_main": {"name": "Canon à main", "slot": "arme", "owner": "artificier", "dmg": 2, "passive": "economie", "rarity": 2},
	"bandes_jade": {"name": "Bandes de jade", "slot": "arme", "owner": "moine", "dmg": 1, "passive": "reflexe", "rarity": 1},
	"chapelet": {"name": "Chapelet du ressac", "slot": "arme", "owner": "moine", "dmg": 2, "passive": "regen", "rarity": 2},
	"arc_frene": {"name": "Arc de frêne", "slot": "arme", "owner": "trappeur", "dmg": 1, "passive": "concentration", "rarity": 1},
	"arc_os": {"name": "Arc en os de silure", "slot": "arme", "owner": "trappeur", "dmg": 2, "passive": "absorbe", "rarity": 2},
	"marteau_forge": {"name": "Marteau de forge", "slot": "arme", "owner": "artificier", "dmg": 2, "passive": "bouclier", "rarity": 3},
	"gantelets_ressac": {"name": "Gantelets du ressac", "slot": "arme", "owner": "moine", "dmg": 2, "passive": "deux_mains", "rarity": 3},
	"arbalete_silure": {"name": "Arbalète du silure", "slot": "arme", "owner": "trappeur", "dmg": 2, "passive": "elan", "rarity": 3},
	"pinceau": {"name": "Pinceau de Sinlaire", "slot": "arme", "owner": "tidiane", "dmg": 1, "passive": "arme_plus", "rarity": 1},
	"palette": {"name": "Palette Grixis", "slot": "arme", "owner": "tidiane", "dmg": 2, "passive": "absorbe", "rarity": 2},
	"pied_biche": {"name": "Pied-de-biche", "slot": "arme", "owner": "receleur", "dmg": 1, "passive": "chasseur", "rarity": 1},
	"crochets": {"name": "Trousseau de crochets", "slot": "arme", "owner": "receleur", "dmg": 2, "passive": "reflexe", "rarity": 2},
	"gants_velours": {"name": "Gants de velours", "slot": "arme", "owner": "receleur", "dmg": 2, "passive": "absorbe", "rarity": 3},
	"stylet": {"name": "Stylet de CSP", "slot": "arme", "owner": "tidiane", "dmg": 2, "passive": "elan", "rarity": 3},
	"anneau_bouclier": {"name": "Anneau du rempart", "slot": "talisman", "owner": "any", "passive": "bouclier", "rarity": 2},
	"bottes_heron": {"name": "Bottes de héron", "slot": "talisman", "owner": "any", "passive": "deplacement", "rarity": 1},
	"sandales_saut": {"name": "Sandales du saut", "slot": "talisman", "owner": "any", "passive": "saut", "rarity": 1},
	"amulette_regen": {"name": "Amulette de mousse", "slot": "talisman", "owner": "any", "passive": "regen", "rarity": 2},
	"plume_elan": {"name": "Plume d'élan", "slot": "talisman", "owner": "any", "passive": "elan", "rarity": 2},
	"ecaille_eau": {"name": "Écaille de carpe", "slot": "talisman", "owner": "any", "passive": "eau", "rarity": 2},
	"oeil_vigilant": {"name": "Œil vigilant", "slot": "talisman", "owner": "any", "passive": "vigilance", "rarity": 1},
	"bracelet_fleches": {"name": "Bracelet paraflèches", "slot": "talisman", "owner": "any", "passive": "parade", "rarity": 1},
	"gantelet": {"name": "Gantelet lesté", "slot": "talisman", "owner": "any", "passive": "arme_plus", "rarity": 2},
	"miroir": {"name": "Miroir de cuivre", "slot": "talisman", "owner": "any", "passive": "retour", "rarity": 2},
	"bourse": {"name": "Bourse trouée", "slot": "talisman", "owner": "any", "passive": "chasseur", "rarity": 1},
	"coeur_pierre": {"name": "Cœur de pierre", "slot": "talisman", "owner": "any", "hp": 8, "passive": "", "rarity": 1},
}
const PRICE := {1: 45, 2: 75, 3: 110}

const PROPS := {
	"coffre": {"name": "Coffre", "text": "Un héros adjacent peut l'ouvrir (utilise son déplacement)."},
	"brasero": {"name": "Brasero", "text": "Un coup le fait exploser : 7 dégâts autour."},
	"pilier": {"name": "Pilier fendu", "text": "Frappé ou poussé, il s'effondre sur les 2 cases suivantes : 9 dégâts."},
	"baril": {"name": "Baril de poudre", "text": "Un coup le fait exploser : 7 dégâts autour."},
	"tourelle": {"name": "Tourelle", "text": "Tire 4 sur l'ennemi le plus proche à chaque fin de tour."},
	"levier": {"name": "Levier d'écluse", "text": "Un héros adjacent l'actionne : le pont-levis s'abaisse."},
}


static func item_text(id: String) -> String:
	var it: Dictionary = ITEMS[id]
	var parts: Array = []
	if it.get("dmg", 0) > 0:
		parts.append("+%d dégâts" % it.dmg)
	if it.get("hp", 0) > 0:
		parts.append("+%d PV max" % it.hp)
	if it.passive != "":
		parts.append("%s : %s" % [PASSIVES[it.passive].name, PASSIVES[it.passive].text])
	var who: String = "Talisman" if it.slot == "talisman" else "Arme de %s" % HEROES[it.owner].name
	return who + "\n" + " · ".join(parts)


# Lumière, ciel et végétation de chaque étage.
# stone : matière des murs · top : dalle | herbe · tree : essence de la couronne · flora : décor des
# sols · ring : objets dressés dans la couronne · crown : sommet des tours · monument : pièce maîtresse.
const BIOMES := [
	{"name": "L'Écluse d'Automne", "stone": "pierre", "top": "dalle", "tree": "autumn", "foliage": "autumn", "flora": "", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.84, 0.64), "sun_energy": 3.1, "sun_elev": 27.0, "sun_az": -38.0,
		"sky_top": Color(0.36, 0.56, 0.76), "sky_hor": Color(0.93, 0.83, 0.68), "ambient": 0.42, "fog": Color(0.86, 0.8, 0.7),
		"water_shallow": Color(0.2, 0.8, 0.74), "water_deep": Color(0.02, 0.32, 0.36), "glow_windows": 0.1, "leaves": ["#b4501c", "#d98434", "#8c3616", "#e39a3e"]},
	{"name": "Les Arches Moussues", "stone": "pierre", "top": "dalle", "tree": "green", "foliage": "green", "flora": "tufts", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.6, 0.34), "sun_energy": 1.7, "sun_elev": 18.0, "sun_az": 150.0,
		"sky_top": Color(0.1, 0.15, 0.28), "sky_hor": Color(0.55, 0.43, 0.4), "ambient": 0.65, "fog": Color(0.26, 0.32, 0.4),
		"water_shallow": Color(0.16, 0.6, 0.6), "water_deep": Color(0.02, 0.16, 0.22), "glow_windows": 0.5, "leaves": [], "moon": Color(0.5, 0.66, 1.0)},
	{"name": "Le Bassin de Braise", "stone": "terre", "top": "dalle", "tree": "autumn", "foliage": "autumn", "flora": "", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.62, 0.44), "sun_energy": 2.5, "sun_elev": 15.0, "sun_az": 70.0,
		"sky_top": Color(0.18, 0.2, 0.3), "sky_hor": Color(1.0, 0.58, 0.38), "ambient": 0.45, "fog": Color(0.55, 0.4, 0.36),
		"water_shallow": Color(0.22, 0.66, 0.7), "water_deep": Color(0.03, 0.2, 0.3), "glow_windows": 0.3, "leaves": ["#b4501c", "#d98434", "#8c3616"], "embers": true, "moon": Color(0.45, 0.5, 0.9)},
	{"name": "Le Sanctuaire Lilas", "stone": "lilas", "top": "dalle", "tree": "green", "foliage": "green", "flora": "tufts", "ring": ["statue"], "crown": "crown", "monument": "statue_giant",
		"sun": Color(1.0, 0.95, 0.82), "sun_energy": 2.6, "sun_elev": 42.0, "sun_az": 20.0,
		"sky_top": Color(0.55, 0.78, 0.86), "sky_hor": Color(0.88, 0.82, 0.96), "ambient": 0.6, "fog": Color(0.82, 0.78, 0.92),
		"water_shallow": Color(0.35, 0.86, 0.8), "water_deep": Color(0.08, 0.32, 0.44), "glow_windows": 0.0, "leaves": ["#e8d46a", "#f2e28a"]},
	{"name": "Les Tours-Bassins", "stone": "brique", "top": "dalle", "tree": "green", "foliage": "green", "flora": "", "ring": [], "crown": "basin", "monument": "monument",
		"sun": Color(1.0, 0.94, 0.84), "sun_energy": 2.8, "sun_elev": 38.0, "sun_az": -60.0,
		"sky_top": Color(0.72, 0.8, 0.78), "sky_hor": Color(0.96, 0.93, 0.86), "ambient": 0.55, "fog": Color(0.88, 0.9, 0.86),
		"water_shallow": Color(0.3, 0.72, 0.74), "water_deep": Color(0.05, 0.28, 0.32), "glow_windows": 0.2, "leaves": ["#6a8f3a", "#7da44a"]},
	{"name": "L'Altiplano", "stone": "terre", "top": "herbe", "tree": "", "foliage": "green", "flora": "tufts", "ring": [], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.9, 0.72), "sun_energy": 3.0, "sun_elev": 30.0, "sun_az": 110.0,
		"sky_top": Color(0.74, 0.86, 0.68), "sky_hor": Color(1.0, 0.9, 0.76), "ambient": 0.5, "fog": Color(0.7, 0.62, 0.72),
		"water_shallow": Color(0.45, 0.72, 0.9), "water_deep": Color(0.12, 0.3, 0.5), "glow_windows": 0.05, "leaves": []},
	{"name": "La Cité de Cristal", "stone": "blanc", "top": "dalle", "tree": "green", "foliage": "green", "flora": "", "ring": ["crystal_0", "crystal_1"], "crown": "crown", "monument": "crystal_giant",
		"sun": Color(1.0, 0.9, 0.74), "sun_energy": 2.9, "sun_elev": 34.0, "sun_az": -20.0,
		"sky_top": Color(0.5, 0.72, 0.95), "sky_hor": Color(0.96, 0.92, 0.84), "ambient": 0.55, "fog": Color(0.86, 0.9, 0.96),
		"water_shallow": Color(0.28, 0.82, 0.82), "water_deep": Color(0.04, 0.3, 0.42), "glow_windows": 0.1, "leaves": []},
	{"name": "La Prairie d'Épilobes", "stone": "blanc", "top": "herbe", "tree": "pine", "foliage": "pink", "flora": "fireweed", "ring": ["column_fallen"], "crown": "crown", "monument": "monument",
		"sun": Color(1.0, 0.82, 0.72), "sun_energy": 2.6, "sun_elev": 24.0, "sun_az": -80.0,
		"sky_top": Color(0.92, 0.7, 0.68), "sky_hor": Color(1.0, 0.88, 0.8), "ambient": 0.55, "fog": Color(0.96, 0.82, 0.78),
		"water_shallow": Color(0.3, 0.7, 0.72), "water_deep": Color(0.08, 0.28, 0.36), "glow_windows": 0.05, "leaves": ["#e0418c", "#f06aa8", "#f59ac4"]},
]

# Champions : un affixe tiré au sort, comme les ennemis rares du Monde des objets.
const AFFIXES := {
	"blinde": {"name": "blindé", "text": "+5 armure par tour."},
	"enrage": {"name": "enragé", "text": "+3 dégâts."},
	"veloce": {"name": "véloce", "text": "+2 déplacement, +1 saut."},
	"epineux": {"name": "épineux", "text": "Riposte au contact."},
	"vampire": {"name": "vampire", "text": "Se soigne de la moitié des dégâts infligés."},
}


## Une carte en main = {"id", "lvl"} (niveau 1 à 5). Renvoie la définition au niveau voulu.
static func level(ci: Dictionary) -> int:
	return clampi(int(ci.get("lvl", 1 + int(ci.get("up", 0)))), 1, 5)


static func card(ci: Dictionary) -> Dictionary:
	var c: Dictionary = CARDS[ci.id].duplicate(true)
	c["id"] = ci.id
	var lv := level(ci)
	c["lvl"] = lv
	c["st"] = ci.get("st", false)
	var k := lv - 1
	if k > 0:
		for key in ["dmg", "block", "heal", "heal_all"]:
			if c.get(key, 0) > 0:
				c[key] += k * maxi(1, int(round(c[key] * 0.25)))
		if c.has("poison"):
			c.poison += k
		if lv >= 3 and c.cost >= 2:
			c.cost -= 1
		if lv >= 4:
			if c.get("draw", 0) > 0:
				c.draw += 1
			if c.has("range") and c.range[1] > 1:
				c.range = [c.range[0], c.range[1] + 1]
			for key in ["mark", "root"]:
				if c.has(key):
					c[key] += 1
		if lv >= 5:
			if c.has("hits"):
				c.hits += 1
			if c.has("trig"):
				for key in ["dmg", "block", "heal", "draw", "energy", "poison"]:
					if c.trig.has(key):
						c.trig[key] += 1 if key in ["draw", "energy"] else maxi(1, int(round(c.trig[key] * 0.5)))
	return c


static func trig_text(c: Dictionary) -> String:
	if not c.has("trig"):
		return ""
	var t: Dictionary = c.trig
	var fx: Array = []
	if t.has("dmg"):
		fx.append("+%d dégâts" % t.dmg)
	if t.has("block"):
		fx.append("+%d armure" % t.block)
	if t.has("heal"):
		fx.append("soigne %d" % t.heal)
	if t.has("draw"):
		fx.append("pioche %d" % t.draw)
	if t.has("energy"):
		fx.append("+%d énergie" % t.energy)
	if t.has("poison"):
		fx.append("+%d poison" % t.poison)
	if t.get("refund", false):
		fx.append("revient en main")
	return "%s : %s." % [TRIGGERS[t.on].name, ", ".join(fx)]


static func card_text(c: Dictionary) -> String:
	var t: String = c.text
	for k in ["dmg", "block", "heal", "heal_all", "poison"]:
		t = t.replace("{%s}" % k, str(c.get(k, 0)))
	var tt := trig_text(c)
	return t + ("\n" + tt if tt != "" else "")


static func keyword_tip(c: Dictionary) -> String:
	## Définitions des mots-clés présents sur la carte.
	var txt: String = card_text(c) + " " + KIND_WORD.get(c.kind, "")
	var out: Array = []
	if c.has("trig"):
		out.append("%s : bonus %s." % [TRIGGERS[c.trig.on].name, TRIGGERS[c.trig.on].text])
	for kw in KEYWORDS:
		if txt.to_lower().contains(kw.to_lower()):
			out.append("%s : %s" % [kw, KEYWORDS[kw]])
	out.append("Niveau %d / 5 : %s" % [c.lvl, KEYWORDS["Niveau"]])
	if c.get("st", false):
		out.append("Carte de départ : ne fusionne pas (la forge reste possible).")
	return "\n".join(out)

const KIND_WORD := {"power": "Pouvoir"}
