# TonerTactic

Roguelike tactique à cartes, en voxels : l'esprit de *Final Fantasy Tactics* et *Disgaea* sur le terrain,
la structure de *Slay the Spire* dans le paquet. Fait avec Godot 4.7 ; tous les modèles sont générés
dans Blender par script (`blender/`).

**Jouer dans le navigateur :** la page GitHub Pages du dépôt (publiée à chaque push sur `main`).

## Commandes

- Clic : choisir un héros, une carte, une case · Espace : fin du tour
- Clic droit maintenu : caméra libre (ZQSD) · Q/E : pivoter · molette : zoom
- P : voir le paquet · M : couper la musique · H : aide · Alt : objets interactifs · Échap : menu
- Manette Xbox prise en charge

## Contenu

- 8 classes, dont le Receleur (vole et bricole les objets) et Tidiane (Analyse, Émotion, Ambition)
- Cartes de niveau 1 à 5 avec déclencheurs, forge et fusion de doubles
- Besace d'objets à usage unique ; les ennemis en portent aussi, on peut les leur voler
- Runes au sol (force, source, garde, élan, portails, ronces)
- Deux modes : Descente (carte d'étage) et Aventure (donjon à explorer)
- Un Ancien à chaque étage, modificateurs de salles, pactes, 5 niveaux de difficulté

## Développement

- Tests : `godot --headless --script res://tests/check.gd`
- Partie automatique : `godot --path . -- --autoplay=6`
- Régénérer les modèles : `blender -b --factory-startup -P blender/gen_chars.py`

Polices libres (SIL OFL / licence Bitstream Vera) : Fraunces, Lato, DejaVu Sans Mono, Noto Sans Math, Noto Emoji.
