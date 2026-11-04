# Projet Godot

- Vérification : `mise run check` (son contenu est dans `mise.toml`). Le hook `Stop` et la CI la lancent ; le hook `PostToolUse` vérifie chaque `.gd` écrit (`tools/claude/post_edit_gd.sh`).
- La logique de jeu est en fonctions pures dans `src/`, testée par GUT dans `tests/` ; les scripts de nœuds restent minces et appellent `src/`.
- Les entrées passent par les actions `move_*` de `project.godot`, pas par les `ui_*` ni des touches en dur.
- L'éditeur est lancé par l'utilisateur, hors du sandbox : c'est lui que godot-ai pilote (scènes, lancement du jeu, entrées, captures). S'il n'est pas ouvert, demande-le au lieu de le lancer.
- godot-ai est déclaré dans `.mcp.json`, écrit par le dock Godot AI > Claude Code > Configure en portée `project` (éditeur lancé depuis la racine du dépôt) et approuvé dans `.claude/settings.json`. `tests/test_mcp_pin.gd` échoue si ce fichier ne suit plus la version de `addons/godot_ai` : refaire Configure après chaque mise à jour de l'addon, puis redémarrer la session. Si ses outils manquent dans la session, demande-le.
- Un changement visible se vérifie dans le jeu lancé avec `/verify` (`.claude/skills/verify/SKILL.md`).
- Export : `mise run export` puis `mise run export-smoke` (presets dans `export_presets.cfg`) ; la CI les lance hors PR et publie les binaires. Sous le sandbox, Godot ne peut pas écrire dans `/tmp` et produit un binaire cassé : l'export local se lance hors sandbox.
- Le rendu Compatibility (`rendering_method` dans `project.godot`) est choisi parce que Vulkan n'a pas de pilote matériel sous WSL2. Un jeu 3D qui veut l'éclairage avancé passe à Forward+ et se teste sous Windows.
- Sous WSLg, le serveur PulseAudio répond par des timeouts (`PulseAudio: sink info error: Timeout` dans le log du jeu) qui figent le jeu plusieurs secondes. Chaque machine WSL a donc à la racine un `override.cfg` ignoré par git, qui fixe `audio/driver/driver="Dummy"` dans la section `[audio]` ; le son se vérifie dans le build Windows.
- Nouveau jeu : cloner ce dépôt, changer `config/name` dans `project.godot`, lancer `mise install` et `git lfs install`, puis garder la démo `*_2d` ou `*_3d` (scène, script, test) et supprimer l'autre ; `src/player_motion.gd` et son test sont à remplacer par les règles du jeu.
