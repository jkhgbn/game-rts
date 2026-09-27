# Items: inventory, essence, recipes, shops, drops (wave 4)

Source of truth for 4.I1 (`ItemType`, `Inventory`, buy / sell, stat items), 4.I2 (recipes, actives, consumables),
4.G1 (on-hit, auras, spell hooks in unit code), 4.S1 (shops, drops, chests, campaign save), 4.U1 (inventory bar,
shop window, tooltips, ground items) and 4.A1 (the bot buys). Written 2026-09-25 (task 4.D1).
Everything here is original. Metres, seconds; positions `(x, z)` on Crown Hollow (`skirmish-1v1.md`).
Item stats go through the **Stats** contract only (`add_modifier("item:<slot>", stats)`).

## Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Who carries items | **Wizards only** (Vessa, Malrik). Soldiers get item **auras**, never slots | One inventory per team keeps the UI, the bot and the save small; auras still make items matter for the army |
| Inventory | **6 item slots + 2 artifact slots** (the 1v1 uses artifact slot 1 for the Ember Crown) | 6 = MOBA habit; artifacts must never push out a bought item |
| Currency | **Essence**, a second currency earned by fighting (kills, the camp, chests, a trickle). Crystals never buy items, except an optional exchange at the base shop | The map has only ~2 950 crystals per side for a whole match (6 nodes x 900 + 250); items priced in crystals would eat the army, and the wave 1-3 balance and bot would break |
| Keys | **Alt+1..6** use slots 1-6 (physical `KEY_1`..`KEY_6` with Alt), **Numpad 1-6** duplicate them, **T** opens / closes the shop; clicking a slot always works | 1-9 alone are control groups (RTS habit wins); Ctrl+digit = set group, Shift+digit = add, so Alt+digit = "the digit's item" follows the same pattern. T is free in the Keys line |
| Recipes | Buy the finished item at a shop: parts already carried are consumed, missing parts sold here are bought in the same click | No recipe scrolls to carry; one click, one price |
| Death | Items are **not** dropped on death in the 1v1 (only the Ember Crown, existing rule) | Respawn already costs 30-90 s; losing 2 000 essence too would end matches on one mistake |
| Campaign | The 6 slots and 2 equipped artifacts carry between missions; essence carries at 50 %, cap 1 500 | Building a hero across missions is the point; the cap stops mission-1 farming |

## Stats used by items (the Stats contract) and the maths
Base values are the `UnitType` / level numbers; items add named modifiers. Caps are on the **total** from items.
| Stat | Meaning | Base for wizards | Item cap |
|---|---|---|---|
| `max_hp`, `max_mana` | Flat. Raising a max **heals by the gain** (as levels do); lowering it (item sold) never kills, HP is clamped | levels.md | none |
| `hp_regen` | HP per second, anywhere (the 1 % / s keep healing of `skirmish-1v1.md` stacks on top) | 0 | +12 / s |
| `mana_regen` | Mana per second | 4.0 | +6 / s |
| `attack_damage` | Flat, applies to auto-attacks only (`_pct` multiplies base + flat) | 14 / 16 | none |
| `attack_cooldown` | `_pct` only from items (`-0.10` = 10 % faster). Floor: the cooldown never goes below **40 % of base** (with `haste` included) | 1.3 | -35 % |
| `move_speed` | Flat m/s | 4.6 / 4.4 | +2.5 |
| `armor` | Flat. Damage taken from **every source** (attacks, towers, spells, burns) is multiplied by `100 / (100 + armor)` when armor >= 0 and by `1 - armor / 100` when negative. 25 armor = -20 %, 50 = -33 %, 100 = -50 %. Applied inside `take_damage` after `shroud`; units, buildings and wardens have 0 | 0 | 150 (x0.4); floor -50 |
| `spell_power` | Percent: spell damage, spell healing, scorch / siphon ticks and item spell effects are multiplied by `1 + spell_power / 100`. Does not change mana costs or radii | 0 | 100 (x2) |
| `cooldown_reduction` | Percent: spell **and item active** cooldowns x `(1 - cdr / 100)`. Fireball has no cooldown, so Vessa gains less from it (deliberate) | 0 | 40 |
Not stats (item passives, 4.G1 hooks): **lifesteal** (heal = % of auto-attack damage dealt, cap 30 % total),
**spell feed** (heal = % of spell damage dealt; total spell healing incl. Malrik's own 50 % capped at 60 %).

## Essence: the item currency
`Economy` gains `essence: int`, `add_essence(amount)`, `spend_essence(amount) -> bool`, `can_afford_essence(amount)`;
`changed` fires for essence too. Only the wizard spends it; it belongs to the team. Both teams earn the same way.
| Source | Essence | Note |
|---|---|---|
| Start | **150** | One component at 0:00 is a real choice |
| Trickle | **+1 per second** per team from the moment the navmesh is ready (60 / min) | Both teams; keeps a passive player able to buy something |
| Any kill by the team (unit, tower, wizard, warden kill credited to a team) | **The victim's XP value in `levels.md`** (Shade 40, Flame Guard 45, worker 15, Ruin Warden 60, wizard `120 + 30 x level`, buildings 100 / 40 / 80 / 200, sites 25 %) | **100 % wherever the wizard is** (unlike XP): it is team money. Kills by wardens give nobody anything |
| The crown camp | 4 x 60 = 240, plus the drop (below) | |
| Chests | 40-120 per open, see the loot table | |
| Selling | 50 % of the item's total value | |
| Exchange (optional, user decision) | At a base shop: **100 crystals -> 40 essence**, no cap | Bad rate on purpose: only for surplus crystals when pop-capped |
Expected 20-minute 1v1 on normal: trickle 1 200 + ~30 kills 1 400 + camp 240 + 4-5 buildings 400 + 1-2 wizard kills
300 + chests 300 = **~3 800**. A passive player still gets ~1 900. Prices below make that **3-4 core items**
(2 top + 1 mid, or 1 top + 2 mid + boots-like) without touching the army budget.

## Tier colours and rules
| Tier | Border colour | Stack per slot | Sold at | Total cost range |
|---|---|---|---|---|
| Component | `(0.85, 0.85, 0.85)` | 1 | Base shops (10), neutral peddlers (2) | 150-250 |
| Mid | `(0.30, 0.75, 1.00)` | 1 | Combine at any shop | 580-750 |
| Top | `(1.00, 0.60, 0.20)` | 1 | Combine at any shop | 1 400-1 950 |
| Consumable | `(0.40, 0.90, 0.40)` | 3 (Owl Stone 4) | Base shops and peddlers | 75-200 |
| Artifact | `(1.00, 0.85, 0.30)` | 1, artifact slots only | Never sold; map / campaign only | - |
- `total_cost(item) = recipe cost + sum of total_cost(parts)`; components and consumables: `cost` only.
- A shop click on a mid / top item costs `recipe + the parts you do not carry` and needs
  `free slots >= 1 - (parts consumed)`. Parts sold only elsewhere: button disabled, tooltip `Needs Warden Scale (neutral peddler)`.
- **Unique passives / auras / actives**: same name never stacks; two copies of an item stack their stats only.
  Rally from a Horn and a Banner: the Banner's values only. Two Bulwarks: two Brace actives on separate cooldowns is **not** allowed: the second Brace is greyed `Unique`.

## Components (12)
| id | Name | Cost | Stats (modifier keys) | Sold at |
|---|---|---|---|---|
| `ember_shard` | Ember Shard | 200 | `attack_damage` +12 | Base |
| `whetted_fang` | Whetted Fang | 200 | `attack_cooldown_pct` -0.10 | Base |
| `ironbark_plate` | Ironbark Plate | 180 | `armor` +15 | Base |
| `wisp_lantern` | Wisp Lantern | 150 | `hp_regen` +1.5 | Base |
| `duskglass` | Duskglass Lens | 200 | `spell_power` +15 | Base |
| `mana_thread` | Mana Thread | 180 | `max_mana` +40, `mana_regen` +1.0 | Base |
| `swiftsoles` | Swiftsoles | 250 | `move_speed` +0.6 | Base |
| `bone_charm` | Bone Charm | 250 | `max_hp` +60, `attack_damage` +5 | Base |
| `cinder_ring` | Cinder Ring | 220 | `cooldown_reduction` +8 | Base |
| `gloom_ink` | Gloom Ink | 180 | `spell_power` +8, `max_mana` +20 | Base |
| `warden_scale` | Warden Scale | 250 | `armor` +8, `max_hp` +40 | **Peddler only** + camp drop |
| `vital_root` | Vital Root | 220 | `max_hp` +120 | **Peddler only** |

## Mid items (9): two components + recipe
| id | Name | Parts + recipe = total | Stats | Passive / active |
|---|---|---|---|---|
| `blazing_edge` | Blazing Edge | Ember Shard + Whetted Fang + 250 = **650** | `attack_damage` +20, `attack_cooldown_pct` -0.12 | **Searing Strikes** (passive): auto-attacks set the target burning: 4 damage every 0.5 s for 2 s (16). Re-hit refreshes, never stacks. Burn credits the wizard |
| `nightveil_cloak` | Nightveil Cloak | Ironbark Plate + Wisp Lantern + 250 = **580** | `armor` +20, `hp_regen` +3 | **Quiet Step** (passive): after 5 s without taking damage, `move_speed` +1.0 until damaged |
| `pyre_staff` | Pyre Staff | Duskglass Lens + Mana Thread + 300 = **680** | `spell_power` +30, `max_mana` +50, `mana_regen` +1.5 | - |
| `ashen_greaves` | Ashen Greaves | Swiftsoles + Wisp Lantern + 200 = **600** | `move_speed` +1.0, `hp_regen` +2 | **Stride** (active, self): `move_speed` +2.5 for 4 s. Cooldown 40, 0 mana |
| `grave_pact` | Grave Pact | Bone Charm + Ember Shard + 300 = **750** | `max_hp` +90, `attack_damage` +18 | **Feed** (passive): 12 % lifesteal on auto-attacks |
| `warlords_horn` | Warlord's Horn | Bone Charm + Ironbark Plate + 300 = **730** | `max_hp` +80, `armor` +15 | **Rally** (aura): friendly **soldiers** (not workers) within 8 m get `attack_damage_pct` +0.10 |
| `siphon_idol` | Siphon Idol | Gloom Ink + Mana Thread + 250 = **610** | `spell_power` +15, `max_mana` +60, `mana_regen` +1.0 | **Spell Drain** (passive): each enemy unit damaged by a spell restores 3 mana, max 15 per cast |
| `emberwake_band` | Emberwake Band | Cinder Ring + Duskglass Lens + 250 = **670** | `cooldown_reduction` +12, `spell_power` +15 | **Afterglow** (passive): `move_speed` +1.0 for 2 s after every spell cast |
| `bulwark_of_ruin` | Bulwark of Ruin | Warden Scale + Vital Root + 250 = **720** | `max_hp` +200, `armor` +15 | **Brace** (active, self): a shield that absorbs 120 damage for 4 s. Cooldown 60, 0 mana |

## Top items (7): mid + mid / component + recipe
| id | Name | Parts + recipe = total | Stats | Passive / active |
|---|---|---|---|---|
| `inferno_blade` | Inferno Blade | Blazing Edge + Grave Pact + 500 = **1 900** | `attack_damage` +45, `attack_cooldown_pct` -0.20, `max_hp` +100 | Feed 15 %; **Searing Strikes II**: 6 / 0.5 s for 3 s (36); when a burning unit dies the burn jumps to enemies within 2 m |
| `shadowstride` | Shadowstride | Ashen Greaves + Nightveil Cloak + 500 = **1 680** | `move_speed` +1.2, `armor` +20, `hp_regen` +3 | Quiet Step; **Blink** (active, point): teleport up to 10 m (closest navmesh point, like Ember Step), clears the current order. Cooldown 45, 0 mana |
| `staff_of_cinders` | Staff of Cinders | Pyre Staff + Emberwake Band + 600 = **1 950** | `spell_power` +60, `cooldown_reduction` +20, `max_mana` +80, `mana_regen` +2 | Afterglow; **Smoulder** (passive): enemies damaged by a spell get status `smoulder` (`move_speed` -1.5) for 1.5 s, refreshed by each tick |
| `banner_of_embers` | Banner of Embers | Warlord's Horn + Vital Root + 500 = **1 450** | `max_hp` +250, `armor` +15 | **Rally II** (aura): soldiers within 10 m get `attack_damage_pct` +0.15 and `hp_regen` +1; **Rallying Cry** (active, self): soldiers within 10 m heal 60 over 4 s. Cooldown 90, 0 mana |
| `gravemaw_idol` | Gravemaw Idol | Siphon Idol + Grave Pact + 500 = **1 860** | `spell_power` +25, `max_hp` +120, `attack_damage` +20, `max_mana` +60 | Feed 12 %; Spell Drain; **Spell Feed** (passive): spell damage heals 15 % of damage dealt |
| `ruinwarden_mantle` | Ruinwarden Mantle | Bulwark of Ruin + Ironbark Plate + 500 = **1 400** | `max_hp` +300, `armor` +35 | **Brace II** (active, self): shield 250 for 5 s. Cooldown 60, 0 mana |
| `phoenix_plume` | Phoenix Plume | Emberwake Band + Vital Root + 700 = **1 590** | `max_hp` +150, `cooldown_reduction` +15, `spell_power` +20 | Afterglow; **Rekindle** (passive): damage that would kill the wizard instead sets HP to 40 % of max and deals 80 to enemies within 4 m. Once per 240 s; the slot shows the cooldown |
Fire-flavoured: Blazing Edge, Pyre Staff, Ashen Greaves, Warlord's Horn, Emberwake Band, Inferno Blade, Staff of
Cinders, Banner, Plume. Shadow-flavoured: Nightveil, Grave Pact, Siphon Idol, Bulwark, Shadowstride, Gravemaw,
Mantle. **Both wizards may buy anything.** Shields: a separate pool consumed before HP, shown as a white
segment at the end of the HP bar; a new Brace replaces the old one.

Ice- and Nature-flavoured items (4 each, Steps 7-8): `kingdom-ice.md` section 6, `kingdom-nature.md` section 5.

## Consumables
| id | Name | Cost | Stack | Effect | Cooldown |
|---|---|---|---|---|---|
| `ember_draught` | Ember Draught | 120 | 3 | Heals 150 over 8 s (not interrupted) | 20 s (shared by both potions) |
| `dusk_vial` | Dusk Vial | 100 | 3 | Restores 80 mana over 8 s | 20 s (shared) |
| `homeward_seal` | Homeward Seal | 200 | 2 | Channel 3 s standing still (any damage or order cancels, seal kept), then teleport to the own keep spawn point (oldest barracks if no keep) | 60 s |
| `owl_stone` | Owl Stone (**wave 5**, needs `fog-of-war.md`) | 75 | 4 | Placed on a ground point within 6 m: a 0.4 m stone with sight 12 for 120 s, 1 HP, attackable, visible to the enemy within 3 m | 5 s |
Using the last charge frees the slot. Potions and seals are sold by base shops and peddlers.

## Artifacts
- The **Ember Crown** becomes `ember_crown`, tier artifact, `is_artifact = true`, lives in **artifact slot 1**.
  Stats `max_hp` +100, `max_mana` +50 (its existing modifier, source `item:artifact_1`). Never sold, never dropped
  by hand; drops 3 s after the wearer's death and can be retaken (unchanged, `skirmish-1v1.md`);
  `Events.artifact_claimed` unchanged. The pickup radius 2.2 rule stays (no right-click needed).
- Campaign artifacts use the same tier: 2 equipped per mission from those owned (the artifact-choice screen).

## Where items come from
| Source | What | Where / when |
|---|---|---|
| **Base shop** = the team's completed **keep or barracks** (no new building). Buying, combining, selling and the exchange work while the wizard is within **12 m** of one | The 10 base components, every mid / top recipe, Ember Draught, Dusk Vial, Homeward Seal, the exchange | A forward Ember Hall is also a forward shop |
| **Ruin Peddler** (neutral shop), 2 mirrored, invulnerable, team `NEUTRAL`, ignored by every unit, group `"shops"` | Warden Scale, Vital Root, Ember Draught, Dusk Vial, Homeward Seal, Owl Stone (wave 5); combines any recipe | `(-22, -22)` and `(22, 22)`: 58 m from both keeps, 31 m from the crown. Generator clearing radius 5 at both |
| **Camp drop** | When the **4th** Ruin Warden dies: 1 Warden Scale + 1 Ember Draught on the ground at `(0, 3)` | Once per match, on top of the 240 essence |
| **Lost Caches** (chests), 4, mirrored | Loot table below | `(-30, 0)`, `(0, 30)` (Fire's near pair, 45 m from its keep) and `(30, 0)`, `(0, -30)`. Appear at **2:00**, reopen **180 s** after being opened. Open = a wizard within 2.2 m (walks in; no key). Clearing radius 3 |
Chest loot (one roll): 40 % **80 essence** (+ 20 x match minute / 5, cap 120) · 20 % Ember Draught · 15 % a
random base component · 15 % Dusk Vial · 10 % Warden Scale. Essence goes to the team at once; items go
into the inventory, or on the ground beside the chest when it is full.
Look: chest = box 1.0 x 0.7 x 0.7 `(0.45, 0.30, 0.15)` with a gold band, lid opens (rotate -70 deg) and it
fades over 1 s; a flat gold ring radius 1.5 `(1.0, 0.85, 0.3, 0.5)` on the ground while closed; 5 x 5 px gold on the minimap. Peddler = a 1.8 m capsule
`(0.60, 0.50, 0.30)` beside a cart box 2 x 1 x 1.5 `(0.35, 0.25, 0.15)`, a lantern orb emissive `(1.0, 0.8, 0.4)`.

## Rules
| Rule | Value |
|---|---|
| Buy | `Inventory.can_buy(type) -> String`: `""` ok, else in this order `"Dead"`, `"No shop nearby"`, `"Not sold here"`, `"Inventory full"`, `"Not enough essence"`. Consumables merge into an existing stack first |
| Sell | At a shop only: **50 %** of `total_cost`, rounded down (a 2-charge potion stack sells each charge at 50 %). Right-click a slot -> menu `Sell (325)` / `Drop`; message `Sold Blazing Edge for 325`. Sold artifacts: refused |
| Drop | Anywhere: the item appears at the wizard's feet (nearest navmesh point), keeps full value, anyone's wizard can take it. Drag a slot onto the world does the same |
| Pick up | Right-click a ground item (or a Move order onto it): the wizard walks and takes it at 2.2 m; `Inventory full` if no slot. Ground items never expire in the 1v1; in the campaign they vanish at mission end |
| Full inventory | Buy and pickup refused; chest items fall to the ground; the camp drop is always on the ground |
| Swap | Drag a slot onto another = swap (also while dead: the bar stays usable) |
| Actives | `use_item(slot, target) -> String`: `""`, `"Dead"`, `"Empty slot"`, `"Not an active"`, `"On cooldown"`, `"Invalid target"`. Point actives (Blink, Owl Stone) use the spell targeting flow (cross cursor, Esc cancels); self actives fire on the key |
| Modifier ids | `item:1`..`item:6`, `item:artifact_1`, `item:artifact_2`; auras on soldiers `aura:rally` (refreshed every 0.5 s, removed 1 s after leaving the radius, one source wins); statuses `burn` (DoT), `smoulder`, `shield` |
| Death | Nothing is dropped or lost except artifacts (Crown rule). Cooldowns keep running; consumable cooldowns reset on respawn |
| Stacking limits | Passives, auras and actives by name never stack (highest values win); item stats always stack; caps in the stats table |

## Campaign (systems, save format decided by 4.S1)
- Carried between missions: the 6 slots (types + potion counts), owned artifacts (all) and which 2 are equipped;
  essence at **50 %, cap 1 500**. Ground items and shop stock are not saved. A mission may set
  `items_locked = true` (no shops on the map; fixed loadout) for scripted missions.
- Mission rewards in the campaign, never sold (tier artifact or top, `campaign_only = true`):
| id | Name | Given by | Stats / effect |
|---|---|---|---|
| `ember_crown` | Ember Crown | Mission 1 (the 1v1's crown) | `max_hp` +100, `max_mana` +50 |
| `masters_signet` | Master's Signet | Mission 3 | `max_hp` +100, `spell_power` +20, `cooldown_reduction` +10 |
| `oath_of_embers` | Oath of Embers (top, occupies an item slot) | Mission 2 secondary objective | `attack_damage` +25, `attack_cooldown_pct` -0.10; Searing Strikes (mid values) |
| `stillwater_orb` | Stillwater Orb | Mission 2 (`mission-02.md`) | `max_mana` +60, `mana_regen` +1.5, `armor` +10; **Stillwater**: `chill` / `frozen` on the wearer last x 0.5 |
- Between missions the choice screen (old plan's 4.U2) shows the 6 slots read-only, the artifacts owned and the 2 equip slots.

## The bot (4.A1; extends `ai.md`)
| Rule | Value |
|---|---|
| When it shops | Every tick while Malrik is **within 12 m of his keep or a Gloom Hall** and alive (his anchor is 9.9 m from the Dusk Keep, so idling shops). Buys the first entry of its list it can afford (`can_buy == ""`), one purchase per tick, components before their recipe as the list orders |
| Retreat to shop | Never on purpose; he buys when he is home (rule 8 HP < 35 % retreat, respawn, idle) |
| Potions | Keep 1 Ember Draught in stock once the first mid item is owned (bought after it); Hard keeps 2 |
| Exchange | If enabled: when `crystals >= 500` and `pop_used >= pop_cap - 2`, exchange once per tick |
| Uses | Ember Draught: HP < 50 % and no potion running. Brace / Brace II: HP < 40 % and an enemy within 8 m. Blink: HP < 25 % (retreat rule), toward the keep, once. Stride: when starting an attack or a retreat. Rallying Cry: 3+ own soldiers within 10 m under 60 % HP. Homeward Seal: not used (no channel logic) |
| Strength | A wizard is worth `170 + 30 x level + total_cost of carried items / 5` (a 3 220-essence build = +644). Vessa's items are read from `inventory.slots` when she is seen (same as her level) |
Build lists (bought in order; the components of the next recipe are the next entries):
| Difficulty | Order |
|---|---|
| Easy | Wisp Lantern, Ironbark Plate, **Nightveil Cloak**, Bone Charm, Ember Shard, **Grave Pact**, Ember Draught, Ironbark Plate (kept as a spare; the list ends there) |
| Normal | Ember Shard, Bone Charm, **Grave Pact**, Ember Draught, Gloom Ink, Mana Thread, **Siphon Idol**, **Gravemaw Idol**, Ironbark Plate, Wisp Lantern, **Nightveil Cloak**, Swiftsoles, Wisp Lantern, **Ashen Greaves**, **Shadowstride** |
| Hard | Ember Shard, Whetted Fang, **Blazing Edge**, Ember Draught, Bone Charm, Ember Shard, **Grave Pact**, **Inferno Blade**, Ironbark Plate, Wisp Lantern, **Nightveil Cloak**, Swiftsoles, Wisp Lantern, **Ashen Greaves**, **Shadowstride**, Ember Draught |
The bot never visits a peddler or a chest in wave 4 (no Warden Scale / Vital Root items in its lists). It does pick
up the camp drop if Malrik takes the crown (Warden Scale is then sold at home on the next shopping tick).

## HUD (4.U1; 1600 x 900, hero column x 272-572, y 660-884, margin 10; `levels.md` rows above)
| Element | Position / size | Look |
|---|---|---|
| **Inventory bar** | 6 slots **36 x 36** at `(282 + i x 40, 834)`, i = 0..5 (x 282-518); **artifact slot** 36 x 36 at `(526, 834)` with a gold border; row bottom y 870 | Slot bg `(0.10, 0.08, 0.12)`, 2 px border in the tier colour (empty: `(0.3, 0.3, 0.3)`); icon = 2-letter abbreviation font 14 (`BE`, `GP`, `ED`...); key digit `1`-`6` font 10 gold bottom-right; stack count font 10 white bottom-left; cooldown overlay as spells (dark, shrinks from the bottom, seconds in the centre); passive-only items show no digit |
| **Essence** in the top bar | The top bar becomes **500 x 40 at (550, 8)**; 4th item after the timer, 48 px gap: a 16 px purple flame `(0.75, 0.45, 1.0)` then the number font 20 `(0.9, 0.8, 1.0)` | Flashes red 0.4 s on a failed `spend_essence` + `show_message("Not enough essence")` |
| **Shop button** | Keep / barracks card r1c3 `Shop T` (key T works anywhere in shop range, with anything selected) | Disabled with `No shop nearby` when Vessa is out of range |
| **Shop window** | **640 x 440 at (480, 200)** (closes above the bottom panels), `_panel` style | Title font 20 `Keep shop` / `Ruin Peddler` left, essence right; **X** button 24 x 24 top-right; Esc or T closes; walking out of range closes it |
| Shop: item grid | Left 380 px: 4 rows labelled font 12 `Components` / `Mid` / `Top` / `Consumables`, buttons **48 x 48** gap 6, 7 per row (2 rows for Top + Consumables share) | Button: abbreviation, tier border, total cost font 10 under it in essence colour; **owned parts -> green cost** (the price shown is what you would pay now); unaffordable: alpha 0.45; not sold here: alpha 0.3 + tooltip |
| Shop: details | Right 240 px: selected item name font 18, stats lines font 13, passive / active text, then the **recipe tree**: the item 48 x 48, a line to its parts 36 x 36, their parts 28 x 28 (3 levels max); parts in the inventory get a green border, missing ones show their cost | **Buy 650** / **Combine 250** button 220 x 36 at the bottom (disabled + reason), **Sell** zone 220 x 28 under it: drag a slot there to sell |
| Tooltip (inventory and shop) | `Blazing Edge  [Alt+2]\n+20 damage · -12 % attack cooldown\nSearing Strikes: attacks burn for 16 over 2 s.\nSell 325` | Actives add a line `Active: shield 120 for 4 s · 60 s cooldown`; consumables `2 charges`; artifacts `Artifact (cannot be sold)` |
| Ground item | A 0.5 m cube rotating 45 deg / s at y 0.6, in the tier colour, emissive 0.8, on a flat disc radius 0.6 `(0.2, 0.2, 0.2)`; `Label3D` name font 32 at `pixel_size` 0.006 0.9 m above; clickable (layer 2, group `"ground_items"`); minimap 3 x 3 px in the tier colour | Highlight ring when hovered |
| Messages | `Bought Ember Shard`, `Inventory full`, `Picked up Warden Scale`, `The Lost Cache holds 80 essence` | `show_message` |
| Buff icons | Active shield: white segment on the HP bar; burning / smoulder enemies: small orange / grey billboard as `haste` does | 4.U1 |
Controls help gains one line: `T: shop    Alt+1-6 / Numpad 1-6: items    Right-click item: sell / drop`.

## Balance: a fully itemised level-6 wizard vs 10 soldiers
Level-6 Vessa (475 HP, 24 dmg, 3 Fireballs at 85) with **Inferno Blade + Bulwark of Ruin + Ashen Greaves**
(3 220 essence, a good 20-minute build): 675 HP, armor 15 (x0.87), 69 damage at cooldown 1.04 (~66 DPS) + burn
(~12 DPS) + 15 % lifesteal (~10 HP / s), 5.6 m/s, Brace 120.
| Fight | Result |
|---|---|
| 10 Shades (800 crystals, 900 HP, 100 DPS) | 2 Fireballs kill ~5; the rest deal 43 DPS after armor, 33 net of lifesteal; she kills one every 1.4 s: **wins with ~430 HP left** (level 6 without items: dies or flees) |
| 10 Nightbolts (1 000 crystals, ranged) | 87 DPS after armor, 77 net: she has ~9 s, kills 4-5 (Fireballs + autos), **dies** unless she Strides out |
| 3 Shadow Knights (900 crystals, 1 260 HP) | 48 DPS after armor, 38 net: 18 s; she deals ~1 400 with Fireballs: **trade, both sides nearly dead** |
| 6 Flame Guards + Kindle'd army behind her | Wins cleanly; Rally II would add +15 % to the soldiers |
Rule of thumb: **1 essence spent = 0.2 crystals of army strength** (3 220 essence = +640, the bot formula).
An itemised level-6 wizard is worth ~1 000 crystals of soldiers (~2.5 min of income): strong, as asked, but
ranged lines, knights and focus fire still kill her, and the essence came from fighting, not mining.
Knobs if playtest 4 says items are too strong: recipe costs +20 %, Ruinwarden Mantle +35 -> +25 armor, Inferno
Blade +45 -> +40 damage, trickle 1 / s -> 0.75 / s. Keep the armor formula as written (readable numbers).
Guardrails already in the stats table: CDR 40, lifesteal 30 %, spell healing 60 %, armor 150, attack cooldown
floor 40 %, move speed +2.5, spell power 100.

## What changed in other specs
- `economy.md`: `Economy` gains essence (fields above); the top bar shows it.
- `ui-hud.md`: top bar 500 x 40 at (550, 8); hero column gains the inventory row at y 834; keep / barracks card
  r1c3 `Shop T`; the help text line; the window at (480, 200).
- `skirmish-1v1.md`: 2 Ruin Peddlers at `(-22, -22)` / `(22, 22)` (clearing 5), 4 Lost Caches (clearing 3),
  the camp drop, the Crown as an artifact item. Death drops nothing else.
- `ai.md`: wizard strength `170 + 30 x level + items / 5`; shopping and item-use rules above.
- `levels.md`: the XP table doubles as the essence table (team-wide, no distance rule). Nothing else changes.
- `buildings.md`: completed keeps and barracks are shops (radius 12). No new `BuildingType`.
- `fog-of-war.md` (wave 5): Owl Stone sight 12 for 120 s.
- The lead's Keys line gains: **T = shop, Alt+1-6 / Numpad 1-6 = use item slot**.

## Suggested API (the lead freezes it when 4.I1 starts)
- `ItemType` (`data/items/<id>.tres`): `id`, `display_name`, `tier` (enum component / mid / top / consumable /
  artifact), `cost` (recipe or unit price), `parts: Array[ItemType]`, `stats: Dictionary`, `passive_id`,
  `active_id`, `active_cooldown`, `active_target` (none / self / point), `stack_max`, `sold_at` (bitmask base /
  peddler), `is_artifact`, `campaign_only`, `icon_abbrev`, `tooltip`, `total_cost() -> int`, `static find(id)`.
- `Inventory` (child of each wizard, `wizard.inventory`): `slots: Array` (6 entries `null` or
  `{ type, count, cooldown_left }`), `artifacts: Array` (2), `add_item(type) -> bool`, `remove_item(slot) -> ItemType`,
  `use_item(slot, target) -> String`, `can_buy(type) -> String`, `buy(type) -> String`, `sell(slot) -> int`,
  `drop(slot)`, `swap(a, b)`, `nearest_shop() -> Node`, `total_item_value() -> int`, signals `inventory_changed`,
  `item_used(slot, type)`, `item_bought(type)`. Modifiers re-applied on every change (`item:<slot>`).
- 4.G1 hooks on `Unit` / `Wizard`: signal `attack_landed(target, amount)` (emitted by the attacker after damage),
  `Wizard` signal `spell_hit(target, amount, spell_id)` and `spell_cast(spell_id)`, statuses `burn` (DoT with a
  source, `apply_dot(id, per_tick, interval, duration, source)`), `smoulder`, `shield` (`add_shield(amount, duration)`),
  aura refresh helper `apply_aura(source_id, radius, stats, filter)`. Gameplay decides the exact shape.

## Done when
- [ ] 4.I1: `ItemType` resources for the 12 components, 9 mid, 7 top, 4 consumables and 3 artifacts with the numbers above; `Inventory` with 6 slots + 2 artifact slots; `can_buy` reasons in order Dead / No shop nearby / Not sold here / Inventory full / Not enough essence; buying spends essence, adds `item:<slot>` modifiers (test: Vessa buys Ember Shard at the keep -> `get_stat("attack_damage")` +12, essence -200; sells it -> +100 essence, stat back; a 7th component -> `Inventory full`; 20 m from every shop -> `No shop nearby`; armor 25 -> a 100-damage hit deals 80; caps hold with 5 Cinder Rings = 40 CDR); the Crown sits in artifact slot 1 with +100 HP / +50 mana; `Economy.essence` starts at 150 and gains 1 / s and the victim's XP value on every team kill wherever the wizard is.
- [ ] 4.I2: buying Blazing Edge with Ember Shard + Whetted Fang carried costs 250 and frees a slot; with nothing carried costs 650; Inferno Blade from Blazing Edge + Grave Pact costs 500; `use_item` reasons in order; Brace absorbs 120 then expires at 4 s, cooldown 60 (48 with 20 CDR); Blink moves 10 m max; Stride +2.5 speed for 4 s; Ember Draught heals 150 over 8 s, 3 per stack, shared 20 s cooldown with Dusk Vial, the last charge frees the slot; Homeward Seal channels 3 s, cancelled by damage, lands at the keep spawn; unique passives / actives never stack; drop / pickup round-trip keeps the item.
- [ ] 4.G1: `attack_landed`, `spell_hit`, `spell_cast` fire with the right amounts; burn 16 over 2 s credited to the wizard (XP and essence), refreshed not stacked, Searing Strikes II jumps 2 m on death; lifesteal and Spell Feed heal by the % with the 30 % / 60 % caps; Rally gives soldiers within 8 m `attack_damage_pct` +0.10 within 0.5 s and removes it 1 s after leaving, Banner overrides Horn; `smoulder` slows 1.5 m/s for 1.5 s; `spell_power` multiplies Fireball (85 -> 136 at +60) and Soul Siphon ticks; `cooldown_reduction` shortens Ember Step (12 -> 9.6 at 20); armor and attack-cooldown floor per the stats table; `PERF OK` with 200 units and 2 auras.
- [ ] 4.S1: keeps and barracks answer as shops within 12 m; peddlers at `(-22, -22)` / `(22, 22)` with the peddler stock and clearing 5; 4 Lost Caches at the positions above appear at 2:00, roll the loot table, reopen 180 s later; the 4th warden's death drops Warden Scale + Ember Draught at `(0, 3)`; the exchange 100 -> 40 if enabled; campaign save / load of the 6 slots, artifacts, equipped pair and 50 % essence (cap 1 500); the smoke test still prints `victory=true`.
- [ ] 4.U1: inventory bar at `(282 + i x 40, 834)` + artifact slot at `(526, 834)` with tier borders, digits, counts and cooldown overlays; Alt+1-6 and Numpad 1-6 use slots by physical keycode, never triggering groups; T opens the shop window at (480, 200) only in range (`No shop nearby` otherwise) and Esc / T / walking away closes it; grid + details + recipe tree with green owned parts and the live price; Buy / Combine with reasons; right-click menu Sell / Drop; drag to swap, to the world to drop, to the Sell zone to sell; tooltips in the format above; essence in the top bar (500 x 40 at (550, 8)) with the red flash; ground items look and pick up by right-click; shield segment on the HP bar; nothing in `scripts/ui/` calls a `_private` function.
- [ ] 4.A1: on normal Malrik owns Grave Pact by ~6:00 and Gravemaw Idol by ~14:00 in a headless run against a passive player (essence from the trickle + camp + kills); he buys only within 12 m of his keep / hall; drinks a Draught under 50 % HP, Braces under 40 % with an enemy within 8 m; strength counts `items / 5` for both wizards; the difficulty lists differ only as written; `PERF OK` unchanged.
