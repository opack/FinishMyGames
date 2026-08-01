# ============================================================================
#  Finish My Games - Setup for Playnite
#
#  ALL names (statuses + categories + tags) live in Get-Cfg below. That is
#  the ONE place to edit if you rename a status/category/tag in Playnite
#  (or want other emojis).
#
#  This file is UTF-8 WITH BOM. Emojis/accents are fine as long as the BOM
#  stays. Do NOT re-save it in an editor that strips the BOM.
#  Idempotent and non-destructive. Make a Playnite backup before running.
# ============================================================================

function Get-Cfg {
    return @{
        # --- Completion statuses: MUST match your Playnite names EXACTLY.
        #     Colonnes Kanban : "À jouer" / "En cours" / "Joué".
        #     Rename a status in Playnite? Update the matching line here.
        Status = @{
            NotYet    = "🚧 Non débuté"    # tout neuf, pas encore trié
            Backlog   = "🚧 Backlog"       # intention d'y jouer
            Hold      = "🚧 En pause"      # en pause, toujours candidat
            Shelf     = "🎮 Sur l'étagère" # étagère active (plafond = cap)
            Evergreen = "🎮 Evergreen"     # toujours bon à jouer (créé par cette extension)
            Abandoned = "✅ Abandonné"     # n'y reviendra pas
            Closed    = "✅ Classé"          # j'ai eu ce que je voulais
            Beaten    = "✅ Terminé"       # 100% / boss de fin battu
        }
        # --- Categories: Humeur (🎭) + Session durations (⚡/⏳/🕰️).
        #     Multi-valued on a game, alongside your finer Catégorie/Type values
        #     (managed in Playnite/Notion, not by this script).
        #     Action/Aventure/Gestion/Reflexion/Detente/Simulation are populated
        #     automatically by your dynamic-rules addon from the fine Catégorie.
        #     Leger has no Notion Genre counterpart (yet?) so stays manual, same
        #     as Session, which has no reliable auto-source either way.
        #     Missing* are the "🚧 Sans ..." marker categories used by
        #     Invoke-TagMissingAxes ("Marquer les jeux non catégorisés") -
        #     named here too so both that function and the structure-creation
        #     step ("Configuration") stay in sync.
        Categories = @{
            Action     = "🎭 Action"
            Aventure   = "🎭 Aventure"
            Gestion    = "🎭 Gestion"
            Reflexion  = "🎭 Réflexion"
            Detente    = "🎭 Détente"
            Simulation = "🎭 Simulation"
            Leger      = "🎭 Léger"
            SShort     = "⏳ Court"
            SMedium    = "⏳ Moyen"
            SLong      = "⏳ Long"
            MissingCategorie = "🚧 Sans catégorie"
            MissingSession   = "🚧 Sans session"
            MissingHumeur    = "🚧 Sans humeur"
        }
        # --- Tags: nothing lives here right now - reserved for anything outside
        #     the Humeur/Session/Catégorie system, should you need it later.
        Tags = @{
        }
        # --- Features: native Playnite "Feature" field (distinct from Categories/Tags).
        #     Demo is set by Steam import (or by hand) on playtest/demo entries and is
        #     the reliable signal to exclude them from the missing-axis marking pass -
        #     unlike Categories, it isn't something this script or Notion manages.
        Features = @{
            Demo = "Démo"
        }
        # --- Filter presets: Name + which statuses/categories/tags to filter, by
        #     KEY from Status/Categories/Tags above. Add / remove / rename freely.
        #     Several values in one list = OR; several statuses = OR. Keys must
        #     exist in Status/Categories/Tags.
        #     Optional per preset: Group / Sort / SortDir to auto-group & sort the view.
        #       Group   = a GroupableField name (CompletionStatus, Genre, Platform, PlayTime, Source, Added...)
        #                 full list: https://api.playnite.link/docs/api/Playnite.SDK.Models.GroupableField.html
        #       Sort    = a SortOrder name (Playtime, Name, Added, LastActivity, CompletionStatus...)
        #                 full list: https://api.playnite.link/docs/api/Playnite.SDK.Models.SortOrder.html
        #       SortDir = "Ascending" or "Descending"
        #     (applied only when the preset is first created; delete an existing one to refresh it)
        Presets = @(
            @{ Name = "📚 Étagère";     Status = @("Shelf"); Sort = "LastActivity"; SortDir = "Descending" },
            @{ Name = "♾️ Evergreen";   Status = @("Evergreen") },
            @{ Name = "⏳ Court";       Status = @("Shelf","Evergreen"); Categories = @("SShort"); Group = "CompletionStatus" },
            @{ Name = "⏳ Moyen";       Status = @("Shelf","Evergreen"); Categories = @("SShort","SMedium"); Group = "CompletionStatus" },
            @{ Name = "⏳ Long";        Status = @("Shelf","Evergreen"); Group = "CompletionStatus" },
            @{ Name = "🎭 Léger";       Status = @("Shelf","Evergreen"); Categories = @("Leger"); Group = "CompletionStatus" },
            @{ Name = "🎭 Action";      Status = @("Shelf","Evergreen"); Categories = @("Action"); Group = "CompletionStatus" },
            @{ Name = "🎭 Aventure";    Status = @("Shelf","Evergreen"); Categories = @("Aventure"); Group = "CompletionStatus" },
            @{ Name = "🎭 Gestion";     Status = @("Shelf","Evergreen"); Categories = @("Gestion"); Group = "CompletionStatus" },
            @{ Name = "🎭 Réflexion";   Status = @("Shelf","Evergreen"); Categories = @("Reflexion"); Group = "CompletionStatus" },
            @{ Name = "🎭 Détente";     Status = @("Shelf","Evergreen"); Categories = @("Detente"); Group = "CompletionStatus" },
            @{ Name = "🎭 Simulation";  Status = @("Shelf","Evergreen"); Categories = @("Simulation"); Group = "CompletionStatus" },
            @{ Name = "📥 Backlog";     Status = @("Backlog","Hold","NotYet"); Group = "CompletionStatus"; Sort = "Playtime"; SortDir = "Descending" }
        )
    }
}

# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------

function Find-Status {
    param([string]$Name)
    $target = Get-NormalizedName $Name
    return $PlayniteApi.Database.CompletionStatuses | Where-Object { (Get-NormalizedName $_.Name) -eq $target } | Select-Object -First 1
}

function Find-Tag {
    param([string]$Name)
    $target = Get-NormalizedName $Name
    return $PlayniteApi.Database.Tags | Where-Object { (Get-NormalizedName $_.Name) -eq $target } | Select-Object -First 1
}

function Resolve-Status {
    param([string]$Name)
    $existing = Find-Status $Name
    if ($null -eq $existing) { return $PlayniteApi.Database.CompletionStatuses.Add($Name) }
    return $existing
}

function Resolve-Tag {
    param([string]$Name)
    $existing = Find-Tag $Name
    if ($null -eq $existing) { return $PlayniteApi.Database.Tags.Add($Name) }
    return $existing
}

function Get-NormalizedName {
    param([string]$Name)
    # Notion itself isn't consistent about which apostrophe character it uses inside a
    # single name (straight ' vs curly '/' vs backtick) - Claude's suggestions faithfully
    # copy whatever Notion actually has, so a straight comparison can treat an existing
    # category/status/tag as brand new just because of a punctuation glyph mismatch.
    # Normalize before comparing so that doesn't happen.
    if ($null -eq $Name) { return $Name }
    return $Name -replace '[‘’ʼ`]', "'"
}

function Find-Category {
    param([string]$Name)
    $target = Get-NormalizedName $Name
    return $PlayniteApi.Database.Categories | Where-Object { (Get-NormalizedName $_.Name) -eq $target } | Select-Object -First 1
}

function Resolve-Category {
    param([string]$Name)
    $existing = Find-Category $Name
    if ($null -eq $existing) { return $PlayniteApi.Database.Categories.Add($Name) }
    return $existing
}

function Find-Feature {
    param([string]$Name)
    $target = Get-NormalizedName $Name
    return $PlayniteApi.Database.Features | Where-Object { (Get-NormalizedName $_.Name) -eq $target } | Select-Object -First 1
}

function New-IdFilter {
    param([Guid[]]$Ids)
    $list = New-Object 'System.Collections.Generic.List[Guid]'
    foreach ($id in $Ids) { $list.Add($id) }
    $f = New-Object Playnite.SDK.Models.IdItemFilterItemProperties
    $f.Ids = $list
    return $f
}

function Resolve-Preset {
    param([string]$Name, $Settings, $Group, $Sort, $SortDir)
    $existing = $PlayniteApi.Database.FilterPresets | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if ($null -ne $existing) { return $existing }
    $preset = New-Object Playnite.SDK.Models.FilterPreset
    $preset.Name = $Name
    $preset.Settings = $Settings
    $preset.ShowInFullscreeQuickSelection = $true
    if ($Group)   { $preset.GroupingOrder         = [Playnite.SDK.Models.GroupableField]$Group }
    if ($Sort)    { $preset.SortingOrder          = [Playnite.SDK.Models.SortOrder]$Sort }
    if ($SortDir) { $preset.SortingOrderDirection = [Playnite.SDK.Models.SortOrderDirection]$SortDir }
    $PlayniteApi.Database.FilterPresets.Add($preset)
    return $preset
}

# ---- Shelf cap (persisted in config.txt) -----------------------------------

function Get-Cap {
    $cfg = Join-Path $PSScriptRoot "config.txt"
    if (Test-Path $cfg) {
        $raw = (Get-Content $cfg -Raw).Trim()
        $n = 0
        if ([int]::TryParse($raw, [ref]$n) -and $n -gt 0) { return $n }
    }
    return 4
}

function Set-Cap {
    param([int]$N)
    Set-Content -Path (Join-Path $PSScriptRoot "config.txt") -Value $N -Encoding UTF8
}

# ---- Workflow helpers ------------------------------------------------------

function Set-GameStatus {
    param($Game, [string]$StatusName)
    $st = Find-Status $StatusName
    if ($null -eq $st) {
        $PlayniteApi.Dialogs.ShowMessage("Statut '$StatusName' introuvable. Vérifie les noms dans Get-Cfg et dans Playnite.", "Finish My Games")
        return $false
    }
    $Game.CompletionStatusId = $st.Id
    $PlayniteApi.Database.Games.Update($Game)
    return $true
}

function Remove-TagEverywhere {
    param([string]$TagName)
    $tag = Find-Tag $TagName
    if ($null -eq $tag) { return }
    foreach ($g in $PlayniteApi.Database.Games) {
        if ($null -ne $g.TagIds -and $g.TagIds.Contains($tag.Id)) {
            $ids = New-Object 'System.Collections.Generic.List[Guid]'
            $ids.AddRange($g.TagIds)
            [void]$ids.Remove($tag.Id)
            $g.TagIds = $ids
            $PlayniteApi.Database.Games.Update($g)
        }
    }
}

function Get-ShelfCount {
    $st = Find-Status (Get-Cfg).Status.Shelf
    if ($null -eq $st) { return 0 }
    return @($PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $st.Id }).Count
}

# ---------------------------------------------------------------------------
#  Main menu
# ---------------------------------------------------------------------------

function GetMainMenuItems {
    param($menuArgs)

    $section = "@|Finish My Games"
    $defs = @(
        @{ D = "Configuration";                    F = "Invoke-CreateStructure" },
        @{ D = "Taille de l'étagère";               F = "Invoke-SetShelfCap" },
        @{ D = "Statistiques";                      F = "Invoke-ShowStats" },
        @{ D = "Marquer les jeux non catégorisés"; F = "Invoke-TagMissingAxes" }
    )

    $items = @()
    foreach ($d in $defs) {
        $mi = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
        $mi.Description  = $d.D
        $mi.FunctionName = $d.F
        $mi.MenuSection  = $section
        $items += $mi
    }
    return $items
}

# ---------------------------------------------------------------------------
#  "Marquer les jeux non catégorisés": tag every game missing one of the
#     three multi-valued category systems - 🕹️ Categorie, ⏳ Session,
#     🎭 Humeur - each with its own standalone marker, in a single pass, so
#     Playnite's native filter becomes usable to find and work through them.
#     A game missing 🎭 Humeur despite already having a 🕹️ Categorie is worth
#     a second look - Humeur should get populated automatically by the
#     dynamic-rules addon once a Categorie is set (except Leger, which stays
#     manual), so seeing one here points at a gap in that automation rather
#     than something to fix by hand. Same demos/playtests + Hidden exclusion
#     throughout. Idempotent - safe to rerun any time, only currently-missing
#     games get (re-)tagged; already-sessioned/categorie'd/humeur'd games are
#     left alone.
# ---------------------------------------------------------------------------

function Invoke-TagMissingAxes {
    param($actionArgs)
    $c = Get-Cfg

    $demoFeature = Find-Feature $c.Features.Demo
    $demoFeatureId = if ($demoFeature) { $demoFeature.Id } else { $null }

    $axes = @(
        @{ Prefix = "🕹️"; MarkerName = $c.Categories.MissingCategorie },
        @{ Prefix = "⏳"; MarkerName = $c.Categories.MissingSession },
        @{ Prefix = "🎭"; MarkerName = $c.Categories.MissingHumeur }
    )
    foreach ($axis in $axes) {
        $axis.PrefixCatIds = @($PlayniteApi.Database.Categories | Where-Object { $_.Name.StartsWith($axis.Prefix) } | ForEach-Object { $_.Id })
        $axis.Marker = Resolve-Category $axis.MarkerName
        $axis.Tagged = 0
    }

    foreach ($g in $PlayniteApi.Database.Games) {
        if ($g.Hidden) { continue }

        $isDemo = ($null -ne $demoFeatureId) -and $g.FeatureIds -and ($g.FeatureIds -contains $demoFeatureId)
        if ($isDemo) { continue }

        $currentIds = if ($g.CategoryIds) { @($g.CategoryIds) } else { @() }
        $newIds = $null

        foreach ($axis in $axes) {
            $hasAxis = $false
            foreach ($id in $currentIds) {
                if ($axis.PrefixCatIds -contains $id) { $hasAxis = $true; break }
            }
            if ($hasAxis) { continue }
            if ($currentIds -notcontains $axis.Marker.Id) {
                if ($null -eq $newIds) {
                    $newIds = New-Object 'System.Collections.Generic.List[Guid]'
                    foreach ($id in $currentIds) { [void]$newIds.Add($id) }
                }
                [void]$newIds.Add($axis.Marker.Id)
                $currentIds = @($newIds)
                $axis.Tagged++
            }
        }

        if ($null -ne $newIds) {
            $g.CategoryIds = $newIds
            $PlayniteApi.Database.Games.Update($g)
        }
    }

    $lines = foreach ($axis in $axes) { "  - $($axis.MarkerName) : $($axis.Tagged)" }
    $msg = "Marquage terminé.`n`n" + ($lines -join "`n") + "`n`nFiltre dans Playnite sur chacune de ces catégories pour retrouver les jeux concernés."
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - marquage manquants")
}

# ---------------------------------------------------------------------------
#  "Configuration": mood/session categories + tags + the 'evergreen' status,
#     plus filter presets (folded in from the old standalone presets step).
#     Idempotent - safe to rerun any time, including after adding a new
#     Categorie.
# ---------------------------------------------------------------------------

function Invoke-CreateStructure {
    param($actionArgs)
    $c = Get-Cfg

    [void](Resolve-Status $c.Status.Evergreen)

    $cats = @(
        $c.Categories.Action, $c.Categories.Aventure, $c.Categories.Gestion, $c.Categories.Reflexion, $c.Categories.Detente, $c.Categories.Simulation, $c.Categories.Leger,
        $c.Categories.SShort, $c.Categories.SMedium, $c.Categories.SLong
    )
    foreach ($cat in $cats) { [void](Resolve-Category $cat) }

    $markerCats = @($c.Categories.MissingCategorie, $c.Categories.MissingSession, $c.Categories.MissingHumeur)
    foreach ($cat in $markerCats) { [void](Resolve-Category $cat) }

    $tags = @($c.Tags.Values)
    foreach ($t in $tags) { [void](Resolve-Tag $t) }

    $needed = @($c.Status.NotYet, $c.Status.Backlog, $c.Status.Hold, $c.Status.Shelf, $c.Status.Abandoned, $c.Status.Closed, $c.Status.Beaten)
    $missing = @()
    foreach ($s in $needed) { if ($null -eq (Find-Status $s)) { $missing += $s } }

    $msg = "Terminé.`n`nStatut créé (ou déjà présent) : $($c.Status.Evergreen)`n" +
           "Catégories créées (ou déjà présentes) :`n  " + ($cats -join ", ") +
           "`n`nCatégories marqueurs créées pour 'Marquer les jeux non catégorisés' (ou déjà présentes) :`n  " + ($markerCats -join ", ")
    if ($tags.Count -gt 0) {
        $msg += "`n" + "Tags créés (ou déjà présents) :`n  " + ($tags -join ", ")
    }
    if ($missing.Count -gt 0) {
        $msg += "`n`nATTENTION - ces statuts (définis dans Get-Cfg) sont introuvables dans Playnite :`n  " + ($missing -join ", ") +
                "`nRenomme-les dans Playnite pour qu'ils correspondent, ou corrige les noms dans Get-Cfg."
    }

    # --- Filter presets: folded in from the old standalone presets step. Needs the Shelf
    #     status to already exist in Playnite (a base Kanban column you set up by hand,
    #     not something this function creates). If it's missing, skip presets instead of
    #     hard-failing - the category/tag/status work above is still valid on its own.
    if ($null -eq (Find-Status $c.Status.Shelf)) {
        $msg += "`n`nPresets de filtres non créés - statut '$($c.Status.Shelf)' introuvable. Corrige le nom dans Get-Cfg ou dans Playnite, puis relance."
    } else {
        $created = @()
        $skipped = @()

        foreach ($p in $c.Presets) {
            $settings = New-Object Playnite.SDK.Models.FilterPresetSettings
            $hasFilter = $false

            if ($p.ContainsKey("Status") -and @($p.Status).Count -gt 0) {
                $sids = @()
                foreach ($k in $p.Status) { $st = Find-Status $c.Status[$k]; if ($st) { $sids += $st.Id } }
                if ($sids.Count -gt 0) { $settings.CompletionStatuses = New-IdFilter $sids; $hasFilter = $true }
            }

            if ($p.ContainsKey("Categories") -and @($p.Categories).Count -gt 0) {
                $cids = @()
                foreach ($k in $p.Categories) { $nm = $c.Categories[$k]; if ($nm) { $cg = Resolve-Category $nm; $cids += $cg.Id } }
                if ($cids.Count -gt 0) { $settings.Category = New-IdFilter $cids; $hasFilter = $true }
            }

            if ($p.ContainsKey("Tags") -and @($p.Tags).Count -gt 0) {
                $tids = @()
                foreach ($k in $p.Tags) { $nm = $c.Tags[$k]; if ($nm) { $tg = Resolve-Tag $nm; $tids += $tg.Id } }
                if ($tids.Count -gt 0) { $settings.Tag = New-IdFilter $tids; $hasFilter = $true }
            }

            if ($hasFilter) { [void](Resolve-Preset $p.Name $settings $p.Group $p.Sort $p.SortDir); $created += $p.Name }
            else { $skipped += $p.Name }
        }

        $msg += "`n`nPresets créés (ou déjà présents) :`n  " + ($created -join "`n  ")
        if ($skipped.Count -gt 0) {
            $msg += "`n`nPresets non créés (aucun statut/catégorie/tag correspondant - vérifie les clés dans Get-Cfg.Presets) :`n  " + ($skipped -join ", ")
        }
    }

    $msg += "`n`nÀ faire ensuite : les catégories Session et Léger sont manuelles - à assigner toi-même, aucune source fiable ne permet de les automatiser. " +
            "Les autres catégories Humeur (Action/Aventure/Gestion/Réflexion/Détente/Simulation) sont peuplées automatiquement par ton add-on de règles dynamiques dès qu'un jeu a une Catégorie fine - rien à faire à la main pour celles-ci."
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - configuration")
}

# ---------------------------------------------------------------------------
#  "Statistiques": a few stats about the FinishMyGames system - shelf
#     occupancy vs the cap (with the roster), evergreen count, and backlog
#     size (Backlog + En pause combined, matching how the "Backlog" filter
#     preset groups them).
# ---------------------------------------------------------------------------

function Invoke-ShowStats {
    param($actionArgs)
    $c = Get-Cfg

    $shelf = Find-Status $c.Status.Shelf
    $evergreen = Find-Status $c.Status.Evergreen
    $backlog = Find-Status $c.Status.Backlog
    $hold = Find-Status $c.Status.Hold

    $missing = @()
    if ($null -eq $shelf) { $missing += $c.Status.Shelf }
    if ($null -eq $evergreen) { $missing += $c.Status.Evergreen }
    if ($null -eq $backlog) { $missing += $c.Status.Backlog }
    if ($null -eq $hold) { $missing += $c.Status.Hold }
    if ($missing.Count -gt 0) {
        $PlayniteApi.Dialogs.ShowMessage("Statut(s) introuvable(s) : $($missing -join ', ').`nCorrige le(s) nom(s) dans Get-Cfg ou dans Playnite.", "Finish My Games")
        return
    }

    $cap = Get-Cap
    $shelfGames = @($PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $shelf.Id })
    $shelfN = $shelfGames.Count
    $shelfList = ($shelfGames | ForEach-Object { "  - " + $_.Name }) -join "`n"
    $shelfVerdict = if ($shelfN -le $cap) { "OK, dans le plafond." } else { "AU-DESSUS du plafond - il faut en retirer un avant d'en ajouter un nouveau." }

    $evergreenN = @($PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $evergreen.Id }).Count

    $backlogN = @($PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $backlog.Id }).Count
    $holdN = @($PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $hold.Id }).Count
    $backlogTotal = $backlogN + $holdN

    $msg = "Étagère : $shelfN / $cap places. $shelfVerdict`n$shelfList`n`n" +
           "Evergreen : $evergreenN jeux`n`n" +
           "Backlog : $backlogTotal jeux ($backlogN en Backlog, $holdN en pause)"

    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - stats")
}

# ---------------------------------------------------------------------------
#  "Taille de l'étagère": set the shelf cap
# ---------------------------------------------------------------------------

function Invoke-SetShelfCap {
    param($actionArgs)
    $cur = Get-Cap
    $res = $PlayniteApi.Dialogs.SelectString("Nombre maximum de jeux sur l'étagère active :", "Taille de l'étagère", $cur.ToString())
    if ($res.Result) {
        $n = 0
        if ([int]::TryParse($res.SelectedString.Trim(), [ref]$n) -and $n -gt 0) {
            Set-Cap $n
            $PlayniteApi.Dialogs.ShowMessage("Taille de l'étagère réglée sur $n.", "Réglage")
        } else {
            $PlayniteApi.Dialogs.ShowMessage("Valeur invalide (un entier > 0 est attendu).", "Réglage")
        }
    }
}

# ===========================================================================
#  WORKFLOW - right-click a game -> Finish My Games
#  The one right-click action that does MORE than a plain status change:
#    - Put on shelf : enforces the shelf cap
#  Everything else is just a Completion Status change -> use Playnite directly.
# ===========================================================================

function GetGameMenuItems {
    param($menuArgs)

    $section = "Finish My Games"
    $defs = @(
        @{ D = "Mettre sur l'étagère";             F = "Invoke-SetShelf" },
        @{ D = "Suggérer une catégorie (Claude)"; F = "Invoke-SuggestCategory" }
    )

    $items = @()
    foreach ($d in $defs) {
        $mi = New-Object Playnite.SDK.Plugins.ScriptGameMenuItem
        $mi.Description  = $d.D
        $mi.FunctionName = $d.F
        $mi.MenuSection  = $section
        $items += $mi
    }
    return $items
}

function Invoke-SetShelf {
    param($actionArgs)
    $c = Get-Cfg
    $games = @($actionArgs.Games)
    $cap = Get-Cap
    $shelf = Find-Status $c.Status.Shelf
    if ($null -eq $shelf) {
        $PlayniteApi.Dialogs.ShowMessage("Statut '$($c.Status.Shelf)' introuvable. Corrige Get-Cfg.", "Finish My Games")
        return
    }
    $count = Get-ShelfCount
    $added = 0
    foreach ($g in $games) {
        if ($g.CompletionStatusId -eq $shelf.Id) { continue }
        if ($count -ge $cap) {
            $PlayniteApi.Dialogs.ShowMessage("Étagère pleine ($count/$cap). Retire un jeu avant d'en ajouter un nouveau.", "Étagère pleine")
            break
        }
        [void](Set-GameStatus $g $c.Status.Shelf)
        $count++; $added++
    }
    if ($added -gt 0) {
        $PlayniteApi.Dialogs.ShowMessage("$added jeu(x) mis sur l'étagère. Étagère : $count/$cap.", "Étagère")
    }
}

# ---------------------------------------------------------------------------
#  Suggest category via Claude Code (needs 'claude' CLI installed, logged
#  into your Max plan, in PATH, with the Notion connector authorized and the
#  'playnite-categorize' skill saved to your account).
# ---------------------------------------------------------------------------

function Invoke-SuggestCategory {
    param($actionArgs)
    $games = @($actionArgs.Games)
    # NOTE: context (tags/description/format instructions) goes over stdin, not as a
    # CLI argument - a JSON --json-schema argument breaks on Windows because it has to
    # survive PowerShell -> the npm .cmd shim -> cmd.exe, three layers of quoting that
    # do not agree on how to escape embedded quotes/braces. Keeping the -p argument to
    # a short, plain string and piping the rest via stdin (the documented
    # "cat file | claude -p ..." pattern) sidesteps that entirely.
    #
    # NOTE: PowerShell decodes an external process's stdout/stdin using the console's
    # OutputEncoding, which on Windows is usually a legacy codepage, not UTF-8 - so
    # accents come back mangled ("Ã©" instead of "é") unless we force it here.
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # Resolve the full path to 'claude' HERE, in the function's normal execution
    # context (the one that's proven to work), rather than relying on a PATH lookup
    # happening inside the ActivateGlobalProgress action below - if that action runs
    # in a different thread/runspace, it may not see the same PATH, which would
    # explain a call that works standalone but not wrapped in the progress overlay.
    $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claudeCmd) {
        $PlayniteApi.Dialogs.ShowMessage("'claude' introuvable dans le PATH de ce contexte. Vérifie l'installation de Claude Code.", "Finish My Games - suggestion")
        return
    }
    $claudePath = $claudeCmd.Source

    foreach ($g in $games) {
        $tagNames = @()
        if ($g.Tags) { $tagNames = $g.Tags | ForEach-Object { $_.Name } }
        $tags = $tagNames -join ", "
        $desc = "(pas de description)"
        if ($g.Description) { $desc = $g.Description -replace '<[^>]+>', '' }

        $promptArg = "/playnite-categorize $($g.Name)"
        $stdinContent = "Tags Steam (deja recuperes par Playnite): $tags`nDescription: $desc`n`n" +
            "Termine ta réponse par exactement ces deux lignes, rien d'autre après :`n" +
            "CATEGORIES: nom1 :: description Notion de nom1 ; nom2 :: description Notion de nom2`n" +
            "REASONING: raisonnement sur une seule ligne"

        # Reverted the ActivateGlobalProgress wrapper - three different fixes on it
        # (typed delegate cast, $script: scope, GetNewClosure) all failed to produce
        # any output at all, while this exact call works fine unwrapped. Rather than
        # keep guessing at why that specific API misbehaves here, back to a plain
        # synchronous call: the UI freezes during the call (as originally flagged),
        # but a Playnite notification at least gives a visible sign something is
        # happening, without needing the fragile delegate machinery.
        # --allowedTools abandonne : chez Didier le serveur Notion est enregistre
        # sous le nom "claude.ai Notion" (synchronise depuis le compte claude.ai,
        # pas ajoute a la main), et le nom d'outil interne exact qui en decoule
        # n'est pas deductible depuis l'exterieur (confirme empiriquement : meme
        # Claude lui-meme ne peut pas le lister sans l'appeler). On bascule donc
        # sur --dangerously-skip-permissions : ca desactive TOUTE demande de
        # permission pour cet appel precis (pas seulement Notion), mais le prompt
        # de la skill est strictement cadre (une seule lecture Notion en lecture
        # seule), donc le risque reel est faible pour ce script perso.
        $raw = $stdinContent | & $claudePath -p $promptArg --output-format json --dangerously-skip-permissions 2>&1

        if ($null -eq $raw -or [string]::IsNullOrWhiteSpace(($raw -join "`n"))) {
            $PlayniteApi.Dialogs.ShowMessage("Pas de sortie du tout pour '$($g.Name)'. Vérifie que 'claude' est installé, connecté, et dans le PATH.", "Finish My Games - suggestion")
            continue
        }

        $response = $null
        try {
            $response = $raw | ConvertFrom-Json
        } catch {
            $PlayniteApi.Dialogs.ShowMessage("Échec de l'appel à Claude Code pour '$($g.Name)'. Vérifie que 'claude' est installé, connecté à ton forfait Max, et dans le PATH.`n`nErreur : $_", "Finish My Games - suggestion")
            continue
        }

        if ($null -eq $response -or -not $response.result) {
            $PlayniteApi.Dialogs.ShowMessage("Pas de réponse exploitable pour '$($g.Name)'. Sortie brute :`n$raw", "Finish My Games - suggestion")
            continue
        }

        $lines = $response.result -split "`n"
        $catLine = $lines | Where-Object { $_ -match '^CATEGORIES:' } | Select-Object -First 1
        $reasonLine = $lines | Where-Object { $_ -match '^REASONING:' } | Select-Object -First 1

        if (-not $catLine) {
            $PlayniteApi.Dialogs.ShowMessage("$($g.Name) : réponse dans un format inattendu, à lire toi-même :`n`n$($response.result)", "Finish My Games - suggestion")
            continue
        }

        # Each suggested category comes as "nom :: description", entries separated by
        # ";" - the description both feeds the Notion reminder below and is a soft
        # signal the name was actually matched against a real Notion row rather than
        # invented, since the skill is only ever supposed to suggest categories that
        # already exist in the live Notion table.
        $catsRaw = $catLine -replace '^CATEGORIES:\s*', ''
        $suggestedList = @()
        foreach ($entry in ($catsRaw -split '\s*;\s*' | Where-Object { $_ })) {
            $parts = $entry -split '\s*::\s*', 2
            $name = $parts[0].Trim()
            $descr = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }
            if ($name) { $suggestedList += [PSCustomObject]@{ Name = $name; Description = $descr } }
        }
        $reasoning = if ($reasonLine) { $reasonLine -replace '^REASONING:\s*', '' } else { $response.result }

        if ($suggestedList.Count -eq 0) {
            $PlayniteApi.Dialogs.ShowMessage("$($g.Name) : aucune catégorie suggérée.`n`n$reasoning", "Finish My Games - suggestion")
            continue
        }

        # Match against categories that already exist in Playnite - try the bare name
        # and the "🕹️ " Playnite convention, in case Notion doesn't carry the emoji.
        # Anything that matches neither gets created (with the emoji prefix, unless
        # the suggested name already has one) rather than blocked - but flagged loudly
        # so you remember to also add it to the Notion reference afterward.
        $foundCats = @()
        $toCreate = @()
        foreach ($item in $suggestedList) {
            $cat = Find-Category $item.Name
            if (-not $cat) { $cat = Find-Category "🕹️ $($item.Name)" }
            if ($cat) {
                $foundCats += $cat
            } else {
                $effectiveName = if ($item.Name.StartsWith("🕹️")) { $item.Name } else { "🕹️ $($item.Name)" }
                $toCreate += [PSCustomObject]@{ Name = $item.Name; Description = $item.Description; EffectiveName = $effectiveName }
            }
        }

        # Show what "type" categories (🕹️) the game already has before asking what to
        # do - Humeur (🎭) and Session categories are never touched by this function
        # either way, only 🕹️ ones are in play for "Remplacer".
        $currentTypeCats = @()
        if ($g.CategoryIds) {
            $currentTypeCats = @($PlayniteApi.Database.Categories | Where-Object { $g.CategoryIds -contains $_.Id -and $_.Name.StartsWith("🕹️") })
        }
        $currentNames = if ($currentTypeCats.Count -gt 0) { ($currentTypeCats | ForEach-Object { $_.Name }) -join ', ' } else { "(aucune)" }

        $displayNames = @()
        $displayNames += ($foundCats | ForEach-Object { $_.Name })
        $displayNames += ($toCreate | ForEach-Object { $_.EffectiveName })
        $namesForDisplay = $displayNames -join ', '
        $msg = "$($g.Name)`n`nCatégories actuelles (🕹️) : $currentNames`n`nCatégories suggérées : $namesForDisplay`n`n$reasoning"
        if ($toCreate.Count -gt 0) {
            $msg += "`n`n⚠️ ATTENTION ! Ces catégories n'existent pas encore dans Playnite - elles seront créées si tu choisis Ajouter ou Remplacer. Pense aussi à les ajouter dans la référence Notion :"
            foreach ($item in $toCreate) {
                $msg += "`n  - $($item.EffectiveName) : $($item.Description)"
            }
        }

        $optAdd = New-Object Playnite.SDK.MessageBoxOption("Ajouter", $true, $false)
        $optReplace = New-Object Playnite.SDK.MessageBoxOption("Remplacer", $false, $false)
        $optNothing = New-Object Playnite.SDK.MessageBoxOption("Ne rien faire", $false, $true)
        $options = New-Object 'System.Collections.Generic.List[Playnite.SDK.MessageBoxOption]'
        $options.Add($optAdd)
        $options.Add($optReplace)
        $options.Add($optNothing)

        $choice = $PlayniteApi.Dialogs.ShowMessage($msg, "Suggestion de catégorie", [System.Windows.MessageBoxImage]::Question, $options)

        if ($null -eq $choice -or $choice.Title -eq "Ne rien faire") { continue }

        $newTypeCatIds = New-Object 'System.Collections.Generic.List[Guid]'
        foreach ($cat in $foundCats) {
            if (-not $newTypeCatIds.Contains($cat.Id)) { [void]$newTypeCatIds.Add($cat.Id) }
        }
        foreach ($item in $toCreate) {
            $newCat = Resolve-Category $item.EffectiveName
            if (-not $newTypeCatIds.Contains($newCat.Id)) { [void]$newTypeCatIds.Add($newCat.Id) }
        }

        $finalIds = New-Object 'System.Collections.Generic.List[Guid]'
        if ($choice.Title -eq "Ajouter") {
            # keep everything the game already has, add the new 🕹️ ones on top
            if ($g.CategoryIds) { $finalIds.AddRange($g.CategoryIds) }
            foreach ($id in $newTypeCatIds) {
                if (-not $finalIds.Contains($id)) { [void]$finalIds.Add($id) }
            }
        } else {
            # Remplacer: drop the game's existing 🕹️ categories, keep everything else
            # (Humeur, Session, anything non-🕹️) untouched, then add the new 🕹️ set
            if ($g.CategoryIds) {
                foreach ($id in $g.CategoryIds) {
                    $wasCurrentType = $currentTypeCats | Where-Object { $_.Id -eq $id }
                    if (-not $wasCurrentType) { [void]$finalIds.Add($id) }
                }
            }
            foreach ($id in $newTypeCatIds) {
                if (-not $finalIds.Contains($id)) { [void]$finalIds.Add($id) }
            }
        }

        $g.CategoryIds = $finalIds
        $PlayniteApi.Database.Games.Update($g)
    }
}
