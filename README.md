# godot-template

Le point de départ des jeux Godot 4.7 : outils épinglés par [mise](https://mise.jdx.dev), tests GdUnit4, CI, export Linux, Windows et web avec auto-test, publication sur GitHub Releases et Pages, configuration Claude Code, et le **kit** (`addons/kit/`) que partagent tous les jeux : options, traduction, entrées clavier, manette et souris. Des menus prêts à l'emploi (`addons/kit_ui/`) s'y ajoutent, qu'un jeu garde, habille ou remplace par les siens.

Le template ne choisit ni le genre, ni la 2D ou la 3D, ni l'apparence : il démarre sur un écran titre, des options, un menu pause et deux démos (2D et 3D) à remplacer.

## Démarrer un jeu

1. « Use this template » sur GitHub, puis cloner le nouveau dépôt.
2. `mise install` et `git lfs install`.
3. Dans Claude Code : `/new-game` (renommer le projet, garder une démo, écrire la vision).
4. `mise run check`.

## Commandes

| Commande | Ce qu'elle fait |
| --- | --- |
| `mise run check` | lint, compilation de chaque fichier, tests (jeu et kit), lancement de chaque scène |
| `mise run export` puis `export-smoke` | exporte Linux, Windows et web, et lance l'auto-test de l'exécutable Linux |
| `mise run web-smoke` | charge la version web dans Chromium et en fait une capture |
| `mise run mouse-check` | clique pour de vrai dans les menus, sous Xvfb |
| `mise run shots` | captures de l'écran titre, des options, d'une démo et de sa pause |
| `mise run editor` | ouvre l'éditeur Windows depuis WSL, que pilote godot-ai |

## Ce qui est à chaque jeu, et ce qui est commun

| Commun (template et kit) | Propre au jeu |
| --- | --- |
| Outils, CI, publication, tests | Le gameplay, le monde, les créatures |
| Options, traduction, entrées | La direction artistique |
| Vrais clics et auto-test de l'exécutable, sur les menus du jeu | Les menus : ceux du kit avec un skin, ou les siens |

Le détail du kit et de sa mise à jour dans les jeux est dans `addons/kit/README.md` ; ses menus, leur skin et la façon de les remplacer, dans `addons/kit_ui/README.md`.
