# Projet Godot

Un jeu Godot 4.7 en GDScript, parti du template `godot-template`. Le kit (`addons/kit/`, voir son README) apporte les options, la traduction, les entrées clavier, manette et souris, et les outils qui vérifient tout cela ; ses menus en liste et leur style sont à part, dans `addons/kit_ui/`, que le jeu garde ou remplace par les siens. Le jeu apporte tout le reste.

## Commandes

- Vérification complète : `mise run check` (lint, compilation de chaque fichier avec les autoloads, tests GdUnit4 du jeu et du kit, lancement de chaque scène). **Un changement de code est terminé quand elle passe.** Un seul fichier de tests : `tools/gdunit.sh res://tests/test_x.gd`. Le hook `Stop` lance `mise run lint` et `mise run validate` quand un fichier du jeu a changé (`.claude/hooks/check-before-stop.sh`) ; `check` entier passe par la CI.
- Export : `mise run export` (Linux, Windows, web) puis `mise run export-smoke` (l'auto-test de l'exécutable Linux : traductions, polices, chaque scène, `SELFTEST OK`). `mise run web-smoke` charge la version web dans Chromium ; lire `build/web_smoke.png`. Sous le sandbox local, Godot ne peut pas écrire dans `/tmp` et produit un binaire cassé : l'export local se lance hors sandbox.
- `mise run mouse-check` : de vrais clics, sous Xvfb, dans les menus que `mouse_check()` de `kit_config.gd` désigne. `mise run kit-core-check` : le kit sur un jeu sans `addons/kit_ui` (`tools/kit_core_fixture`). `mise run shots` : captures de l'écran titre, des options, d'une démo et de sa pause dans `build/shots`.
- Mettre le jeu à jour depuis le template : `mise run template-update` (Copier ; `copier.yml` dit ce qui est au jeu et n'est jamais touché). Un jeu sans `.copier-answers.yml` passe par `mise run kit-update`. `mise run copier-check` prouve le tout sur le template.
- Publier : une entrée `## x.y.z` dans `CHANGELOG.md`, `config/version` dans `project.godot`, puis le workflow `release` (tag `vx.y.z`, ou lancement manuel depuis `main` avec « publish ») : Release GitHub et version web sur Pages.
- L'éditeur tourne sous Windows : l'utilisateur le lance depuis WSL avec `mise run editor`, hors du sandbox, et c'est lui que godot-ai pilote. S'il n'est pas ouvert, le lui demander. Dans une session cloud, pas d'éditeur : vérifier par `mise run shots` sous Xvfb et lire les images.
- Un changement visible se vérifie dans le jeu lancé avec `/verify`, ou sur capture : lire l'image avant de dire que c'est bon.

## Conventions

- La logique de jeu est en fonctions pures dans `src/`, testée par GdUnit4 ; les scripts de nœuds restent minces et appellent `src/`.
- Les entrées passent par les actions de `project.godot` (`move_*`, `interact`, `pause`), par position physique des touches, plutôt que par les `ui_*` ou des touches en dur. Les événements de manette sont liés avec `device = -1`.
- Ce que le kit doit savoir du jeu est dans `kit_config.gd` : les actions que le joueur peut changer, la légende, les licences des polices, le skin, les contrôles de l'auto-test et les clics du mouse-check.
- Tout texte montré au joueur s'écrit en français et passe par `Loc.t("…")` ; son anglais s'ajoute dans `locale/en.po` (`msgid` = le français, à l'identique). `test_locale.gd` du kit échoue s'il manque. Une taille de texte passe par `Prefs.px(taille)` (`Prefs.px(UiStyle.JETON)` avec les menus du kit), un nom de touche par `Prefs.key_label(action)` : jamais « Espace » écrit en dur.
- Chaque menu du jeu tient `MenuContract` et figure dans `menus()` de `kit_config.gd` : `test_menu_contract.gd` le parcourt au clavier, à la manette et au stick, vérifie taille, contraste et traductions, et `mouse-check` y clique. Les menus lisent leurs événements par `MenuInput` (`fresh` une fois par événement, puis `pressed` / `accepts`). Une correction de menu ou d'entrée se teste avec de vrais événements (`KitSim.key`, `pad`, `stick`, `send`, `tap`).
- Un test ne lit ni n'écrit les fichiers du joueur (`Prefs.persist` est coupé pendant un test) et libère ce qu'il ajoute à l'arbre : une exécution finit avec `0 orphans`.
- Un bug corrigé arrive avec un test qui échoue sans la correction.
- Le kit et ses menus ne se modifient pas dans un jeu : la correction se fait dans le template, puis les jeux la récupèrent (`mise run kit-update`, `addons/kit/README.md`). Le kit ne nomme jamais ses menus (`test_core_alone.gd`).
- Le rendu Compatibility est choisi parce que Vulkan n'a pas de pilote matériel sous WSL2. Un jeu 3D qui veut l'éclairage avancé passe à Forward+ et se teste sous Windows.
- Code, commentaires et commits en anglais, au format `type: résumé` ; textes du jeu et documentation en français.

## Pièges déjà rencontrés

- `godot --check-only --script fichier.gd` signale de fausses erreurs dès qu'un script utilise un autoload (`Prefs`). `tools/validate.gd` compile avec les autoloads chargés : c'est lui que lancent `mise run validate` et le hook d'édition.
- Un `class_name` nouveau ou renommé reste inconnu tant que `godot --headless --import` n'a pas tourné (`mise run import`).
- Tous les avertissements GDScript sont des erreurs (`project.godot`, section `debug`), le kit compris (`directory_rules` n'exclut que les addons tiers) ; seul `return_value_discarded` reste coupé, car les assertions GdUnit4 rendent une valeur à chaque appel. Un transtypage depuis un `Variant` (`x.get("a") as Foo`) ne compile pas : typer la variable (`var a: Foo = x.get("a")`). Un argument `Variant` passé à une fonction typée non plus : `str(x)` ou une variable typée. `round()` et `floor()` rendent un `Variant` : `roundi()`, `floori()`. Une division entière voulue s'écrit `floori(a / 2.0)`. Une coroutine lancée sans `await` exprès porte `@warning_ignore("missing_await")` et un commentaire.
- `.claude/settings.json` demande confirmation avant toute modification des garde-fous (`.claude/`, `.mcp.json`, `tools/claude/`, `gdlintrc`, `mise.toml`, `.github/`) et avant un `git push` ; il refuse le push forcé, `git reset --hard`, `git clean` et la lecture des secrets (`.env`, `.godot/export_credentials.cfg`, keystores). Ces refus valent pour les outils de Claude Code, pas pour un script lancé par Bash : le vrai rempart reste le sandbox.
- Sans fenêtre, Godot dort 6,9 ms à chaque image (`low_processor_usage_mode_sleep_usec`) et aucun événement souris n'atteint un `Control`.
- Sans `internationalization/locale/fallback="fr"`, un jeu réglé sur le français afficherait la traduction anglaise.
- `get_translation_object(langue)` ne rend qu'un des fichiers d'une langue (le kit en a un, le jeu un autre) : passer par `Loc.messages(langue)`, qui les lit tous.
- Un export n'embarque que des ressources : un `.txt` ou un `.json` lu à l'exécution s'ajoute à `include_filter` (`export_presets.cfg`). L'auto-test de l'exécutable le vérifie.
- `set_anchors_preset()` appelé dans `_ready` ne déplace pas un Control déjà dans l'arbre : utiliser `set_anchors_and_offsets_preset()`.
- Xvfb met environ 3 s à accepter une fenêtre ; sans carte graphique, le jeu y tourne à quelques images par seconde.
- `build/` et `docs/` portent un `.gdignore`, sinon Godot importe les exports et les captures, et les embarque.
