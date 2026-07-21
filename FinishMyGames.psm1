# ============================================================================
#  Finish My Games - Setup for Playnite
#
#  ALL names (statuses + tags) live in Get-Cfg below. That is the ONE place
#  to edit if you rename a status/tag in Playnite (or want other emojis).
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
        # --- Tags (emojis OK; file is UTF-8 BOM).
        Tags = @{
            Action     = "[Mood] 💥 Action"
            Aventure   = "[Mood] 🗺️ Aventure"
            Gestion    = "[Mood] 🏗️ Gestion"
            Reflexion  = "[Mood] 🧩 Réflexion"
            Detente    = "[Mood] 🍃 Détente"
            Simulation = "[Mood] 🏎️ Simulation"
            Leger      = "[Mood] 🪶 Léger"
            SShort     = "[Session] ⚡ Court"
            SMedium    = "[Session] ⏳ Moyen"
            SLong      = "[Session] 🕰️ Long"
            Marker     = "[Session] __AUTO__"
        }
        # --- Filter presets: Name + which statuses/tags to filter, by KEY from
        #     Status/Tags above. Add / remove / rename freely. Several tags = OR;
        #     several statuses = OR. Keys must exist in Status/Tags.
        #     Optional per preset: Group / Sort / SortDir to auto-group & sort the view.
        #       Group   = a GroupableField name (CompletionStatus, Genre, Platform, PlayTime, Source, Added...)
        #                 full list: https://api.playnite.link/docs/api/Playnite.SDK.Models.GroupableField.html
        #       Sort    = a SortOrder name (Playtime, Name, Added, LastActivity, CompletionStatus...)
        #                 full list: https://api.playnite.link/docs/api/Playnite.SDK.Models.SortOrder.html
        #       SortDir = "Ascending" or "Descending"
        #     (applied only when the preset is first created; delete an existing one to refresh it)
        Presets = @(
            @{ Name = "📚 Étagère";      Status = @("Shelf"); Sort = "LastActivity"; SortDir = "Descending" },
            @{ Name = "⚡ 30 min";      Status = @("Shelf","Evergreen"); Tags = @("SShort"); Group = "CompletionStatus" },
            @{ Name = "⏳ 1h";          Status = @("Shelf","Evergreen"); Tags = @("SShort","SMedium"); Group = "CompletionStatus" },
            @{ Name = "🕰️ Soirée";      Status = @("Shelf","Evergreen"); Group = "CompletionStatus" },
            @{ Name = "♾️ Evergreen";   Status = @("Evergreen") },
            @{ Name = "🪶 Léger";       Status = @("Shelf","Evergreen"); Tags = @("Leger"); Group = "CompletionStatus" },
            @{ Name = "💥 Action";      Status = @("Shelf","Evergreen"); Tags = @("Action"); Group = "CompletionStatus" },
            @{ Name = "🗺️ Aventure";    Status = @("Shelf","Evergreen"); Tags = @("Aventure"); Group = "CompletionStatus" },
            @{ Name = "🏗️ Gestion";     Status = @("Shelf","Evergreen"); Tags = @("Gestion"); Group = "CompletionStatus" },
            @{ Name = "🧩 Réflexion";   Status = @("Shelf","Evergreen"); Tags = @("Reflexion"); Group = "CompletionStatus" },
            @{ Name = "🍃 Détente";     Status = @("Shelf","Evergreen"); Tags = @("Detente"); Group = "CompletionStatus" },
            @{ Name = "🏎️ Simulation";  Status = @("Shelf","Evergreen"); Tags = @("Simulation"); Group = "CompletionStatus" },
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

function Test-GameHasTagLike {
    param($Game, [string]$Pattern)
    if ($null -eq $Game.TagIds) { return $false }
    foreach ($tid in $Game.TagIds) {
        $t = $PlayniteApi.Database.Tags.Get($tid)
        if ($t -and $t.Name -like $Pattern) { return $true }
    }
    return $false
}

function Add-GameTags {
    param($Game, [Guid[]]$TagIds)
    $ids = New-Object 'System.Collections.Generic.List[Guid]'
    if ($null -ne $Game.TagIds) { $ids.AddRange($Game.TagIds) }
    foreach ($id in $TagIds) { if (-not $ids.Contains($id)) { $ids.Add($id) } }
    $Game.TagIds = $ids
    $PlayniteApi.Database.Games.Update($Game)
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

# ---- Session mapping (loaded from editable session-map.txt) ----------------

function Get-SessionMap {
    $path = Join-Path $PSScriptRoot "session-map.txt"
    $default = (Get-Cfg).Tags.SMedium
    $buckets = @()
    if (Test-Path $path) {
        foreach ($line in (Get-Content $path -Encoding UTF8)) {
            $l = $line.Trim()
            if ($l -eq "" -or $l.StartsWith("#")) { continue }
            $idx = $l.IndexOf("=")
            if ($idx -lt 0) { continue }
            $key = $l.Substring(0, $idx).Trim()
            $val = $l.Substring($idx + 1).Trim()
            if ($key -eq "DEFAULT") { $default = $val; continue }
            $genres = @()
            foreach ($g in $val.Split(",")) { $t = $g.Trim(); if ($t -ne "") { $genres += $t } }
            if ($key -ne "") { $buckets += @{ Tag = $key; Genres = $genres } }
        }
    }
    return @{ Default = $default; Buckets = $buckets; Path = $path }
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
        @{ D = "1) Create tags + 'Evergreen' status";        F = "Invoke-CreateStructure" },
        @{ D = "2) Create filter presets";                   F = "Invoke-CreatePresets" },
        @{ D = "3) Seed Session tags from genres (draft)";   F = "Invoke-SeedSession" },
        @{ D = "4) Count the active shelf";                  F = "Invoke-CountShelf" },
        @{ D = "5) Set the shelf cap...";                    F = "Invoke-SetShelfCap" }
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
#  1) Structure: mood/session tags + the 'evergreen' status
# ---------------------------------------------------------------------------

function Invoke-CreateStructure {
    param($actionArgs)
    $c = Get-Cfg

    [void](Resolve-Status $c.Status.Evergreen)

    $tags = @(
        $c.Tags.Action, $c.Tags.Aventure, $c.Tags.Gestion, $c.Tags.Reflexion, $c.Tags.Detente, $c.Tags.Simulation, $c.Tags.Leger,
        $c.Tags.SShort, $c.Tags.SMedium, $c.Tags.SLong
    )
    foreach ($t in $tags) { [void](Resolve-Tag $t) }

    $needed = @($c.Status.NotYet, $c.Status.Backlog, $c.Status.Hold, $c.Status.Shelf, $c.Status.Abandoned, $c.Status.Closed, $c.Status.Beaten)
    $missing = @()
    foreach ($s in $needed) { if ($null -eq (Find-Status $s)) { $missing += $s } }

    $msg = "Done.`n`nCreated status (or already present): $($c.Status.Evergreen)`n" +
           "Created tags (or already present):`n  " + ($tags -join ", ")
    if ($missing.Count -gt 0) {
        $msg += "`n`nWARNING - these statuses (from Get-Cfg) were NOT found in Playnite:`n  " + ($missing -join ", ") +
                "`nRename them in Playnite to match, or fix the names in Get-Cfg."
    }
    $msg += "`n`nNext: tag your games with `"[Mood] ...`" yourself, and run action 3 for a Session draft."
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
        $msg += "`n`nSkipped (no matching status/tag - check the keys in Get-Cfg.Presets):`n  " + ($skipped -join ", ")
    }
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - presets")
}

# ---------------------------------------------------------------------------
#  3) Seed Session tags from genres (draft). Only games with no Session tag yet.
# ---------------------------------------------------------------------------

function Invoke-SeedSession {
    param($actionArgs)
    $c = Get-Cfg
    $map = Get-SessionMap

    $go = $PlayniteApi.Dialogs.ShowMessage(
        "This puts a Session tag on games that have none, based on their genres, using the rules in:`n  $($map.Path)`n`n" +
        "It's a DRAFT: each touched game also gets the '$($c.Tags.Marker)' marker so you can filter and fix them.`n`nDid you make a backup? Continue?",
        "Finish My Games - Session (draft)",
        'YesNo'
    )
    if ($go -ne 'Yes') { return }

    foreach ($b in $map.Buckets) { [void](Resolve-Tag $b.Tag) }
    [void](Resolve-Tag $map.Default)
    $marker = Resolve-Tag $c.Tags.Marker

    # Set of "already has a Session tag" ids - robust to any tag naming scheme.
    $sessionIds = New-Object 'System.Collections.Generic.HashSet[Guid]'
    foreach ($b in $map.Buckets) { $bt = Find-Tag $b.Tag; if ($bt) { [void]$sessionIds.Add($bt.Id) } }
    $dt = Find-Tag $map.Default; if ($dt) { [void]$sessionIds.Add($dt.Id) }
    foreach ($nm in @($c.Tags.SShort, $c.Tags.SMedium, $c.Tags.SLong)) { $ct = Find-Tag $nm; if ($ct) { [void]$sessionIds.Add($ct.Id) } }
    [void]$sessionIds.Add($marker.Id)

    $touched = 0
    foreach ($game in $PlayniteApi.Database.Games) {
        $already = $false
        if ($null -ne $game.TagIds) { foreach ($tid in $game.TagIds) { if ($sessionIds.Contains($tid)) { $already = $true; break } } }
        if ($already) { continue }

        $genreNames = @()
        if ($null -ne $game.GenreIds) {
            foreach ($gid in $game.GenreIds) {
                $g = $PlayniteApi.Database.Genres.Get($gid)
                if ($g) { $genreNames += $g.Name }
            }
        }

        $chosen = $null
        foreach ($b in $map.Buckets) {
            $hit = $false
            foreach ($gn in $genreNames) { if ($b.Genres -contains $gn) { $hit = $true; break } }
            if ($hit) { $chosen = $b.Tag; break }
        }
        if ($null -eq $chosen) { $chosen = $map.Default }

        $tagObj = Resolve-Tag $chosen
        Add-GameTags $game @($tagObj.Id, $marker.Id)
        $touched++
    }

    $PlayniteApi.Dialogs.ShowMessage(
        "Draft applied to $touched game(s).`n`nTo review: filter on the '$($c.Tags.Marker)' tag, fix the mistakes, then remove that marker as you go.`n`nTo change the rules, edit session-map.txt and run this action again.",
        "Finish My Games - Session (draft)"
    )
}

# ---------------------------------------------------------------------------
#  4) Count the active shelf
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
#  5) Set the shelf cap
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
