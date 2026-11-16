---
name: new-game
description: Partir de ce template pour un nouveau jeu - renommer le projet, installer les outils, garder une seule démo, écrire la vision, choisir l'apparence des menus.
disable-model-invocation: true
---

# Nouveau jeu

1. Changer `config/name` (et `config/description`) dans `project.godot`, et remettre `config/version` à `0.1.0`.
2. Lancer `mise install` et `git lfs install`.
3. Garder la démo `*_2d` ou `*_3d` (scène, script, test) et supprimer l'autre ; `START_SCENE` de `scenes/title.gd` pointe vers celle qu'on garde.
4. Remplacer `src/player_motion.gd` et son test par les règles du jeu.
5. Écrire `docs/vision.md` avec l'utilisateur avant de coder la suite.
6. Dans `kit_config.gd` : les actions du jeu (et leurs touches dans `project.godot`), la légende, et le skin si les menus doivent avoir une autre allure. Ajouter chaque nouveau texte à `locale/en.po`.
7. `mise run check`, puis `mise run shots` et lire les captures.
8. Dans GitHub : Settings > Pages > Source : GitHub Actions, une fois, pour que la publication mette la version web en ligne.
