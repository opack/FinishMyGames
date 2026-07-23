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
        }
        # --- Tags: nothing lives here right now - reserved for anything outside
        #     the Humeur/Session/Catégorie system, should you need it later.
        Tags = @{
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
            @{ Name = "📥 Backlog";     Status = @("Backlog","Hold"); Group = "CompletionStatus"; Sort = "Playtime"; SortDir = "Descending" }
        )
    }
}

# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------

function Find-Status {
    param([string]$Name)
    return $PlayniteApi.Database.CompletionStatuses | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
}

function Find-Tag {
    param([string]$Name)
    return $PlayniteApi.Database.Tags | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
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

function Find-Category {
    param([string]$Name)
    return $PlayniteApi.Database.Categories | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
}

function Resolve-Category {
    param([string]$Name)
    $existing = Find-Category $Name
    if ($null -eq $existing) { return $PlayniteApi.Database.Categories.Add($Name) }
    return $existing
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
        $PlayniteApi.Dialogs.ShowMessage("Status '$StatusName' not found. Check the names in Get-Cfg vs Playnite.", "Finish My Games")
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
        @{ D = "1) Create categories/tags + 'Evergreen' status"; F = "Invoke-CreateStructure" },
        @{ D = "2) Create filter presets";                   F = "Invoke-CreatePresets" },
        @{ D = "3) Count the active shelf";                  F = "Invoke-CountShelf" },
        @{ D = "4) Set the shelf cap...";                    F = "Invoke-SetShelfCap" }
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
#  1) Structure: mood/session categories + tags + the 'evergreen' status
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

    $tags = @($c.Tags.Values)
    foreach ($t in $tags) { [void](Resolve-Tag $t) }

    $needed = @($c.Status.NotYet, $c.Status.Backlog, $c.Status.Hold, $c.Status.Shelf, $c.Status.Abandoned, $c.Status.Closed, $c.Status.Beaten)
    $missing = @()
    foreach ($s in $needed) { if ($null -eq (Find-Status $s)) { $missing += $s } }

    $msg = "Done.`n`nCreated status (or already present): $($c.Status.Evergreen)`n" +
           "Created categories (or already present):`n  " + ($cats -join ", ")
    if ($tags.Count -gt 0) {
        $msg += "`n" + "Created tags (or already present):`n  " + ($tags -join ", ")
    }
    if ($missing.Count -gt 0) {
        $msg += "`n`nWARNING - these statuses (from Get-Cfg) were NOT found in Playnite:`n  " + ($missing -join ", ") +
                "`nRename them in Playnite to match, or fix the names in Get-Cfg."
    }
    $msg += "`n`nNext: Session and Léger categories are manual - assign them yourself, no reliable auto-source exists. " +
            "The other Humeur categories (Action/Aventure/Gestion/Réflexion/Détente/Simulation) get populated automatically by your dynamic-rules addon once a game has a fine Catégorie - nothing to do by hand there."
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - structure")
}

# ---------------------------------------------------------------------------
#  2) Filter presets
# ---------------------------------------------------------------------------

function Invoke-CreatePresets {
    param($actionArgs)
    $c = Get-Cfg

    if ($null -eq (Find-Status $c.Status.Shelf)) {
        $PlayniteApi.Dialogs.ShowMessage("Status '$($c.Status.Shelf)' not found. Fix the name in Get-Cfg or in Playnite first.", "Finish My Games")
        return
    }

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

    $msg = "Presets created (or already present):`n  " + ($created -join "`n  ")
    if ($skipped.Count -gt 0) {
        $msg += "`n`nSkipped (no matching status/category/tag - check the keys in Get-Cfg.Presets):`n  " + ($skipped -join ", ")
    }
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - presets")
}

# ---------------------------------------------------------------------------
#  3) Count the active shelf
# ---------------------------------------------------------------------------

function Invoke-CountShelf {
    param($actionArgs)
    $c = Get-Cfg
    $shelf = Find-Status $c.Status.Shelf
    if ($null -eq $shelf) {
        $PlayniteApi.Dialogs.ShowMessage("Status '$($c.Status.Shelf)' not found. Fix the name in Get-Cfg or Playnite.", "Finish My Games")
        return
    }

    $cap = Get-Cap
    $actives = $PlayniteApi.Database.Games | Where-Object { $_.CompletionStatusId -eq $shelf.Id }
    $n = @($actives).Count
    $list = (@($actives) | ForEach-Object { "  - " + $_.Name }) -join "`n"
    $verdict = if ($n -le $cap) { "OK, you're within the cap of $cap." } else { "OVER the cap of $cap - retire one before adding a new one." }

    $PlayniteApi.Dialogs.ShowMessage("Active shelf: $n game(s) '$($c.Status.Shelf)'.`n`n$list`n`n$verdict", "Finish My Games - shelf")
}

# ---------------------------------------------------------------------------
#  4) Set the shelf cap
# ---------------------------------------------------------------------------

function Invoke-SetShelfCap {
    param($actionArgs)
    $cur = Get-Cap
    $res = $PlayniteApi.Dialogs.SelectString("Max number of games on the active shelf:", "Shelf cap", $cur.ToString())
    if ($res.Result) {
        $n = 0
        if ([int]::TryParse($res.SelectedString.Trim(), [ref]$n) -and $n -gt 0) {
            Set-Cap $n
            $PlayniteApi.Dialogs.ShowMessage("Shelf cap set to $n.", "Setting")
        } else {
            $PlayniteApi.Dialogs.ShowMessage("Invalid value (expected an integer > 0).", "Setting")
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
        @{ D = "Put on shelf (respects the cap)"; F = "Invoke-SetShelf" }
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
        $PlayniteApi.Dialogs.ShowMessage("Status '$($c.Status.Shelf)' not found. Fix Get-Cfg.", "Finish My Games")
        return
    }
    $count = Get-ShelfCount
    $added = 0
    foreach ($g in $games) {
        if ($g.CompletionStatusId -eq $shelf.Id) { continue }
        if ($count -ge $cap) {
            $PlayniteApi.Dialogs.ShowMessage("Shelf full ($count/$cap). Retire a game before adding.", "Shelf full")
            break
        }
        [void](Set-GameStatus $g $c.Status.Shelf)
        $count++; $added++
    }
    if ($added -gt 0) {
        $PlayniteApi.Dialogs.ShowMessage("$added game(s) put on the shelf. Shelf: $count/$cap.", "Shelf")
    }
}
