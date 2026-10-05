---
name: playnite-categorize
description: >
  Suggests which Playnite "Catégorie" tag(s) a video game should get, based on Didier's
  personal Notion taxonomy of game categories (page "Système de notation"). Use this
  whenever Didier gives one or more game titles and asks where they fit in his category
  system — phrases like "catégorise-moi X", "où je mets X", "X va où", "quelle catégorie
  pour X", or when he pastes a list of game titles to sort during a Playnite/Notion
  classification pass. Always trigger for this even if he doesn't name the skill directly
  — any request to sort, classify, or find the right Catégorie for a specific game title
  is this skill's job.
---

# Playnite categorize

## What this does

Given one or more game titles, look up each game on Steam, fetch Didier's live Notion
category definitions, and suggest which Catégorie tag(s) fit — with a short, direct
justification. This mirrors the manual process Didier and Claude worked through together
while splitting his oversized "Aventure" category bucket: read what the game's Steam page
reveals about its actual design, weigh that against the *foregrounded* experience (not a
superficial keyword match), and check whether a specific category and the generic "RPG"
tag both genuinely apply.

## Step 1 — Get the current category definitions, always live

Fetch the Notion page "Système de notation" (id `3a5109fb405f80aeb9ffe6e84ff274eb`) with
`notion-fetch` every time this skill runs. Don't reuse definitions from a previous run or
from this file — Didier edits this page regularly (new categories, refined wording), and
a stale copy would silently drift from what he's actually using in Playnite.

**If this fetch fails for any reason** (permission denied, connector not authorized,
network error) — stop right there. Report the failure plainly and do not suggest any
category name at all, not even a plausible-sounding one from general genre knowledge.
The entire point of this skill is to only ever match against Didier's real, curated list
— a suggestion produced without that list is exactly the kind of unvetted category
invention he's built this whole system to avoid, even if it happens to be labeled as
"unverified." Half-completing the task (a name with a missing description) is worse than
refusing outright, because a name alone is easy to mistake for a real match.

The page has three tables:

- **Humeurs** — broad mood groupings (Action, Aventure, Détente, Gestion, Réflexion,
  Simulation). Not this skill's output, but useful context for sanity-checking a call.
- **Fonctionnalités** — objective mechanical facts (Roguelite, MMO, Couch-gaming, PvP...).
  These map to Playnite *Features*, not *Categories* — ignore them for this skill's output.
- **Catégorie** — the real target list, roughly 55+ fine-grained values with a one-line
  **Description**, a **Mots-clé** column, and an **Humeur** each. This is what you're
  matching the game against. (Table title as of the last correction: "Catégorie", with the
  accent — the earlier "Categorie" spelling was a typo Didier fixed in Notion, so match on
  the table's position/content rather than hardcoding an exact title string, in case it's
  edited again.)

**Use the Mots-clé column as a supporting signal, not a search target.** It exists to
surface the main ideas behind a category in a few words, and sometimes it genuinely names
a facet the prose description doesn't spell out — e.g. Metroidvania's keyword list once
implied platforming was required until Didier trimmed it back because some Metroidvania
games barely platform at all; Zelda-like's keywords dropped "Histoire" because the story is
a throughline you don't actually need to follow, not a foregrounded pillar. When a keyword
isolates something the game's own description/tags genuinely support but that your
reasoning hadn't weighed yet, it's worth revisiting the call. But don't go hunting for a
keyword that happens to appear somewhere in the game's blurb and treat that lexical
coincidence as proof — that's the same "which words overlap" trap Rule 1 already warns
about, just one level removed. A real second-round audit against a keyword refresh turned
up 9 candidate changes and only 5 survived independent verification; the 4 rejected ones
all traced back to a keyword echoing a word already in the description without adding any
new axis of judgment (e.g. seeing "plateau" in a game's blurb and reflexively pulling in
Jeu de société's keyword, when the game is not actually a board-game adaptation).

## Step 2 — Research the game

Search for the game's Steam store page and read it: description, community genre/tags,
and — if visible — a couple of reviews that describe actual gameplay rather than just
praise or complaints. If the game isn't on Steam, or you can't find a confident match
(obscure indie, several same-named games, a delisted title), say so plainly instead of
guessing from the title alone. A wrong classification is worse than an honest "I'm not
sure, here's what I found."

## Step 3 — Apply the decision protocol

This is the part that actually requires judgment, not keyword matching. Rules Didier and
Claude arrived at together, working through concrete cases, in order of importance:

1. **The test is "what experience is foregrounded", not "which words overlap".** Steam
   tags are a starting point, not the answer — read the description and reviews to figure
   out what a player actually spends their time *doing*, and what the game wants them to
   care about most.

2. **A specific Catégorie and the generic "RPG" tag are different axes, not competitors.**
   RPG answers "is character progression + build choices + story genuinely the priority,
   all three at once?" A specific category (Souls-like, Metroidvania, Deckbuilding,
   Tactical, Zelda-like, Hack'n slash...) answers "what mechanical system actually carries
   the game?" A game can honestly earn both — e.g. Shards of Order is a full RPG
   (leveling, skill trees, equipment, story-forward) whose combat happens to resolve
   through deckbuilding. Having a specific category is not a reason to withhold RPG, and
   having some RPG-shaped stats is not a reason to skip the specific category.

3. **RPG needs all three — progression, build choices, AND story — genuinely foregrounded.**
   A hack'n slash roguelite with light stats and thin narrative (the Hades type) doesn't
   clear that bar just because it technically has a bit of each; none of the three is
   actually the point of the game. Don't add RPG reflexively — check whether a player
   would describe the character-building and story as what the game is *about*.

4. **Multi-tag when two categories describe genuinely different axes of the same game;
   don't multi-tag when they're two names for the same thing.** Dungeon crawler
   (structure: rooms explored floor by floor) and Hack'n slash (loop: loot/stats against
   hordes) can both legitimately apply to the same game. Two categories whose definitions
   largely restate each other should not both go on — pick the one that's the real driver.
   This same "two names for the same thing" test applies to a *proposed new* category too
   (see rule 8) — a new name that just rephrases an existing definition is a duplicate, not
   a discovery.

5. **A card-based game that doesn't build or evolve its deck over a run is "Cartes", not
   "Deckbuilding".** Check the exact current wording of both definitions fetched in Step 1
   — this distinction is subtle and Didier cares about getting it right.

6. **Two similarly-named categories' actual axis of distinction can change — always
   re-derive it from the current wording, never from memory of how it used to work.**
   Casse-tête vs. Puzzle used to be split by duration (a one-off riddle vs. a puzzle system
   running the whole game); Didier later redefined them around mechanism instead (logic-led
   solving vs. search/collect/assemble/position of elements or clues) — the same two names,
   a completely different test. Reapplying the old duration-based reasoning after that edit
   got at least one call backwards even for Didier himself: he'd just decided, under the old
   wording, that a physical puzzle-box game should keep Casse-tête over Puzzle — but under
   the new mechanism-based wording, that same game (built entirely around finding, combining
   and positioning hidden objects) is a textbook Puzzle case. Rule 5's advice generalizes:
   whenever two categories look like they compete for the same game, read both definitions
   fresh, right now, rather than pattern-matching against a past case that used old wording.

7. **When only adding a category to a game that already has at least one — not replacing
   or removing anything — a lower bar is fine: reasonable, well-grounded doubt is enough,
   full certainty isn't required.** An addition is low-risk and easy to undo, so don't
   withhold it just because the evidence falls short of ironclad; the same leniency applies
   to a game that currently has *no* Catégorie at all, since suggesting its first one is
   also purely additive. Reserve the strict "does this really survive scrutiny" bar for
   calls that would remove or replace something already there, or add a categorization to
   an already-categorized game where the addition itself is what's in question rather than
   just how confident you are in it (e.g. arguing a whole different category should apply
   instead). Concretely: a specific, named piece of evidence pointing the right way (a
   Steam tag, a line in the description, a keyword that isolates a real facet) clears the
   bar for an addition even without a second source confirming it; a bare intuition with
   nothing citable behind it doesn't.

8. **Don't stretch a mediocre fit just because it's on the list — but don't invent casually,
   and never invent a near-duplicate of something that already fits.** Two checks, in order,
   before you ever propose something new:

   a. *Is the gap real?* Does your best existing-category match actually describe what's
      foregrounded here, or does it just overlap a bit more than the others? If every
      existing Catégorie is only a loose "closest available" fit, say so rather than quietly
      picking the least-bad one — that's exactly how a bucket like the old oversized
      "Aventure" category happens again.

   b. *Is it actually new?* Before finalizing a proposal, compare its definition against
      every category you're about to suggest for this same game, and against the full list
      from Step 1 — not just a quick title scan, actually reread the neighboring
      definitions. If an existing category's definition, read fairly, already covers the
      mechanic — even in different words — that's not a gap, that's rule 4's "two names for
      the same thing," and the existing category is the answer, full stop. For example: a
      stealth game whose foregrounded loop is avoiding detection and preferring discreet
      takedowns over confrontation is already "Infiltration" (Éviter la détection ...
      élimination discrète privilégiée à la confrontation directe) — proposing a new category
      whose definition just restates that sentence differently is not a discovery, it's a
      duplicate, and should never be suggested.

   The bar for a genuinely new proposal is high and it should be rare: it must name a
   mechanic or experience structurally distinct from every existing definition, not a
   narrower or differently-worded restatement of one that already exists — "Incrémental"
   and "Combinaisons" cleared that bar; "a Metroidvania set underwater," or any rewrite of
   an existing definition, would not. When unsure whether the gap is real or you're just
   being picky, lean toward the existing category and say explicitly why the fit, while
   imperfect, is still the right one.

   **Naming format, when you do propose one:** a Catégorie name is a short noun phrase —
   one word, or at most a handful, matching the existing list's style ("Autobattler",
   "Point & click", "Jeu de société", "Défense de tours") — **never a descriptive clause or
   full sentence.** If the idea needs a sentence to express, that sentence belongs in the
   Description field, not the name. A proposal titled "élimination discrète privilégiée à
   l'affrontement direct" is malformed on its face, independent of whether the underlying
   idea has merit — check the candidate name itself reads like every other row in the
   Catégorie column before offering it.

## Step 4 — Answer directly

For each game, give one of three kinds of answer — don't blend them into vague hedging:

- **A confident match.** The suggested Catégorie(s) — one or more — with a short
  justification (2-4 sentences), citing the specific bit of the Notion definition and the
  specific bit of Steam-page evidence that drove the call. Never a bare list of names with
  no reasoning.
- **A new category proposal**, per rule 8 above, when nothing existing genuinely fits —
  rare, and only after the two checks in rule 8 (real gap, not a duplicate). Explain
  briefly why each closest existing candidate falls short, then give: a short noun-phrase
  **name** (never a sentence), a one-line **Description** (the sentence lives here), 2-3
  **Mots-clé**, and a candidate **Humeur** — clearly labeled as a proposal Didier would
  need to add to Notion himself (never invent it silently into the "suggested" bucket as
  if it already exists in his system).
- **Genuinely ambiguous / information missing** (can't confirm whether a deck evolves,
  can't find the game, two Steam listings share a name) — say so explicitly and ask rather
  than picking one arbitrarily.

Match Didier's own tone when he does this exercise himself: opinionated, willing to say
"no, I don't think X fits, here's why", no hedging for the sake of politeness, and
comfortable pushing back if an obvious-looking match doesn't actually survive the
"is this really the foregrounded experience" test — that same directness applies to
saying "none of these are actually right, here's what's missing," and equally to saying
"no, that's not a new category, X already covers it."

## A note for bulk/offline passes (not single-game lookups)

If this skill is being run across many titles at once from an export rather than live
against Playnite (e.g. an audit pass), be aware Didier's library has duplicate entries for
some titles — the same game imported more than once, sometimes with different current
Catégorie values on each copy. Record each game's *current* Catégorie set alongside your
suggestion, not just its name — that fingerprint is what lets a change be matched back to
the right copy later (or safely applied to more than one copy, if they're indistinguishable
and share the same current set) instead of guessing which entry "the game" refers to.
