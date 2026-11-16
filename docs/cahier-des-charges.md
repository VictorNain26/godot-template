# Cahier des charges

Où en est le jeu, métier par métier. Un état y change dans le même commit que le code qui le justifie. « Humain » : ce qu'aucune machine sans écran, sans manette et sans oreilles ne peut juger.

| Exigence | État |
| --- | --- |
| Boucle de jeu jouable de bout en bout | À faire |
| Écran titre, options, pause | Fait : kit |
| Texte en français et en anglais | Fait pour le kit ; à tenir pour le jeu (`test_locale.gd`) |
| Clavier, manette, souris dans les menus | Fait : kit, testé par de vrais événements |
| Interface lisible (tailles, contraste) | Fait : tenu par `test_skin.gd` pour tout skin |
| Export Linux, Windows, web avec auto-test | Fait : `mise run export`, `export-smoke` |
| Publication (Release, Pages) | Fait : workflow `release` |
| Fluidité sur une vraie carte graphique | **Humain** |
| Son, ressenti, équilibrage | **Humain** |
