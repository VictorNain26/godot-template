# Le kit

Ce que tout jeu fait sur ce template partage, quel que soit son genre : les options et leur fichier, la traduction, les entrées clavier, manette et souris, les menus en liste (options, pause), un style d'interface remplaçable, et les outils qui vérifient tout cela. Il est né de Cairnlight et d'Emberwake, qui l'utilisent.

Le kit donne le **comportement** des menus, pas leur **apparence** : un jeu garde l'allure qu'il veut, et les tests du kit vérifient qu'elle reste lisible.

## Ce qu'il contient

| Dossier | Contenu |
| --- | --- |
| `core/` | `Settings` (les options en données), `Loc` (la traduction, l'espace insécable du français), `MenuInput` (ce que veut dire une touche, un bouton ou un stick dans un menu) |
| `prefs/prefs.gd` | L'autoload `Prefs` : applique les options, les garde dans `user://settings.json` à part de la progression, nomme les touches comme le clavier du joueur les imprime et les boutons de la manette quand il s'en sert |
| `ui/` | `UiStyle` (les jetons : polices, tailles, couleurs, espacements), `UiDraw` (le dessin commun : lignes de menu, réglettes, touches, légendes, panneaux), `MenuRow`, `LegendBar`, `OptionsMenu`, `PauseMenu` |
| `fonts/` | Cinzel et Atkinson Hyperlegible Next, sous SIL Open Font License, avec leur licence |
| `locale/en.po` | L'anglais des textes du kit |
| `dev/` | `self_test.gd` (l'auto-test d'un exécutable exporté), `mouse_check.tscn` (de vrais clics sous Xvfb) |
| `tests/` | Les tests du kit (GdUnit4) et `KitSim`, qui envoie de vraies touches, de vrais boutons et un vrai pointeur |

## Brancher un jeu

1. `project.godot` :
   - autoload `Prefs="*res://addons/kit/prefs/prefs.gd"` ;
   - `internationalization/locale/translations` : `res://addons/kit/locale/en.po` puis le fichier du jeu ; `locale/fallback="fr"` (sinon un joueur français lit l'anglais) ;
   - `gui/theme/custom_font` : la police de lecture du skin ;
   - les actions `pause` et `interact`, et `kit/config` si la config n'est pas `res://kit_config.gd`.
2. `kit_config.gd`, à la racine : `ACTIONS` (les actions que le joueur peut changer, avec leur nom dans le menu), `FIXED_ACTIONS`, `HELP` (la légende des écrans titre et pause), et au besoin `static func skin()`, `static func self_test()` (des contrôles de plus pour l'auto-test du kit) ou `SELF_TEST` (le chemin d'un auto-test propre au jeu, lancé à la place de celui du kit).
3. Les exports incluent `addons/kit/fonts/*.txt` (les licences ne sont pas des ressources) et excluent `addons/kit/tests/*` et `addons/kit/dev/mouse_check.*`.
4. `mise run test` lance les tests du jeu et ceux du kit.

## Changer l'apparence : le skin

Tous les jetons de `UiStyle` sont des variables : polices (`DISPLAY_PATH`, `BODY_PATH`, `LICENCES`), tailles (`LOGO` à `SMALL`), graisses, espacements (`UNIT`, `MARGIN`, rayons), couleurs (`INK`, `TEXT`, `ACCENT`, `ACCENT_HOT`, `EDGE`) et opacités. Le skin d'un jeu les règle dans `kit_config.gd` :

```gdscript
static func skin() -> void:
	UiStyle.DISPLAY_PATH = "res://assets/fonts/MesTitres.ttf"
	UiStyle.ACCENT = Color("4fc3f7")
	UiStyle.RADIUS = 0
```

`Prefs` l'appelle au démarrage, avant tout écran. `tests/test_skin.gd` vérifie ensuite le résultat contre les règles d'une interface lisible : deux polices avec leur licence, des tailles en ordre et au-dessus d'un plancher (20 px à 100 %, soit 30 px en 1080p), le texte lisible sur son panneau (contraste 4,5:1 sur fond blanc comme noir), une sélection qui se voit autrement que par la couleur. Un skin qui casse une règle fait échouer `mise run check`.

Pour une interface d'une autre forme (menu circulaire, interface dans le décor, inventaire en grille), le jeu écrit ses propres écrans : il garde `Prefs`, `MenuInput`, `Loc` et `KitSim`, et n'est pas obligé d'utiliser `UiDraw`.

## Les règles que le kit tient

- Une touche simulée marche sans fenêtre si l'événement porte `keycode` et `physical_keycode` et qu'on appelle ensuite `Input.flush_buffered_events()` : c'est ce que fait `KitSim.send`.
- Sans fenêtre, aucun événement souris n'atteint un `Control` : les tests émettent les signaux `pointed` et `clicked` de `MenuRow`, et `mise run mouse-check` clique pour de vrai sous Xvfb.
- Le display server `headless` et le web ne connaissent pas la disposition du clavier : `Prefs._printed` garde alors le nom de la position.
- Un test ne lit ni n'écrit les fichiers du joueur : `Prefs.persist` est coupé pendant un test, avec ou sans fenêtre.
- Changer de sélection ne déplace rien à l'écran, et le texte sélectionné ne clignote pas.
- Une marque se dessine (`UiDraw.chevron`, `UiDraw.keycap`), elle ne se tape pas : aucune des deux polices n'a ■, ▼, ‹ ou ›.

## Partager le kit entre les jeux

Le kit vit dans ce template, qui en est la source. Un jeu le garde à jour avec `git subtree` : le code est copié dans le jeu, si bien qu'une session qui n'a accès qu'au jeu le lit quand même. Le jeu extrait `addons/kit` de la branche `main` du template au moment de la mise à jour : aucune branche de plus à entretenir.

```bash
mise run kit-update
```

La tâche ajoute le dépôt du template comme remote `template`, extrait `addons/kit` de sa branche `main` (`git subtree split`) et le fusionne dans le jeu (`git subtree merge --squash`). La première fois, un jeu créé avec « Use this template » tient le kit en fichiers ordinaires : la tâche les retire dans un commit puis les rajoute par `git subtree add`. L'arbre de travail doit être propre.

Une correction faite dans un jeu se reporte dans le template, puis les autres jeux la récupèrent : le kit ne se modifie pas dans un jeu sans revenir ici.
