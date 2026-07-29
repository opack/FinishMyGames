# Finish My Games

Extension [Playnite](https://playnite.link/) (script PowerShell) qui organise une ludothèque pour aider à **« finir » ses jeux** — non pas les terminer à 100 %, mais y trouver ce qu'on cherchait puis passer à autre chose sans regret.
Conçu comme un système anti-paralysie : limiter le WIP, clore explicitement, réduire chaque décision à un preset.

## Le principe

Le vrai problème n'est pas de choisir un jeu, c'est d'en avoir trop d'« ouverts » à la fois. Deux leviers :

- une **étagère active plafonnée** — on ne joue qu'à _N_ jeux en même temps ;
- un **« fini » explicite** qui ferme la boucle, avec une voie **Evergreen** à part pour les jeux qu'on garde indéfiniment sous la main sans jamais viser une fin (roguelites, jeux de score, etc.).

Autour : des **Humeurs**, des **Catégories** fines et des **durées de session** en Categories Playnite, et des **presets de filtres** qui réduisent chaque décision à un clic.

## Comment ça marche dans Playnite

Tout s'appuie sur les champs natifs de Playnite. Un seul champ, **Categories**, porte plusieurs systèmes différents à la fois, distingués uniquement par leur préfixe emoji :

| Préfixe | Système               | Géré par                                                                            | Notes                                                                                                            |
| ------- | --------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 🕹️      | Catégorie (fine)      | Défini **à la main** à partir des valeurs de la page Notion « Système de notation » | ~53 valeurs (Metroidvania, Souls-like, RPG, MOBA, Party...), plusieurs possibles par jeu.                        |
| 🎭      | Humeur (large)        | l'add-on **Metadata Utilities** (Conditional Actions)                               | Action/Aventure/Gestion/Réflexion/Détente/Simulation sont auto-déduites de la Catégorie 🕹️ ; Léger reste manuel. |
| ⏳      | Durée de session      | Défini **à la main**                                                                | Court / Moyen / Long, pas de source fiable pour l'automatiser.                                                   |
| 🚧      | Marqueurs « Sans... » | **ce script** (menu) ou l'add-on **Metadata Utilities** (Conditional actions)       | `Sans catégorie` / `Sans session` / `Sans humeur` — posés automatiquement pour repérer les trous.                |

Le reste :

- **Completion Status** — les colonnes Kanban : `🚧 Non débuté` / `🚧 Backlog` / `🚧 En pause` / `🎮 Sur l'étagère` (plafonnée) / `🎮 Evergreen` / `✅ Abandonné` / `✅ Classé` / `✅ Terminé`.
- **Filter presets** — le « menu de décision » : selon le temps et l'humeur, un preset montre les jeux de l'étagère (ou de l'Evergreen) qui collent au moment.

## Ajouter une nouvelle Catégorie (🕹️)

Quand on crée une nouvelle valeur de Catégorie fine (ex. Party, MOBA), la mécanique d'auto-déduction de l'Humeur (🎭) ne se met pas à jour toute seule : c'est un système externe, pas ce script. Checklist à suivre à chaque fois :

1. **Ajouter la catégorie dans Notion** — page « Système de notation », table Catégorie, avec sa Description et ses Mots-clé.
2. **Mettre à jour l'add-on Metadata Utilities** (menu Playnite > Add-ons... > Extension Settings > Generic > Metadata Utilities > Conditional actions) puis ajouter/ajuster les règles :
   - `+cat. 🎭 X`, `-cat. 🎭 X`
   - `+cat. 🚧 Sans catégorie`, `-cat. 🚧 Sans catégorie`.

   > En cas d'oubli : des jeux avec cette nouvelle Catégorie se retrouvent marqués `🚧 Sans humeur` après un passage du menu « Marquer les jeux non catégorisés » ou par l'add-on Metadata Utilities

3. Rien à faire côté `FinishMyGames.psm1` : les menus « Marquer les jeux non catégorisés » (`Invoke-TagMissingAxes`) et « Configuration » (`Invoke-CreateStructure`, pour les marqueurs) fonctionnent par préfixe emoji, pas par liste de noms — une nouvelle Catégorie 🕹️ est automatiquement couverte par les deux dès sa création.

## Configuration

### `Get-Cfg`

Tous les noms (statuts, catégories et la Feature `Démo`) sont centralisés dans la fonction **`Get-Cfg`** en haut du `.psm1`, y compris les 3 catégories marqueurs `Missing*`. **C'est le seul endroit à éditer** si on renomme un statut, une catégorie ou la Feature `Démo` dans Playnite — les fonctions qui les utilisent (`Invoke-CreateStructure`, `Invoke-TagMissingAxes`) lisent toutes cette même source, donc un renommage ne se fait qu'une fois. Les statuts sont en ASCII (éditables sans risque) ; les catégories contiennent des emojis (préserver le BOM).
Les presets sont également définis dans cette section.
Cette modification nécessite le redémarrage de Playnite.

## Installation

1. Créer un répertoire `%AppData%\Playnite\Extensions\FinishMyGames`
2. Y copier les fichiers `extension.yaml` et `FinishMyGames.psm1`
   > ⚠️ `FinishMyGames.psm1` est en **UTF-8 avec BOM**. Ne pas le ré-enregistrer dans un éditeur qui retire le BOM : PowerShell lirait mal le fichier et les emojis casseraient le chargement de l'extension.
3. Redémarrer Playnite
4. Pour l'action « Suggérer une catégorie (Claude) » : copier `skills/playnite-categorize/SKILL.md` vers `%USERPROFILE%\.claude\skills\playnite-categorize\SKILL.md`.

## Utilisation

### Mise en route

(Note: les entrées de menu globales sont accessibles via \*\*Extensions > Finish My Games)

1. Renommer les Completion Status de Playnite selon le schéma Kanban (cf. `Get-Cfg`), et les réordonner `À jouer` → `En cours` → `Joué`.
2. Menu **Configuration** : crée d'un coup le statut Evergreen, les Catégories Humeur/Session, les 3 marqueurs `Sans...`, et les filter presets.
3. Menu **Taille de l'étagère** pour changer la taille de l'étagère (4 par défaut).
4. Menu **Marquer les jeux non catégorisés** : à faire de temps en temps, pour repérer les trous à combler (voir section suivante).

### Actions du menu principal

| Action                           | Rôle                                                                                                                                                                                                                                                                                                            |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Configuration                    | Crée le statut `🎮 Evergreen`, les Catégories Humeur/Session, les 3 marqueurs `Sans...`, et les filter presets. Idempotent — se relance sans risque, y compris après l'ajout d'une nouvelle Catégorie 🕹️.                                                                                                       |
| Taille de l'étagère              | Change la taille de l'étagère.                                                                                                                                                                                                                                                                                  |
| Statistiques                     | Nombre de jeux sur l'étagère / places disponibles (avec la liste), nombre de jeux Evergreen, taille du backlog (`Backlog` + `En pause` combinés).                                                                                                                                                               |
| Marquer les jeux non catégorisés | Marque chaque jeu auquel il manque une Catégorie 🕹️, une Session ⏳ et/ou une Humeur 🎭 avec le marqueur correspondant (`🚧 Sans...`), en une seule passe. Exclut les jeux portant la Feature Playnite `Démo` et ceux marqués Hidden dans Playnite (transitoires, pas la peine de les catégoriser). Idempotent. |

### Workflow (clic droit sur un jeu)

- **Mettre sur l'étagère** — passe le jeu en `🎮 Sur l'étagère`, en **refusant si l'étagère est pleine**.
- **Suggérer une catégorie (Claude)** — appelle Claude Code (CLI, doit être installé et connecté à un compte Claude) avec la skill `playnite-categorize` pour proposer une ou plusieurs Catégories 🕹️ à partir des tags/description Steam déjà connus de Playnite, avec le raisonnement. Propose ensuite d'Ajouter, de Remplacer (les Catégories 🕹️ existantes du jeu, en laissant Humeur/Session intactes), ou de Ne rien faire. Si une catégorie suggérée n'existe pas encore dans Playnite, elle est créée à la volée mais clairement signalée — à ajouter aussi dans la référence Notion (voir « Ajouter une nouvelle Catégorie » ci-dessus).

Tout le reste (finir, abandonner, mettre en pause, passer en Evergreen…) n'est qu'un changement de Completion Status : à faire directement via Playnite (menu contextuel ou fiche du jeu).

## Fichiers

- `extension.yaml` — manifeste Playnite.
- `FinishMyGames.psm1` — le script (UTF-8 **BOM**, ne pas retirer le BOM).
- `config.txt` — taille d'étagère (généré à l'usage, ignoré par git).
- `skills/playnite-categorize/SKILL.md` — la skill Claude Code utilisée par « Suggérer une catégorie (Claude) », versionnée ici pour pouvoir la réinstaller si besoin (voir Installation).

---
