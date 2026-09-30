# Champions: autonomous hired heroes (indirect control)

Task 9.D2, written 2026-09-26. Source of truth for tasks 9.C1-9.C11 and 9.V1-9.V6 (section 15).
**User decisions (final):** the wizard stays under direct control. **Champions can never be selected-and-ordered**:
they act on their own, driven by personality. The player steers them only indirectly: **bounty flags**, where the
buildings are, and money (essence). Inspired by the *idea* of indirect-control hero games; every name, champion,
ability, number and rule here is our own.
Metres, seconds, `m:ss` since the navmesh was ready; positions `(x, z)` on Crown Hollow (`skirmish-1v1.md`,
`balance-1.md` layout). Numbers build on `levels.md`, `items.md`, `balance-1.md`, `balance-2.md`.

## 1. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Where to hire | **Two neutral taverns**, mirrored on the neutral diagonal, beside the Ruin Peddlers (section 2). No new base building | The centre is the Ember Crown; on the `x = z` line every point is equally far from both keeps, and a mirrored pair keeps the map perfectly fair |
| Price | **Crystals + essence**, rising per hire; **pop 2** each; **max 3** per side | Crystals make a champion a real army choice; essence ties them to fighting |
| Control | None. Clicking one = **inspect only** (read-only panel). Never in box select, groups, F2, right-click orders | User decision |
| How to steer | **Bounty flags** (Hunt / Explore / Guard / Escort) paid in essence; "home" = your keeps and barracks | Flags + base layout + money are the three levers |
| Champion money | A personal **purse** (in essence). Filled by bounties and loot, spent **by the champion** at shops; **20 % tithe** of each purchase returns to the team | Your bounties become their gear; part comes back |
| Death | Fallen, not gone: **revive for essence** at your keep. Items kept, 30 % of the purse dropped to the killer | Losing a levelled hero forever to one bad fight is too harsh for a 20-min match |
| Levels | 1-6 on the wizard XP curve (L2-L6), +8 % HP / damage per level, 3rd ability at level 4 | Reuses `levels.md`; stays below the wizard (max 8) |
| Two sides want the same champion | Each archetype exists **twice** (sibling pair, same model, two names). First hire of an archetype on either side gets name A, the other side's gets name B | No denial race, no duplicate names |
| Naming clash | Veterancy rank 4 "Champion" is **renamed "Paragon"** (text only: `Unit.VETERANCY_NAMES`, UI strings) | "Champion" now means these heroes (user to confirm) |

## 2. Map: the two taverns (systems)
| Item | Value |
|---|---|
| `TAVERN_SPOTS` (`skirmish.gd`) | `(-15, -15)` and `(15, 15)`: 64.4 m from **both** keeps, 21.2 m from the crown, 9.9 m from the nearest peddler, 21.2 m off the lane |
| Door point (spawn / rest anchor) | `spot x 0.8` = `(-12, -12)` / `(12, 12)` (the side facing the crown) |
| Clearing | r **6** at each spot (generator, mirrored like the peddler clearings) |
| Node | `Tavern` (`scripts/world/tavern.gd`), team `NEUTRAL`, **invulnerable, never a target**, ignored by every unit (like the peddler), clickable (layer 2, group `"taverns"`); click = open the tavern window. Footprint 6 x 6 blocks the build grid and the navmesh |
| Fog | At match start `FogOfWar.reveal(team, spot, 6)` for PLAYER and ENEMY: both taverns are **explored from 0:00** (landmark lantern). Minimap: 6 x 6 px amber `(1.0, 0.75, 0.35)` square, always drawn once explored |
| Opening | Closed until **2:00** (window shows `The tavern opens at 2:00`); at 2:00 `show_message("The taverns open their doors")` and a one-time hint `Y: hire champions` |
| Rest | Any champion within **8 m** of a door heals **2 % max HP / s** (both teams; neutral ground, fighting is still allowed) |
| Held | A tavern is **held by the enemy** when an enemy soldier, wizard or champion is within 12 m of its door and none of yours is |

## 3. Hiring, roster, upkeep, death (systems: `ChampionGuild`, one per team)
### 3.1 Hire
| Rule | Value |
|---|---|
| Roster | Max **3** champions per team (alive, reviving or fallen all count). Each of the 4 archetypes at most once per team |
| Cost of the n-th champion (n = roster size + 1) | 1st **200 crystals + 75 essence**; 2nd **250 + 100**; 3rd **300 + 125**. Pop **2** each (counted while in the roster, alive or not) |
| Where | Opened with **Y**, a tavern click or an empty portrait slot; works from anywhere once the tavern is open. The champion walks out of the door of the tavern that is **not held**, the one nearer your wizard (your keep if she is dead) if both are free, **3 s** after paying |
| Refusal reasons (`can_hire(id) -> String`, in order) | `"Tavern closed"`, `"Max 3 champions"`, `"Already hired"`, `"Population cap reached"`, `"Not enough crystals"`, `"Not enough essence"`, `"Enemies hold both taverns"` |
| New champion | Level 1, empty inventory, **purse 50** (a signing bonus paid by the tavern, not by you), full HP |
| Message | `Tamsin Farrow joins you` (enemy hire: `Malrik hired Tobin Farrow` only if the door is visible to you) |
### 3.2 Upkeep
- Every **10 s**: **1 essence per living champion** (6 / min each; fallen or reviving ones cost nothing).
- If the bank cannot pay **3 ticks in a row**, every champion of the team is **Unpaid**: it ignores bounties (rule R6)
  until the next paid tick. Message once: `Your champions are unpaid: they ignore bounties`.
### 3.3 Death, revive, dismiss
| Event | Rule |
|---|---|
| Death | Portrait greys, intent `Fallen`. Drops **30 % of its purse**: into the killer champion's purse, or the killer team's bank. Items and the other 70 % are kept. XP value as a victim: **100 + 25 x level** (L1 125, L6 250), paid to the killer's team like any kill (`levels.md`, `EssenceBank`) |
| Revive (`revive(champion) -> String`: `"Not fallen"`, `"No home"`, `"Not enough essence"`) | **60 + 30 x level essence** (L1 90, L6 240). Returns after **15 + 5 x level s** (L6 45 s) at the own keep's spawn point (oldest barracks if no keep). Full HP, same level / XP / items / purse, ability cooldowns reset |
| Dismiss (alive or fallen; click twice within 3 s) | The champion fades out over 1 s where it stands. The team bank gets **50 % of its purse + 50 % of its items' total value**. Frees the slot and the pop; the archetype can be hired again at level 1 |
| Message | `Garran Stoneward has fallen` / `... returns in 30 s` / `... leaves your service` |

## 4. The four champions
Base stats are level 1. `pop 2`, `hp_regen 0`, no mana: abilities run on cooldowns only (`cooldown_reduction` and
`spell_power` from items apply to them; ability damage, heals and shields grow **+8 % per level above 1**).
Champions count as heroes for status `hero_mult` (crowd control lasts half as long on them). No veterancy chevrons.

### 4.1 Stats (`data/champions/<id>.tres`, `ChampionType`)
| id | Names (A / B) | Role | HP | Armor | Damage | Range | Cooldown | DPS | Speed | Aggro | Sight | Radius | Height | Flee under |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `wayfinder` | Tamsin Farrow / Tobin Farrow, *the Wayfinder* | Scout, ranged | 260 | 0 | 13 | 8.0 | 1.1 | 11.8 | 5.8 | 9 | **18** | 0.45 | 1.8 | **40 %** |
| `oathwall` | Garran Stoneward / Gerda Stoneward, *the Oathwall* | Guardian, melee | 520 | 20 | 15 | 1.8 | 1.3 | 11.5 | 4.3 | 10 | 11 | 0.6 | 2.0 | **20 %** |
| `coin_cutter` | Sable Quint / Silas Quint, *the Coin-Cutter* | Raider, melee | 300 | 5 | 17 | 1.6 | 0.9 | 18.9 | 5.6 | 8 | 12 | 0.45 | 1.7 | **35 %** |
| `mender` | Orla Fenwick / Osric Fenwick, *the Mender* | Healer, ranged | 280 | 5 | 9 | 7.0 | 1.4 | 6.4 | 4.8 | 9 | 12 | 0.45 | 1.7 | **45 %** |
Projectile colours: Wayfinder `(1.0, 0.8, 0.4)`, Mender `(0.5, 1.0, 0.6)`.

### 4.2 Personality (traits used by the brain, section 8)
| | Greed | Courage | Engage radius | Hunt | Explore | Guard | Escort | Likes | Fears |
|---|---|---|---|---|---|---|---|---|---|
| Wayfinder | 1.0 | 0.9 | 10 | 0.6 | **2.0** | 0.3 | 0.5 | Unexplored ground, Explore flags, open roads | Towers and keeps: never goes within 12 m of a **known** enemy tower / keep before level 4; being chased by melee |
| Oathwall | 0.8 | **1.6** | **20 around own buildings** | 0.7 | 0.2 | **2.0** | 1.0 | Your buildings, your wizard, Guard flags | Leaving home: any flag > **35 m** from every own building x **0.3** |
| Coin-Cutter | **1.5** | 0.8 | 8 | **1.8** (x 1.3 on workers and champions) | 0.6 | 0.3 | 0.3 | Bounties, lone workers, low-HP targets, Lost Caches | Fair fights, towers, the enemy wizard above 50 % HP (counts double in danger) |
| Mender | 0.9 | 0.7 | 9 (heals) | 0.4 | 0.3 | 0.8 | **2.0** (x 1.2 on the wizard) | The army, the wizard, Escort flags | The front line: stays >= 4 m behind the nearest ally, on the side away from the nearest seen enemy |
Personality line (tavern window, tooltip): Wayfinder `Goes where the map is blank.` · Oathwall `Would rather stand at your door than walk to theirs.` · Coin-Cutter `Loves a bounty more than a fair fight.` · Mender `Follows the army and keeps it standing.`

### 4.3 Abilities (all autocast; `ChampionAbilities` checks triggers every 0.5 s, one cast per check)
| Champion | id | Name | Unlock | Cooldown | Range | Effect (level 1) | Autocast when |
|---|---|---|---|---|---|---|---|
| Wayfinder | `flare_arrow` | Flare Arrow | L1 | 18 | 20 | Arrow to a point: **20 damage** radius 2; the point is **visible** for its team, radius **8**, for **6 s** (a sight marker, section 13) | Exploring or on an Explore flag: at the least-explored point 14-20 m ahead on its path. Fighting: at the last position of a visible enemy that just left vision within 20 m |
| Wayfinder | `snare_line` | Snare Line | L1 | 14 | 8 | **15 damage** + `rooted` 1.5 s on one enemy | Fleeing and an enemy within 8 m targets it; or its Hunt target is within 8 m and moving away |
| Wayfinder | `trailblaze` | Trailblaze | **L4** | 30 | self, r 8 | Itself and own non-worker units within 8 m get `haste` for **5 s** | Fleeing; or walking to a flag or explore point more than 25 m away |
| Oathwall | `oath_of_iron` | Oath of Iron | L1 | 16 | self, r 6 | Enemy non-hero units within 6 m get new status `taunted` 3 s (they attack the Oathwall only); itself `armor` +20 for 3 s (modifier `ability:oath`) | 2+ enemies within 6 m attack an own unit or building, or 3+ enemies target the Oathwall |
| Oathwall | `shield_bash` | Shield Bash | L1 | 10 | 2.2 | **30 damage** + new status `dazed` 0.8 s (no move, no act) | Its current target is in range; prefers a target that attacks an own building or the wizard |
| Oathwall | `bulwark_stand` | Bulwark Stand | **L4** | 40 | self, r 5 | Plants its shield **6 s**: itself `rooted`; own units within 5 m get new status `braced` (damage taken x 0.7), refreshed every 0.5 s | 3+ enemies within 8 m and it is Guarding, or within 20 m of an own building |
| Coin-Cutter | `cutpurse` | Cutpurse | L1 | 8 | melee | Its next attack deals **+25 damage**; if it kills, **+15 purse** loot | Target below 50 % HP, or a worker |
| Coin-Cutter | `smoke_pouch` | Smoke Pouch | L1 | 25 | self, r 3 | Itself `shroud` **3 s** (half damage, +2 m/s); enemies within 6 m drop it as a target and cannot auto-target it for 3 s | HP below flee threshold + 10 %, or 3+ enemies target it |
| Coin-Cutter | `marked_for_coin` | Marked for Coin | **L4** | 20 | 8 | New status `marked` on one enemy **6 s**: damage taken x **1.15** from every source | On its Hunt target or raid target when in range |
| Mender | `mending_draught` | Mending Draught | L1 | 7 | 9 | Heals the most hurt (lowest HP %) own unit, wizard or champion by **50** (instant) | Any ally within 9 m below 70 % HP (itself included) |
| Mender | `soothing_circle` | Soothing Circle | L1 | 24 | 9 (point), r 5 | Heal zone **6 HP / s for 5 s** (30 each) on own units inside (reuse `spell_hot.gd`) | 3+ allies within 5 m of one point below 80 % HP |
| Mender | `lifeline` | Lifeline | **L4** | 35 | 9 | `add_shield(100, 5.0)` on one ally | The wizard or a champion within 9 m below 35 % HP (wizard first) |
Growth example: Mending Draught heals 50 / 62 / 70 at L1 / L4 / L6 (x `1 + spell_power / 100` from items).
New statuses (gameplay, `Unit.STATUSES`): `taunted` (forced target = the caster; wizards immune), `dazed` (no move, no act, no
immunity after), `braced` (damage taken x 0.7), `marked` (damage taken x 1.15). Existing `haste`, `rooted`, `shroud` reused.

### 4.4 Shopping wish lists (ids from `items.md`; bought in order, section 7)
| Champion | Order (combines consume their parts; max 4 slots) |
|---|---|
| Wayfinder | Swiftsoles, Ember Draught, Whetted Fang, Ember Shard, **Blazing Edge**, Wisp Lantern, **Ashen Greaves** |
| Oathwall | Ironbark Plate, Ember Draught, Wisp Lantern, **Nightveil Cloak**, Bone Charm, Ironbark Plate, **Warlord's Horn** |
| Coin-Cutter | Ember Shard, Whetted Fang, **Blazing Edge**, Ember Draught, Bone Charm, Ember Shard, **Grave Pact** |
| Mender | Wisp Lantern, Ember Draught, Duskglass Lens, Cinder Ring, **Emberwake Band**, Ironbark Plate, **Nightveil Cloak** |
Every list fits 4 slots at each step. After the list ends: keep 1 Ember Draught, save the rest.

### 4.5 Barks (one `Label3D` line above the head for 3 s; max one per champion per 20 s; only when visible to the local team)
| Trigger (chance) | Wayfinder | Oathwall | Coin-Cutter | Mender |
|---|---|---|---|---|
| Hired (100 %) | Maps are just rumours with lines. Let's draw some. | Point me at a wall. I'll stand in front of it. | Pay me and I'll love you. Briefly. | Try not to need me. You will. |
| Takes a bounty (30 %) | A coin for a corner? I know a corner. | Nobody touches this door. Nobody. | Now THAT is a pretty number. | Stay close. I only reach so far. |
| Flees (50 %) | Nope. Mapping the way home! | Tactical... leaning backwards! | Nothing's worth dying for. Except more coin. Not this coin. | Healer first, hero never! |
| Level up (100 %) | I've seen more. I am more. | Heavier. Good. | Richer AND better. Unfair, really. | My hands remember more. |
| Buys an item (20 %) | New boots. Same blank map. | Thicker is better. | Retail therapy. | Every good bag needs a better bag. |

### 4.6 Look (global style of `art-units.md`: chunky "3 heads tall", silhouette = role, painted shaders, 1-2 glow points)
Champions are free agents, not kingdom troops: each has its **own neutral palette** (warm leathers, weathered cloth) and
only a **team sash + back pennant / cape** in the owner's kingdom colour (`set_team_color`, recolour cached per colour as in
`art-units.md` 2.2). Variant B (the sibling) = one toggled node (hair / hood / beard piece), same scene.
Budget: as a wizard (**<= 26 authored meshes, <= 16 draw instances after the merge, 0 lights**, particles only < 45 m).
Materials: **<= 5 per champion**, in its own folder; shared `art/units/materials/` read-only. Height = `body_height`.
| Champion | Silhouette (the 40 m black test) | Palette | Glow (energy 1.5, halo 3.0) | Attack / cast pose |
|---|---|---|---|---|
| Wayfinder (1.8 m) | Wide-brim hat, long split coat, **a tall lantern pole on the back** (top at 2.6 m, narrow), short bow in ArmR | Coat moss `(0.35, 0.40, 0.28)`, leather `(0.40, 0.26, 0.14)`, hat `(0.22, 0.18, 0.14)` | Lantern `(1.0, 0.8, 0.4)` 1.5 (+ eye bar dark) | `bow`: draw 0.15 s; cast = raises the bow high and shoots up |
| Oathwall (2.0 m) | Square, **a door-sized riveted shield** (1.2 x 1.6 m) in ArmL, short war hammer in ArmR, flat helm | Iron `(0.45, 0.46, 0.50)`, oak `(0.36, 0.24, 0.12)` shield boards, padded cloth `(0.55, 0.50, 0.40)` | Shield boss rune steel-blue `(0.6, 0.85, 1.0)` 1.5, visor | `slam`: hammer overhead; cast = shield forward and stomp (Bulwark: shield planted in the ground) |
| Coin-Cutter (1.7 m) | Lean, **hood with a long tail**, two short curved knives, a **bulging loot sack on the hip**, coin belt | Charcoal `(0.16, 0.15, 0.17)`, burgundy `(0.45, 0.12, 0.14)`, brass `(0.70, 0.55, 0.25)` | Coin belt gold `(1.0, 0.85, 0.3)` 1.5, eye bar | `slash2` fast double cut; cast = throws a pouch (smoke) or flips a coin (mark) |
| Mender (1.7 m) | Round, **wicker backpack stacked with jars**, staff with a hanging censer-kettle, apron | Linen `(0.80, 0.76, 0.62)`, wicker `(0.55, 0.40, 0.20)`, herb green cloth `(0.30, 0.50, 0.30)` | Censer green `(0.5, 1.0, 0.6)` 1.5 (pulse), jars 1.5 | `staff` jab (bolt from the censer); cast = swings the censer in a circle |

**In-game read pass (2026-09-30, `docs/art/ingame_grade/under_90.md` rows 18-21).** At RTS zoom 30 the champions read
as small brown slabs, so: (1) a hired champion's model is drawn **x1.15** (`Champion.MODEL_SCALE`; the `body_height`
of `data/champions/*.tres` is the scaled height: Wayfinder 2.07, Oathwall 2.3, Coin-Cutter / Mender 1.96); (2) each
archetype wears **one bright identity colour** on its biggest top-facing mass, away from the four kingdom colours (the
team colour stays on the sash / pennant / cape): Wayfinder **saffron coat** `(0.86, 0.60, 0.14)` (was moss),
Oathwall **heraldic cream door planks** `(0.90, 0.83, 0.64)` (was bare oak), Coin-Cutter **raspberry mantle / loot
sack** `(0.80, 0.14, 0.36)` (was burgundy), Mender **teal dress** `(0.08, 0.60, 0.58)` (was herb green, lost on the
meadow); the class weapons (kit, 11.V1) carry the class read; (3) **B8 material merge**: every painted and glow part
of a champion draws with ONE palette material (`art/units/champions/champion_palette.gd` / `.gdshader`; the Mender's
own `mender_painted` gained a glow mode), motes share one draw material: 5 materials per champion (Mage Archer 7: her
three team-cloth materials). Glow energies: lantern 1.9, coin belt 3.2 (the old 1.5 sat under the bloom level).

## 5. Levels and XP (reuses `levels.md`)
| Level | 1 | 2 | 3 | 4 | 5 | 6 (max) |
|---|---|---|---|---|---|---|
| Total XP (wizard curve) | 0 | 150 | 400 | 750 | 1 200 | 1 750 |
| HP / damage x base | 1.00 | 1.08 | 1.16 | 1.24 | 1.32 | 1.40 |
| Unlock | 2 abilities | | | **3rd ability** | | `MAX` |
| XP source | Amount |
|---|---|
| Killing blow by the champion | 100 % of the victim's XP value (`levels.md` table; champion victims 100 + 25 x level) |
| A team kill within **12 m** of the champion | 25 % (rounded up, min 1). Champions never take the soldiers' veterancy share |
| A bounty paid to it | **half the essence paid** (a 100 bounty = 50 XP) |
Level-up heals the HP gained, flashes gold (`play_level_up`), bark. Levels survive death and revive. The wizard's share
rules are unchanged: champion kills are team kills.

## 6. Bounty flags (the only way to direct champions)
### 6.1 Kinds
| Kind | Placed on | Min stake (essence) | Done when / pays | Expires |
|---|---|---|---|---|
| **Hunt** | A **visible** enemy or neutral unit, champion, wizard or enemy building (a building ghost counts) | **75** | The target dies. Paid to **contributors**: own champions that damaged it in the last 10 s, or were pursuing it within 12 m when it died; split equally. **No contributor = 100 % refund** | Target unseen for 60 s (the flag stays on its last seen spot meanwhile): 100 % refund |
| **Explore** | Any ground point, **also unexplored** | **25** | First own champion within **4 m** of the point gets it all | Never |
| **Guard** | An own completed building | **50** | Service of **90 s**: every 10 s, `stake / 9` is split among own champions within **14 m** of it (a tick with nobody there is kept) | 180 s after placement, or the building dies: the unpaid rest is refunded |
| **Escort** | An own living unit (the wizard, a soldier, a worker) | **50** | As Guard, champions within **10 m** of the unit | 180 s, or the unit dies: unpaid rest refunded |
### 6.2 Placing, raising, removing
| Action | Rule |
|---|---|
| Place | **R** (physical) = bounty mode: coin-flag cursor with the kind and price for what is under it: enemy / neutral target = Hunt, own building = Guard, own unit = Escort, ground = Explore. Left-click places at the minimum stake; **Shift+click** places and stays in the mode; right-click / Esc cancels. Placing on something that already has your flag **raises** it instead |
| Refusals (`BountyBoard.place(...) -> String`, in order) | `"No champions"` (roster empty), `"Too many bounties"` (**5** active per team), `"Invalid target"` (Hunt target not visible, Guard on a site / enemy building, Explore off the map or within 8 m of your other Explore flag: that one is raised instead), `"Not enough essence"` |
| Raise (stack) | Select the flag (click it), **Z** = +25, **Shift+Z** = +100, max **500** (`"Max bounty"`). Raising never changes who pursues it; the brain re-plans within 2 s |
| Remove | Flag selected, **Delete**. Unpaid part: **100 % refund** if no champion is pursuing it, else **50 %** refund and 50 % split among the pursuers as a walk fee |
| Payment | Paid from the stake (already taken from the bank at placement) into the champions' purses; message `Bounty paid: 100 to Sable Quint` |
### 6.3 Visibility to the enemy
- A flag is a world object: the enemy sees it (world + minimap) **only where it has vision**, like a unit.
- **Hunt** flags warn their victim's owner at placement and on each raise of +100 or more: `A bounty of 150 is on Vessa!` /
  `... on your Ember Hall!`, and a small coin icon floats above the hunted thing for its owner (always) and for the hunter's
  team (while visible). The bot reads `BountyBoard.hunts_on(team)`.

## 7. Champion economy
| Rule | Value |
|---|---|
| Purse | `Champion.purse: int` (essence). Start 50. Never goes to the team except by dismiss or death drop |
| Income | Bounties (6); **loot = 25 % of the victim's XP value** on its own killing blows (a Shade 10, a worker 4, a L5 wizard 68), in addition to the team's normal kill essence; Cutpurse +15; **Lost Caches** (champions may open them: essence rolls go to the purse, items to its inventory or the ground); death drops of enemy champions |
| Inventory | The `Inventory` of `items.md` with **4 item slots, 0 artifact slots** (champions never carry artifacts, never pick up the Ember Crown). Item stats, caps, passives and auras work as for wizards (Rally from a Warlord's Horn helps nearby soldiers) |
| Buying | Only from its wish list (4.4), at any shop it may use: own keep / barracks, **either Ruin Peddler** (12 m, `items.md` rule). Pays the full price from the purse; **20 % of the price goes to the team bank** as tithe (`Tithe from Sable Quint: 40` in the message line, at most once per 10 s, summed) |
| Selling | Never (except dismiss: 50 % to the team) |
| Consumables | Drinks an Ember Draught under **50 % HP** (shared potion cooldown rules); uses **Stride** (Ashen Greaves) when fleeing. Other actives are not on any list |

## 8. Autonomous behaviour (ai: `ChampionBrain`, a child of each champion)
### 8.1 Rule list (first rule that fires wins; R1-R5 every **0.5 s**, R6-R9 re-planned every **2.0 s** or at once on
an event: flag placed / raised / removed, damage taken while not fighting, arrived. Brains are staggered by 0.1 s per champion)
| # | Rule | Intent shown |
|---|---|---|
| R1 | Fallen / reviving: nothing | `Fallen` / `Returns in 24 s` |
| R2 | **Flee**: HP < flee threshold -> walk to the nearest **rest spot** (own completed keep / barracks within 15 m of it, or a tavern door that is not held), escape abilities fire (4.3). Stay until HP >= **85 %** or 60 s. Home rest heals **2 % max HP / s** within 15 m of an own keep or barracks | `Fleeing`, then `Resting` |
| R3 | **Potion**: HP < 50 % and an Ember Draught ready -> drink (does not stop other rules) | (no change) |
| R4 | **Join a fight**: it was hit in the last 2 s, or an own unit / building within its **engage radius** was hit in the last 2 s by a visible enemy, **and** danger there <= courage x power x 1.5 -> `command_attack` the best target (Coin-Cutter: lowest HP %, workers first; Oathwall: the enemy hitting your building / wizard; others: nearest). Mender: heals and keeps its distance instead | `Fighting` |
| R5 | **Unpaid** (3.2): skip R6 | `Unpaid!` |
| R6 | **Bounty**: keep the current flag while valid; switch only if another flag scores **>= 1.5 x** the current one. Else take the best flag with utility **>= 10** (8.2). Walk / attack-move to it; Guard = patrol within 14 m of the building; Escort = stay 4 m behind the unit | `Hunting bounty` / `Scouting bounty` / `Guarding` / `Escorting` |
| R7 | **Shopping**: purse >= the next wish-list price and (resting, or the nearest usable shop is <= 40 m and no flag is taken); at most one shopping detour per 60 s. Buys every affordable entry in order, then leaves | `Shopping` |
| R8 | **Personality default** (8.3) | `Exploring` / `Patrolling` / `Raiding` / `With the army` |
| R9 | **Idle**: wander within 10 m of its home (nearest own keep or barracks), a new point every 8-12 s | `Idle` |
The brain moves its champion with the normal `command_move` / `command_attack` / `command_attack_move` (internal calls;
only the player's input is blocked). Intents change the `Champion.intent` field and emit `intent_changed`.

### 8.2 Flag utility
`U = S x G x A x D x R x H`
| Factor | Formula |
|---|---|
| S, share | `stake / (1 + other own champions already pursuing it)` |
| G, greed | trait (4.2) |
| A, affinity | kind affinity (4.2), with the special multipliers (Oathwall home leash x 0.3, Coin-Cutter x 1.3 on workers / champions, Mender x 1.2 escorting the wizard) |
| D, distance | `30 / (30 + d)`, `d` = straight distance x 1.2 (no path queries) |
| R, risk | `danger` = strength of visible enemies within 15 m of the flag + known enemy towers (150) / keeps (250) whose range + 5 m covers it. `R = 1` if `danger <= courage x power`, else `courage x power / danger` (min 0.05) |
| H, health | current HP ratio, min 0.3 |
**Power** (also used by the bot) = `150 + 50 x level + items' total value / 5`, x HP ratio for danger checks (L1 = 200).
| Example (level 1, no pursuers, full HP) | U | Result |
|---|---|---|
| Coin-Cutter, Hunt 100 on a worker 50 m away, unguarded | 100 x 1.5 x 2.34 x 0.33 = **117** | Takes it |
| Oathwall, Explore 25 at 60 m | 25 x 0.8 x 0.2 x 0.29 = **1.2** | Ignores |
| Wayfinder, Explore 25 at 60 m | 25 x 1.0 x 2.0 x 0.29 = **14.7** | Takes it |
| Oathwall, Guard 50 on a hall 20 m away | 50 x 0.8 x 2.0 x 0.56 = **44.4** | Takes it |
| Coin-Cutter, Hunt 75 on a Shade among 5 Shades 25 m away (danger 400 vs 0.8 x 200 = 160, R 0.4) | 75 x 1.5 x 1.8 x 0.5 x 0.4 = **40.5** | Takes it (greed wins); R2 pulls it out at 35 % HP. A big stake can lure a champion into a bad fight: that is the player's risk |
Knob: the take threshold **10** (`ChampionType.bounty_threshold`, same for all in 9.C5).

### 8.3 Personality defaults (R8)
| Champion | Default |
|---|---|
| Wayfinder | **Explore**: sample 12 points on a ring of 30 m around it; score `2` unexplored / `1` explored-not-visible / skip visible, `+ distance from own keep / 60`, skip points with danger > courage x power or near a known tower / keep (before L4); walk to the best; Flare Arrow ahead. When nothing scores (map known): patrol between the 4 Lost Cache spots and the taverns |
| Oathwall | **Patrol**: every 20 s walk to the next own completed building (clockwise around the keep); the building hit most recently in the last 30 s first. Never chases more than 25 m past the last building |
| Coin-Cutter | **Raid**: an enemy worker seen by its team in the last 30 s with danger <= courage x power around it -> hunt it (no flag, loot only). Else the nearest **closed Lost Cache** -> open it. Else lurk at the tavern door nearer the enemy half |
| Mender | **Follow the army**: the own soldier with the most own soldiers within 10 m (sample <= 20 soldiers) is the group centre; stay 4 m behind it. Fewer than 3 soldiers: follow the wizard at 5 m. Wizard dead: rest at home |

### 8.4 Fog and knowledge (no map hacks, both teams)
- Champions are fog sources (their `sight_radius`) for their team; the Flare Arrow adds a temporary sight marker.
- Everything they "know" comes from their team's fog (`FogOfWar.state_at(team, pos)`, fog tracks PLAYER and ENEMY):
  visible enemy units, and enemy buildings on **explored** cells. Explore targets use `state_at`. Fog off: all visible.
- **ChampionSense** (one per team, refreshed every 0.5 s): one pass over `"units"` and `"buildings"`: visible enemies
  (position, strength, is_worker, target of whom), enemy workers seen in the last 30 s, known enemy towers / keeps. Brains
  only read this cache. Budget: all brains + senses **< 0.1 ms per frame on average** with 6 champions and 200 units;
  `PERF OK` unchanged.

## 9. UI: what must be shown (layout, sizes and looks: ui-designer, `docs/design/ui-champions.md`, task 9.D3)
| Element | Content | Interaction |
|---|---|---|
| **Champion bar** (3 slots, always visible) | Portrait, name, level badge, HP bar, **intent** text + colour (Fighting `(1.0, 0.55, 0.2)`, Fleeing `(0.95, 0.35, 0.3)`, Resting `(0.4, 0.9, 0.4)`, Hunting bounty `(1.0, 0.85, 0.4)`, Exploring / Scouting `(0.45, 0.85, 1.0)`, Guarding / Escorting `(0.6, 0.75, 1.0)`, Shopping `(0.75, 0.45, 1.0)`, Unpaid `(0.6, 0.6, 0.6)`, others white), purse. Fallen: grey, `Fallen` / `Returns in 24 s`. Empty slot: `+` | Click = **centre the camera** on it (no orders, no selection). Fallen or empty: opens the tavern window at its row. **F5 / F6 / F7** = centre on champion 1 / 2 / 3. Tooltip: personality line, current target (`Hunting bounty: Gloom Hall (150)`), 4 item icons, XP |
| **Inspect view** (click a champion in the world; own or visible enemy) | The single-unit view, read-only: name + title, level, HP, XP `x / y`, `Damage · Range · Speed · Armor`, intent, purse, 4 item slots (read-only), 3 abilities with cooldowns. Command card empty with the text `Champions act on their own. Bounty: R` | Nothing can be ordered. Box select, double-click, groups, F2 skip champions |
| **Tavern window** (Y, tavern click) | 4 rows: portrait, name + title (name A or B), role, personality line, level-1 stats, the 3 abilities (one line each), price `250 crystals · 100 essence · 2 pop`, status: `Hire` (disabled + reason), or `Hired · Level 3 · Hunting bounty`, or fallen: `Revive 150` + `Dismiss`. Footer: `Upkeep 1 essence / 10 s per champion · Tavern opens at 2:00` | Buttons call `ChampionGuild.hire / revive / dismiss`. Esc / Y closes |
| **Bounty mode** (R) | Cursor coin-flag with the kind icon and `Hunt · 75 essence` / `Explore · 25` / `Guard · 50` / `Escort · 50` / `Raise +25` or the refusal reason in red | As 6.2 |
| **Flag card** (a flag selected) | Kind, target, stake, paid so far, pursuers (portrait chips), time left (Guard / Escort / lost Hunt target) | Command card: `Raise +25 Z` (Shift = +100), `Remove Del` (tooltip shows the refund) |
| **World flag** | Own flags always; enemy flags in vision: the 3D flag (9.V6) + `Label3D` stake in gold | Clickable (layer 2, group `"bounties"`) |
| **Minimap** | Own champions 5 x 5 circle in the own colour with a 1 px gold border; enemy champions when visible; flags 4 x 4 gold coin with a team-colour border (enemy flags only when visible); taverns (section 2) | |
| **Messages** | `Tamsin Farrow joins you`, `Sable Quint took your bounty on the Gloom Hall`, `Bounty paid: 100 to Sable Quint`, `Bounty refunded: 75`, `A bounty of 150 is on Vessa!`, `Garran Stoneward has fallen`, `Your champions are unpaid: they ignore bounties`, `Tithe from Sable Quint: 40` | `show_message` |
| Help text | Adds `R: bounty    Y: tavern    F5-F7: find champion` | |
| Barks | 4.5, `Label3D` 3 s, white font 32 with a 2 px black outline, `pixel_size` 0.006, 0.6 m above the HP bar | Only visible champions |
New keys (physical, for the lead's Keys line): **R** bounty mode, **Y** tavern window, **F5 / F6 / F7** find champion 1-3; with a flag
selected **Z** raise (+ Shift), **Delete** remove. R and Y are free (the old "Keep Q W E R T Y" line is stale: buildings use Z X C V B).

## 10. The bot (ai: extends `ai.md` with rule 9; knobs in `AIProfile` / `data/ai/*.tres`)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `champion_max` | 1 | 2 | 3 |
| Hire order | Oathwall | Coin-Cutter, Oathwall | Coin-Cutter, Mender, Wayfinder |
| Earliest hire | 6:00 | 3:00 | 2:00 |
| Hire when | crystals >= price + 150, essence >= price, no build waiting (20 s rule), the chosen tavern not held |
| Revive | When essence allows, before items (normal / hard); after items (easy) |
| Bounty budget | Guard flags only | Stakes of active flags <= 25 % of essence above the next item price, max 2 flags | 40 %, max 3 flags |
Bounty rules (normal / hard; first that applies, one per tick):
| # | Trigger | Flag |
|---|---|---|
| B1 | Rule 1 intrusion on a building and no Guard flag | **Guard 50** on that building (easy too) |
| B2 | No attack group out; a seen enemy forward hall (X1 / X2 mirror) or 3+ enemy workers at a node > 30 m from their keep | **Hunt 100** on the hall / the nearest of those workers (max 1 such flag) |
| B3 | Vessa seen below 40 % HP within 30 m of a bot champion | **Hunt 150** on her |
| B4 | The enemy natural or rich hall spot not seen for 120 s (hard 90 s) | **Explore 25** there, every 120 s |
The bot never removes flags (they expire by their own rules). Strength: an own champion within 20 m of the rally counts
its power (8.2) in `own_strength`; a seen enemy champion counts its power in `seen_strength`.

## 11. Campaign
- Champions appear only in missions with `tavern_enabled = true` (none before mission 3; missions 1-2 unchanged).
- **Companion**: after a victory, the choice screen lists the champions hired in that mission (alive or fallen); the
  player picks **one** (or none). Carried: archetype, name variant, the 4 item slots, purse at **50 %, cap 300**. Level
  resets to 1 (like the wizard). It starts the next mission beside the wizard as roster slot 1 (no hire cost; the next
  hire is the "2nd" price). Save key `companion: {id, variant, items, purse}` in the campaign save (systems).
- A companion who dies in a mission can be revived there as usual; if fallen at the end it is still carried (revived free).

## 12. Balance
| | L1 | L4 | L6 | Worth in soldier crystals (L1 / L6, no items) |
|---|---|---|---|---|
| Wayfinder HP / damage | 260 / 13 | 322 / 16.1 | 364 / 18.2 | ~200 / ~320, plus sight 18 and Flare vision |
| Oathwall | 520 / 15 (armor 20) | 645 / 18.6 | 728 / 21 | ~280 / ~420 as a defender with taunt + tower cover |
| Coin-Cutter | 300 / 17 | 372 / 21.1 | 420 / 23.8 | ~250 / ~380; ~500 with Blazing Edge (~57 DPS) |
| Mender | 280 / 9, heal 50 / 7 s | heal 62 | heal 70 | ~13 HP / s to an army at L1 (~4 Bloomtenders) |
- **Fight checks.** L1 Coin-Cutter vs 2 Shades: wins with ~48 % HP. Vs 3 Shades: flees at 35 % after killing one.
  L6 with Blazing Edge vs 4 Shades: wins with ~50 % HP; vs 8: flees. L1 Oathwall + one spire vs 3 Shades at a hall: holds.
- **Vs the wizard.** A level-6 itemised wizard is ~1 000 crystals of soldiers (`items.md`); the best champion ~500-650.
  **No champion outclasses the wizard; three together are an army wing.**
- **Cost of 3 champions over 20 min:** 750 crystals + 300 essence to hire, ~250 upkeep, ~600-1 200 in bounties (20 % of
  what they spend on items comes back) = about 750 crystals + 1 300 essence (~1 000 crystal-equivalent) + 6 pop, for
  ~1 000-1 400 of late value + free scouting and base defence. Fair, not mandatory: an army-only player keeps 6 pop and 750 crystals.
- **Timing (normal):** first hire ~2:30-4:00 (= one barracks cycle of crystals), L2 ~5:00, L4 ~12:00-14:00, L6 rare.
- **Watch in playtest:** Mender + Nature regen (the `balance-2.md` D1 sustain problem); Coin-Cutter worker raids before 6:00.
- **Knobs (one at a time):** growth +8 % -> +6 %; hire prices +50 crystals; upkeep 1 -> 2 per 10 s; Mending Draught 50 -> 40;
  Coin-Cutter damage 17 -> 15; tithe 20 % -> 10 %; loot 25 % -> 15 %; take threshold 10 -> 15.

## 13. Proposed contracts (the lead freezes them in `CLAUDE.md` before phase 1: task 9.L1)
- **Champion** (`scripts/units/champion.gd`, `class_name Champion extends Unit`, groups `"units"`, `"champions"`):
  `champion_type: ChampionType`, `variant: int` (0 = name A, 1 = B), `display_name`, `level` (1-6), `xp`, `xp_to_next() -> int`,
  `add_xp(amount)`, `purse: int`, `add_purse(n)`, `spend_purse(n) -> bool`, `intent: StringName`, `intent_target: Node3D`,
  `set_intent(id, target)`, `inventory: Inventory` (4 slots), `abilities: ChampionAbilities`, `brain: Node`,
  `power() -> float`, `is_unpaid: bool`, `get_save_state() -> Dictionary`, `apply_save_state(d)`. Signals `intent_changed(champion,
  intent)`, `purse_changed(amount)`, inherited `level_changed`, `died`. Creates children `"ChampionAbilities"` and `"Brain"`
  (`res://scripts/ai/champion_brain.gd`, if the script exists) in `_ready`, like `SpellCaster`.
- **Unit**: `is_commandable() -> bool` (true; Champion false). SelectionManager never selects-for-orders a unit that returns false.
  Statuses `taunted`, `dazed`, `braced`, `marked` (4.3). `VETERANCY_NAMES[3]` = `"Paragon"`.
- **ChampionType** (`data/champions/<id>.tres`): `id`, `title`, `names: PackedStringArray` (2), `role`, the stat fields of
  `UnitType` used here + `armor`, `sight_radius`, `growth_pct` (0.08), `flee_pct`, `traits: Dictionary` (greed, courage,
  engage_radius), `affinity: Dictionary` (hunt, explore, guard, escort), `bounty_threshold` (10), `ability_ids` (3),
  `wishlist: Array[StringName]`, `personality_line`, `barks: Dictionary`, `model_scene`, `projectile_color`. `static find(id)`, `all()`.
- **ChampionAbilities** (`scripts/units/champion_abilities.gd`): `ability_ids()`, `is_unlocked(id)`, `cooldown_left(id)`,
  `cast(id, target) -> String` (`""`, `"Dead"`, `"Locked"`, `"On cooldown"`, `"Invalid target"`), signal `ability_cast(id)`.
- **ChampionGuild** (`scripts/world/champion_guild.gd`, one per team, group `"champion_guilds"`, `static for_team(team)`):
  `champions: Array` (<= 3), `is_open() -> bool`, `hire_cost(id) -> Dictionary {crystals, essence}`, `can_hire(id) -> String`,
  `hire(id) -> String`, `can_revive(ch)`, `revive(ch) -> String`, `revive_time_left(ch) -> float`, `dismiss(ch)`,
  signals `roster_changed`, `champion_hired(ch)`, `champion_fallen(ch)`, `champion_revived(ch)`.
- **BountyBoard** (`scripts/world/bounty_board.gd`, one per team, `static for_team(team)`): `bounties: Array[Bounty]`,
  `kind_for(target) -> int`, `min_stake(kind) -> int`, `place(kind, target: Node3D, pos: Vector3) -> String`,
  `raise(bounty, amount) -> String`, `remove(bounty) -> int` (refund), `hunts_on(team) -> Array`, signals `bounty_placed`,
  `bounty_paid(bounty, champion, amount)`, `bounty_ended(bounty, reason)`. **Bounty** (`scripts/world/bounty.gd`, Node3D, group
  `"bounties"`, layer 2): `team`, `kind` (`HUNT`, `EXPLORE`, `GUARD`, `ESCORT`), `target`, `stake`, `paid`, `pursuers: Array`,
  `add_pursuer(ch)`, `remove_pursuer(ch)`, `is_valid()`, `time_left()`.
- **SightMarker** (`scripts/world/sight_marker.gd`): `team`, `sight_radius`, `lifetime`; FogOfWar stamps nodes in group
  `"fog_sources"` like units.
- **Inventory**: `slot_count` / `artifact_count` per owner (6 / 2 wizards, 4 / 0 champions); when the owner has a `purse`,
  `buy` pays from it and credits the 20 % tithe to the team bank; `next_wishlist_buy(list) -> ItemType` helper.
- **Champion VFX** (`art/vfx/champion_vfx.gd`, like `spell_vfx.gd`): `play(ability_id, caster, target_or_point)`.
- Ownership: `data/champions/` = gameplay-coder; `art/units/champions/<id>/`, `art/buildings/tavern/`, `art/vfx/champion_*` = tech-artists.

## 14. What changes in other specs
- `levels.md`: veterancy rank 4 is `Paragon`; victim table gains `Champion: 100 + 25 x level`; champion levels (section 5).
- `items.md`: champion inventories (4 slots, no artifacts), purse buying, 20 % tithe, champions open Lost Caches.
- `skirmish-1v1.md`: 2 taverns + clearings + reveal at start, open at 2:00. Nothing else (win rules unchanged: champions are not buildings).
- `fog-of-war.md`: champion sight radii (4.1); `"fog_sources"` group; taverns explored from 0:00.
- `ai.md`: rule 9 (section 10); champion power in the strength sums.
- `ui-hud.md` / `ui-style.md`: new champion bar, tavern window, flag card, bounty cursor (layout by 9.D3).
- `CLAUDE.md` (lead): contracts of section 13; Keys **R, Y, F5-F7**, flag **Z / Delete**; owner rows for the new folders.

## 15. Task list (step 9)
**Phase 0 (before coders):** 9.L1 lead, 9.D3 ui-designer. **Phase 1 (12 in parallel, no shared files):** 9.C1-9.C8,
9.V1-9.V4. **Phase 1b (as slots free):** 9.V5, 9.V6. **Phase 2:** 9.C9, 9.C10, 9.C11, then 9.D4 after the playtest.
Phase-1 tests use the frozen contracts and may stub the other parts inside their own test file.
| Id | Agent | Task | Files |
|---|---|---|---|
| 9.L1 | lead | Freeze section 13 in `CLAUDE.md`, the Keys line, owner rows; add ids to `waves.md` | `CLAUDE.md`, `docs/plan/` |
| 9.D3 | ui-designer | Layout of the champion bar, inspect view, tavern window, bounty cursor, flag card, minimap icons | `docs/design/ui-champions.md` |
| 9.C1 | gameplay-coder-high [H] | `Champion`, `ChampionType`, 4 `.tres`, levels / XP / loot / death drop / home rest, `is_commandable`, 4 new statuses, `Paragon`, save state | `scripts/units/champion.gd`, `champion_type.gd`, `unit.gd`, `wizard.gd` (`xp_value_of`), `data/champions/` |
| 9.C2 | gameplay-coder | The 12 abilities with autocast triggers | `scripts/units/champion_abilities.gd` |
| 9.C3 | systems-coder-high [H] | Taverns on the map, `ChampionGuild` (hire / costs / upkeep / unpaid / revive / dismiss / held), campaign companion save | `scripts/world/tavern.gd`, `champion_guild.gd`, `skirmish.gd`, `scripts/campaign/campaign_state.gd` |
| 9.C4 | systems-coder | `BountyBoard`, `Bounty`, payouts / refunds / expiry / warnings, `SightMarker` + fog group, champions open caches | `scripts/world/bounty_board.gd`, `bounty.gd`, `sight_marker.gd`, `fog_of_war.gd` (group only), `lost_cache.gd` |
| 9.C5 | ai-coder | `ChampionBrain` (R1-R9, utility, defaults), `ChampionSense` | `scripts/ai/champion_brain.gd`, `champion_sense.gd` |
| 9.C6 | items-coder | Per-owner slot counts, purse buying + tithe, wish-list helper, champion potion / Stride use API | `scripts/items/inventory.gd`, `item_actives.gd` |
| 9.C7 | ui-coder | Champion bar, inspect view, tavern window, Y, F5-F7 | `scripts/ui/champion_bar.gd`, `tavern_window.gd`, `selection_panel.gd` (inspect only), `hud.gd` (wiring) |
| 9.C8 | ui-coder | Bounty mode R, flag card, world flag labels, minimap icons, selection filter, barks and messages | `scripts/ui/bounty_mode.gd`, `flag_card.gd`, `selection_manager.gd`, `command_card.gd`, `minimap.gd`, `scripts/vfx/champion_barks.gd` |
| 9.V1 | tech-artist | Wayfinder model + variant B | `art/units/champions/wayfinder/` |
| 9.V2 | tech-artist | Oathwall model + variant B | `art/units/champions/oathwall/` |
| 9.V3 | tech-artist | Coin-Cutter model + variant B | `art/units/champions/coin_cutter/` |
| 9.V4 | tech-artist | Mender model + variant B | `art/units/champions/mender/` |
| 9.V5 | tech-artist (VFX) | 12 ability effects + `champion_vfx.gd` | `art/vfx/champion_vfx.gd`, `art/vfx/champion_*` |
| 9.V6 | tech-artist | Tavern building + bounty flag (4 kind icons) | `art/buildings/tavern/` |
| 9.C9 | ai-coder | The bot hires, revives and places bounties; strength | `scripts/ai/ai_champions.gd`, `commander.gd`, `ai_profile.gd`, `data/ai/*.tres` |
| 9.C10 | gameplay-coder | Plug the 4 models (`ChampionType.model_scene`), animation hooks (`play_cast(ability_id)`), VFX calls, gold HP-bar frame | `scripts/units/`, `data/champions/` |
| 9.C11 | lead | Integration + headless run (below) | `tests/` (lead) |
| 9.D4 | game-designer | Balance check from the 9.C11 logs and the playtest; knobs of section 12 | `docs/design/champions.md` |

## Done when
- [ ] 9.L1: section 13 is in `CLAUDE.md`; Keys line has R, Y, F5-F7, flag Z / Delete; owners for `data/champions/`, `art/units/champions/`, `art/buildings/tavern/`.
- [ ] 9.D3: `ui-champions.md` gives positions / sizes / looks at 1600 x 900 for every element of section 9, consistent with `ui-style.md`.
- [ ] 9.C1: 4 `ChampionType` files with the 4.1 / 4.2 numbers; a spawned Coin-Cutter has 300 HP / armor 5 / 17 dmg; at 150 XP it is level 2 with 324 HP and 18.4 dmg, healed by 24; level 6 at 1 750 XP, then `MAX`; killing blow on a Shade gives 40 XP and 10 purse, a team kill 10 m away gives 10 XP, 13 m gives 0; its death drops 30 % of a 200 purse (60) to the killer's bank and its XP value is 125 at L1; `is_commandable()` false (true on soldiers); `taunted` / `dazed` / `braced` / `marked` work (a `marked` Shade takes 11.5 from a 10 hit; `braced` 7); rest heals 2 % / s within 15 m of an own keep; `get_save_state` / `apply_save_state` round-trip level, XP, purse, items; `VETERANCY_NAMES[3] == "Paragon"`.
- [ ] 9.C2: each ability's numbers and trigger (4.3) in a test: Flare Arrow makes a point 18 m away visible for 6 s; Snare roots 1.5 s (0.75 s on a hero); Trailblaze only from L4; Oath of Iron taunts 3 non-hero enemies within 6 m and not the wizard; Shield Bash dazes 0.8 s; Bulwark roots itself 6 s and braces allies within 5 m; Cutpurse adds 25 and 15 purse on a kill; Smoke Pouch shrouds 3 s and clears enemy targets; Marked for Coin x1.15 for 6 s; Mending Draught heals the lowest-HP ally by 50 (62 at L4), Soothing Circle 30 over 5 s, Lifeline shields 100 for 5 s; `spell_power` and `cooldown_reduction` apply; `cast` reasons in order.
- [ ] 9.C3: taverns at `(-15, -15)` / `(15, 15)` with clearing 6, invulnerable, explored for both teams at 0:00, open at 2:00; hire costs 200+75 / 250+100 / 300+125 and pop 2; refusal reasons in order (test each); the champion appears at the free tavern door nearer the wizard 3 s after paying, name A for the first hire of an archetype, B for the other team's; upkeep 1 / 10 s per living champion, Unpaid after 3 failed ticks; revive 60 + 30 x level after 15 + 5 x level s at the keep spawn; dismiss pays 50 % purse + 50 % items; companion saved and restored in a campaign save round-trip.
- [ ] 9.C4: place / raise / remove with the reasons and limits of 6.2 (5 flags, max 500, Explore merge within 8 m); Hunt pays contributors equally and refunds 100 % without one; Hunt expires 60 s after the target is unseen; Explore pays the first champion within 4 m; Guard / Escort pay `stake / 9` every 10 s to champions in range and refund the rest at 180 s or on death; removal refunds 100 % / 50 % + walk fee; hunted owner gets the warning and `hunts_on` lists it; bounty XP = half the payment; enemy sees flags only in its vision; a champion opening a Lost Cache puts the essence in its purse.
- [ ] 9.C5: a headless scene proves each rule: flee at the threshold to the nearest rest spot and back at 85 %; potion under 50 %; joins a fight within its engage radius; Unpaid skips flags; the utility examples of 8.2 give the listed decisions; hysteresis 1.5 x; shopping detour only within 40 m and once per 60 s; Wayfinder explores unexplored cells first and avoids a known tower before L4; Oathwall stays within 25 m of buildings; Coin-Cutter raids a seen worker and opens a cache; Mender follows the largest group 4 m behind; decisions use only the team's fog; `PERF OK` with 6 champions and 200 units.
- [ ] 9.C6: a champion inventory has 4 slots and no artifact slots; buying Ember Shard from a 300 purse leaves 100 and adds 40 to the team bank; the wish-list helper returns the next buyable entry (combines consume parts); wizards unchanged (6 + 2, bank pays, no tithe); champions can use Ember Draught and Stride through the API.
- [ ] 9.C7: the bar shows 3 slots with portrait, name, level, HP, intent text in its colour, purse; fallen / reviving countdown; clicking centres the camera and never selects or orders; F5-F7 centre; Y and a tavern click open the window with the 4 rows, prices, reasons, Hired / Revive / Dismiss states; inspect view read-only with an empty command card and the hint line; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 9.C8: R enters bounty mode with the kind and price under the cursor, Shift+click stays, Esc / right-click cancel; the flag card raises with Z / Shift+Z and removes with Delete showing the refund; box select, double-click, groups and F2 never include a champion; right-click never orders one; world flag stake labels; minimap champions and flags per section 9; barks and messages per 4.5 / section 9.
- [ ] 9.V1-9.V4: each scene follows 4.6 and `art-units.md` (pivots, merge, hooks incl. `play_cast`, `set_team_color` on sash / pennant only, variant B toggle, <= 26 meshes, <= 16 draw instances, 0 lights, <= 5 materials); a contact sheet `docs/art/screens/champions_silhouette.png` tells the four apart in black; headless instantiation without errors.
- [ ] 9.V5: 12 effects, one-shot emitters pre-built and restarted, none looping beyond their duration, `play(ability_id, caster, target)` for each id; no new materials at runtime.
- [ ] 9.V6: tavern 6 x 6 footprint, ~6 m tall, timber and moss stone with a hanging lantern sign (glow `(1.0, 0.8, 0.4)`), neutral palette, readable at 60 m; bounty flag 1.6 m pole, team-colour pennant (`set_team_color`), gold coin disc r 0.35 spinning, 4 kind icons (crossed blades, eye, shield, linked rings).
- [ ] 9.C9: normal bot hires a Coin-Cutter between 3:00 and 5:00 and an Oathwall later (never more than 2), easy 1 after 6:00, hard 3 from 2:00; it revives before buying items (normal / hard); places B1-B4 flags under their triggers and budgets; counts champion power in its strengths; `PERF OK`.
- [ ] 9.C10: the 4 models replace the placeholders; ability casts play `play_cast` and the VFX; champions show a gold-framed HP bar and no chevrons; the smoke test still prints `victory=true`.
- [ ] 9.C11 (lead): headless 1v1 normal bot vs normal bot with champions, cap 24:00: both sides hire, at least one bounty of each kind is paid, no champion ever receives a player order, match length stays 14:00-22:00, `PERF OK`.
