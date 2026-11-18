# Journal des changements

Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Numéros de version : [SemVer](https://semver.org/lang/fr/). Le numéro vit dans `project.godot` (`config/version`) ; le workflow `release` publie la version qui y est écrite, avec l'entrée de ce fichier pour notes.

## 0.1.0 — à venir

### Ajouté

- Le point de départ : écran titre, options, pause, deux démos.
- Configuration stricte pour l'agent : tous les avertissements GDScript en erreurs, le kit compris ; `gdlintrc` (fichiers de 500 lignes au plus, 8 arguments) ; hook `Stop` qui compile en plus du lint ; permissions Claude Code durcies (secrets, push forcé, garde-fous sous confirmation) ; Dependabot pour les actions ; `.editorconfig`.

- Les menus du kit sont à part, dans `addons/kit_ui`, et facultatifs : un jeu peut les supprimer et écrire les siens. Le kit ne les nomme plus (`test_core_alone.gd`) ; la config du jeu lui donne les licences des polices (`LICENCES`), ses contrôles d'export (`self_test()`) et ses clics (`mouse_check()`). `mise run kit-core-check` fait tourner le kit sur un jeu sans eux, en CI aussi. `mise run kit-update` ne tire `kit_ui` que dans un jeu qui l'a, et fait passer un jeu à l'ancienne disposition.

### Corrigé

- Le kit échappait aux avertissements de typage (tout `res://addons` était exclu) : une soixantaine de transtypages et d'arguments `Variant` non vérifiés, de variables qui en masquaient d'autres et de divisions entières, maintenant typés et nommés.
