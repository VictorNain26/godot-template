# Projet Godot

- Vérification : `mise run check` (son contenu est dans `mise.toml`). Le hook `Stop` et la CI la lancent ; le hook `PostToolUse` vérifie chaque `.gd` écrit (`tools/claude/post_edit_gd.sh`).
- La logique de jeu est en fonctions pures dans `src/`, testée par GUT dans `tests/` ; les scripts de nœuds restent minces et appellent `src/`.
- Les entrées passent par les actions `move_*` de `project.godot`, pas par les `ui_*` ni des touches en dur.
- L'éditeur est lancé par l'utilisateur, hors du sandbox : c'est lui que godot-ai pilote (scènes, lancement du jeu, entrées, captures). S'il n'est pas ouvert, demande-le au lieu de le lancer.
- godot-ai s'enregistre une fois par machine : dans l'éditeur, dock Godot AI > Claude Code > Configure (portée `user`), puis redémarrer la session Claude Code. Si ses outils manquent dans la session, demande-le.
- Le rendu Compatibility (`rendering_method` dans `project.godot`) est choisi parce que Vulkan n'a pas de pilote matériel sous WSL2. Un jeu 3D qui veut l'éclairage avancé passe à Forward+ et se teste sous Windows.
- Nouveau jeu : cloner ce dépôt, changer `config/name` dans `project.godot`, lancer `mise install` et `git lfs install`, puis garder la démo `*_2d` ou `*_3d` (scène, script, test) et supprimer l'autre ; `src/player_motion.gd` et son test sont à remplacer par les règles du jeu.
