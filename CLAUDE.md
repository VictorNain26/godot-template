# Projet Godot

- Vérification complète : `mise run check` (lint, tests GUT, smoke). Le hook `Stop` lance `mise run lint`, `check` passe par la CI.
- La logique de jeu est en fonctions pures dans `src/`, testée par GUT ; les scripts de nœuds restent minces et appellent `src/`.
- Les entrées passent par les actions `move_*` de `project.godot`, plutôt que par les `ui_*` ou des touches en dur.
- L'éditeur tourne sous Windows : l'utilisateur le lance depuis WSL avec `mise run editor`, hors du sandbox, et c'est lui que godot-ai pilote. S'il n'est pas ouvert, le lui demander.
- Un changement visible se vérifie dans le jeu lancé avec `/verify`.
- Export : `mise run export` puis `mise run export-smoke`. Sous le sandbox, Godot ne peut pas écrire dans `/tmp` et produit un binaire cassé : l'export local se lance hors sandbox.
- Le rendu Compatibility est choisi parce que Vulkan n'a pas de pilote matériel sous WSL2. Un jeu 3D qui veut l'éclairage avancé passe à Forward+ et se teste sous Windows.
