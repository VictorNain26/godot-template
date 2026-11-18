# Le kit

Ce que tout jeu fait sur ce template partage, quel que soit son genre : les options et leur fichier, la traduction, les entrées clavier, manette et souris, et les outils qui vérifient tout cela (auto-test de l'exécutable, vrais clics sous Xvfb). Il est né de Cairnlight et d'Emberwake, qui l'utilisent.

Le kit n'impose **aucune interface**. Ses menus (options, pause, avec leur style) vivent à part, dans `addons/kit_ui` (voir son README) : un jeu les garde, les habille par un skin, ou supprime le dossier et écrit les siens. Le kit ne nomme aucune classe ni aucun fichier de `kit_ui` : `test_core_alone.gd` le vérifie, et `mise run kit-core-check` fait tourner le kit sur un jeu qui a son propre menu et pas de `kit_ui`.

## Ce qu'il contient

| Dossier | Contenu |
| --- | --- |
| `core/` | `Settings` (les options en données), `Loc` (la traduction, l'espace insécable du français), `MenuInput` (ce que veut dire une touche, un bouton ou un stick dans un menu), `KitConfig` (trouve la config du jeu) |
| `prefs/prefs.gd` | L'autoload `Prefs` : applique les options, les garde dans `user://settings.json` à part de la progression, nomme les touches comme le clavier du joueur les imprime et les boutons de la manette quand il s'en sert |
| `dev/` | `self_test.gd` (l'auto-test d'un exécutable exporté), `mouse_check.tscn` (`MouseCheck` : de vrais clics sous Xvfb sur les menus que la config du jeu désigne) |
| `tests/` | Les tests du kit (GdUnit4) et `KitSim`, qui envoie de vraies touches, de vrais boutons et un vrai pointeur |

## Brancher un jeu

1. `project.godot` :
   - autoload `Prefs="*res://addons/kit/prefs/prefs.gd"` ;
   - `internationalization/locale/translations` : le fichier du jeu (et `res://addons/kit_ui/locale/en.po` si le jeu garde les menus du kit) ; `locale/fallback="fr"` (sinon un joueur français lit l'anglais) ;
   - `gui/theme/custom_font` : la police de lecture du jeu ;
   - les actions `pause` et `interact`, et `kit/config` si la config n'est pas `res://kit_config.gd`.
2. `kit_config.gd`, à la racine :
   - `ACTIONS` (les actions que le joueur peut changer, avec leur nom dans le menu), `FIXED_ACTIONS`, `HELP` (la légende des écrans titre et pause) ;
   - `LICENCES` : les fichiers de licence des polices du jeu, que l'auto-test cherche dans l'exécutable ;
   - `static func menus() -> Array[Callable]` : chaque menu du jeu, construit par un appel. Chacun tient le contrat `MenuContract` (voir plus bas) ;
   - `static func mouse_check(check: MouseCheck)` : les clics de `mise run mouse-check`. `await check.menus()` pointe et clique chaque élément de chaque menu ; le jeu y ajoute ses propres vérifications (`check.move`, `check.click`, `check.frames`, `check.expect`). Sans elle, `mise run mouse-check` échoue : des menus que personne ne clique passeraient sinon ;
   - au besoin `static func skin()` (l'allure du jeu, réglée avant tout écran), `static func self_test()` (des contrôles de plus pour l'auto-test ; elle peut attendre des images avec `await`, le temps de construire un niveau) ou `SELF_TEST` (le chemin d'un auto-test propre au jeu, lancé à la place de celui du kit).
3. Les exports incluent les licences des polices (`include_filter`, ce ne sont pas des ressources) et excluent `addons/kit/tests/*`, `addons/kit_ui/tests/*` et `addons/kit/dev/mouse_check.*`.
4. `mise run test` lance les tests du jeu, ceux du kit et ceux de `kit_ui` s'il est là.

## Les règles que le kit tient

- Une touche simulée marche sans fenêtre si l'événement porte `keycode` et `physical_keycode` et qu'on appelle ensuite `Input.flush_buffered_events()` : c'est ce que fait `KitSim.send`.
- Sans fenêtre, aucun événement souris n'atteint un `Control` : `mise run mouse-check` clique pour de vrai sous Xvfb, sur ce que `mouse_check()` de la config désigne.
- Le display server `headless` et le web ne connaissent pas la disposition du clavier : `Prefs._printed` garde alors le nom de la position.
- Un test ne lit ni n'écrit les fichiers du joueur : `Prefs.persist` est coupé pendant un test, avec ou sans fenêtre.
- Le kit ne nomme pas ses menus (`test_core_alone.gd`) et tourne sans eux (`mise run kit-core-check`, aussi en CI).

## Le contrat des menus

Quel que soit son dessin (menus du kit, boutons du moteur, menu circulaire, interface dans le décor), chaque menu listé par `menus()` offre `MenuContract` : le signal `menu_chosen(index)`, `menu_dry_run` (un choix n'émet que le signal, pour qu'un test puisse choisir « Quitter » sans quitter), `menu_open()`, `menu_rects()` (chaque élément à l'écran, dans l'ordre de haut en bas), `menu_index()`, `menu_texts()` (les textes tels qu'écrits, en français) et `menu_text_style()` (taille du texte à 100 % et paires de couleurs texte / fond, telles qu'à l'écran). Le détail est en tête de `core/menu_contract.gd`.

`tests/test_menu_contract.gd` vérifie alors chaque menu avec de vrais événements :
- les flèches, les touches de déplacement du jeu, la croix et le stick de la manette avancent d'un élément (au bout, la sélection revient au début ou reste) ;
- Entrée et le bouton A choisissent l'élément sélectionné ;
- chaque élément est entièrement à l'écran, fait au moins 24 × 24 px (WCAG 2.2, 2.5.8) et ne chevauche pas les autres ;
- chaque texte a son anglais, mesure au moins 19 px à 100 % et contraste à 4,5:1 au moins avec ce qu'il recouvre (WCAG 2.2, 1.4.3).

Sous Xvfb, `check.menus()` vérifie que le pointeur sélectionne chaque élément et qu'un clic le choisit. `tools/kit_core_fixture` en est un exemple minimal, avec des `Button` du moteur.

La taille et les couleurs sont celles que le menu déclare : le test les vérifie, il ne les mesure pas à l'écran. Un menu qui déclare autre chose que ce qu'il dessine passe à tort ; une capture (`mise run shots`) reste à relire après un changement d'allure.

## Partager le kit entre les jeux

Le kit vit dans ce template, qui en est la source. Un jeu le garde à jour avec `git subtree` : le code est copié dans le jeu, si bien qu'une session qui n'a accès qu'au jeu le lit quand même. Le jeu extrait `addons/kit` (et `addons/kit_ui` s'il les garde) de la branche `main` du template au moment de la mise à jour : aucune branche de plus à entretenir.

```bash
mise run kit-update
```

La tâche ajoute le dépôt du template comme remote `template`, extrait chaque dossier de sa branche `main` (`git subtree split`) et le fusionne dans le jeu (`git subtree merge --squash`). `addons/kit_ui` n'est tiré que si le jeu l'a : un jeu qui l'a supprimé ne le retrouve pas. Un jeu à l'ancienne disposition (les menus dans `addons/kit/ui`) passe à `addons/kit_ui`, et la tâche affiche ce qu'il reste à changer dans `project.godot` et les exports. La première fois, un jeu créé avec « Use this template » tient le kit en fichiers ordinaires : la tâche les retire dans un commit puis les rajoute par `git subtree add`. L'arbre de travail doit être propre.

Une correction faite dans un jeu se reporte dans le template, puis les autres jeux la récupèrent : le kit ne se modifie pas dans un jeu sans revenir ici.
