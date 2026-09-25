# TonerTactic

Roguelike tactique à cartes, en voxels : l'esprit de *Final Fantasy Tactics* et *Disgaea* sur le terrain,
la structure de *Slay the Spire* dans le paquet. Fait avec Godot 4.7 ; tous les modèles sont générés
dans Blender par script (`blender/`).

**Jouer dans le navigateur :** la page GitHub Pages du dépôt (publiée à chaque push sur `main`).

## Règles en bref

- Initiative à la FFT : héros et ennemis jouent chacun leur tour, du plus rapide au plus lent.
- Chaque héros a son propre paquet, sa main (3 cartes) et son mana (3) à son tour.
- Cartes de niveau 1 à 3 : chaque niveau change la carte (aperçu avant / après à la forge).
- Vocation à la FFT : chaque héros gagne des points de job (1 par combat, 2 par élite). À la maîtrise II il choisit
  une deuxième classe ; la paire forme une **guilde** (28 guildes, 168 cartes : commune et peu commune dès la
  vocation, 3 rares à la maîtrise III, une légendaire à la maîtrise IV). La carte de vocation arrive dans une case
  bonus du butin, en plus des trois cartes de classe.
- Bibliothèque (écran titre) : toutes les cartes déjà croisées, gardées d'une partie à l'autre.
- Fin du tour à la FFT : le héros choisit où il regarde (son dos est exposé) ; les ennemis se tournent vers le héros le plus proche.
- Marchand : un étal de cartes à la Slay the Spire (dont une carte de guilde et une soldée), objets, soins, épuration, forge.
  Un seul passage ; un second marchand attend avant le gardien.
- Étages de 7 salles. La run se sauvegarde entre deux salles : « Reprendre la partie » à l'écran titre.

## Commandes

- Clic : choisir un héros, une carte, une case · Espace : fin du tour, puis orientation (souris ou ← →, Espace pour valider)
- Clic droit maintenu : caméra libre (ZQSD) · Q/E : pivoter · molette : zoom
- P : voir le paquet · M : couper la musique · H : aide · Alt : objets interactifs · Échap : menu
- Manette Xbox prise en charge

## Contenu

- Chaque héros joue à son tour (vitesse), avec son paquet et son mana
- 8 classes, dont le Receleur (vole et bricole les objets) et Tidiane (Analyse, Émotion, Ambition)
- Cartes de niveau 1 à 3 avec déclencheurs, forge et fusion de doubles
- Besace d'objets à usage unique ; les ennemis en portent aussi, on peut les leur voler
- Runes au sol (force, source, garde, élan, portails, ronces)
- Deux modes : Descente (carte d'étage) et Aventure (donjon à explorer)
- Un Ancien à chaque étage, modificateurs de salles, pactes, 5 niveaux de difficulté

## Développement

- Tests : `godot --headless --script res://tests/check.gd`
- Partie automatique : `godot --path . -- --autoplay=6`
- Chaque carte de guilde jouée en combat : `godot --headless --path . -- --cardtest --party=garde,lame,tidiane`
- Captures des écrans de vocation, de l'étal, de la carte, du titre et de l'orientation : `godot --path . -- --voctest=DOSSIER`
- Sauvegarde et reprise (Descente et Aventure) : `godot --path . -- --savetest`
- Régénérer les modèles : `blender -b --factory-startup -P blender/gen_chars.py`

Polices libres (SIL OFL / licence Bitstream Vera) : Fraunces, Lato, DejaVu Sans Mono, Noto Sans Math, Noto Emoji.

Icônes : [game-icons.net](https://game-icons.net) (Lorc, Delapouite, Darkzaitzev, Sbed, Faithtoken, Caro Asercion,
Carl Olsen et al.), licence [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/), repassées en pixel art.
Idéogrammes PV, déplacement, armure, attaque, portée générés avec KIE.
