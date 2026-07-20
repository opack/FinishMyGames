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
        #     Kanban columns: "To Play" / "Playing" / "Played".
        #     Rename a status in Playnite? Update the matching line here.
        Status = @{
            NotYet    = "To Play (not played)"     # brand new, unsorted
            Backlog   = "To Play (plan to play)"   # intend to play
            Hold      = "To Play (on hold)"        # paused, still a candidate
            Shelf     = "Playing (on shelf)"       # active shelf (max = cap)
            Evergreen = "Playing (fil rouge)"      # created by this add-on
            Abandoned = "Played (abandoned)"       # won't return
            Finished  = "Played (completed)"       # got what I wanted
            Beaten    = "Played (beaten)"          # 100% / end boss down
        }
        # --- Tags (emojis OK; file is UTF-8 BOM).
        Tags = @{
            Focus     = "🎯 Focus"
            Hype      = "🔥 Hype"
            Action    = "Mood/Action 💥"
            Adventure = "Mood/Adventure 🗺️"
            Simple    = "Mood/Simple 🍬"
            Light     = "Mood/Light 🎈"
            SShort    = "Session/Short ⚡"
            SMedium   = "Session/Medium ⏳"
            SLong     = "Session/Long 🕰️"
            Marker    = "Session/__AUTO__"
        }
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
    param([string]$Name, $Settings)
    $existing = $PlayniteApi.Database.FilterPresets | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if ($null -ne $existing) { return $existing }
    $preset = New-Object Playnite.SDK.Models.FilterPreset
    $preset.Name = $Name
    $preset.Settings = $Settings
    $preset.ShowInFullscreeQuickSelection = $true
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
        @{ D = "1) Create tags + 'Fil rouge' status";        F = "Invoke-CreateStructure" },
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
#  1) Structure: mood/session tags + the 'fil rouge' status
# ---------------------------------------------------------------------------

function Invoke-CreateStructure {
    param($actionArgs)
    $c = Get-Cfg

    [void](Resolve-Status $c.Status.Evergreen)

    $tags = @(
        $c.Tags.Action, $c.Tags.Adventure, $c.Tags.Simple, $c.Tags.Light,
        $c.Tags.SShort, $c.Tags.SMedium, $c.Tags.SLong,
        $c.Tags.Hype, $c.Tags.Focus
    )
    foreach ($t in $tags) { [void](Resolve-Tag $t) }

    $needed = @($c.Status.NotYet, $c.Status.Backlog, $c.Status.Hold, $c.Status.Shelf, $c.Status.Abandoned, $c.Status.Finished, $c.Status.Beaten)
    $missing = @()
    foreach ($s in $needed) { if ($null -eq (Find-Status $s)) { $missing += $s } }

    $msg = "Done.`n`nCreated status (or already present): $($c.Status.Evergreen)`n" +
           "Created tags (or already present):`n  " + ($tags -join ", ")
    if ($missing.Count -gt 0) {
        $msg += "`n`nWARNING - these statuses (from Get-Cfg) were NOT found in Playnite:`n  " + ($missing -join ", ") +
                "`nRename them in Playnite to match, or fix the names in Get-Cfg."
    }
    $msg += "`n`nNext: tag your games with Mood/... yourself, and run action 3 for a Session draft."
    $PlayniteApi.Dialogs.ShowMessage($msg, "Finish My Games - structure")
}

# ---------------------------------------------------------------------------
#  2) Filter presets
# ---------------------------------------------------------------------------

function Invoke-CreatePresets {
    param($actionArgs)
    $c = Get-Cfg

    $shelf = Find-Status $c.Status.Shelf
    $ever  = Resolve-Status $c.Status.Evergreen
    $plan  = Find-Status $c.Status.Backlog
    $hold  = Find-Status $c.Status.Hold

    if ($null -eq $shelf) {
        $PlayniteApi.Dialogs.ShowMessage("Status '$($c.Status.Shelf)' not found. Fix the name in Get-Cfg or in Playnite first.", "Finish My Games")
        return
    }

    $focus  = Resolve-Tag $c.Tags.Focus
    $hype   = Resolve-Tag $c.Tags.Hype
    $short  = Resolve-Tag $c.Tags.SShort
    $medium = Resolve-Tag $c.Tags.SMedium
    $action = Resolve-Tag $c.Tags.Action
    $advent = Resolve-Tag $c.Tags.Adventure
    $light  = Resolve-Tag $c.Tags.Light
    $simple = Resolve-Tag $c.Tags.Simple

    $created = @()

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.Tag = New-IdFilter @($focus.Id)
    [void](Resolve-Preset "Focus" $s); $created += "Focus"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.Tag = New-IdFilter @($hype.Id)
    [void](Resolve-Preset "Hype" $s); $created += "Hype"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    [void](Resolve-Preset "Evening" $s); $created += "Evening"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    $s.Tag = New-IdFilter @($short.Id)
    [void](Resolve-Preset "30 min" $s); $created += "30 min"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    $s.Tag = New-IdFilter @($short.Id, $medium.Id)
    [void](Resolve-Preset "1h" $s); $created += "1h"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    $s.Tag = New-IdFilter @($action.Id)
    [void](Resolve-Preset "Action" $s); $created += "Action"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    $s.Tag = New-IdFilter @($advent.Id)
    [void](Resolve-Preset "Adventure" $s); $created += "Adventure"

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($shelf.Id)
    $s.Tag = New-IdFilter @($light.Id, $simple.Id)
    [void](Resolve-Preset "Chill" $s); $created += "Chill"

    # Backlog = Plan to Play + On Hold (candidates you intend / paused).
    $backlogIds = @()
    if ($plan) { $backlogIds += $plan.Id }
    if ($hold) { $backlogIds += $hold.Id }
    if ($backlogIds.Count -gt 0) {
        $s = New-Object Playnite.SDK.Models.FilterPresetSettings
        $s.CompletionStatuses = New-IdFilter $backlogIds
        [void](Resolve-Preset "Backlog" $s); $created += "Backlog"
    }

    $s = New-Object Playnite.SDK.Models.FilterPresetSettings
    $s.CompletionStatuses = New-IdFilter @($ever.Id)
    [void](Resolve-Preset "Fil rouge" $s); $created += "Fil rouge"

    $PlayniteApi.Dialogs.ShowMessage(
        "Presets created (or already present):`n  " + ($created -join "`n  ") +
        "`n`nStill to create by hand (date / playtime filters, ~20s each):`n" +
        "  Recently added = Date added: last month`n" +
        "  Unfinished     = backlog + Time played > 0`n`n" +
        "Pin the ones you use most.",
        "Finish My Games - presets"
    )
}

# ---------------------------------------------------------------------------
#  3) Seed Session tags from genres (draft). Only games without any Session/*.
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

    $touched = 0
    foreach ($game in $PlayniteApi.Database.Games) {
        if (Test-GameHasTagLike $game "Session/*") { continue }

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
#  Only the two actions that do MORE than a plain status change:
#    - Put on shelf : enforces the shelf cap
#    - Set as Focus : moves the single Focus tag off the previous game
#  Everything else is just a Completion Status change -> use Playnite directly.
# ===========================================================================

function GetGameMenuItems {
    param($menuArgs)

    $section = "Finish My Games"
    $defs = @(
        @{ D = "Put on shelf (respects the cap)"; F = "Invoke-SetShelf" },
        @{ D = "Set as Focus";                    F = "Invoke-SetFocus" }
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

function Invoke-SetFocus {
    param($actionArgs)
    $c = Get-Cfg
    $games = @($actionArgs.Games)
    if ($games.Count -ne 1) {
        $PlayniteApi.Dialogs.ShowMessage("Select a single game to set as Focus.", "Focus")
        return
    }
    $g = $games[0]
    $cap = Get-Cap
    $shelf = Find-Status $c.Status.Shelf

    if ($null -ne $shelf -and $g.CompletionStatusId -ne $shelf.Id) {
        if ((Get-ShelfCount) -ge $cap) {
            $PlayniteApi.Dialogs.ShowMessage("Shelf full ($cap). Free a slot before setting a new focus.", "Shelf full")
            return
        }
        [void](Set-GameStatus $g $c.Status.Shelf)
    }

    [void](Resolve-Tag $c.Tags.Focus)
    Remove-TagEverywhere $c.Tags.Focus
    $focusTag = Find-Tag $c.Tags.Focus
    Add-GameTags $g @($focusTag.Id)
    $PlayniteApi.Dialogs.ShowMessage("'$($g.Name)' is your new Focus.", "Focus")
}
