# Finish My Games

Extension [Playnite](https://playnite.link/) (script PowerShell) qui organise une ludothèque pour aider à **« finir » ses jeux** — non pas les terminer à 100 %, mais y trouver ce qu'on cherchait puis passer à autre chose sans regret.
Conçu comme un système anti-paralysie : limiter le WIP, clore explicitement, réduire chaque décision à un preset.

## Le principe

Le vrai problème n'est pas de choisir un jeu, c'est d'en avoir trop d'« ouverts » à la fois. Deux leviers :

- une **étagère active plafonnée** (WIP limit) — on ne joue qu'à _N_ jeux en même temps ;
- un **« fini » explicite** qui ferme la boucle et tue le regret.

Autour : un jeu **focus** (la priorité du moment), des **humeurs** et des **durées de session** en tags, une voie **fil rouge** pour les jeux sans fin, et des **presets de filtres** qui réduisent chaque décision à un clic.

## Comment ça marche dans Playnite

Tout s'appuie sur les champs natifs de Playnite :

- **Completion Status** — un board Kanban en trois colonnes : `To Play` / `Playing` / `Played`.
  - étagère active = `Playing (on shelf)` (plafonnée) ;
  - fil rouge = `Playing (fil rouge)` (hors plafond) ;
  - backlog = `To Play (plan to play)` + `To Play (on hold)`.
- **Tag `🎯 Focus`** — le jeu prioritaire, un seul à la fois.
- **Tags `Mood/…`** — l'humeur (Action, Adventure, Simple, Light).
- **Tags `Session/…`** — la durée minimale d'une session (Short, Medium, Long).
- **Filter presets** — le « menu de décision » : selon le temps et l'humeur, un preset montre les 0 à 2 jeux de l'étagère qui collent au moment.

## Configuration

### `Get-Cfg`

Tous les noms (statuts + tags) sont centralisés dans la fonction **`Get-Cfg`** en haut du `.psm1`. **C'est le seul endroit à éditer** si on renomme un statut ou un tag dans Playnite. Les statuts sont en ASCII (éditables sans risque) ; les tags contiennent des emojis (préserver le BOM).
Cette modification nécessite le redémarrage de Playnite.

### `session-map.txt`

Règles éditables **genre → durée de session**. Une ligne par bucket, premier match gagnant (ordonner du plus long au plus court). Éditer librement les genres ; garder le fichier en UTF-8. Relancer l'action 3 après modification.
Cette modification ne nécessite pas le redémarrage de Playnite car ce fichier est lu dynamiquement.

## Installation

1. Créer un répertoire `%AppData%\Playnite\Extensions\FinishMyGames`
2. Y copier les fichiers `extension.yaml`, `FinishMyGames.psm1` et `session-map.txt`
   > ⚠️ `FinishMyGames.psm1` est en **UTF-8 avec BOM**. Ne pas le ré-enregistrer dans un éditeur qui retire le BOM : PowerShell lirait mal le fichier et les emojis casseraient le chargement de l'extension.
3. Redémarrer Playnite

## Utilisation

### Mise en route

1. Renommer les Completion Status de Playnite selon le schéma Kanban (cf. `Get-Cfg`), et les réordonner `To Play` → `Playing` → `Played`.
2. Menu **Extensions → Finish My Games** :
   - `1) Create tags + 'Fil rouge' status`
   - `2) Create filter presets`
   - `3) Seed Session tags from genres` (brouillon d'après les genres)
3. Taguer les jeux en `Mood/…` à la main (c'est personnel).
4. `5) Set the shelf cap` pour changer la taille de l'étagère (4 par défaut).

### Actions du menu principal

| #   | Action               | Rôle                                                                                         |
| --- | -------------------- | -------------------------------------------------------------------------------------------- |
| 1   | Create tags + status | Crée les tags Mood/Session/Focus/Hype et le statut `Playing (fil rouge)`.                    |
| 2   | Create presets       | Focus, Hype, Evening, 30 min, 1h, Action, Adventure, Chill, Backlog, Fil rouge.              |
| 3   | Seed Session         | Pose un tag de durée d'après les genres, avec un marqueur `Session/__AUTO__` pour relecture. |
| 4   | Count shelf          | Compte les jeux `Playing (on shelf)` sur l'étagère.                                          |
| 5   | Set shelf cap        | Change la taille de l'étagère.                                                               |

### Workflow (clic droit sur un jeu)

Seules les deux actions qui font **plus** qu'un simple changement de statut :

- **Put on shelf** — passe le jeu en `Playing (on shelf)`, en **refusant si l'étagère est pleine**.
- **Set as Focus** — pose le tag `🎯 Focus` et le **retire du jeu focus précédent**.

Tout le reste (finir, abandonner, mettre en pause…) n'est qu'un changement de Completion Status : à faire directement via Playnite (menu contextuel ou fiche du jeu).

## Fichiers

- `extension.yaml` — manifeste Playnite.
- `FinishMyGames.psm1` — le script (UTF-8 **BOM**, ne pas retirer le BOM).
- `session-map.txt` — règles de session éditables.
- `config.txt` — taille d'étagère (généré à l'usage, ignoré par git).

---
