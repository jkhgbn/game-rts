# Kingdom: Nature (Ysolde). Step 8

Written 2026-09-25 (task 5.D3). Source of truth for Step 8 tasks 8.L1-8.D1 (list at the end). Same formats as
`kingdom-ice.md`; the shared mechanics (statuses incl. `rooted`, `idle_regen_pct`, support autocast `heal`, `lifetime`,
`BuildingType` aura / regen fields) are **defined in `kingdom-ice.md` section 2 and built in Step 7 (7.G1)**.
Metres, seconds. Everything here is original.

## 1. Identity and play style
| | Nature (Ysolde) |
|---|---|
| One line | **The swarm that grows back.** Cheap, fragile, many bodies; everything heals between fights; the fastest start. |
| Kingdom passive "Verdant" | Nature units (and Ysolde) regenerate **1.5 % max HP / s after 4 s without taking damage** (`idle_regen_pct`; Bramblehorn 3 %). Nature buildings regenerate **1 % / s after 10 s** without damage, have **-10 % HP** and **-15 % build time** vs Fire. **3 Seed Hollows** allowed: pop cap **50**. Workers cost 40. |
| How it wins | Saturates workers first, attacks early with Thornlings, retreats, regrows for free, comes back. Out-trades per crystal; summons and heals win long skirmishes of attrition. |
| vs Fire | Fire's area burst is the natural counter (Fireball rank 1 one-shots a Burr Slinger, rank 2 one-shots a Thornling). Nature must spread out, bait Fireballs and hit when Vessa is out of mana. |
| vs Shadow | Shadow's elite Knights and life-drain hate being swarmed: 3 Thornlings cost less than one Shade + one Hound. Soul Siphon on a clump is the danger. |
| **Weakness** | **Fragile and pop-hungry.** Low HP everywhere: area damage deletes it; at equal pop it is the weakest army (see 9). Its healing needs downtime: constant pressure (towers, a second front) denies the regen. Buildings are the easiest to kill. |

## 2. Units (UnitType; trained at the Grove Hall, worker at the keep). All have `idle_regen_pct` 1.5 unless listed
| id | Display name | Role | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Colour (secondary cloth) | Cost | Pop | Train (s) | Key | kill_xp | Extra |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `sprigling` | Sprigling | Worker | 45 | 3 | 1.4 | 1.2 | 4.6 | 0 | 0.35 | 1.2 | `(0.55, 0.50, 0.30)` | **40** | 1 | 10 | Z (keep) | 15 | `is_worker` |
| `thornling` | Thornling | Cheap melee swarm | 70 | 8 | 1.5 | 0.9 | 5.4 | 8 | 0.4 | 1.4 | `(0.30, 0.60, 0.20)` | 55 | 1 | 12 | Z | 30 | - |
| `burr_slinger` | Burr Slinger | Ranged | 50 | 7 | 8.5 | 1.2 | 5.0 | 10 | 0.4 | 1.5 | `(0.60, 0.70, 0.25)`, bolt `(0.55, 0.40, 0.20)` | 70 | 1 | 14 | X | 35 | - |
| `bloomtender` | Bloomtender | Support, heals | 60 | 5 | 7.0 | 1.5 | 4.8 | 9 | 0.45 | 1.6 | `(0.95, 0.60, 0.75)` (blossom), bolt `(0.75, 1.00, 0.40)` | 90 | 1 | 18 | C | 45 | `heal` 12 every 3 s, range 7 |
| `bramblehorn` | Bramblehorn | Heavy bruiser (quadruped) | 380 | 18 | 1.8 | 1.2 | 4.6 | 9 | 0.7 | 2.2 | `(0.28, 0.40, 0.18)` | 200 | **2** | 34 | V | 100 | `idle_regen_pct` 3.0 |
| `sapling` | Sapling (summon, never trained) | Temporary melee | 90 | 9 | 1.5 | 1.0 | 4.8 | 10 | 0.4 | 1.2 | `(0.45, 0.75, 0.30)` | 0 | **0** | - | - | **0** | `lifetime` 25 / 30 s, gives no essence, never levels |
Bot rule: Bramblehorn only when crystals >= 200 and soldier pop >= 6.

## 3. The wizard: Ysolde, Nature Wizard (pop 0)
| id | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Body / hat / orb | Mana | Regen /s |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `ysolde` | 340 | 13 | 7.5 | 1.2 | 4.8 | 9 | 0.5 | 2.0 | `(0.35, 0.70, 0.25)` / `(0.15, 0.40, 0.15)` / `(0.75, 1.00, 0.40)` | 110 | 4.5 |
Growth: **+22 HP / +2 dmg / +12 mana / +0.3 regen** per level -> L6 450 / 23 / 170 / 6.0, L8 494 / 27 / 194 / 6.6.
Verdant regen applies to her (1.5 % / s after 4 s). Fastest, frailest, most mana of the four.

### 3.1 Spells, rank 1 (`spells.md` format; keys F / Q / E)
| id | Name | Key | Target | Mana | Cooldown | Range | Radius | Effect |
|---|---|---|---|---|---|---|---|---|
| `thornburst` | Thornburst | F | point | 35 | 5 | 14 | 3.0 | 40 damage to enemy units and buildings in the circle; enemy units `rooted` 1.5 s |
| `wild_bloom` | Wild Bloom | Q | area | 50 | 16 | 12 | 5.0 | Friendly units (soldiers, workers, wizards; not buildings, not Saplings) inside at cast heal 60 over 5 s (6 every 0.5 s) |
| `call_the_thicket` | Call the Thicket | E | point | 60 | 45 | 10 | 1.2 (ring) | 3 Saplings sprout on a ring r 1.2 at the point (grow 0.5 s, then attack-move to the point's nearest enemy within 10 m, else hold); wither after 25 s |
Tooltips: `Thornburst  [F]\n35 mana · 40 damage · radius 3\nThorns erupt and root enemies in place.` ·
`Wild Bloom  [Q]\n50 mana · 16 s cooldown · radius 5\nHeals friends in the circle over 5 s.` ·
`Call the Thicket  [E]\n60 mana · 45 s cooldown · 3 Saplings\nSaplings fight for 25 s, then wither.` Icons `TB`, `WB`, `CT`.
Saplings are the caster's team, selectable, controllable, show a lifetime bar (8.U1), pop 0, and give **0 XP and
0 essence** to the killer. Healing is multiplied by `spell_power` (items.md).

### 3.2 Ranks (F 1/3/5, Q 2/4/6, E 4/7)
| Spell | Rank 1 | Rank 2 | Rank 3 |
|---|---|---|---|
| Thornburst (F), 35 mana, range 14 | 40 damage, radius 3.0, root 1.5 s, cooldown 5 | 50 damage, radius 3.25, root 2.0 s, cooldown 5 | 62 damage, radius 3.5, root 2.5 s, cooldown 4 |
| Wild Bloom (Q), 50 mana, range 12 | 60 over 5 s, radius 5.0, cooldown 16 | 90 over 6 s, radius 5.5, cooldown 16 | 120 over 6 s, radius 6.0, cooldown 14 |
| Call the Thicket (E), 60 mana, range 10 | 3 Saplings, 25 s, cooldown 45 | 5 Saplings, 30 s, cooldown 40 | - |

### 3.3 AI cast rules (bot Ysolde; every 0.5 s, first rule that applies, one cast per check, skip unlearned)
1. **Wild Bloom**: ready, mana >= 50, and (an own soldier has >= 3 own soldiers under 60 % HP within 5 m of it, itself
   included: centre there; or Ysolde HP < 45 %: centre on herself).
2. **Call the Thicket**: ready, mana >= 60, >= 4 enemy units within 12 m of Ysolde; point = 3 m from the nearest enemy
   toward Ysolde, clamped to 10 m.
3. **Thornburst**: ready, mana >= 35: an enemy unit within 14 m with >= 2 enemy units within 3 m (itself included),
   centre on the best; else the enemy wizard if in range.
`ai.md` rule 8 retreat (HP < 35 %): Wild Bloom on herself first if ready.

## 4. Buildings (BuildingType; `buildings.md` rules unless listed). All: `idle_regen_pct` 1.0 once completed
| id | Display name | Cost | Build time | max_hp | Footprint | Height | Gives | Trains / attack | Build key |
|---|---|---|---|---|---|---|---|---|---|
| `nature_keep` | Heartwood | - | - | 1350 | 3 x 3 | 6 | +20 pop, drop-off, shop | Sprigling Z | - |
| `nature_barracks` | Grove Hall | 130 | 38 | 810 | 3 x 3 | 4 | drop-off, shop | Thornling Z, Burr Slinger X, Bloomtender C, Bramblehorn V | X |
| `nature_hollow` | Seed Hollow | 60 | 20 | 360 | 2 x 2 | 3 | +10 pop, **max 3** (cap 50) | - | Z |
| `nature_tower` | Bramble Spire | 100 | 30 | 540 | 1 x 1 | 5 | sight 15; **aura** r 8: friendly non-worker units `hp_regen` +2 (`aura:bramble`, always on) | dmg 10, range 10, cooldown 1.2, aggro 10, bolt `(0.55, 0.40, 0.20)` | C |
- Building XP / essence: Grove Hall 100, Seed Hollow 40, Bramble Spire 80, Heartwood 200 (same as Fire / Shadow).
- The Hearth rule "max 2" becomes "`max_count` of the kingdom's house" (2 Fire / Shadow / Ice, 3 Nature). Message unchanged.

## 5. Items (add to `items.md`; every base shop, any wizard)
| id | Name | Tier | Parts + recipe = total | Stats | Passive / active |
|---|---|---|---|---|---|
| `verdant_seed` | Verdant Seed | Component | 180 | `hp_regen` +2.0, `max_hp` +30 | - |
| `thornweave_vest` | Thornweave Vest | Mid | Verdant Seed + Ironbark Plate + 250 = **610** | `armor` +18, `hp_regen` +2 | **Barbs**: melee auto-attackers take 20 % of the damage they deal to the wizard (credited to her team) |
| `bloomcaller_staff` | Bloomcaller Staff | Mid | Verdant Seed + Duskglass Lens + 250 = **630** | `spell_power` +20, `hp_regen` +2, `max_mana` +30 | **Blossom**: the wizard's spell heals and shields x1.25 (after `spell_power`) |
| `heart_of_the_grove` | Heart of the Grove | Top | Bloomcaller Staff + Warlord's Horn + 550 = **1 910** | `spell_power` +35, `max_hp` +200, `hp_regen` +4 | **Verdant Ward** (aura): soldiers within 10 m `hp_regen` +2; **Overgrowth** (active, self): friendly units within 8 m heal 100 over 5 s; cooldown 80, 0 mana |
Bot lists for Ysolde: **Normal** Verdant Seed, Duskglass Lens, **Bloomcaller Staff**, Ember Draught, Bone Charm, Ironbark Plate,
**Warlord's Horn**, **Heart of the Grove**, Swiftsoles, Wisp Lantern, **Ashen Greaves**. Easy = first 4. Hard = Normal + Ember
Draught after Heart of the Grove. Overgrowth: 3+ own soldiers within 8 m under 60 % HP (Rallying Cry rule).

## 6. Bot differences (extends `ai.md`)
| Rule | Nature change |
|---|---|
| Profile | `data/ai/nature_<difficulty>.tres`: `attack_ratio` -0.1 (normal 1.2), `worker_target_home` / `expanded` **7 / 10** (normal) |
| Build | Grove Hall at 0:00 (130: leaves 120 = 3 Spriglings queued); Seed Hollows at the V1 / V2 rule, **V3** at offset `(7, -15)` with the same rule once cap is 40; expansion X1 at **4:30** (not 6:00) |
| Mix (default / vs ranged / vs melee) | Thornling 45 / 55 / 30 %, Burr Slinger 25 / 10 / 40 %, Bloomtender 15 / 10 / 15 %, Bramblehorn 15 / 25 / 15 % |
| Retreat | At **50 %** HP (was 40 %); after a retreat the next attack also needs the group's average HP >= 85 % (or 30 s at the rally) |
| Scout | A Thornling (fastest unit) from 1:30 |

## 7. Art direction (brief; `art-keep.md` section 0, `art-units.md` rules)
Palette (building, `art-keep.md` 0.2 Nature row): team `(0.35, 0.70, 0.25)`, glow `(0.75, 1.00, 0.40)`, mossy stone
`(0.45, 0.42, 0.32)`, dark stone `(0.22, 0.20, 0.14)`, bark trim `(0.40, 0.28, 0.16)`, cloth shadow `(0.15, 0.40, 0.15)`.
Units: team cloth `(0.35, 0.70, 0.25)`, team dark `(0.15, 0.40, 0.15)`, skin bark-tan `(0.78, 0.66, 0.48)`, "metal" =
bark `(0.40, 0.28, 0.16)`, glow `(0.75, 1.00, 0.40)`, dark base `(0.18, 0.14, 0.08)`; blossom `(0.95, 0.60, 0.75)` only as
secondary cloth on Ysolde and the Bloomtender (<= 5 %). Ground decal: moss `(0.20, 0.35, 0.12, 0.50)`.

### 7.1 Heartwood (keep), 3 x 3, max height 14 m
Read at 40 m: a colossal twisted tree whose **roots are the walls**, a knot in the trunk glowing green, a round canopy
with three glowing seed-lanterns hanging under it. Mood: old forest, cradle, breathing. Wide roots, round top.
| Part | Shape, size | Position | Colour / emission |
|---|---|---|---|
| Root walls | 6 bent capsules r 0.6 h 3.5, lying around the plinth, tips sunk | ring r 2.6, y 0.6 | bark |
| Plinth | Cylinder r 3.2 h 0.6, 8 seg | (0, 0.3, 0) | dark stone + moss top |
| Trunk | 3 twisted cylinders top r 0.8 bottom r 1.6 h 9, rotated 0 / 120 / 240° with 15° twist | centre, base y 0.6 | bark |
| Gate | Arch hollow in the trunk: dark box 1.6 x 2.2 x 0.4 | -Z face of the trunk | dark stone, frame glow strip 1.5 |
| Heart knot | Sphere r 0.5 half sunk in the trunk | (0, 4.5, 1.2) | `rune_glow` 3.0, pulse 2.5 s |
| Canopy | 3 flattened spheres r 2.6 / 2.0 / 2.0 (y scale 0.6) | y 10.5-12.5, within 4 m of the centre | team, lighter tops |
| Seed-lanterns (3) | Sphere r 0.3 on a 1 m vine | under the canopy, y 8.5 | glow 2.5, swing +-8° over 3 s |
| Banners (2) | `banner.gdshader` leaf-shaped 0.9 x 2.0 | gate sides | team |
| Light | 1 OmniLight3D `(0.75, 1.00, 0.40)` energy 1.2 range 9 | y 6 | shadows off |
| Particles | pollen motes 40 rising (ADD), 16 falling leaves (MIX) | canopy | - |
Glowing points: heart knot, 3 lanterns (4). States per `art-keep.md` 8; damage = the canopy thins (scale 1.0 -> 0.7),
destroyed = the trunk splits and falls back. Grove Hall: a long hall whose roof is a living hedge with 3 blossoms.
Seed Hollow: a giant hollow seed-pod r 1.6 with a leaf roof. Bramble Spire: a 5 m twisted thorn trunk with a glowing bud
(blinks per shot) and a slow green pulse ring r 8 on the ground every 4 s (the aura).

### 7.2 Characters
| Unit | Height / radius | Concept | Silhouette at 40 m | Signature detail | Glow points |
|---|---|---|---|---|---|
| **Ysolde** | 2.0 / 0.5 | A young forest-queen in a leaf gown with a **wide crown of branches and blossoms**, a living staff that holds a glowing seed | Crown wider than the shoulders, staff with a leafy top, leaf cape | 8 petals drift from the crown; the seed opens into a flower on cast | seed 3.0, crown blossoms, eye bar |
| Sprigling | 1.2 / 0.35 | A small round sprout-creature with a **leaf on its head**, a wooden hoe and a seed pouch | Smallest unit, leaf sticking up | The head leaf bounces as it walks | none (dark eye bar) + carried crystal |
| Thornling | 1.4 / 0.4 | A lanky thorn imp, **two long thorn claws**, spiky back | Thin, hunched, claws | Back thorns (5 cones) | eyes 1.5 |
| Burr Slinger | 1.5 / 0.4 | A crouched slinger with a **long pod-launcher held sideways** | Narrow + long horizontal pod | Spiky burr loaded in the pod | pod tip 1.5 |
| Bloomtender | 1.6 / 0.45 | A robed caretaker under a **huge bell-flower hat**, a pole with a hanging pollen censer | Bell robe + bell hat (widest hat) | The censer puffs pollen on each heal | censer 1.5 |
| Bramblehorn | 2.2 / 0.7 | A huge moss-backed beast with **bramble-wrapped horns** | Long low mass + two big horns | Moss mane with 3 blossoms | eyes 1.5 |
| Sapling | 1.2 / 0.4 | A walking young tree: trunk body, leaf-ball head, root feet | Round head on a stick | Grows 0.2 -> 1.0 scale in 0.5 s; withers (brown, sinks) at the end | none |

## 8. Status and summon looks (8.V5)
`rooted`: see `kingdom-ice.md` 2.1. Thornburst: 12 thorn cones erupt in the circle (0 -> 0.8 m in 0.15 s, fade 0.6 s).
Wild Bloom: flat green ring r 5 + 30 rising petals, each healed unit gets a green `+` sparkle every tick. Verdant regen:
2 tiny green motes per second on a regenerating unit (hidden at LOD far). Heal beam: `(0.75, 1.00, 0.40)` 0.25 s.

## 9. Balance sanity check vs Fire, Shadow and Ice (CE / PE as defined in `kingdom-ice.md` 9)
| Unit | EHP | DPS | Cost | Pop | CE | PE | Speed | Note |
|---|---|---|---|---|---|---|---|---|
| Flame Guard / Shade / Rimeshield | 130 / 90 / 173 | 12 / 10 / 10 | 90 / 80 / 100 | 1 | 19.3 / 14.1 / 17.3 | 15.6 / 9.0 / 17.3 | 5.0 / 4.8 / 4.2 | lines |
| **Thornling** | 70 | 8.9 | 55 | 1 | **20.6** | 6.2 | 5.4 | best per crystal, worst per pop |
| Ember Archer / Nightbolt / Shardcaster | 70 / 65 / 84 | 7.5 / 7.7 / 6.4 | 100 / 100 / 110 | 1 | 5.3 / 5.0 / 4.5 | 5.3 / 5.0 / 5.4 | | ranged 9 |
| **Burr Slinger** | 50 | 5.8 | 70 | 1 | 6.0 | 2.9 | 5.0 | range 8.5; dies to one Fireball |
| **Bloomtender** | 60 | 3.3 | 90 | 1 | 2.5 | 2.0 | 4.8 | + 4 HP/s healing |
| Blaze Rider / Grave Hound | 220 / 60 | 20 / 11.4 | 180 / 70 | 2 / 1 | 13.6 / 14.0 | 11.0 / 6.9 | 7.5 / 7.0 | |
| **Bramblehorn** | 380 | 15.0 | 200 | 2 | 14.3 | 14.3 | 4.6 | + 3 % regen |
| Shadow Knight / Rime Colossus | 420 / 624 | 18.6 / 15.6 | 300 / 330 | 3 | 8.7 / 8.9 | 8.7 / 10.8 | 4.0 / 3.4 | |
| Ysolde (L1) | 340 | 10.8 | - | 0 | - | - | 4.8 | frailest, most mana; Saplings = 270 HP of free bodies per 45 s |
- 1 000 crystals of melee line (N² x value): **Thornlings 206 k** > Flame Guards 193 k > Rimeshields 173 k > Shades 141 k.
  At the pop cap: 50 Thornlings 1.56 M vs 40 Flame Guards 2.50 M vs 40 Rimeshields 2.76 M. Nature wins cheap early fights,
  must mix Bramblehorns (PE 14.3) late. The map holds ~2 950 crystals per side, so crystals, not pop, usually bind:
  the pop cap 50 lets Nature spend them all.
- Counters by design: Fireball rank 1 (60) one-shots a Burr Slinger, rank 2 (72) a Thornling; Soul Siphon rank 3 (70) a
  Thornling; Flash Freeze + chill stops the swarm's speed. Ice vs Nature: Ice wins maxed fights, Nature wins by tempo.
- Economy: Nature's opening is 3 workers at 0:00 (vs 2) and a hall 7 s sooner: about +40 crystals by 2:00 (+5 %).
- Knobs (playtest 8): too strong: Thornling cost 55 -> 60 (CE 17.3) or Verdant 1.5 -> 1.0 %; too weak: Thornling HP 70 -> 75
  (survives a rank-2 Fireball), Seed Hollow 60 -> 50.

## 10. Step 8 task list (20-minute boxes; files never overlap inside the step)
| Id | Task | Owner | Files |
|---|---|---|---|
| 8.L1 | Keys line says "the player's wizard" (not Vessa); skirmish `player_kingdom` in the contract; house `max_count` per kingdom | lead | `CLAUDE.md`, `docs/plan/` |
| 8.G1 | 6 Nature `UnitType` .tres (incl. Sapling); Ysolde's stats, growth and Verdant regen | gameplay | `data/units/nature_*.tres`, `scripts/units/wizard.gd` |
| 8.G2 **[H]** | Thornburst (root), Wild Bloom (HoT), Call the Thicket (summons with `lifetime`, 0 XP / essence) + ranks, Ysolde AI rules 3.3 | gameplay-high | `scripts/spells/`, `data/spells/` (Nature ids) |
| 8.S1 | 4 Nature `BuildingType` .tres, building regen, Bramble Spire aura, 3 hollows / cap 50 | systems | `scripts/buildings/`, `data/buildings/nature_*.tres` |
| 8.S2 | Kingdom select: any of the 4 kingdoms on each side (mirror allowed), right keep / workers / wizard / bot profile | systems | `scripts/world/skirmish.gd` |
| 8.U1 | Kingdom select in the skirmish setup (4 cards, colour + wizard name), Ysolde card / tooltips, Sapling lifetime bar, pop shows `/ 50` | ui | `scripts/ui/`, `scenes/ui/` |
| 8.I1 | 4 Nature items + Barbs, Blossom, Verdant Ward, Overgrowth | items | `data/items/`, `scripts/items/item_actives.gd` |
| 8.A1 | Nature bot: profile, V3 slot, mix, retreat / regrow rule, Ysolde casts, item list; any-kingdom bot vs bot test | ai | `scripts/ai/`, `data/ai/nature_*.tres` |
| 8.V1 | Heartwood (7.1) + states | tech-artist | `art/buildings/nature_keep*` |
| 8.V2 | Grove Hall, Seed Hollow, Bramble Spire + states | tech-artist | `art/buildings/nature_{hall,hollow,spire}*` |
| 8.V3 | Ysolde + Sprigling + Thornling + Sapling | tech-artist | `art/units/wizards/ysolde*`, `art/units/nature/{sprigling,thornling,sapling}*` |
| 8.V4 | Burr Slinger, Bloomtender, Bramblehorn | tech-artist | `art/units/nature/{slinger,bloomtender,bramblehorn}*` |
| 8.V5 | VFX of section 8 | tech-artist | `art/vfx/nature_*` |
| 8.D1 | 4-kingdom balance pass from bot-vs-bot numbers (`balance-2.md`) | game-designer | `docs/design/` |
The Windows export is the lead's (not in this list).

## 11. Done when
- [ ] 8.G1: 6 units and Ysolde match sections 2-3; a Thornling at 20 HP regains full HP in ~48 s without damage and none while hit; Ysolde L6 = 450 / 23 / 170 / 6.0.
- [ ] 8.G2: test: Thornburst 40 + root 1.5 s (Vessa 0.75 s), rooted units still attack; Wild Bloom heals 60 over 5 s; 3 Saplings live 25 s, cost 0 pop, their death gives 0 XP and 0 essence; ranks 3.2 exact; bot Ysolde follows 3.3.
- [ ] 8.S1: numbers of section 4; a 4th hollow is refused; cap reaches 50; a Grove Hall regains 1 % / s after 10 s; soldiers within 8 m of a Bramble Spire get +2 HP/s.
- [ ] 8.S2 / 8.U1: every pair of the 4 kingdoms starts (16 combos, headless smoke per combo reaches 1:00 without errors).
- [ ] 8.I1: 4 items with those numbers; Blossom makes Wild Bloom rank 1 heal 75.
- [ ] 8.A1: headless normal run: Grove Hall at 0:00, 3 Spriglings queued, expansion by 5:00, retreat at 50 % and re-attack only at 85 % HP.
- [ ] 8.V1-8.V5: silhouette sheet names every Nature unit and building; `PERF OK` with 200 Nature units incl. regen motes.
