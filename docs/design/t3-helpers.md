# Tier-3 helpers: each kingdom calls its campaign ally, plus one new tier-3 unit per kingdom

Owner: game-designer. Written 2026-09-27 (task TH.D1). Source of truth for tasks TH.* (section 13).
User request (JS, 2026-09-27, verbatim, in order): "add to the plan t3 all have 1 wizard help to hire possible to hire u the
already t3 so some for and more t3 unit and helper to balance out all" · "yes the t3 is the guys that help them in the
campaign" · "it will be in cutscene and all so try to make them equally as epic as the main wizard and plz balance the for good
player rush it at same time main wizard reach the ultimate skill" · later note: "when ask question for 3 take in mind thats in
campain 3 etc".
Builds on `story-episode-1.md` ("ep1": cast, missions M0-M4, Episode 2 direction), `research.md` ("rs.": Stronghold / Citadel,
prices, bot timings), `levels.md` (level curve, E at level 4), `level-boons.md` ("lb."), `tier3-extras.md` ("t3.": Mage Archer
unique-NPC pattern), `titans-2.md` ("t2.": the Wildcaller), `champions.md` ("ch."), `cinematics.md`, `rush-balance.md` ("rb.").
Every name, line and number here is our own. Metres, seconds, `m:ss` since the navmesh was ready.

## 0. Reading of the request (my verdicts)
| # | Reading | Verdict |
|---|---|---|
| R1 | At tier 3 (the **Citadel**) every kingdom can call **one helper**: the character who helps that kingdom's wizard in the story | Kept. Called at the **Citadel keep**, slot N (section 3) |
| R2 | Helpers are as epic as the main wizards (cutscenes, model, VFX, voice) | Kept: wizard budget, portrait, video model, arrival set-piece, Theatre reveal (section 10) |
| R3 | "More T3 units so the four kingdoms stay balanced" + JS's ideas (genie, spy, vampire, "more suggestion") | **One new T3 unit per kingdom (4)** + **one neutral T3 hire (the Genie)**: every kingdom ends with **4 tier-3 options + 1 helper**; a menu of 3-6 candidates per kingdom lets JS pick (section 7) |
| R4 | A good player rushing T3 gets the helper when the wizard reaches its "ultimate" | Our wizards have **no formal ultimate** (`levels.md`: "Spell 3 (E) is not an ultimate"). The closest thing is **spell 3 (E)**, the strongest, learnable at **level 4 = 8:00-10:00** for an active player. Target: **helper on the field 9:30-10:15 for a good rusher, within ~1 min of the wizard's level 4** (section 6) |
| R5 | "Campaign 3 etc." | The story numbers missions M0-M4 in Episode 1; **M3 (Sighing Wood) is where Maelis first appears**. No "Episode 3" exists yet. I read it as: each helper's campaign moment comes first and unlocks its cutscene; the others arrive in later episodes. Asked in Q2 |

## 1. The four helpers (who they are, where they are in the campaign)
| Kingdom / wizard | Helper (id) | Title | Campaign link (existing unless marked) | Campaign moments (Ep1 = Episode 1) |
|---|---|---|---|---|
| Fire / Vessa | **Torren "Old" Vey** (`helper_vey`) | The Storm-Sword | ep1 2: the Master's old sword, Vessa's first teacher; saves her in the assassination night, is lost, returns in a storm | Ep1 V1 + **M0** (at her side), M1 (memory), **M4** (the rescue, VIDEO `m4_storm`), Episode 2 guide |
| Shadow / Malrik | **Mother Hush** (`helper_hush`) | The Knife That Never Misses | ep1 2: Malrik's chief assassin, leads the attempt on Vessa, flees "a recurring threat for Episode 2" | Ep1 V1 + **M0** (mini-boss), Episode 2 at Malrik's side |
| Nature / Ysolde | **Maelis Oakenhollow** (`helper_maelis`) | The Wildcaller | ep1 2: "Ysolde's warden"; `t2.` 5 already built her as Nature's unique druid | Ep1 **M3** (guards Root Heart RH3, a skill-check foe), Episode 2 fights beside Ysolde when Nature joins Fire |
| Ice / Torvald | **Aldra Stillwater** (`helper_aldra`) **NEW, proposed** | The Glass Warden | **No Ice ally exists in the story docs.** Proposal: the last of the Stillwater wardens who have kept the Heartfrost of Glasswater Mere "for a hundred winters" (Torvald's L8 in M2); a rune-carver who **carves and wakes the Sleeping Sentinels** and raises the shore walls "from afar" in M2 | Ep1 **M2** (a voice + one silhouette on the ridge when the Sentinels wake; a 2-line patch for 19.D2), Episode 2 at Torvald's side when Ice joins Shadow |
Aldra look (new): about 1.9 m, a tall woman in her fifties, grey-blond hair in a crown braid threaded with glass beads, a long
coat of white felt over a hauberk of **glass scales** (ice that never melts), a rune-chisel staff tipped with a clear crystal
the size of a fist; her colour **glass-teal `(0.62, 0.95, 0.88)`** (distinct from Torvald's `(0.55, 0.80, 1.00)`).
**Maelis moves**: she stops being the Elder Circle's slot-C option (`t2.` 5) and becomes Nature's helper (same person, same
kit family, upgraded); the Elder Circle's C slot gets Nature's new T3 unit (section 7). Two Maelis would break the story.
**Mirror**: in a mirror both teams get the same helper, as both get the same wizard (the helper names take no B variant).

## 2. What a helper is (vs the wizard, champions and the unique NPCs)
| | Wizard | Helper (new) | Champion / Mage Archer |
|---|---|---|---|
| Control | Commandable, F / Q / E | **Autonomous** + a **stance** the player sets (section 2.1) | Autonomous (bounties) |
| Level | 1-8, own XP | **= its bonded wizard's level**, always (no own XP) | Own XP, 1-6 / 1-9 |
| Kit | 3 spells with ranks, mana | **3 abilities + 1 passive**, cooldowns only, no mana; ability 3 (signature) from level **5** | Archetype + class tree |
| Items, purse, boons | Yes / - / yes | **None** (no shop trips: it stays in the fight) | Items + purse |
| Death | Respawns (1v1 rules) | **Fallen**, revived at the keep for essence (section 3) | Fallen, revive |
| Count | 1 | **1 per team** | 3 + 1 unique |
**Recommendation: autonomous with a stance** (Q4). Why: the keys F / Q / E belong to the wizard and every other letter is taken
(`lb.` 9); a second micro-heavy hero doubles the APM of a good player; the codebase already has the autonomous pattern (champions,
Mage Archer, Old Vey in the story: ep1 Q5 recommends "autonomous ally"); the stance keeps the player in charge of *where* it fights.
### 2.1 Stances (the one player lever; not an order, so `is_commandable()` stays false)
| Stance | Behaviour | Default when |
|---|---|---|
| **Escort** (default) | Stay 3-7 m from the bonded wizard; fight what threatens her / him first (the story brains of 19.A2) | Called |
| **Vanguard** | Follow the largest own soldier group (the Mender's centre rule, ch. 8.3) and fight with it | - |
| **Hold home** | Stand between the keep and the Citadel's door, fight intruders within 20 m | - |
Set by 3 buttons on the helper's inspect card (click, or Z / X / C while it is inspected: the card's own slot letters, no
new letter key; 2026-09-29). Bounty flags do **not** steer helpers (they are
not mercenaries). If the wizard is dead, Escort acts as Vanguard until the respawn. Brain rules R2 (flee under **25 %** HP to the
keep, rest 2 % / s within 15 m) and R4 (fight) of ch. 8.1 apply.

## 3. Calling, one per team, death, revive
| Rule | Value |
|---|---|
| Where | The **keep card slot r1c4, key N**: the slot that said "Upgrade to Stronghold / Citadel" says **`Call Old Vey`** (the kingdom's helper) once the Citadel is complete. Same key, the tier ladder continues. Queue = the keep's upgrade lane (beside the worker queue). *As built (tiers.md 3, ui-hud.md, 2026-09-29): the tier button is r1c2 key X, the tier-3 unit r1c3 key C, Call / Revive r1c4 key **V**; the keys never move (X stays empty at the Citadel).* |
| Gate | Research on: a completed **Citadel** (`"Needs a Citadel"`). Research off: an own completed **Lair** (`"Requires a Lair"`, t3. 2 rule). `helpers_enabled` false: hidden |
| Price | **350 crystals + 200 essence**, **60 s**, pop **4** (from the queue on, while alive and while fallen). No upkeep, no dismiss |
| Arrives | At the keep door, at its wizard's **current level**, full HP, stance Escort; arrival set-piece + voice line (10.2) |
| One per team | `"Already called"` while queued, alive or fallen. 2v2: **one per team**; the first teammate to call picks (its kingdom's helper), bonded to that wizard |
| Refusals (first that applies) | `"Needs a Citadel"` / `"Requires a Lair"`, `"Already called"`, `"Population cap reached"`, `"Not enough crystals"`, `"Not enough essence"` |
| Death (skirmish, 1v1 and 2v2) | Intent `Fallen`; body fades after 3 s; **never ends a match** (1v1 rule unchanged: a side loses with no living building). Victim XP **100 + 30 x level** (a wizard is 120 + 30 x level), kill essence **40 + 10 x level** |
| Revive | Slot N becomes **`Revive Old Vey`**: **120 + 20 x level essence**, back after **25 + 5 x level s** (L4 45 s, L8 65 s) at the keep door. Refusals `"Not fallen"`, `"No home"` (no living keep), `"Not enough essence"`. Also from the helper's portrait slot |
| Keep lost / tier lost | A living or fallen helper is kept; revive needs a living keep of any tier; a first call needs the Citadel |
| Warnings (both teams) | `The enemy calls Old Vey!` at queue start (own: `Old Vey answers the call`), `Old Vey takes the field!`, `Old Vey has fallen`, through `Events.titan_event(team, &"helper", what)` (no minimap diamond; a gold ring icon on the minimap like the wizard's) |
| Missions | `helpers_enabled := false` in missions: the story's own scripted units stay (`torren_vey` 19.C11, Hush 19.C12, Maelis at RH3); they **reuse the helper models, VFX and ability code** with the story numbers. A later mission may switch helpers on |

## 4. Kits (level L = the wizard's level; ability amounts x `(1 + 0.04 x (L - 1))`: L4 x1.12, L8 x1.28)
### 4.1 Stats
| Helper | HP L1 / per level (L4 · L8) | Armor | Damage L1 / per level (L4) | Range | CD | DPS L4 | Speed | Sight | Kind |
|---|---|---|---|---|---|---|---|---|---|
| Old Vey | 700 / +50 (850 · 1 050) | 20 | 26 / +3 (35) | 2.0 melee | 1.2 | 29 | 5.0 | 13 | melee |
| Mother Hush | 520 / +35 (625 · 765) | 10 | 24 / +3 (33) | 1.6 melee | 1.0 | 33 | 5.4 | 13 | melee |
| Aldra Stillwater | 620 / +45 (755 · 935) | 15 | 18 / +2 (24) | 9.0 | 1.3 | 18.5 | 4.4 | 13 | ranged (glass shard, 24 m/s) |
| Maelis Oakenhollow | 560 / +40 (680 · 840) | 5 | 20 / +2.5 (27.5) | 9.5 | 1.25 | 22 | 4.9 | 14 | ranged (thorn bolt, t2. 5.2) |
Compare: Vessa L4 425 HP / 20 dmg; Mage Archer L3 ~580 HP / 24 DPS. CC on helpers uses `hero_mult` (half duration).
Helpers take no research modifiers; Shadow **Souls** count Hush's kills (Mage Archer rule). They are not soldiers (no Heat,
wares, veterancy, army boons).
### 4.2 Old Vey, the Storm-Sword (Fire): the blade in front of the fire
Vessa burns from range; Vey holds the line in front of her and dives what reaches her. Distinct from Sword champions: lightning
chains and a dash.
| Slot | Name (id) | CD | Effect | Autocast when |
|---|---|---|---|---|
| Passive | **Storm-Sworn** (`vey_storm_sworn`) | - | Every 3rd strike chains to 2 enemies within 5 m for 50 % of the hit. **Bond "The spark first"**: each Vessa Fireball that lands within 14 m of him takes 2 s off Chain Lightning (max once per 2 s) | - |
| 1 | **Lightning Lunge** (`vey_lunge`) | 12 | Dash up to 10 m through enemies to a target: **60** to it, **30** + `dazed` 0.5 s to each enemy on the path | An enemy targets the wizard within 10 m, else an enemy caster / ranged unit within 10 m |
| 2 | **Chain Lightning** (`vey_chain`) | 10 | Bolt jumps 5 times between enemies within 8 m: **45, 38, 32, 27, 23** (x0.85 per jump) | 3+ enemies within 8 m of each other in range 8 |
| 3 (L5) | **Stormcall** (`vey_stormcall`) | 70 | 8 bolts over 3 s on enemies within 12 m, **50** each; own units inside get `attack_cooldown_pct` -0.15 for 6 s (the story's Charged Ground, folded in) | 6+ enemies within 12 m, or an enemy titan / helper within 8 m |
### 4.3 Mother Hush, the Knife That Never Misses (Shadow): the assassin
Malrik drains and endures; the Mage Archer snipes from 11 m; Hush is the **melee dive** that finishes heroes.
| Slot | Name (id) | CD | Effect | Autocast when |
|---|---|---|---|---|
| Passive | **Mouthless Veil** (`hush_veil`) | - | After 4 s without attacking or being hit she is **veiled** (smoke trail thins): enemies and towers farther than **5 m** cannot auto-target her; her first strike out of the veil **+60 %**. **Bond "The Bishop's knife"**: enemies hit by Malrik's Shadow Lance or Soul Siphon in the last 4 s take **+15 %** from her | - |
| 1 | **Blink Strike** (`hush_blink`) | 10 | 0.5 s violet ring at the target, then she appears behind it: **55** (story 19.C12 telegraph). Range 14 | Lowest HP % enemy hero / helper / caster within 14 m |
| 2 | **Smoke Cloak** (`hush_smoke`) | 22 | Smoke r 4, 5 s at her spot: own units inside get `powder_smoke` (ranged x0.75); she gets `shroud` 3 s and enemies targeting her drop her | HP < 50 %, or 3+ enemies target her |
| 3 (L5) | **Night of Knives** (`hush_knives`) | 75 | She vanishes 1.5 s (untargetable), then 6 strikes 0.25 s apart on up to 6 enemies within 10 m: **40** each, heroes / champions / helpers **x1.5** + `marked` 4 s; she reappears at the last | 4+ enemies within 10 m, or an enemy wizard under 40 % HP within 10 m |
### 4.4 Aldra Stillwater, the Glass Warden (Ice): the warden of the wall
Torvald chills and shields everyone around him at once; Aldra **picks** who lives, lines up freezes and wakes a Sentinel.
| Slot | Name (id) | CD | Effect | Autocast when |
|---|---|---|---|---|
| Passive | **Glasswater Ward** (`aldra_ward`) | - | Aura r 8: own units take **-12 %** from `ranged` and `spell` hits (multiplies with Canopy / smoke). **Bond "Winter's mirror"**: enemies hit by Torvald's Rime Bolt or Flash Freeze within 12 m of her get **+34 frost** (Frostbite meter, ungated, rs. 3.3) | - |
| 1 | **Shatterglass** (`aldra_shatter`) | 11 | A 12 m line, 1.5 m wide: **50** + **34 frost** to up to 6 enemies | 3+ enemies in such a line, or a charging / mounted enemy |
| 2 | **Glass Aegis** (`aldra_aegis`) | 20 | Shield **100** for 6 s (`add_shield`) on the 4 lowest-HP % own units within 10 m (wizards and herself included) | 2+ own units under 50 % HP within 10 m |
| 3 (L5) | **Wake the Sentinel** (`aldra_sentinel`) | 90 | A **Rime Colossus** (the Frost Hall unit, level 1) bursts from ice at a point within 10 m and fights 30 s: pop 0, 0 XP / essence, max 1 (the M2 Sleeping Sentinels, now hers) | 5+ enemies within 12 m, or an enemy titan within 12 m |
### 4.5 Maelis Oakenhollow, the Wildcaller (Nature): the wild in her call
Ysolde heals and summons Saplings; Maelis never heals (rs. Q3) and controls with thorns, wolves and stags. Her `t2.` 5.5 kit
stays, re-slotted; `t2.` 5.2-5.4 (champion XP, class tree, purse, Lair call) are superseded by sections 2-4 here.
| Slot | Name (id) | CD | Effect | Autocast when |
|---|---|---|---|---|
| Passive | **The Forest Has Opinions** (`maelis_opinions`) | - | Her Spirit Wolves and own Saplings within 12 m attack 20 % faster and move +1.0. **Bond "Ysolde's warden"**: enemies rooted by Ysolde's Thornburst take **+20 %** from Maelis and her wolves | - |
| 1 | **Thornsnare** (`thornsnare`) | 14 | As t2. 5.5: ring, 0.6 s, **20** + `rooted` 1.2 s (ground only) | t2. 5.5 |
| 2 | **Call the Pack** (`call_the_pack`) | 28 | As t2. 5.5/5.6: 2 Spirit Wolves, 20 s (their HP x the level factor) | t2. 5.5 |
| 3 (L5) | **Wild Stampede** (`wild_stampede`) | 50 | As t2. 5.5 (was L6): 16 m line, **45** + knockback 1.5 m + `dazed` 0.5 s, max 8 | t2. 5.5 |

## 5. Interaction with level boons (`level-boons.md`)
- Boons stay **wizard-only** (lb. D3): helpers never draw boons, have no Luck, and are **not** touched by army boons or wizard
  auras (Mending Presence, Rally Standard, Iron Discipline, Legion's Oath, Banner): they are not soldiers, like champions.
- A helper's **level follows the wizard**, so every level-up gives the wizard its boon pick **and** grows the helper (HP,
  damage, ability factor; signature at level 5). Boons that raise the wizard's power make the **Bond** passives stronger for
  free (Fireball, Shadow Lance / Soul Siphon, Rime Bolt / Flash Freeze, Thornburst hit harder or wider, the bonds follow them).
- **One new boon** (the 41st, lb. 5 Epic, family `army` for the bot): **Sworn Bond** (`sworn_bond`, stack 1): the bonded
  helper `max_hp_pct` +0.15, ability amounts +15 %, revive time -30 %. **Eligible only** while the team's helper is queued,
  alive or fallen and this wizard is its bond (lb. 2 offer filter "requires" `&"helper"`). Tier value 80.
- The enemy wizard earns XP for a helper kill (victim table row, section 3), so killing the helper feeds the killer's boons.
- VFX: the helper's arrival and Stormcall-type bursts use their own budget; never more than 2 boon bursts per wizard (lb. 10).

## 6. Timing: a good T3 rush vs the wizard's "ultimate" (E, level 4)
Research and keep prices from rs. 2.1-2.4 (no trade: gold folded into crystals). A **good rusher** = keeps ~10-12 soldiers for
the 3:30-4:30 first attack (rb.), both research buildings early, tier-2 in both tracks at once.
| Step | Theoretical floor (no army) | Good rusher | Price |
|---|---|---|---|
| Hall complete | 1:30 | 1:45 | - |
| Forge / Sanctum placed -> done | 2:30 -> 3:10 / 2:45 -> 3:25 | 3:00 -> 3:40 / 3:15 -> 3:55 | 125 + 125 |
| Tier-1 tech + keystone (magic) | 3:10 -> 3:50 / 3:25 -> 4:00 | 3:40 -> 4:20 / 3:55 -> 4:30 | 100 · 50 + 50 e |
| **Stronghold** (60 s) | 3:50 -> 4:50 | 4:40 -> 5:40 | 200 |
| 2 tier-2 in parallel (55 s) | 4:50 -> 5:45 | 5:50 -> 6:45 (crystals for the army first) | 200 (tech, no trade) + 75 + 125 e |
| **Citadel** (90 s) | 5:45 -> **7:15** | 7:15 -> **8:45** (waits ~30 s on crystals) | 300 |
| **Call the helper** (60 s) | 7:15 -> **8:15** | 8:45 -> **9:45** | 350 + 200 e |
| Wizard level 4 (E learnable) | - | **8:30-9:30** (levels.md 8:00-10:00; a tech rush fights a bit less) | - |
Essence check (good rusher at 8:45): 150 start + ~525 trickle + ~100 kills - 175 spent = **~600 >= 200**. Crystals ~1 450 in tech
by 9:45 of the ~3 600 gathered: a real army-or-tech choice, not a free win.
**Result: the helper walks out 0-75 s after the wizard can learn E** (window target: -60 s .. +90 s). The normal bot (Citadel
11:00-12:30) gets it at **12:00-13:30**, before its first titan (13:00-14:30); the hard bot (Citadel 9:30) at **~10:40**.
Why the keep and not the Lair: the Lair (300 crystals + build) would push the rush to ~11:00, a full level late.
Knobs if the rush lands too early (Bot Lab section 11): call time 60 -> 75 s; price 350 -> 400; signature level 5 -> 6.

## 7. More tier-3 units: JS's ideas placed, a menu to pick from, and the recommended set
### 7.0 JS's three ideas (2026-09-27: "genie strong lighting dmg", "spy ... another playstyle", "vampire strong melee with life steal")
| Idea | Where | Why there |
|---|---|---|
| **Genie** (strong lightning) | **Neutral, hireable by any kingdom** at T3: the **Stormbottle Genie** (`stormbottle_genie`) | Lightning is **no kingdom's element**: it is the Master's storm, Old Vey's mystery (ep1 2). A kingdom unit would break that; a neutral bottled fragment of the storm deepens it (it crackles louder near Vey). Alternative: Fire only (Vey's side) |
| **Spy** (another playstyle) | **Fire**: the **Ashveil Saboteur** (`ashveil_saboteur`) | Fire already owns black powder (Cinderlocks, Salamander Oil): a disguised powder-sapper is its alchemy turned sly. Shadow was the obvious home but gets the vampire; Fire gains a non-combat playstyle instead of more raw power (it is the strongest kingdom) |
| **Vampire** (strong melee, life steal) | **Shadow**: the **Nightblood Reaver** (`nightblood_reaver`) | Shadow is the lifesteal kingdom (Shadow Lance, Soul Siphon, the Knight); a melee duelist that drinks is its fantasy, and fire (Fire's whole kingdom) is its counter |
### 7.1 The menu: candidates per kingdom (★ = recommended pick; one line each: role · fantasy · counter)
| Kingdom (slot) | Candidates |
|---|---|
| **Fire** (Dragon Roost X) | ★ **Ashveil Saboteur**: spy / sapper · looks like an enemy worker, plants powder charges, reads enemy queues · towers, Seers, any hero within 8 m · **Kiln Golem**: front-line tank · a walking furnace with a burn aura · chill quenches it, range · **Phoenix Herald**: flying support · on death a burning egg hatches it back in 8 s · kill the egg, anti-air · **Emberlance Duelist**: fast hero-hunter infantry · burning rapier, lunges at casters · armor, shields · **Sunforge Mortar**: incendiary siege crew · sets building roofs ablaze · dives, cavalry |
| **Shadow** (Gloom Hall N) | ★ **Nightblood Reaver**: vampire duelist · strong melee, drinks 35 % of damage, frenzies at low HP · fire (halves its drinking), kiting ranged · **Dusk Wraith**: flying anti-caster · a masked shroud that drains mana · ranged / towers x2 · **Bonecaller Hierophant**: Souls spender · raises the fallen as Risen · area damage, focus it first · **Gloomweaver Spider**: trapper · webs root cavalry · fire, flyers · **Mirrorshade**: mimic · copies the last enemy it touched for 20 s · burst before it copies |
| **Ice** (Glacier Den X) | ★ **Shardguard**: anti-dive halberdier · stops a charge and freezes the rider · spells, armor pierce · **Hoarfrost Oracle**: seer · reveals disguised / veiled units in r 10, slows projectiles in a dome · dives · **Glacier Skater**: fast skirmisher · +50 % speed on frozen water and the river · land maps, cavalry · **Avalanche Caller**: siege caster · snow slides on buildings · hunters, cavalry · **Rime Wolfpack**: 3 frost wolves as one squad · pack hunting · area damage |
| **Nature** (Elder Circle C, Maelis's old slot) | ★ **Briar Roc**: flyer · a bark-and-thorn bird that roots from the air · anti-air · **Sporemother**: area denial · spore carpets slow and reveal · fire · **Hivebearer**: walking hive · wasp swarms (DoT) on clumps · fire, area spells · **Moonstag Shifter**: shapeshifter · stag (fast) / bear (tank) forms · CC in the swap · **Rootwarden Shaman**: growth-ring booster · rings grow twice as fast near it · focus it, dives |
| **Neutral** (tavern, 1 per team, from the Citadel) | ★ **Stormbottle Genie**: lightning artillery · a storm fragment in a brass bottle · dives, Hush, silence (Dusk Wraith drain) · (the Spy could move here instead if JS prefers Fire keep the Kiln Golem) |
Recommended set: **Fire Saboteur, Shadow Reaver, Ice Shardguard, Nature Briar Roc, neutral Genie** (JS picks in Q3; any ★ can be
swapped for a menu line: the stat sketch of a swapped-in unit is TH.D2's job).
Gate: `required_keep_tier` 3 (t3. 2 rules, `"Needs a Citadel"` / `"Requires a Lair"`), `expansion` true, hidden in missions. The
Genie: hired at either **tavern** (`Y` window, a "Wonders" row) by a team with a Citadel; `"Already hired"`, max 1 per team.
### 7.2 Stats sketch of the recommended set (level 1; CE / PE of `kingdom-ice.md` 9; knobs for TH.D2)
| id | HP | Armor | Dmg / range / CD (DPS) | Speed | Cost | Pop | Train | kill_xp | CE | PE | Special |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `ashveil_saboteur` | 200 | 0 | 10 / 1.5 / 1.2 (8.3) | 5.6 | 200 | 2 | 35 | 100 | 4.2 | 4.2 | **Disguise**: out of combat the enemy sees an own worker (model, name, minimap dot); enemy auto-aggro ignores it; revealed by attacking, by a tower / keep within 6 m, or by an enemy hero / Oracle within 8 m; re-disguises after 8 s unseen. **Powder Charge** (cd 45): 3 s plant on an enemy building (reveals), 5 s fuse: **250** to it (x1.5 breaching) and its training / research **paused 10 s**. **Eavesdrop**: while disguised within 12 m of an enemy building, its owner sees that building's queue. Max 4 alive |
| `nightblood_reaver` | 480 | 10 | 26 / 1.8 / 1.3 (20) | 5.0 | 260 | 3 | 40 | 130 | 15.7 | 11.8 | **Nightblood**: heals **35 %** of damage dealt. **Blood Frenzy** (cd 30): under 40 % HP, +30 % attack speed and 60 % drinking for 5 s. **Sunburn**: any fire hit (Fire units, Fireball, burn) halves its drinking for 4 s |
| `shardguard` | 440 (Ice +20 % in) | 25 | 18 / 2.4 / 1.5 (12) | 4.0 | 225 | 3 | 36 | 115 | 13.0 | 7.3 | **Hold the Line**: the first charge, lunge or blink that ends within 2.4 m of it each 10 s is stopped and the attacker `frozen` 1.0 s (heroes 0.5). **Challenge** autocast every 14 s: `taunted` 2.5 s on enemies within 5 m that attack an own ranged unit |
| `briar_roc` | 700 | 5 | 18 / 4.0 / 1.4 (12.9) | 5.6 (flying) | 380 | 4 | 55 | 190 | 6.6 | 6.0 | Flyer rule. **Seed Storm** every 16 s: r 3 at a point within 8 m, **30** + `rooted` 1.0 s to ground enemies (the only Nature root from the air); never heals (rs. Q3) |
| `stormbottle_genie` (neutral) | 600 | 5 | 30 / 12.0 / 1.8, chains to 2 more within 5 m at 22 / 16 (~38 on a clump) | 4.6 (hovers, not a flyer) | 250 + 150 gold (no trade: 400 crystals) | 4 | 45 at the tavern | 200 | ~7 | ~8 | Kind `spell`. **Tempest Bolt** (cd 12): **120** to one target + 40 chain x2; x1.5 on titans. **Unbottled**: at 0 HP it returns to its bottle at the tavern (revive 150 essence, 40 s). **Commandable** like a soldier (a hired unit, not a hero); no levels, no veterancy. Hums near Old Vey (cosmetic line) |
References (t3. 8): Flame Guard CE 19.3, Mossback 15.0 / 10.8, Rifleman 5.6 / 4.3, cavalry ~13 / ~11. All sit below line
infantry per crystal and at T2-or-better per pop (the t3. 8 rule). Fire, the strongest kingdom (balance-2), gets the unit with
the least fight value (the Saboteur's worth is tempo and information, measured by the Bot Lab, not by CE). The Genie's price in
gold makes it a trade-player's pick; its strong single-target lightning is balanced by 600 HP, a slow attack and one per team.
### 7.3 Art briefs (tech-artist, `art-units.md` style: chunky, silhouette = role, 1-2 glow points, 0 lights)
| Unit | Brief |
|---|---|
| Ashveil Saboteur | Two models: the **disguise** is the enemy kingdom's worker (reuse), the **true form** a lean figure in an ash-grey hooded coat, soot mask, bandolier of brass powder flasks, one glowing fuse-cord at the belt (the only glow); reveal = the disguise burns away in 0.3 s of embers |
| Nightblood Reaver | 2.1 m pale noble-warrior in black-red plate with a high collar, a long curved blade dripping violet-red light, torn cape like bat wings; drinking = red threads flow from the target into the blade; frenzy = eyes and blade flare crimson |
| Stormbottle Genie | A 2.6 m storm-spirit of white-gold cloud with a torso and huge arms, tail pouring from a floating brass bottle below it, runes like Vey's blade on its forearms; bolts = jagged white-gold beams (19.V25 kit) |
| Shardguard | 2.2 m Ice heavy in white-blue lamellar, tower-high glaive with a glass-crescent head (Aldra's workshop), a rimed cape; bracing pose when Hold the Line is ready (glaive planted, a faint glass ring) |
| Briar Roc | 5 m wingspan bird of bark and thorn, feathers like dry leaves, antler-crest, seed-pod belly; Seed Storm = a shake of the pod, seeds rain as green sparks |

## 8. Balance targets
| Measure | Target |
|---|---|
| Helper value at arrival (L4) | ~650-750 crystals of fight value (a titan is ~600-700); at L8 <= ~1 000. Rule kept: **no single hire worth more than two minutes of income** (late ~550 / min) |
| Helper vs helper duels (same level, no support, 20 seeds) | Every pair **40-60 %** at L4 and at L8 |
| Helper vs its counters | Vey loses to 6 Riflemen / kiting ranged; Hush to towers + Shardguards + Aegis; Aldra to dives without her Sentinel (cavalry, Hush); Maelis to cavalry dives and out-range. Each helper dies in < 12 s to 1 000 crystals of its counter |
| Kingdom win rates with helpers + new units | Every kingdom **45-55 %**; \|with - without\| <= 5 pts; Fire must not rise (it starts > 55 % in rb. 12.1) |
| Timing | Good-rusher helper on the field 0-90 s after wizard level 4 (median); normal bot helper before its first titan |
| Game length | Median change <= 10 % (rb. target 15-20 min) |
| A team with a living helper | Wins <= 65 % of the fights it joins (fight log) |
Knobs, one at a time: helper price +50 crystals; HP per level -10; ability factor 0.04 -> 0.03; signature level 5 -> 6; revive
time +10 s; Bond bonuses halved; new units' cost +10 %; Reaver drinking 35 -> 28 %; Genie Tempest Bolt 120 -> 100; Saboteur charge 250 -> 200.

## 9. The bot (ai-coder; extends `ai.md`, rs. 8, t3. 10, lb. 7)
| Rule | Easy | Normal | Hard |
|---|---|---|---|
| Call | Never | Citadel complete, crystals >= 350 + `research_reserve`, essence >= 200 -> call **before** the Lair | Same, and it saves for it from the Citadel start |
| Revive | - | At once when essence allows (before any research) | Same |
| Stance | - | Escort while the wizard is with the attack group; Vanguard otherwise; Hold home while rule 1 (defend) runs | Same + Vanguard on the push that kills a keep |
| Strength | - | Helper = **200 + 40 x level** in `own_strength` / `seen_strength` (wizard is 170 + 30 x level) | Same |
| New units | Not trained | `unit_mix` entries (default, vs_ranged, vs_melee): Nightblood Reaver (0.10, 0.12, 0.06), Shardguard (0.08, 0.06, 0.12), Briar Roc (0.05, 0.06, 0.05) once trainable. **Saboteur**: 2 max, sent disguised to the enemy Forge / Sanctum / Lair (rule "sabotage", every 90 s). **Genie**: hired when gold >= 150 + reserve after the helper | Counter-mix: +Shardguard vs seen cavalry / Hush / Reavers; +Reaver vs ranged-heavy armies; +Briar Roc vs walls; any tower near the Forge vs a seen Saboteur |
New profile **`rush_t3`** (Bot Lab only): hard knobs with `stronghold_time` 4:30, `citadel_time` 7:00, army floor 10 soldiers:
the reference "good rusher" for section 6. Bot Lab log per match: `helper_called_at`, `helper_ready_at`, `wizard_l4_at`,
`wizard_e1_at`, helper kills / deaths / revives, stance changes.

## 10. Cutscenes and art direction: as epic as the wizards
### 10.1 Parity checklist (each helper gets exactly what a wizard has)
| Item | Spec | Owner |
|---|---|---|
| Game model | Wizard budget: <= 26 meshes, <= 16 draw instances, **0 lights** (emission only), one signature glow focus, readable at 40 m; hooks: standard + the 3 ability anims + `play_arrival`, `play_fall`, `play_revive`, `set_charge(0..1)`, the 19.V10 gestures (`point`, `nod`, `kneel`, `stand_up`, `raise_weapon`) | tech-artist |
| Video model | Hi-res (3-5x, cloth, hair cards) for the Theatre and Episode videos | tech-artist [H] |
| Portrait | 512 x 512 painted, ep1 19.V6 style (Vey, Hush, Maelis already listed: re-use; **Aldra new**) | tech-artist |
| VFX family | 3 abilities + passive tell + arrival + fall + revive, `art/vfx/helper_<id>_*`, <= 2 particle systems per effect, pooled | tech-artist + ui-coder |
| Voice | 8 lines per helper (call, arrival, 3 abilities, low HP, fall, revive), audio hooks `helper_<id>_<event>`; CC0 / generated placeholders until real voices | ui-coder (hooks) |
| Theatre reveal | One ENGINE stage cinematic per helper, **0:35-0:45** (ep1 U1: nothing over 2:00), unlocked by its campaign moment (section 1) | four-wizards-high (cine tool) + systems |
### 10.2 In the skirmish: the arrival set-piece (no camera takeover: the enemy keeps playing)
3.5 s at the keep door, both teams can see it; a top-centre banner (portrait + name + title, 3 s) for the owner only; the
voice line; the owner's camera is **not** moved (a `Space`-like "centre on helper" key: **F4**).
| Helper | Arrival (3.5 s) | Signature look | Colour |
|---|---|---|---|
| Old Vey | A single white-gold bolt strikes the keep door, he stands up out of the flash, sword dragging sparks, coat snapping | Stormcall: a local cloud card, 8 jagged beams, blade blazing white-gold (19.V25 kit, `m4` look) | `(0.95, 0.95, 0.55)` |
| Mother Hush | The keep's own shadow stretches, smoke boils up from it, the white mask surfaces first, then the knives | Night of Knives: she vanishes, violet slash-lines appear on each victim, she resolves behind the last | `(0.60, 0.50, 0.75)` |
| Aldra Stillwater | A glass spire bursts from the ground at the door and cracks open like a shell; she steps out, tapping the chisel-staff (a ringing note) | Wake the Sentinel: rune-lines race across the ground, a Rime Colossus tears out of an ice dome | `(0.62, 0.95, 0.88)` |
| Maelis Oakenhollow | Roots part at the door, a spirit stag runs through and becomes her as it stops; the staff crown blossoms | Wild Stampede: three translucent green-gold stags, petals in their wake | `(0.60, 0.85, 0.50)` |
### 10.3 Theatre reveals (shot-list outlines; full lists by TH.D3 in `cinematics.md` format)
| id | Title | Set | Beats (<= 0:45) |
|---|---|---|---|
| `helper_vey` | The Storm Returns | Emberfall watch-keep at dusk (19.V24) | Vey sharpens the black blade; Vessa: "You're late." / "Twelve years late. Still counts." Storm gathers; the motto "The spark first, then the storm"; lightning frames them back to back |
| `helper_hush` | Another Night | Malrik's crypt (19.V15) | Malrik lights one candle; Hush is already there. "Who?" / "Anyone you like." The candle goes out; her mask is the last thing lit |
| `helper_aldra` | A Hundred Winters | Glasswater Mere shore at night | Aldra carves a rune into a Sentinel's shell; Torvald: "Wake it only if they cross." / "They always cross." The shell's eyes open, glass-teal |
| `helper_maelis` | The Forest Has Opinions | Ysolde's grove corner (19.V8) | Ysolde kneels at a burnt sapling; Maelis: "They'll come for the wood." / "Then the wood comes for them." Wolves rise from the ferns |
### 10.4 Voice direction and sample lines (original)
| Helper | Voice | Samples |
|---|---|---|
| Vey | Old, gravelly, dry humour, warm under it | Arrival: `Still throwing fire at everything? Good. I brought thunder.` · Lunge: `Duck.` · Fall: `Not... this storm.` · Revive: `Told you. The storm comes back.` |
| Hush | Whisper, unhurried, faintly amused (processed: no mouth) | Arrival: `The Bishop sends his regrets. To everyone.` · Blink: `Behind you.` · Low HP: `The knife bends.` · Fall: `There is always another night.` |
| Aldra | Calm, precise, clear as struck glass | Arrival: `The mere remembers every footstep.` · Sentinel: `Wake. We have guests.` · Aegis: `Stand behind the glass.` · Fall: `Cracked. Not broken.` |
| Maelis | Earthy, old, amused | Arrival: `The forest has opinions. Today they're about you.` · Pack: `Run with me, little ones.` · Stampede: `Make way for the old herd!` · Fall: `Bury me by the roots.` |

## 11. Balance Lab / Bot Lab plan (TH.D2; Balance Lab needs a `helpers` variant key)
Variants: `{"helpers": {"enabled": false}}`, `{"helpers": {"new_units": false}}`, `{"helpers": {"price": 400}}`,
`{"helpers": {"level_factor": 0.03}}`, `{"helpers": {"genie": false}}`, `{"bot": {"profile": "rush_t3"}}` (one seat).
Arm C also reports the Genie's hire rate and win rate with / without it (target: hired in 30-60 % of trade games, its
owner's win rate within 5 pts of the non-owner's in mirrors) and the Saboteur's damage + queue-seconds paused per match.
| Arm | Question | Games |
|---|---|---|
| A: helpers off, new units off | Today's baseline | 12 non-mirror pairs x 8 seeds = 96 |
| B: helpers on, new units off | Does a helper move any kingdom > 5 pts? Length +- 10 %? | 96 |
| C: helpers on, new units on | The shipped state: every kingdom 45-55 % | 96 |
| D: `rush_t3` vs normal, all 12 pairs | Section 6 timing: median `helper_ready_at - wizard_l4_at` in -60..+90 s; does the rusher win > 60 %? | 12 x 8 = 96 |
| E: helper duels (harness, no bots) | 16 pairs x L4 / L8 x 20 seeds: every pair 40-60 % | 640 (fast) |
Quick sweep first (`-Tick 30 -Limit 1200`, seeds 1-4, pairs fire:shadow, shadow:fire, ice:nature, nature:ice), then A/B/C at
60 Hz. Fail -> section 8 knobs, one per run, logged here.

## 12. Suggested API (FROZEN proposal: the lead freezes it in `CLAUDE.md` at TH.L1)
- **`HelperType`** resource (`data/helpers/<id>.tres`, gameplay): `id`, `display_name`, `title`, `kingdom: StringName`,
  `bonded_wizard_id: StringName`, `hp_base`, `hp_per_level`, `damage_base`, `damage_per_level`, `armor`, `attack_range`,
  `attack_cooldown`, `move_speed`, `sight`, `aggro`, `kind: StringName`, `ability_ids: Array[StringName]` (3, slot order),
  `passive_id`, `signature_level := 5`, `level_factor := 0.04`, `call_crystals := 350`, `call_essence := 200`, `call_time := 60.0`,
  `pop := 4`, `model_scene: PackedScene`, `portrait: Texture2D`, `color: Color`, `voice_prefix`, `static find(id)`,
  `static for_kingdom(kingdom) -> HelperType`.
- **`Helper extends Champion`** (`scripts/units/helper.gd`, groups `"units"`, `"champions"`, `"helpers"`): `helper_type`,
  `bonded_wizard: Wizard`, `stance: StringName` (`&"escort"`, `&"vanguard"`, `&"home"`), `set_stance(id) -> String` (`""` or
  `"Invalid stance"`), `level` synced from `bonded_wizard.level_changed` (no own XP: `add_xp` does nothing), `ability_factor() ->
  float`, `is_commandable() -> false`; no class, tree, purse, shop or mount (the Champion paths skip when `helper_type` is set);
  signals `stance_changed(helper, stance)`, inherited `intent_changed`. Child `"HelperAbilities"`: `cast(id, target) -> String`,
  `cooldown_left(id)`, `cooldown_total(id)`, `ability_ids()`, signal `ability_cast(id)`.
- **`HelperRoster`** (`scripts/buildings/helper_roster.gd`, systems, one per team, group `"helper_rosters"`):
  `static for_team(team) -> HelperRoster`, `helper: Helper`, `state() -> StringName` (`&"none"`, `&"queued"`, `&"alive"`,
  `&"fallen"`), `can_call() -> String` / `call() -> String` (refusals of section 3, in order), `can_revive()` / `revive()`,
  `revive_cost() -> int`, `revive_time() -> float`; signals `helper_called(team, id)`, `helper_ready(helper)`,
  `helper_fallen(helper)`, `helper_revived(helper)`. The keep's slot r1c4 N calls it (stub `UnitType` in the upgrade lane, the
  Mage Archer pattern).
- **Skirmish / missions**: `@export var helpers_enabled := true` (missions false), `@export var t3_expansion_units := true`.
- **Events**: reuse `titan_event(team, &"helper", what)` (`&"calling"`, `&"ready"`, `&"fallen"`, `&"revived"`).
- **Victims**: `levels.md` row `Helper: 100 + 30 x level`; essence `40 + 10 x level` (`items.md` kill table).
- **VFX**: `HelperVfx.play(id: StringName, helper, target)` (`scripts/vfx/helper_vfx.gd`, group `"helper_vfx"`), ids = ability ids +
  `&"arrival"`, `&"fall"`, `&"revive"`. **Keys**: **F4** = centre on the helper (twice = inspect). No other key.
- **New units** (recommended set; ids of swapped-in menu units follow the same pattern):
  `data/units/{ashveil_saboteur,nightblood_reaver,shardguard,briar_roc,stormbottle_genie}.tres`; `UnitAbilities` ids
  `disguise`, `powder_charge`, `eavesdrop`, `nightblood`, `blood_frenzy`, `hold_the_line`, `challenge`, `seed_storm`,
  `tempest_bolt`; statuses reused (`chill`, `frozen`, `taunted`, `rooted`, `marked`) + new `disguised` (read by auto-aggro,
  minimap and the selection panel: `Unit.is_disguised_for(team) -> bool`), `UnitType.disguise_as_worker: bool`,
  `UnitType.lifesteal_pct: float`. Tavern: `Tavern.wonders_for(team) -> Array[UnitType]`, `hire_wonder(type, team) -> String`
  (`"Needs a Citadel"`, `"Already hired"`, pop, money refusals).
- **Boons**: `data/boons/sworn_bond.tres`, `BoonType.requires` gains `&"helper"`.

## 13. Tasks (step TH; builds after steps 13, 13b, 13c, 14 and LB)
| Id | Owner | What | Files | Done when |
|---|---|---|---|---|
| TH.L1 | lead | Freeze section 12 in `CLAUDE.md` (Helper, HelperType, HelperRoster, flags, F4 key, owner rows `data/helpers/` gameplay, `helper_roster.gd` systems); waves.md step | `CLAUDE.md`, `docs/plan/` | Contracts frozen, keys line has F4 |
| TH.D2 | game-designer | Update `level-boons.md` (Sworn Bond), `titans-2.md` 5 (Maelis moved, Elder Circle C = Briar Roc), `levels.md` victim row, balance runs of section 11 | `docs/design/` | Docs consistent; lab arms A-E reported here |
| TH.D3 | game-designer | Theatre shot lists (10.3) in `cinematics.md` format; Aldra's 2-line M2 patch for 19.D2 | `docs/design/` | 4 shot lists, each <= 0:45 |
| TH.D4 | ui-designer | `ui-helpers.md`: keep slot N states, portrait slot next to the hero column, stance buttons, banner, tooltips, minimap ring | `docs/design/ui-helpers.md` | Sizes at 1600 x 900 and 3440 x 1440 |
| TH.G1 **[H]** | gameplay-coder-high | HelperType + 4 `.tres`, Helper, HelperAbilities, 4 kits + passives + bonds, level sync, stances in the brain hooks | `scripts/units/helper*.gd`, `data/helpers/`, `tests/test_th_g1.gd` | Test: Vey L4 = 850 HP / 35 dmg, L8 1 050; level follows the wizard at once; signature refused before L5; Chain Lightning 45/38/32/27/23 x1.12 at L4; Fireball within 14 m cuts Chain by 2 s (max once per 2 s); Hush veiled after 4 s idle, not auto-targeted at 6 m, +60 % first strike; Bond +15 % after a Lance; Aldra ward -12 % on a ranged hit, Sentinel lives 30 s at pop 0, max 1; Maelis wolves +20 % speed within 12 m, never heals; `is_commandable()` false; `add_xp` no-op |
| TH.G2 **[H]** | gameplay-coder-high | The 5 new units + abilities of the picked set (7.2), `disguised` status, lifesteal field | `data/units/`, `scripts/units/`, `tests/test_th_g2.gd` | Saboteur ignored by enemy auto-aggro at 10 m, revealed by a tower at 6 m and by attacking, charge 250 after 5 s and pauses the queue 10 s; Reaver heals 35 % of damage, 17.5 % for 4 s after a fire hit, frenzy under 40 %; Shardguard stops a Blaze Rider charge and freezes it 1 s, once per 10 s; Roc Seed Storm roots 1 s, ground only; Genie chain 30 / 22 / 16, Tempest 120 (x1.5 titans) |
| TH.S1 | systems-coder | HelperRoster, keep slot N call / revive, refusal order, 2v2 one-per-team, warnings, `helpers_enabled`, new unit slots (Roost X, Gloom Hall N, Glacier Den X, Elder Circle C), tavern "Wonders" row for the Genie, victim / essence rows | `scripts/buildings/`, `scripts/world/skirmish.gd`, `data/buildings/`, `tests/test_th_s1.gd` | Refusals in section-3 order; second call `"Already called"`; revive L4 = 200 essence, 45 s; helper death never ends a 1v1; missions show no slot; smoke `victory=true` |
| TH.A1 | ai-coder | Section 9: call, revive, stances, strength, mixes, `rush_t3` profile, Bot Lab log fields | `scripts/ai/`, `data/ai/`, `tests/test_th_a1.gd` | Normal calls within 10 s of affording after the Citadel; easy never; strength 200 + 40 x level; log has the 4 timing fields |
| TH.U1 | ui-coder | Slot N states, portrait slot, stance buttons, banner, F4, tooltips, messages, audio hooks (per TH.D4) | `scripts/ui/`, `tests/test_th_u1.gd` | F4 by physical keycode; stance click never orders; nothing calls `_private` |
| TH.U2 | ui-coder | `HelperVfx` wiring of the TH.V assets | `scripts/vfx/helper_vfx.gd`, `tests/test_th_u2.gd` | Every id plays and frees in <= 3 s; 0 lights added; `PERF OK` with 4 helpers casting signatures at once |
| TH.V1-V4 **[H]** | tech-artist (one per helper) | Game models: Vey (19.V20 + `skirmish` look = `m4`), Hush (19.V23 raised to wizard budget), Maelis (13c model raised to wizard budget), **Aldra (new)** | `art/units/helpers/<id>/` | Art Lab pass; contact sheet beside Vessa at 40 m; hooks of 10.1 |
| TH.V5-V8 | tech-artist (one per helper) | VFX families + arrival set-pieces (10.2) | `art/vfx/helper_<id>_*` | 0 lights, <= 2 particle systems per effect, pooled |
| TH.V9-V13 | tech-artist (one per unit) | Saboteur (+ the disguise swap), Reaver, Shardguard, Briar Roc, Genie (7.3) | `art/units/<kingdom>/`, `art/units/neutral/genie/` | Art Lab pass; flyers use `FlyerModel`; 0 lights |
| TH.V14 **[H]** | tech-artist | Hi-res video models (Aldra new; Hush / Maelis upgrades; Vey = 19.V21), Aldra portrait | `art/cinematics/hires/`, `art/portraits/` | Render in the Theatre sets |
| TH.C1 | four-wizards-high (cine tool) | 4 Theatre reveals as `data/cinematics/helper_*.tres` + stages | `data/cinematics/`, `missions/cinematics/` | Each plays and skips cleanly, <= 0:45, unlocks on its campaign flag |

## Done when (step TH)
- [ ] Section 3 rules pass TH.S1 tests; section 4 numbers pass TH.G1; section 7 units pass TH.G2; `PERF OK`; smoke `victory=true`.
- [ ] Bot Lab arm D: median `helper_ready_at - wizard_l4_at` within -60..+90 s for `rush_t3`; arms B / C inside section 8.
- [ ] Each helper passes the 10.1 parity checklist (Art Lab + a side-by-side contact sheet with its wizard).

## Questions for the user (recommendation first; framed on the campaign moments)
1. **Ice has no campaign ally yet.** (a) **Aldra Stillwater, the Glass Warden**: debuts in **mission 2** (Torvald's lake) as the
   hand that wakes the Sentinels and raises the shore walls (2 new lines, one silhouette), then fights for Torvald in Episode 2
   (b) Torvald's old apprentice, debuting only in Episode 2 (c) you name the character.
2. **"Campaign 3"**: (a) **you mean mission 3** (the Sighing Wood, where Maelis first appears): each helper's story moment
   (Vey and Hush in mission 0, Aldra in mission 2, Maelis in mission 3) unlocks its Theatre reveal, and all 4 are callable in
   skirmish from the start (b) you mean a future **Episode 3** starring another wizard with its helper (tell me which one)
   (c) helpers stay locked in skirmish until their campaign mission is won.
3. **Extra T3 units** (menu in 7.1): (a) **the recommended set: Fire Ashveil Saboteur (your spy), Shadow Nightblood Reaver (your
   vampire), Ice Shardguard, Nature Briar Roc in Maelis's old slot (Maelis becomes Nature's helper, one Maelis as in mission 3),
   and your Genie as a neutral tavern hire** (lightning stays the Master's storm, Old Vey's mystery) (b) the same but the Genie
   is Fire's (Vey's kingdom) and Fire's spy moves to neutral (c) you pick one line per kingdom from the menu.
4. **Control**: (a) **autonomous with 3 stances (Escort / Vanguard / Hold home)**, like Old Vey in the story (b) a second hero you
   command, its 3 abilities on the command card.
5. **Timing**: our wizards have no true ultimate; I timed the helper to the **E spell at level 4 (~9:00-10:00)**. (a) **Keep that**
   (b) time it to level 6 (~15:00, the helper comes later and stronger) (c) give each wizard a real ultimate at level 6 (a new
   spec).
