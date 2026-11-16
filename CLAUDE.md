# Projet Godot

Un jeu Godot 4.7 en GDScript, parti du template `godot-template`. Le kit (`addons/kit/`, voir son README) apporte les options, la traduction, les entrées clavier, manette et souris, les menus en liste et leur style ; le jeu apporte tout le reste.

## Commandes

- Vérification complète : `mise run check` (lint, compilation de chaque fichier avec les autoloads, tests GdUnit4 du jeu et du kit, lancement de chaque scène). **Un changement de code est terminé quand elle passe.** Un seul fichier de tests : `tools/gdunit.sh res://tests/test_x.gd`. Le hook `Stop` lance `mise run lint`, `check` passe par la CI.
- Export : `mise run export` (Linux, Windows, web) puis `mise run export-smoke` (l'auto-test de l'exécutable Linux : traductions, polices, chaque scène, `SELFTEST OK`). `mise run web-smoke` charge la version web dans Chromium ; lire `build/web_smoke.png`. Sous le sandbox local, Godot ne peut pas écrire dans `/tmp` et produit un binaire cassé : l'export local se lance hors sandbox.
- `mise run mouse-check` : de vrais clics dans les menus, sous Xvfb. `mise run shots` : captures de l'écran titre, des options, d'une démo et de sa pause dans `build/shots`.
- Publier : une entrée `## x.y.z` dans `CHANGELOG.md`, `config/version` dans `project.godot`, puis le workflow `release` (tag `vx.y.z`, ou lancement manuel depuis `main` avec « publish ») : Release GitHub et version web sur Pages.
- L'éditeur tourne sous Windows : l'utilisateur le lance depuis WSL avec `mise run editor`, hors du sandbox, et c'est lui que godot-ai pilote. S'il n'est pas ouvert, le lui demander. Dans une session cloud, pas d'éditeur : vérifier par `mise run shots` sous Xvfb et lire les images.
- Un changement visible se vérifie dans le jeu lancé avec `/verify`, ou sur capture : lire l'image avant de dire que c'est bon.

## Conventions

- La logique de jeu est en fonctions pures dans `src/`, testée par GdUnit4 ; les scripts de nœuds restent minces et appellent `src/`.
- Les entrées passent par les actions de `project.godot` (`move_*`, `interact`, `pause`), par position physique des touches, plutôt que par les `ui_*` ou des touches en dur. Les événements de manette sont liés avec `device = -1`.
- Ce que le kit doit savoir du jeu est dans `kit_config.gd` : les actions que le joueur peut changer, la légende, le skin (l'apparence des menus) et des contrôles propres à l'auto-test.
- Tout texte montré au joueur s'écrit en français et passe par `Loc.t("…")` ; son anglais s'ajoute dans `locale/en.po` (`msgid` = le français, à l'identique). `test_locale.gd` du kit échoue s'il manque. Une taille de texte passe par `Prefs.px(UiStyle.JETON)`, un nom de touche par `Prefs.key_label(action)` : jamais « Espace » écrit en dur.
- Les menus lisent leurs événements par `MenuInput` (`fresh` une fois par événement, puis `pressed` / `accepts`). Une correction de menu ou d'entrée se teste avec de vrais événements (`KitSim.key`, `pad`, `stick`, `send`, `tap`).
- Un test ne lit ni n'écrit les fichiers du joueur (`Prefs.persist` est coupé pendant un test) et libère ce qu'il ajoute à l'arbre : une exécution finit avec `0 orphans`.
- Un bug corrigé arrive avec un test qui échoue sans la correction.
- Le kit ne se modifie pas dans un jeu : la correction se fait dans le template, puis les jeux la récupèrent (`addons/kit/README.md`).
- Le rendu Compatibility est choisi parce que Vulkan n'a pas de pilote matériel sous WSL2. Un jeu 3D qui veut l'éclairage avancé passe à Forward+ et se teste sous Windows.
- Code, commentaires et commits en anglais, au format `type: résumé` ; textes du jeu et documentation en français.

## Pièges déjà rencontrés

- `godot --check-only --script fichier.gd` signale de fausses erreurs dès qu'un script utilise un autoload (`Prefs`). `tools/validate.gd` compile avec les autoloads chargés : c'est lui que lancent `mise run validate` et le hook d'édition.
- Un `class_name` nouveau ou renommé reste inconnu tant que `godot --headless --import` n'a pas tourné (`mise run import`).
- Les avertissements de typage sont des erreurs (`project.godot`, section `debug`) : un transtypage depuis un `Variant` (`x.get("a") as Foo`) ne compile pas ; typer la variable (`var a: Foo = x.get("a")`).
- Sans fenêtre, Godot dort 6,9 ms à chaque image (`low_processor_usage_mode_sleep_usec`) et aucun événement souris n'atteint un `Control`.
- Sans `internationalization/locale/fallback="fr"`, un jeu réglé sur le français afficherait la traduction anglaise.
- `get_translation_object(langue)` ne rend qu'un des fichiers d'une langue : lire tous ceux de `internationalization/locale/translations`.
- Un export n'embarque que des ressources : un `.txt` ou un `.json` lu à l'exécution s'ajoute à `include_filter` (`export_presets.cfg`). L'auto-test de l'exécutable le vérifie.
- `set_anchors_preset()` appelé dans `_ready` ne déplace pas un Control déjà dans l'arbre : utiliser `set_anchors_and_offsets_preset()`.
- Xvfb met environ 3 s à accepter une fenêtre ; sans carte graphique, le jeu y tourne à quelques images par seconde.
- `build/` et `docs/` portent un `.gdignore`, sinon Godot importe les exports et les captures, et les embarque.
