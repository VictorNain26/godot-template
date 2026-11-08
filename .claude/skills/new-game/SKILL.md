---
name: new-game
description: Partir de ce template pour un nouveau jeu - renommer le projet, installer les outils, garder une seule démo.
disable-model-invocation: true
---

# Nouveau jeu

1. Cloner ce dépôt, changer `config/name` dans `project.godot`.
2. Lancer `mise install` et `git lfs install`.
3. Garder la démo `*_2d` ou `*_3d` (scène, script, test) et supprimer l'autre.
4. Remplacer `src/player_motion.gd` et son test par les règles du jeu.
