# Projet Godot

- Vérification : `mise run test` (définie dans `mise.toml`). Le hook `Stop` de `.claude/settings.json` la lance et bloque si elle échoue.
- La logique de jeu est en fonctions pures dans `src/`, testée par GUT dans `tests/` ; les scripts de nœuds restent minces et appellent `src/`.
- L'éditeur est lancé par l'utilisateur, hors du sandbox : c'est lui que godot-ai pilote (scènes, lancement du jeu, entrées, captures). S'il n'est pas ouvert, demande-le au lieu de le lancer.
- godot-ai s'enregistre une fois par machine : dans l'éditeur, dock Godot AI > Claude Code > Configure (portée `user`), puis redémarrer la session Claude Code. Si ses outils manquent dans la session, demande-le.
- Nouveau jeu : cloner ce dépôt, changer `config/name` dans `project.godot`, remplacer la démo (`src/player_motion.gd`, `scenes/main.tscn`, `scenes/player.gd` et leurs tests).
