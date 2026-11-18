# godot-template

Le point de départ des jeux Godot 4.7 : outils épinglés par [mise](https://mise.jdx.dev), tests GdUnit4, CI, export Linux, Windows et web avec auto-test, publication sur GitHub Releases et Pages, configuration Claude Code, et le **kit** (`addons/kit/`) que partagent tous les jeux : options, traduction, entrées clavier, manette et souris. Des menus prêts à l'emploi (`addons/kit_ui/`) s'y ajoutent, qu'un jeu garde, habille ou remplace par les siens.

Le template ne choisit ni le genre, ni la 2D ou la 3D, ni l'apparence : il démarre sur un écran titre, des options, un menu pause et deux démos (2D et 3D) à remplacer.

## Démarrer un jeu

Avec [Copier](https://copier.readthedocs.io), que `mise install` installe dans ce dépôt (ou `pipx install copier==9.19.1`) :

1. `copier copy --vcs-ref main gh:VictorNain26/godot-template mon-jeu`, puis dans `mon-jeu` : `git init`, un premier commit, et un dépôt GitHub où le pousser.
2. `mise install` et `git lfs install`.
3. Dans Claude Code : `/new-game` (renommer le projet, garder une démo, écrire la vision).
4. `mise run check`.

## Garder un jeu à jour

`mise run template-update` amène dans le jeu la dernière version de `main` du template. Le socle (kit, menus du kit, outils, CI, réglages de Claude Code, `mise.toml`, `project.godot`, exports, lint) est fusionné à trois voies : les changements du jeu sont gardés, un conflit est marqué dans le fichier. Ce qui est au jeu (`src/`, `scenes/`, `docs/`, `locale/`, `kit_config.gd`, ses tests, `README.md`, `CHANGELOG.md`) n'est jamais touché, et un fichier du socle que le jeu a supprimé (`addons/kit_ui`, par exemple) ne revient pas. Le partage est décrit dans `copier.yml` ; `mise run copier-check` le prouve, en CI aussi.

Un jeu créé avant Copier (« Use this template ») n'a pas de `.copier-answers.yml` : il garde `mise run kit-update` pour le kit et ses menus.

## Commandes

| Commande | Ce qu'elle fait |
| --- | --- |
| `mise run check` | lint, compilation de chaque fichier, tests (jeu et kit), lancement de chaque scène |
| `mise run export` puis `export-smoke` | exporte Linux, Windows et web, et lance l'auto-test de l'exécutable Linux |
| `mise run web-smoke` | charge la version web dans Chromium et en fait une capture |
| `mise run mouse-check` | clique pour de vrai dans les menus, sous Xvfb |
| `mise run template-update` | amène les changements du template dans le jeu (Copier) |
| `mise run copier-check` | prouve que Copier crée un jeu et le met à jour sans toucher à ce qui est au jeu |
| `mise run shots` | captures de l'écran titre, des options, d'une démo et de sa pause |
| `mise run editor` | ouvre l'éditeur Windows depuis WSL, que pilote godot-ai |

## Ce qui est à chaque jeu, et ce qui est commun

| Commun (template et kit) | Propre au jeu |
| --- | --- |
| Outils, CI, publication, tests | Le gameplay, le monde, les créatures |
| Options, traduction, entrées | La direction artistique |
| Vrais clics et auto-test de l'exécutable, sur les menus du jeu | Les menus : ceux du kit avec un skin, ou les siens |

Le détail du kit et de sa mise à jour dans les jeux est dans `addons/kit/README.md` ; ses menus, leur skin et la façon de les remplacer, dans `addons/kit_ui/README.md`.
