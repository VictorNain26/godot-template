# Les menus du kit

Des menus prêts à l'emploi pour un jeu qui utilise le kit (`addons/kit`) : la page d'options (volumes, plein écran, secousses, taille du texte, langue, touches), le menu de pause, et le style qui les dessine. Ils sont **facultatifs** : un jeu les garde, les habille, ou supprime ce dossier et écrit les siens.

| Fichier | Contenu |
| --- | --- |
| `ui_style.gd` | `UiStyle` : les jetons (polices, tailles, couleurs, espacements) |
| `ui_draw.gd` | `UiDraw` : le dessin commun (lignes de menu, réglettes, touches, légendes, panneaux) |
| `menu_row.gd`, `legend_bar.gd`, `options_menu.gd`, `pause_menu.gd` | `MenuRow`, `LegendBar`, `OptionsMenu`, `PauseMenu` |
| `ui_self_test.gd` | `KitUiSelfTest` : ce que l'auto-test d'un exécutable vérifie des menus (leurs polices, leurs licences, la police par défaut) |
| `ui_mouse_check.gd` | `KitUiMouseCheck` : les vrais clics de `mise run mouse-check` sur les options et la pause |
| `fonts/` | Cinzel et Atkinson Hyperlegible Next, sous SIL Open Font License, avec leur licence |
| `locale/en.po` | L'anglais des textes des menus |
| `tests/` | Leurs tests (GdUnit4) : comportement sous de vrais événements, mise en page, lisibilité du skin, traductions, export |

## Les garder

Les trois menus (`OptionsMenu`, `PauseMenu`, et l'écran titre du template) tiennent le contrat `MenuContract` du kit. La config du jeu (`kit_config.gd`) les branche : `menus()` les liste, `LICENCES` liste les licences de `fonts/`, `self_test()` renvoie `KitUiSelfTest.run()`, `mouse_check(check)` appelle `check.menus()` puis `KitUiMouseCheck.run(check)`. `project.godot` déclare `locale/en.po` dans les traductions et la police de lecture dans `gui/theme/custom_font`.

## Changer leur apparence : le skin

Tous les jetons de `UiStyle` sont des variables : polices (`DISPLAY_PATH`, `BODY_PATH`, `LICENCES`), tailles (`LOGO` à `SMALL`), graisses, espacements (`UNIT`, `MARGIN`, rayons), couleurs (`INK`, `TEXT`, `ACCENT`, `ACCENT_HOT`, `EDGE`) et opacités. Le skin d'un jeu les règle dans `kit_config.gd` :

```gdscript
static func skin() -> void:
	UiStyle.DISPLAY_PATH = "res://assets/fonts/MesTitres.ttf"
	UiStyle.ACCENT = Color("4fc3f7")
	UiStyle.RADIUS = 0
```

`Prefs` l'appelle au démarrage, avant tout écran : aucune police n'est encore construite, rien à vider. Un changement de jetons en cours de partie appelle ensuite `UiStyle.reset()`. `tests/test_skin.gd` vérifie le résultat contre les règles d'une interface lisible : deux polices avec leur licence, des tailles en ordre et au-dessus d'un plancher (19 px à 100 %, soit 28 px en 1080p), le texte lisible sur son panneau (contraste 4,5:1 sur fond blanc comme noir), une sélection qui se voit autrement que par la couleur. Un skin qui casse une règle fait échouer `mise run check`.

## Les remplacer

Pour une interface d'une autre forme (menu circulaire, interface dans le décor, inventaire en grille) :

1. Supprimer `addons/kit_ui` et les écrans qui s'en servent (`scenes/title.gd`, `scenes/game_pause.gd` dans le template).
2. Dans `kit_config.gd` : retirer les appels à `KitUiSelfTest` et `KitUiMouseCheck`, mettre dans `LICENCES` les licences des polices du jeu, lister ses propres menus dans `menus()` (chacun tient `MenuContract`, voir le README du kit) et garder `await check.menus()` dans `mouse_check(check)`.
3. Dans `project.godot` et `export_presets.cfg` : retirer `addons/kit_ui/locale/en.po` des traductions, pointer `gui/theme/custom_font` sur la police du jeu, et mettre ses licences dans `include_filter`.
4. `mise run check` puis `mise run mouse-check`.

Les nouveaux menus gardent `Prefs` (options, touches, `px()`, `key_label()`), `MenuInput`, `Loc` et `KitSim`.

## Les règles qu'ils tiennent

- Sans fenêtre, aucun événement souris n'atteint un `Control` : les tests émettent les signaux `pointed` et `clicked` de `MenuRow`, et `mise run mouse-check` clique pour de vrai sous Xvfb.
- Changer de sélection ne déplace rien à l'écran, et le texte sélectionné ne clignote pas.
- Une marque se dessine (`UiDraw.chevron`, `UiDraw.keycap`), elle ne se tape pas : aucune des deux polices n'a ■, ▼, ‹ ou ›.
