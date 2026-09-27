# Building levels and staffing

Task 18.D1, written 2026-09-26. Source of truth for step 18 (tasks in section 14). User request (`waves.md` "Step 18"):
buildings get **levels 2-3** (more slots, speed, better units or items); production needs **someone inside**: a building
must be **staffed** by a worker or a specialist to train units or craft items, more / better staff = faster or better
output; it must stay **readable** and must **not slow the game down** (auto-staff?). **Art per level**: every building has a
distinct look at each level (extra floors, towers, banners, glow; same footprint), one art task per building family per
kingdom.
Every name, rule and number here is our own. Metres, seconds, `m:ss` since the navmesh was ready. Builds on the real code
(`scripts/buildings/building.gd`, `training_building.gd`, `keep.gd`, `market.gd`, `building_type.gd`,
`scripts/economy/economy.gd`, `worker.gd`, `data/buildings/*.tres`) and on `buildings.md`, `economy.md`, `research.md` (keep
tiers Stronghold / Citadel, Forge / Sanctum), `cavalry-mounts.md` (Stables, Lairs), `rush-balance.md` (rushes, Muster Bell,
T2 Hall units), `tier3-extras.md` (T3 units), `titans-2.md`, `market-trade.md` (Bazaar, caravans), `grand-market.md`,
`levels.md` (veterancy), `ai.md`, and the step-17b worker **Auto** button (`waves.md`; its spec is not written yet: section 5.4
is the contract it must follow). **Built after steps 12-14 (and 16-17) are merged.** Short names: rs. = research.md,
cm. = cavalry-mounts.md, rb. = rush-balance.md, gm. = grand-market.md, mt. = market-trade.md.

## 0. The idea in six lines
1. **Levels**: most buildings go **1 -> 2 -> 3** by a paid timed upgrade (key **L**). A building's level can never be above the
   **keep tier** (rs. 2.2): level 2 needs a Stronghold, level 3 a Citadel. The keep's own levels *are* its tiers.
2. Each level: **+20 % / +40 % HP**, **one more staff slot**, a **new look**, and one family perk (new unit, faster research,
   more caravans, epics, pop, tower damage...).
3. **Staff**: production buildings work only with **at least 1 worker inside**. Workers walk in and vanish (out of the scene
   tree: **no pop, no CPU**); they come out when ejected or when the building falls.
4. More staff = faster (x1.00 / x1.25 / x1.45 / x1.60). A **Master** (a promoted staff worker) counts double and adds one
   quality perk.
5. **Auto-staff is on by default**: the worker who finishes a production building stays inside as its first staff, and an
   unstaffed building with work waiting pulls the nearest idle worker. The player only thinks about *extra* staff.
6. Early game is unchanged: every level-1 building has **1 slot**; the skirmish starts with **4 workers** (was 3) so the first
   Hall's crew is free; nothing levels before the Stronghold (~7:00), so 3:00 rushes see today's numbers.

## 1. Decisions in one table (designer decisions; the user's questions are at the end)
| Question | Decision | Why |
|---|---|---|
| Who levels | Keep (= its tiers), Hall, Stables, Forge, Sanctum, Bazaar, House, Tower: levels 1-3. Lair and Grand Market: 1-2. **Ice Wall: never** | Every building the user named plus the ones a player looks at every game; walls are cheap spam (16 per team) and already have Packed-Ice Walls research |
| Level gate | Level L needs keep tier >= L (Lair / Grand Market level 2: the Citadel). Research off: tier 2 from **6:00**, tier 3 from **11:00** (match time) | One ladder with research (rs. 2.2) and the T2 / T3 unit gates (rb. 5, tier3-extras 2); the 6:00 fallback is rb.'s |
| Who staffs | Only **workers** (`UnitType.is_worker`: Cinder Hand, Gloom Thrall, Rime Hauler, Sprigling). A staff worker can be promoted to a **Master** (the specialist) | No new unit per kingdom; the specialist is an upgrade of what you already own |
| Needs staff | Buildings with a production queue: Hall, Stables, Lair, Forge, Sanctum, Bazaar (caravan training), Grand Market (tier 4-5 crafting, relic restock). The **keep never needs staff** (an innate Steward) | Keep: the team must always be able to make workers again |
| Never staffed | House, Tower, Wall, neutral buildings (taverns, posts, guild houses, watchtowers, shrines), step-17b improvements | Not production |
| Pop | Staff inside **do not count for population** (they leave the scene tree; `Economy` already frees pop on `tree_exiting`) | Staffing must not shrink armies; capped by slots |
| 0 staff | The queue stays, **progress freezes**; queuing is still allowed (paid, paused) | Nothing is lost; the fix is one key |
| Early game | L1 = 1 slot; skirmish start **4 workers** (missions unchanged); auto-staff keeps the builder inside | 0:00-4:00 plays like today; rushes stay viable (section 6) |
| Speed | Staff power P (worker 1, Master 2): x0 / x1.00 / x1.25 / x1.45 / x1.60 for P = 0 / 1 / 2 / 3 / 4 | Diminishing: one more Hall is still better for raw quantity; levels are for quality |
| Missions | `staffing_enabled` and `levels_enabled` **false** in missions 1-4 | One new system per mission |

## 2. Which buildings level (per kingdom)
| Family (`kind`) | Fire | Shadow | Ice | Nature | Levels | Staff slots L1 / L2 / L3 | Master title |
|---|---|---|---|---|---|---|---|
| Keep (`keep`) | Keep | Dusk Keep | Rime Keep | Heartwood | 1-3 = Keep / Stronghold / Citadel (rs. 2.2) | Steward (innate) + 0 / 1 / 2 extra | - (the Steward) |
| Hall (`barracks`) | Ember Hall | Gloom Hall | Frost Hall | Grove Hall | 1-3 | 1 / 2 / 3 | Drillmaster |
| Stables (`stables`) | Ember Stables | Gloom Stables | Frost Stables | Grove Stables | 1-3 | 1 / 2 / 3 | Horsemaster |
| Lair (`lair`) | Dragon Roost | Dread Paddock | Glacier Den | Elder Circle | 1-2 | 1 / 2 / - | Beastwarden |
| Forge (`forge`) | Ember Forge | Bone Foundry | Rime Forge | Root Nursery | 1-3 | 1 / 2 / 3 | Master Smith |
| Sanctum (`sanctum`) | Cinder Sanctum | Soul Crypt | Rune Sanctum | Wildroot Sanctum | 1-3 | 1 / 2 / 3 | Loremaster |
| Bazaar (`market`) | Ember Bazaar | Gloom Bazaar | Frost Bazaar | Grove Bazaar | 1-3 | 1 / 2 / 3 | Factor |
| Grand Market (`grand_market`) | Brasslight Exchange | Duskvault Exchange | Hoarglass Exchange | Mossgold Exchange | 1-2 | 1 / 2 / - | Artificer |
| House (`house`) | Hearth | Hovel | Snow Lodge | Seed Hollow | 1-3 | never staffed | - |
| Tower (`tower`) | Ember Spire | Night Spire | Rime Spire | Bramble Spire | 1-3 | never staffed | - |
| Wall (`wall`) | - | - | Ice Wall | - | 1 only | never | - |
- The Lair and the Grand Market already need a Citadel / Stronghold to exist, so their only upgrade is level 2 (the Lair's
  needs the Citadel it already has; the Grand Market's needs the Citadel).
- Trade off / research off / cavalry off / titans off: the families that do not exist in that match simply are not there.

## 3. Levels
### 3.1 Upgrade rules (systems 18.C1)
| Rule | Value |
|---|---|
| Where | Building card **Level up [L]** (keep: **N**, the rs. key, and **L** as an alias). Completed, living, own building only |
| Pay | Crystals only, paid at start (table 3.2). No kingdom multiplier (rs. rule for keep upgrades); Nature pays its lower L1 cost only |
| Runs | **Beside** production (the building keeps training / researching), one level-up at a time per building. No worker needed |
| Cancel | Click the level-up chip in the panel: **full refund**, progress lost |
| Destroyed while upgrading | 75 % refund (the rs. 2.3 / construction-cancel ratio) |
| Done | `level += 1`, HP factor 1.2 (L2) / 1.4 (L3) of the type's base, the HP gained is healed (as `set_hp_mult`); the Masons' Charter and research HP factors multiply on top; new slot, perk and look at once |
| Refusals (`can_level_up()`, first that applies) | `"Max level"`, `"Under construction"`, `"Level up in progress"`, `"Needs a Stronghold"` / `"Needs a Citadel"` (research off: `"Available at 6:00"` / `"Available at 11:00"`), `"Not enough crystals"` (flashes the top bar) |
| Lost tier | A keep that falls lowers the team tier: levels already bought stay; new level-ups are refused |
| Enemy view | The level is **visible** (the look, and `Level 2` on hover); staff counts are hidden (the "working" glow is the only hint) |

### 3.2 Costs and times
| Family | Level 2 | Level 3 | Notes |
|---|---|---|---|
| Keep | Stronghold 200, 60 s | Citadel 300, 90 s | rs. 2.2, unchanged (needs a Forge / Sanctum and researches as written there) |
| Hall | **125**, 40 s | **200**, 55 s | per Hall (a second Hall levels on its own) |
| Stables | 125, 40 s | 200, 55 s | |
| Lair | 200, 50 s | - | |
| Forge / Sanctum | 100, 35 s | 150, 50 s | |
| Bazaar | 100, 35 s | 150, 50 s | |
| Grand Market | 200, 50 s | - | |
| House | 60, 25 s | 90, 30 s | per house |
| Tower | 75, 30 s | 110, 40 s | per tower (max 4) |
A whole base at max level (2 Halls, Stables, Lair, Forge, Sanctum, Bazaar, GM, 2 houses, 4 towers): **~3 150 crystals**. A
normal game buys ~800-1 300 of it (section 9.1): a real "army, research or levels" choice.

### 3.3 What each level gives
Shared by every levelled family: **HP x1.2 (L2) / x1.4 (L3)**, **+1 staff slot** (production families), the **Master** slot
opens at L2, the new look (section 11).
| Family | Level 2 | Level 3 |
|---|---|---|
| Keep | Stronghold (rs.): +1 extra staff slot (worker training up to x1.25) | Citadel (rs.): +2 extra slots (up to x1.45) |
| Hall | Unlocks the Hall's **T2 unit**: Pyre Adept (Ember, B), Hexweaver (Gloom, B), Vinelasher (Grove, B). **Frost Hall** (no T2 unit since the Frostbow was dropped, tier3-extras Q3): its soldiers get **+8 % max HP** ("Hardened") instead | Unlocks the Hall's **T3 unit**: Cinderlock Musketeer (Ember, N), Frostrune Rifleman (Frost, N). **Drilled**: every soldier trained here starts with **+50 XP** (half-way to Veteran, `levels.md`) |
| Stables | **Remount**: cavalry trained here +10 % max HP | Unlocks the Grove Stables' **Glade Outrider** (B). **Drilled** for everything trained here (+50 XP) |
| Lair | **Bonded**: titans and Lair units trained here +10 % max HP (not the Mage Archer / Wildcaller, who level as champions) | - |
| Forge / Sanctum | Research here takes **-15 % time**; queue 3 -> **4** | **Second bench**: **two researches at once** in this building (each at the building's work speed) |
| Bazaar | Caravan limit 6 -> **8** | Limit **10**; caravans trained here **+10 % gold per trip** |
| Grand Market | **Epics (T5) open** (replaces gm.'s "Epics: Needs a Citadel"; the Citadel is still needed through the level); relic stock 2 -> **3** | - |
| House | **+5 pop** (Nature Seed Hollow **+4**) | **+5 pop** (Nature **+4**) |
| Tower | Damage **x1.2**, range **+1** | Damage **x1.4**, range **+2**, sight **+2** |
- **Unit gates** (the only rule change to other specs): a unit with `required_keep_tier` N trained at a Hall or Stables also
  needs **that building at level N** (`"Needs Ember Hall level 2"`). Stables V-slot units (Sparkwing, Bone Ballista, Frost
  Mortar, Bore Beetle), cavalry and Lair units keep their current gates. Level 2 itself needs the Stronghold, so the old gate
  is kept and a building step is added. With `levels_enabled` false the old gates apply unchanged.
- **Pop cap**: house levels raise the hard cap (`Economy.max_pop_cap`) by the same amounts: Fire / Shadow / Ice 40 -> **50**
  (both houses L2) -> **60** (both L3); Nature 50 -> 62 -> **74** (3 hollows). Same ~+25 % Nature margin as today.
- **Tower levels** multiply before Garrison fire (rb. 3.1) and add to research tower bonuses (Salamander Oil +3 / +1 range):
  an L3 Ember Spire hits 15 x 1.4 = 21 (+3 Oil = 24), x1.5 vs swarm.
- **Hall / Stables levels never change unit stats globally**: perks apply to units **trained there** (a modifier
  `level:<building kind>` put on the unit at spawn), so a player can read "these came from my L3 Hall".

### 3.4 Research off, missions, trade off
| Case | Rule |
|---|---|
| Research off (skirmish `--no-research`) | No keep tiers: `team_tier()` = 1, **2 from 6:00**, **3 from 11:00** (match time). The Grand Market keeps its own gm. times (7:00 build, level 2 from 12:00). The keep has no level-up; its extra staff slots follow `team_tier()` |
| Missions 1-4 | `levels_enabled = false`, `staffing_enabled = false`: no buttons, no slots, work speed 1.0 everywhere, start workers as today (`mission-01.md`, `mission-02.md` unchanged) |
| Trade off | No Bazaar; Grand Market rules as gm. (gold parts as essence) |

## 4. Staffing
### 4.1 Staff power and work speed (systems 18.C2)
Staff power **P** = sum over the workers inside: **1** per worker, **2** for a Master of this family (a Master of another family
counts 1). The keep's Steward counts 1 and cannot leave.
| P | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| **Work speed** | **x0 (paused)** | x1.00 (today's times) | x1.25 | x1.45 | x1.60 (max) |
- Work speed multiplies **every** production clock of the building: unit training (`TrainingBuilding` progress), research
  progress, caravan training, the Crucible's free Flame Guard timer (titans-2), Grand Market relic restock. It multiplies with
  the research `train_speed_mult()` (Great Bellows) and the Forge / Sanctum L2 -15 % time.
- Reachable P per level: L1 1 slot -> P 1 (x1.00); L2 2 slots -> P 2 (x1.25), P 3 with a Master (x1.45); L3 3 slots -> P 3
  (x1.45), P 4 with a Master (x1.60).
- With `staffing_enabled` false: `work_speed()` = 1.0 always, slots hidden.

### 4.2 Entering and leaving
| Rule | Value |
|---|---|
| Who may enter | An own **worker** (not a caravan, soldier, champion, wizard), alive, not frozen / rooted, **not damaged in the last 3 s** (no hiding from raiders), not a Muster Bell militia |
| Where it goes | Walks to the building's **door** = its spawn point (`TrainingBuilding.spawn_point()`; research buildings / Grand Market: the footprint corner facing `front_toward`). At the door: 0.4 s fade + a dust puff (model hook `play_staff_enter()` if present), then the worker is **removed from the scene tree** and kept by the building (`staff: Array`) |
| Slot reservation | A worker ordered in **reserves** a slot at order time (hollow pip in the panel); a second worker for a full building is refused at order time |
| While inside | Not in the tree: no physics, no nav agent, no fog source, not selectable, not attackable, **no pop** (`Economy` releases it on `tree_exiting` and counts it again on `node_added`). Carried crystals: delivered on the way if the building is a drop-off, else kept |
| Leaving (Staff Out, or the building falls) | Re-added at the door with the HP it had, `reset_physics_interpolation`. Staff Out: it resumes gathering its last node (else the nearest within 30 m, else idle at the door). Building destroyed: all staff come out and **run to the nearest own keep**, then go idle (F3 finds them; auto-staff may reuse them) |
| Pop on leaving | Counted again at once; `pop_used` may exceed `pop_cap` (the Hearth-destroyed rule of `buildings.md`): training waits until units die |
| Selection / groups | Entering drops the worker from the selection and from control groups (SelectionManager already reacts to `tree_exiting`); ejected workers join no group |
| Order of ejection | Plain workers first (the one that entered last), the Master last |

### 4.3 What 0 staff does
| Building | With 0 staff |
|---|---|
| Hall, Stables, Lair | Queue kept, **progress frozen**, new units can still be queued (paid, reserved pop). Rally, drop-off (Halls), shop (Halls) all still work |
| Forge, Sanctum | Research frozen; queuing allowed |
| Bazaar | Caravan training frozen; **existing caravans keep trading** (routes are not production); wares still buyable |
| Grand Market | T1-T3 items, elixirs and relics in stock still sell; **tier 4-5 recipes** are refused `"No staff at the Grand Market"`; relic restock frozen |
| Keep | Never (Steward) |
A production building with 0 staff **and** work waiting is **blocked**: it shows the world icon and counts in the top-bar
alert (section 7). A building with 0 staff and nothing queued is just idle (no alert).

### 4.4 Masters (the specialist)
| Rule | Value |
|---|---|
| How | Building card **Train Master** (r3c3, no key): promotes one plain worker **inside** a level-2+ building. **100 crystals, 30 s**, beside production; cancel = full refund |
| Limit | **1 Master per building** (inside). A Master can enter any building (it counts 2 only in its own family) |
| Refusals | `"Needs level 2"`, `"No staff to promote"`, `"Already has a Master"`, `"Promotion in progress"`, `"Not enough crystals"` |
| Keeps the title | A Master is a worker with `mastery = <kind>` for its whole life (`Cinder Hand · Drillmaster`); outside it mines like any worker; it dies like any worker |
| Look | Kingdom worker kit + a master accessory (18.V37: sash + a family badge); UI pip in gold |
| Perk (on top of power 2) | Drillmaster: soldiers trained here **+25 XP** (stacks with Drilled: +75). Horsemaster: same for the Stables. Beastwarden: titans / Lair units **-10 % crystals**. Master Smith / Loremaster: research here **-10 % crystals** (not gold / essence). Factor: caravans trained here **+5 % gold per trip** (stacks with L3: +15 %). Artificer: tier 4-5 recipes **-10 % gold part** |

### 4.5 Start, worker count, pop
- Skirmish with staffing on: each side starts with **4 workers** (was 3), 250 crystals, cap 20. The 4th stands with the others
  and gathers; it is "the first Hall's crew" in spirit. Missions keep 3.
- Typical staff by time (normal bot, section 8): 1 at 0:50 (Hall), 2-3 at 4:30 (Forge, Bazaar), 4-5 at 7:00 (Sanctum,
  Stables), 6-8 at 12:00 (+ 1-3 extra staff, Lair). The bot trains them **on top** of its mining target, so mining income is
  unchanged: staffing costs **50 crystals + 12 s of keep time per staff** and the mining a staff would have done.
- Staff are pop-free, so armies keep today's size; the only "pop" change of step 18 is the house levels (3.3).

## 5. Auto-staff (systems 18.C5)
### 5.1 Modes (game setting `Auto-staff`, per team; bots use the same code)
| Mode | Rule |
|---|---|
| **Crew (default)** | Keeps **the first slot** of every production building filled: at completion the finishing builder stays inside; later, an **unstaffed building with work waiting** pulls one worker (5.2). Never fills slots 2-3 |
| Fill | Crew, plus: while a building has **2+ items queued**, it fills its free slots with **idle** workers only (never miners) |
| Off | Nothing automatic; the builder walks back to its node as today |
- Per-building override: the **Auto** pill in the building panel (on by default; off = this building is never auto-staffed).
- Auto never ejects staff, never promotes Masters, never touches the keep.

### 5.2 Who gets picked (event-driven + one sweep every 2 s per team, staggered)
Triggers: `construction_finished`, `queue_changed` (item added to an unstaffed building), a staff leaving, the sweep. For one
blocked building, the first worker that qualifies:
1. The **builder** that just finished it (at completion only; if several, the one nearest the door).
2. The nearest **idle** worker within **40 m**.
3. The nearest worker in **Auto** mode (step 17b) doing a low-priority job (gathering).
4. The nearest **gathering** worker whose node has **3+** miners; else the nearest gathering worker. Only if the building has
   work queued.
Never: a worker with a build order, carrying out a repair, damaged in the last 3 s, a militia worker, a worker already
ordered into a building. One pick per building per trigger; a failed pick retries at the next sweep.
Nature's proxy Grove Hall (rb. 4.3): its Sprigling builder stays inside at P1: the proxy works at once, and the crew is lost
if the proxy dies before it can run home (part of the gamble).

### 5.3 Interaction with the Muster Bell (rb. 3.4)
Staff inside buildings are **not** militia (they are not in the tree). Militia workers cannot be auto-picked while the Bell
rings. When the Bell ends, workers go back to their nodes as rb. says; auto-staff may then pick them normally.

### 5.4 Interaction with the worker Auto button (step 17b; the 17b spec must follow this)
- Worker Auto job priority: **1** own construction site within 40 m, **2** staff a **blocked** production building (the
  crew slot only), **3** repair a pillaged improvement (Roadside Post), **4** gather.
- A worker that enters as staff keeps its Auto flag; when ejected it resumes Auto. Inside, Auto does nothing.
- Auto workers never take slots 2-3 (extra staff is always the player's choice, or the Fill mode's idle workers).

## 6. Early game and rushes (step 16 must stay viable)
| Moment | Today (rb.) | With step 18 (Crew mode, 4 start workers) |
|---|---|---|
| 0:00-0:50 | 3 workers mine while the Hall builds | 4 workers (the builder + 3): **+~55 crystals** by 0:50 |
| 0:50 Hall done | 5 miners (3 + 2 trained) | builder stays inside: **5 miners** (same) |
| 1:55 rusher's 2nd Hall done | 5 miners | 4 miners (2nd Hall's builder stays): **-~80 crystals by 3:05** (~1.5 rush units) |
| 3:00 contact | 12-13 Scorchlings / ~10 Hounds / 12-13 Thornlings / ~10 Rimelings | **-1 to -2 units** for two-Hall rushes (net of the +55); **Nature proxy** also loses the proxy's crew if the proxy dies |
| Defender at 3:00 | Hall + tower + army | Hall (staffed by its builder) + tower (no staff) + army: **same** as today; no level exists before ~7:00 |
| Rush-unit training speed | x1.00 | x1.00 (L1 = 1 slot: no way to speed a Hall before the Stronghold) |
- Net: rushes lose ~5-10 % of their bodies at contact, defenders are unchanged, the rusher's economy after the rush is ~equal
  to today (its 2 staff are pop-free). This sits inside rb. 8's 20-50 % success band; rb.'s re-test rounds B / C run with
  staffing on (9.3). If rush success drops below 20 %: knob 9.2 row 1 (start crystals +25 for both sides).
- **Anti-hide**: a worker damaged in the last 3 s cannot enter a building, and L1 buildings have 1 slot: raiders' worker
  kills (rb. 3.2 break-even) are not dodged by stuffing workers inside.
- Towers need no staff: the Ice forward Rime Spire (rb. 4.4) and every rush-defence tower work as today.
- Levels cannot arrive before the Stronghold (~7:00 normal, ~6:00 hard): the 3:00-4:30 rush window never meets a levelled
  building.

## 7. UI: what must be shown (layouts, sizes, looks: ui-designer addendum `docs/design/ui-staffing.md`, task 18.U0)
| Element | Content | Interaction |
|---|---|---|
| **Keys** (physical) | Building selected: **I** = Staff In (Shift+I = fill every free slot), **O** = Staff Out (Shift+O = all but the Master), **L** = Level up (keep: N and L). Workers selected: **I** = Staff (targeted: click an own building). Checked: I is only the Grand Market key *inside the build menu* (gm.); O and P are free everywhere; L is only the Sanctum *inside the build menu* (rs.); N stays the keep upgrade | AZERTY prints I, O, L on those keys too |
| Right-click | Workers selected, right-click an **own completed building with a free slot** = enter as staff (carrying workers deliver first if it is a drop-off). No free slot: today's right-click (move / drop-off) + message `No free staff slot (2 / 2)` | Construction sites keep "build" |
| Command card, row 3 (every staffable building) | r3c1 **Staff In I**, r3c2 **Staff Out O**, r3c3 **Train Master** (no key; hidden below level 2), r3c4 **Level up L**. Houses / towers: only r3c4. Tooltips: `Staff In  [I]\nThe nearest idle worker walks in (else a miner).\nStaff 1 / 2 · speed x1.00 -> x1.25` · `Level 2  [L]\n125 crystals · 40 s\n+20 % HP · 2 staff slots · Master\nUnlocks Pyre Adepts.` (+ `\nNeeds a Stronghold` when disabled) · `Train Master\n100 crystals · 30 s\nA staff worker becomes a Drillmaster: counts as 2 staff; soldiers from here +25 XP.` | Disabled buttons show the reason as today |
| Worker card | r2c2 **Staff I** (targeted order, cross cursor; left-click an own building confirms; Esc / right-click cancel) | |
| **Selection panel** (building) | Title `Ember Hall · Level 2` + 3 small level pips (I II III, the current ones lit; max-2 families show 2). **Staff strip**: one pip per slot (worker grey, Master gold, reserved hollow-bright, empty outline, Steward locked gold on the keep) + `x1.25` + an **Auto** pill (toggle). Chips beside the queue: `Level 3 · 62 % · 21 s` and `Master · 40 %` (click = cancel, full refund). Blocked: the queue's progress bar turns red with `No staff: training paused` | Click a pip = select nothing (read-only); hover = worker name / title |
| **World: blocked icon** | Own production buildings that are **blocked** (0 staff and work waiting): a small red **empty-stool** icon floats 1 m above the roof (billboard, ~0.9 m, visible to 60 m, own team only) | Hidden the moment a worker is ordered in |
| **World: working look** | Every staffable building: lit windows / chimney / moving parts when staffed (`set_staffed(n)`, section 11), dark and still at 0. Seen by both teams (a scouting hint) | |
| **Top bar** | A warning chip `1 building unstaffed` **only while >= 1 own building is blocked** (after the gold / Souls chips) | Click = select and centre on the next blocked building (cycles) |
| Messages | `Ember Hall is now level 2` · `Ember Hall has no staff: training paused` (once per 30 s per building, only when blocked) · `Your Ember Hall was destroyed: 2 staff escaped` · `A Drillmaster is ready at the Ember Hall` · `No free staff slot (2 / 2)` · enemy: `The enemy Hall has reached level 3` only if visible when it completes | `show_message`, max one level line per 3 s (summed) |
| End screen | `Levels bought 7 · Staff peak 8 · Unstaffed 0:42` per side | |
| Settings | Game settings `Auto-staff: Crew / Fill / Off` (default Crew). Skirmish option `Staffing and building levels: On / Off` (default On) | Sets `Skirmish.staffing_enabled` / `levels_enabled` before the scene enters the tree |
| Help text | `I / O: staff in / out (building) · I: staff (workers) · L: level up` | |
| Audio (ui-coder, SFX bus) | Door thud on enter / exit (max 2 / s), level-up horn per kingdom (4), master promotion chime, blocked warning (soft, once per 30 s) | |

## 8. The bot (ai 18.A1 / 18.A2: new rule **17** of `ai.md`, knobs in `AIProfile` / `data/ai/*.tres`)
| Knob | Easy | Normal | Hard |
|---|---|---|---|
| `auto_staff_mode` | Crew | Crew | Crew |
| `staff_extra_max` (extra staff beyond the crew slots, whole base) | 0 | **3** | 5 |
| `staff_extra_after` (earliest) | - | 6:00 | 5:00 |
| `level_enabled` | true (max level 2) | true | true |
| `level_first_delay` (after the Stronghold / Citadel) | 90 s | **30 s** | 15 s |
| `level_reserve` (crystals kept after a level-up) | 150 | **100** | 75 |
| `master_max` | 0 | 1 | 2 |
| Rule | Trigger -> action (first that applies; at most one level-up or promotion purchase per **15 s**; shares research's pressure rule 14d) |
|---|---|
| 17a Workers | Worker target = `worker_target_*` (ai.md 3) **+ the staff it has and wants** (crew slots of its production buildings + extra staff): mining stays at today's count |
| 17b Crew | The shared auto-staff code (Crew). Rusher style: same (its 2 Halls take their builders) |
| 17c Extra staff | After `staff_extra_after`, crystals >= **350 for 20 s** and a queue of **2+** somewhere and pop room: Staff In one worker (trained on top, 17a) to the building with the longest queue (Halls first, then the Forge while researching), up to `staff_extra_max`. Never while rule 1 / 1b (defend, rush alert) runs. Never ejects |
| 17d Levels | Tier reached + `level_first_delay` + crystals >= price + `level_reserve` + no defence running + `own_strength >= research_min_ratio x seen_strength` -> the next entry of its kingdom's order (below) whose building exists and whose level is allowed. Houses only when pop_used >= pop_cap - 2 |
| 17e Masters | After the first L2 building of the order: promote in it (normal: the main Hall; hard: + the Forge) |
| 17f Rusher | No level-up, extra staff or Master before its TRANSITION phase (rb. 6.2) |
| 17g Strength | `own_strength` x (1 + 0.03 per building level above 1, max +0.2); a seen enemy building at level 3 adds +3 % to `seen_strength` |
| Kingdom | Normal order (after **S** = Stronghold, **C** = Citadel) |
|---|---|
| Fire | S: main Hall L2 (Pyre Adept), Forge L2, Stables L2, houses L2 (at cap), Bazaar L2 (5+ caravans) · C: main Hall L3 (Cinderlock), Lair L2, Grand Market L2, Sanctum L2, Forge L3, 2nd Hall L2 |
| Shadow | S: main Hall L2 (Hexweaver), Sanctum L2, Stables L2, houses L2 · C: Lair L2 (Mage Archer / Knights), main Hall L3 (Drilled), Grand Market L2, Sanctum L3, Forge L2 |
| Ice | S: Forge L2, main Hall L2 (Hardened), 2 towers L2 (the ones nearest the keep; hard: 3), houses L2 · C: main Hall L3 (Rifleman), Forge L3, Lair L2, Grand Market L2, towers L3 (hard) |
| Nature | S: main Hall L2 (Vinelasher), Stables L2, Sanctum L2, houses L2 (3 hollows) · C: Stables L3 (Outrider), Lair L2, main Hall L3, Grand Market L2, Sanctum L3 |
Expected (normal): first extra staff ~6:00-7:00, first L2 ~7:45-8:30, 3-4 levels by 11:00, first L3 ~12:30-13:30, ~1 000
crystals of levels by 15:00. Easy: never above level 2, no extra staff.

## 9. Balance
### 9.1 Economics checks (numbers behind the knobs)
| Check | Result |
|---|---|
| One extra staff in an L2 Ember Hall | x1.00 -> x1.25: Flame Guard 18 s -> 14.4 s = **+0.83 Guards / min** (~75 crystals of army / min). Price: a worker (50) + its mining (~70 / min). About even: worth it only when crystals **float** (production-bound). That is the decision we want |
| Hall L3 with Master + 2 workers (x1.60) vs two L1 Halls (x2.00) | L3 Hall: 150 + 125 + 200 + 100 (Master) = 575 + 3 staff. Two Halls: 300 + 2 staff. **More Halls win on quantity**; the L3 Hall wins on quality (T3 unit, Drilled +50 / +75 XP, 1.4x HP) and base space |
| Drilled + Drillmaster | +75 XP = 75 % of Veteran: a Guard reaches Veteran (x1.1 HP / damage) after one kill instead of 2-3. ~+4-6 % army value mid-late; readable (chevrons appear sooner) |
| Forge L2 + 2 staff | x1.25 / 0.85 = **x1.47** research speed: a 55 s tier-2 research in 37 s. Keep tiers still gate: the tree is not reached earlier, only digested faster after each tier |
| Second bench (L3) | Two researches at once per building: the full tree (rs. ~17:00-19:00 normal) ends ~1:30-2:30 sooner for players who buy it (~300 crystals of levels) |
| House levels | +20 pop per team (Nature +24) after ~13:00 at 300 crystals (Nature 450): late armies +25 %, only when the player invests in both houses. 60 pop + staff stay under the 200-unit perf test (~120-140 units in a late game) |
| Tower L3 | 21 damage (24 with Salamander Oil), range 13: a keep-side tower kills a Flame Guard in 7 shots instead of 9. Defensive tier: slows late pushes, never early ones |
| Staff at 15:00 | ~7-10 per side (350-500 crystals of workers, pop-free), ~500-700 crystals / min of mining not done by them: the price of the speed |

### 9.2 Knobs (one at a time; 18.D2 after the 18.L2 runs)
| Symptom | Knob |
|---|---|
| Rush success < 20 % with staffing on (rb. rounds B / C) | Start crystals 250 -> **275** (both sides); if still low: rush units' train time -1 s (never their HP, rb. 12.2) |
| Players leave buildings blocked (playtest: > 60 s unstaffed per game) | Auto-staff default **Crew -> Fill**; blocked icon visible to 90 m |
| Extra staff never pays (nobody staffs beyond the crew) | Speed table x1.25 / 1.45 / 1.60 -> **x1.30 / 1.55 / 1.75** |
| Extra staff dominates (bots with 3+ extra staff win > 60 %) | -> **x1.20 / 1.35 / 1.45** |
| Levels bought after 10:00 only | Hall / Stables L2 125 -> **100**; Forge / Sanctum / Bazaar L2 100 -> **75** |
| Games > 22:00 (levels + research + titans) | Level HP x1.2 / x1.4 -> **x1.1 / x1.25** (not the keep); tower L3 damage x1.4 -> **x1.3** |
| Games < 14:00 | Tower L2 x1.2 -> **x1.3**; house L3 +5 -> **+0** (pop 50 max) |
| Late armies too big (perf or length) | House levels +5 / +5 -> **+3 / +3** (Nature +2 / +2) |
| Research finishes too early (all 12 before 15:00) | Second bench -> **research -15 % crystals** at L3 instead |
| Masters ignored | Promotion 100 -> **75** crystals, 30 -> 20 s |
| Drilled snowballs (Champions-rank armies by 15:00) | Drilled +50 -> **+30** XP; Drillmaster +25 -> **+15** |
| Frost Hall L2 feels empty | Hardened +8 % -> **+12 %** max HP |

### 9.3 Re-test plan (lead 18.L2, then 18.D2)
Harness: the any-kingdom bot-vs-bot run (normal, cap 24:00) with new flags **`--no-staffing`** and **`--no-levels`** as controls.
| Round | Pairs | Runs | Pass |
|---|---|---|---|
| A | 6 non-mirror pairs, both orders | 12 with staffing + levels, 6 with both flags | Median length within **15:00-20:00** and within **+-1:30** of the control; every kingdom 35-65 % |
| B | same runs | - | Per side: blocked production **< 20 s** per game (bots); first L2 by 9:00 in >= 70 %; 600-1 500 crystals of levels by 15:00; staff peak 6-10 |
| C | rb. rush rounds B / C (Rusher vs Balanced, all 16 pairs), staffing on | as rb. 11.3 | rb.'s bands: each cell 20-50 % rush success, <= 15 % of rush games end before 8:00 |
| Perf | perf test + both sides maxed (every family at max level, 12 staff, houses L3: 60 / 74 pop) | 1 | `PERF OK`, stuck 0 |

## 10. Performance
| Item | Budget / rule |
|---|---|
| Staff | Out of the scene tree: **no** physics, nav, avoidance, fog stamp or `_process`. More staff = fewer simulated units (a small gain) |
| Work speed | One float per building, recomputed only on `staff_changed` / `level_changed` (never per frame) |
| Auto-staff | Event-driven + one 2 s sweep per team over the cached production-building list (<= 12); worker search over the team's cached worker list (<= 25), squared distances, no physics queries |
| Level looks | Add-on nodes pre-built in the model scene, hidden; `set_level` toggles visibility (no instancing at runtime). <= 8 extra meshes per level (merged), **0 real lights**, emissive glow only, shared materials, no shadows on thin parts |
| Working look | `set_staffed(n)`: one instance-shader parameter (emission) + a particle emitter toggled; <= 24 particles per building, `fixed_fps 30`, hidden beyond 60 m |
| Level-up burst | One pooled `GPUParticles3D` (<= 40, 1.5 s) per play |
| Blocked icon | One `Sprite3D` per building, created lazily, hidden by default |
| Totals | New logic **< 0.05 ms / frame** average (200-unit perf test, all families maxed) |

## 11. Art per level (tech-artists; style `art-keep.md` section 0: chunky, hand-painted, readable at 40 m)
### 11.1 Rules for every level task
- **Same footprint**, same collider, same door (spawn corner). Add-ons may overhang the footprint by at most 0.5 m. Height:
  L2 <= L1 + **1.5 m**, L3 <= L1 + **3.0 m** (towers +1.2 / +2.4 m).
- **Distinct at a glance**: a 40 m black-silhouette test must tell L1 / L2 / L3 apart (a new mass on the skyline at L2, a new
  crown / tower element at L3), not just colour.
- Pattern: **L2 = a second storey or wing + banners** (the "grown" look); **L3 = a crown element + one more glow point**
  (the "proud" look). Max 4 glow points total per building. **0 real lights.**
- Budgets: <= 8 extra meshes per level (merged, indexed, `generate_normals`), shared materials (the painted / banner /
  rune_glow shaders of `art-keep.md` 5), no runtime materials.
- Scene layout: children `Level2` and `Level3` (Node3D) holding the add-ons; the L3 look shows **both** (L2 add-ons stay
  unless an L3 part replaces one: then hide it in `set_level(3)`).
- Hooks on the scene root script (called by `Building` if present): `set_level(level: int)` (1-3, instant; also used on load
  and by fog ghosts), `play_level_up()` (1.5 s burst in the kingdom glow, scaffold-free, as the keep's `play_tier_up`),
  `set_staffed(count: int)` (0 = dark windows, cold chimney, still wheel; >= 1 = lit and moving; 2+ = a little brighter).
  Optional `play_staff_enter()` / `play_staff_exit()` (door dust). Construction and destroyed states stay the L1 ones; the
  destroyed animation hides or drops the add-ons with the rest.
- Each task edits the existing model scene of that building (paths in `data/buildings/<id>.tres` `model_scene` /
  `model_path`), renders L1 / L2 / L3 previews (`art/buildings/previews/`), and lists the hooks in
  `docs/handoff/for-systems-coder.md`.
- Keep levels = keep tiers: **already covered by 14.V9-14.V12** (`set_tier`); step 18 adds no keep art.

### 11.2 The level art tasks (one agent per row)
| Task | Building | Level 2 (grown) | Level 3 (proud) |
|---|---|---|---|
| 18.V1 | Ember Hall (Fire) | Dark-brick upper storey with a row of ember-slit windows; two crossed-spear banners on the gate | Bell-shaped ember watch cupola on the ridge (new glow); iron-studded corner buttresses |
| 18.V2 | Gloom Hall (Shadow) | Slate upper floor with pointed dormers and violet arrow-slits; tattered pennants | Twin needle spires at the rear corners joined by a chain; a raven-wing crest over the gate with a glowing eye |
| 18.V3 | Frost Hall (Ice) | Ice-brick upper ring with blue shield-row windows; white wolf-pelt banners | Frozen crenellated crown with 4 icicle spikes; a floating rune shield over the gate |
| 18.V4 | Grove Hall (Nature) | Woven-branch second level wrapping the roof, hanging moss and seed lanterns | A young tree grows through the roof, a canopy above (+2 m) with glow-fruit |
| 18.V5 | Hearth (Fire) | Timber loft with a small balcony; the chimney doubled | A second loft roof, a brass weathervane, an ember lamp over the door |
| 18.V6 | Hovel (Shadow) | Crooked lean-to shed with its own roof; bone wind-chimes | A narrow crooked tower room with a single violet candle window |
| 18.V7 | Snow Lodge (Ice) | A second snow-brick dome joined by a short tunnel | A smoke-hole cap with an antler rack; a frost-lantern post |
| 18.V8 | Seed Hollow (Nature) | A second mushroom-cap roof tier and a vine ladder | A flowering bough arch over the door with firefly jars |
| 18.V9 | Ember Spire (Fire) | A ring of iron braziers round the upper gallery; a short banner | A taller crown with a bigger orb cage (+1.2 m); the orb brighter |
| 18.V10 | Night Spire (Shadow) | Bat-wing buttress fins on four sides | A slow-spinning violet ring around the orb; a spike crown |
| 18.V11 | Rime Spire (Ice) | An icicle collar and a frosted gallery | A second crystal shard crown slowly orbiting the top |
| 18.V12 | Bramble Spire (Nature) | Thicker thorn coils and a bird's-nest platform | A blooming thorn crown with glowing seed pods |
| 18.V13 | Ember Bazaar (Fire) | A second row of striped-awning stalls, stacked crates, a brass scale sign | A clock-and-lantern gate arch; a larger copper dome roof |
| 18.V14 | Gloom Bazaar (Shadow) | Extra covered stalls with hanging violet lamps and caged ravens | A crooked counting tower with a coin-shaped glowing window |
| 18.V15 | Frost Bazaar (Ice) | Sled racks, fur bales and a second hide tent | An ice-glass counting-hall roof with a hanging crystal bell |
| 18.V16 | Grove Bazaar (Nature) | Woven basket stalls and a honey-lamp line on the branches | A root-arch trade gate with a glowing amber sign |
| 18.V17 | Ember Forge (Fire) | A second, smaller chimney; a roofed anvil yard | A great bellows wheel on the side; a molten channel glowing across the yard |
| 18.V18 | Bone Foundry (Shadow) | A second ribcage arch extending the roof; skull lamps | The bone crane lifts a glowing cauldron above the roof |
| 18.V19 | Rime Forge (Ice) | A sluice gutter hung with icicles; a second smaller wheel | A frozen smelting tower with a blue-white core |
| 18.V20 | Root Nursery (Nature) | A second small dome on the side, linked by vines | The main dome opens into a bloom crown with one glowing flower |
| 18.V21 | Cinder Sanctum (Fire) | Fire-glyph caps on the pillars; a low ring of braziers | A floating stone ring slowly circling the bird flame; the flame taller |
| 18.V22 | Soul Crypt (Shadow) | Two hooded guardian statues flank the stair; more wisps | A hovering crown of black stones above the obelisk |
| 18.V23 | Rune Sanctum (Ice) | Two more monoliths; an inscribed floor disc | A second, larger rune disk stacked higher, counter-rotating |
| 18.V24 | Wildroot Sanctum (Nature) | The stumps sprout new shoots and hang lanterns | An arch of intertwined roots over the glowing sapling |
| 18.V25 | Ember Stables (Fire) | A hay loft with a hoist beam; a horseshoe banner | A tack tower topped by an ember weathervane of a charging boar |
| 18.V26 | Gloom Stables (Shadow) | A covered paddock with black-iron fencing | A stable tower with a hanging horse-skull lantern |
| 18.V27 | Frost Stables (Ice) | A sled shed with antlered gate posts | A lookout roofed by a tusk arch, frost lantern inside |
| 18.V28 | Grove Stables (Nature) | A living-hedge paddock with a flower gate | A great stag-antler arch woven from branches |
| 18.V29 | Dragon Roost (Fire, L2 only) | A second perch spur and a glowing coin-hoard in the nest | - |
| 18.V30 | Dread Paddock (Shadow, L2 only) | Black banners on pikes and a spiked gate arch with a violet brazier | - |
| 18.V31 | Glacier Den (Ice, L2 only) | A tusk arch over the entrance, a frozen trough and an ice crown | - |
| 18.V32 | Elder Circle (Nature, L2 only) | A ring of young sapling-guardians and hanging lantern vines | - |
| 18.V33 | Brasslight Exchange (Fire, L2 only) | Gilded dome ribs, a second bell in the tower, the sun-dial glows | - |
| 18.V34 | Duskvault Exchange (Shadow, L2 only) | Obsidian obelisks flank the vault door; gilded raven-scale dome | - |
| 18.V35 | Hoarglass Exchange (Ice, L2 only) | A crystal spire on the dome; the frosted bell doubled | - |
| 18.V36 | Mossgold Exchange (Nature, L2 only) | A flowering canopy over the dome, a glow-fruit garland | - |
| 18.V37 | Master kit (4 kingdoms) | Worker accessory: a sash in the kingdom colour + a small family badge (7 badges: whistle, horseshoe, fang, hammer, book, scale, gem); `set_master(kind)` on the worker kit | - |
| 18.V38 | Level / staff VFX + world icons | `play_level_up` burst (kingdom-tinted, shared), door dust puff, the red empty-stool blocked icon (billboard) | - |
| 18.V39 | UI icons | Staff In, Staff Out, Train Master, Level up (I / II / III), staff pips (worker, Master, reserved, empty, Steward), Auto pill, 7 Master titles (`art/icons/staffing/`) | - |
Dependencies: V1-V16 edit models that exist today; V17-V24 wait for 14.V1-14.V8, V25-V32 for the step-13 Stables / Lair
models, V33-V36 for 17.V1-17.V5 (the Grand Market is one structure + kingdom trims: each task adds that kingdom's trim to the
shared L2 parts, the first one to land builds the shared parts).

## 12. Proposed contracts (the lead freezes them in `CLAUDE.md`: task 18.L1)
Phase-1 rule (as steps 9-17): never use another step-18 agent's new `class_name` as a static type; reach it with groups,
`has_method()`, `get()`.
- **BuildingType** new fields: `max_level: int = 1`, `level_costs: Array[int] = []` (index 0 = L2, 1 = L3), `level_times:
  Array[float] = []`, `staff_slots: Array[int] = []` (per level; empty = never staffed), `innate_staff: int = 0` (keeps: 1),
  `master_title: String = ""`. Constants in `scripts/buildings/building_levels.gd` (`class_name BuildingLevels`, static data,
  every number of 3.3 / 4.1 / 4.4 in one place: `HP_MULT := [1.0, 1.2, 1.4]`, `SPEED_BY_POWER := [0.0, 1.0, 1.25, 1.45,
  1.6]`, perks by kind and level, Master price / time / perks, `TIER_TIME_FALLBACK := [0, 360, 660]`).
- **Building** (all buildings): `level: int` (read only, 1-3), `max_level() -> int`, `can_level_up() -> String`,
  `start_level_up() -> String`, `cancel_level_up()`, `is_levelling() -> bool`, `level_up_progress() -> float`,
  `level_up_time_left() -> float`, `set_level(level: int)` (load / tests; applies HP, perks, look), signals
  `level_changed(building, level: int)`, `level_up_started(building)`. HP: effective `max_hp` = base x level factor (keeps:
  tier factor) x GoldBank factor x research factor. `static team_tier(team: int) -> int` (ResearchBank keep tier, else the
  time fallback of 3.4).
- **Building** (staffing, staffable kinds): `staff: Array[Node]` (read only; workers out of the tree), `staff_slots() -> int`,
  `staff_count() -> int`, `staff_power() -> int` (incl. innate), `work_speed() -> float` (1.0 when staffing is off),
  `needs_staff() -> bool`, `is_blocked() -> bool` (0 staff and work waiting), `can_take_staff(worker) -> String`
  (`"No free staff slot"`, `"Under construction"`, `"Not a worker"`, `"Under attack"` (damaged < 3 s), `"Can't staff this"`),
  `reserve_staff(worker) -> String`, `add_staff(worker)` (the worker calls it at the door), `eject_staff(count := 1,
  keep_master := true) -> int`, `eject_all()`, `auto_staff: bool` (per-building pill), `can_promote() -> String`,
  `promote_master() -> String`, `cancel_promotion()`, `promotion_progress() -> float`, `has_master() -> bool`, signal
  `staff_changed(building)`. Model hooks `set_level`, `play_level_up`, `set_staffed`, `play_staff_enter`, `play_staff_exit`.
- **TrainingBuilding / ResearchBuilding / Market / GrandMarket / Lair**: every production clock `+= delta x work_speed() x
  (existing multipliers)`; `is_blocked()` true while the queue is not empty and staff is 0. ResearchBuilding at L3 runs
  queue[0] and queue[1] together; `research_progress(slot := 0)`. `MAX_QUEUE` 3 -> 4 at L2.
- **Unit gate**: `can_queue(type)` adds `"Needs <building name> level N"` after the keep-tier check when `levels_enabled` and
  `type.required_keep_tier > level` at a Hall / Stables.
- **Worker**: `command_staff(building)` (walk to the door, `add_staff`), `is_staff() -> bool`, `staff_building: Node` (read
  only), `mastery: StringName` (`&""` = none), `is_master_for(kind: StringName) -> bool`, `last_damaged_time()` (or the
  existing `seconds_since_damage`), model hook `set_master(kind)`. The UI checks `has_method("command_staff")`.
- **StaffDirector** (`scripts/economy/staff_director.gd`, `class_name StaffDirector extends Node`, one per team, group
  `"staff_directors"`, created by the Skirmish when `staffing_enabled`): `static for_team(team) -> StaffDirector` (null when
  off), `mode: StringName` (`&"crew"` / `&"fill"` / `&"off"`), `blocked_buildings() -> Array[Node]`, `staff_total() -> int`,
  `request_staff(building) -> Node` (5.2 pick, used by Staff In and by bots), signal `blocked_changed(count: int)`.
- **Economy**: `max_pop_cap` + the house-level bonus (`add_pop_cap_bonus(amount)`); staff pop is free through the existing
  `tree_exiting` / `node_added` counting (no new pop code).
- **Skirmish**: `@export var staffing_enabled := true`, `@export var levels_enabled := true` (missions false); start workers
  **4** when `staffing_enabled`; end-screen line; test flags `--no-staffing`, `--no-levels`.
- **GameSettings**: `auto_staff_mode` (`&"crew"` default).
- **Keys line** (lead): `building selected: I = staff in (Shift = fill), O = staff out (Shift = all), L = level up (keep: N
  or L)`, `workers selected: I = staff (click a building)`.
- **Ownership**: `scripts/buildings/building_levels.gd`, `scripts/economy/staff_director.gd`, `data/buildings/` =
  systems-coder; `scripts/ui/` staffing parts = ui-coder; `art/buildings/**` level add-ons, `art/units/workers/master_kit`,
  `art/vfx/level_*`, `art/icons/staffing/` = tech-artists; `scripts/ai/` = ai-coder. No `Events` change (the building
  signals are enough).

## 13. What changes in other specs (18.D2 writes the lines after the build)
- `buildings.md` / `economy.md`: levels, staff slots, 4 start workers (skirmish), pop cap bonus of house levels.
- `research.md`: keep tiers also give keep staff slots; Forge / Sanctum L2 / L3 (queue 4, -15 % time, second bench);
  `train_speed_mult` multiplies with `work_speed`.
- `rush-balance.md`: T2 Hall units need the Hall at L2; section 6 of this file in 3.2 (rush cost); rounds B / C with staffing.
- `tier3-extras.md`: Cinderlock / Rifleman need the Hall at L3, the Glade Outrider the Grove Stables at L3.
- `cavalry-mounts.md`, `titans-2.md`: Lair L2 (Bonded), the Crucible timer uses the Lair's work speed.
- `market-trade.md`: caravan limit 8 / 10 by Bazaar level, L3 +10 % gold, the Factor.
- `grand-market.md`: epics open at Grand Market L2 (Citadel), relic stock 3, tier 4-5 crafting needs staff, the Artificer.
- `levels.md`: Drilled (+50 XP) and Drillmaster / Horsemaster (+25 XP) at spawn.
- `ai.md`: rule 17, worker target + staff. `ui-hud.md`: row 3 of building cards, top-bar blocked chip, help text.
- Step 17b spec (`worker-improvements.md`, when written): section 5.4 of this file.

## 14. Task list (step 18; build after steps 12-14 and 16-17 are merged)
**Phase 0:** 18.L1, 18.U0. **Phase 1 (parallel, no shared files):** 18.C1, 18.C2, 18.V1-18.V16, 18.V37-18.V39.
**Phase 2:** 18.C3, 18.C4, 18.C5, 18.U1-18.U3, 18.V17-18.V36 (as their base models exist). **Phase 3:** 18.A1, 18.A2, 18.A3,
then 18.L2 (runs) and 18.D2 (tuning).
| Id | Owner | Size | Task | Files | Done when |
|---|---|---|---|---|---|
| 18.L1 | lead | S | Freeze section 12 in `CLAUDE.md` (contracts, Keys, ownership), 18 ids in `waves.md`, the user's answers | `CLAUDE.md`, `docs/plan/` | Contracts and keys written |
| 18.U0 | ui-designer (Fable) | S | Layout addendum `docs/design/ui-staffing.md`: card row 3, panel staff strip / pips / chips, blocked icon, top-bar chip, tooltips | `docs/design/ui-staffing.md` | Every element of section 7 has a size, place and look |
| 18.C1 [H] | systems-coder-high | L | Levels: BuildingType fields + all `data/buildings/*.tres`, `BuildingLevels`, Building level API, HP factor, keep tier = level, `team_tier` with the time fallback, house pop-cap bonus, tower damage / range / sight, unit gates (Hall / Stables level) | `scripts/buildings/`, `data/buildings/`, `scripts/economy/economy.gd` | Test: an Ember Hall levels 1 -> 2 (125, 40 s) only with a Stronghold (research off: from 6:00), HP 1300 -> 1560 healed; L3 needs a Citadel; cancel refunds 100 %, destroyed mid-level 75 %; Pyre Adept refused `Needs Ember Hall level 2` at L1; two L3 Hearths give cap 60; an L3 Ember Spire hits 21; Ice Wall has no level-up |
| 18.C2 [H] | systems-coder-high | L | Staffing core: `Worker.command_staff`, door walk, out-of-tree storage, reservation, eject (manual / destroyed: flee to keep), pop through tree exit, `work_speed()` on TrainingBuilding, anti-hide 3 s, Steward on keeps, Masters (promote, `mastery`, power 2, perks) | `scripts/buildings/`, `scripts/economy/worker.gd` | Test: an unstaffed Hall with a queued Flame Guard does not progress; 1 worker -> 18.0 s +-0.1, 2 (L2) -> 14.4 s, Master + worker -> 12.4 s; pop_used drops by 1 when a worker enters and rises when it leaves; a destroyed Hall ejects its 2 staff alive; a worker hit 1 s ago is refused `Under attack`; the keep trains workers with 0 staff |
| 18.C3 | systems-coder | M | Production hooks and family perks: ResearchBuilding (work speed, L2 -15 % and queue 4, L3 second bench), Market (caravan training, limits 8 / 10, +10 % gold, Factor), Grand Market (tier 4-5 crafting needs staff, relic restock, epics at L2, relic stock 3, Artificer), Lair (Bonded, Crucible timer, Beastwarden), Stables (Remount, Drilled), Hall (Drilled, Hardened, Drillmaster) | `scripts/buildings/`, `scripts/research/` (research_building hooks only) | Test: Forge L3 runs 2 researches at once; an unstaffed Grand Market refuses a heroic recipe with `No staff at the Grand Market`; a Bazaar L2 accepts an 8th caravan; a soldier from an L3 Hall with a Drillmaster spawns with 75 XP |
| 18.C4 | systems-coder | S | Skirmish flags `staffing_enabled` / `levels_enabled` (missions false), 4 start workers, `--no-staffing` / `--no-levels`, end-screen stats | `scripts/world/skirmish.gd` | Mission 1 smoke test unchanged (`victory=true`); a skirmish starts with 4 workers; with both flags off every building behaves as before step 18 |
| 18.C5 | systems-coder | M | `StaffDirector`: Crew / Fill / Off, the 5.2 pick order, per-building Auto, Muster Bell exclusion, the 17b Auto job hook (priority 2), `blocked_buildings()` | `scripts/economy/staff_director.gd` | Test: a finished Hall keeps its builder inside (Crew); a destroyed-then-rebuilt Hall is re-staffed by an idle worker within 2 s; Fill never pulls a miner; Off leaves the builder free; militia workers are never picked |
| 18.U1 | ui-coder | M | Command card row 3 (I / O / Train Master / L, Shift variants), keep L alias, worker Staff I targeted order, right-click enter + message, tooltips and reasons | `scripts/ui/` | Keys work on AZERTY; every refusal of 3.1 / 4.2 / 4.4 shows its text; nothing calls a `_private` function |
| 18.U2 | ui-coder | M | Selection panel: title with level, level pips, staff strip (pips, speed, Auto pill), level-up and Master chips (click = cancel), red paused bar | `scripts/ui/` | A selected L2 Hall with 1 worker shows `Ember Hall · Level 2`, pips 1 / 2, `x1.00`, Auto on |
| 18.U3 | ui-coder | M | Blocked world icon, top-bar blocked chip (click cycles), messages (rate limits), settings (Auto-staff; skirmish toggle in the menu), help text, audio | `scripts/ui/`, `scripts/ui/menus/`, `assets/audio/` | The chip appears only while a building is blocked and disappears within 0.5 s of staffing it |
| 18.V1-18.V36 | tech-artist (one per row of 11.2) | M (V29-V36: S) | Level add-ons, `set_level`, `play_level_up`, `set_staffed`, previews, handoff lines | `art/buildings/**` | 40 m silhouette test tells L1 / L2 / L3 apart; same footprint; <= 8 meshes per level; 0 lights; hooks listed in the handoff |
| 18.V37 | tech-artist | S | Master kit on the 4 worker models (`set_master(kind)`) | `art/units/workers/` | A Drillmaster reads at 30 m |
| 18.V38 | tech-artist | S | Level-up burst, door dust, blocked icon | `art/vfx/level_*`, `art/icons/staffing/` | Budgets of section 10 |
| 18.V39 | tech-artist | S | UI icons (card, pips, titles) | `art/icons/staffing/` | 64 px, the `ui-style.md` icon rules |
| 18.A1 | ai-coder | M | Bot staffing: worker target + staff (17a), Crew via StaffDirector (17b), extra staff (17c), Masters (17e), Rusher 17f; knobs in AIProfile + `data/ai/*.tres` | `scripts/ai/`, `data/ai/` | Bot-vs-bot: blocked production < 20 s per game; mining workers at 5:00 within 1 of the `--no-staffing` control |
| 18.A2 | ai-coder | M | Bot levels: rule 17d orders per kingdom, pressure, strength 17g | `scripts/ai/`, `data/ai/` | Normal bot: first L2 by 9:00 in >= 70 % of runs; never levels while defending |
| 18.A3 | ai-coder | S | Harness: flags, CSV columns (level times, staff peak, blocked seconds, levels crystals) | `tests/test_18_a3.gd` | The CSV has the new columns; controls run with both flags |
| 18.L2 | lead | M | Runs of 9.3 (A, B, C, perf) | CI copy | Results in `balance-2.md` style table |
| 18.D2 | game-designer | S | Tune with 9.2 (one knob per re-run), write section 13 lines in the other specs | `docs/design/` | 9.3 passes |

## Done when (step 18)
- [ ] 18.C1-18.C5, 18.U1-18.U3, 18.A1-18.A3 done-when lists pass; smoke test `victory=true`; perf test `PERF OK` with both
  sides maxed (9.3 perf row).
- [ ] A playtest skirmish: the first Hall works with no staffing action from the player (Crew); pressing I / O / L on a Hall
  works; a blocked building is obvious within 2 s (icon + chip); every levelled building looks different at L1 / L2 / L3.
- [ ] 9.3 rounds A-C pass (length, rush bands, blocked time, level timings).

## Questions for the user (recommendation first; the spec assumes it)
1. **How strict is "production needs someone inside"?**
   (a) **Strict, with a free first crew**: no staff = no production, but the skirmish starts with **4 workers** and the builder
   stays inside automatically, so the first Hall costs nothing extra and 3:00 rushes stay as they are *(recommended)*.
   (b) Soft: every building comes with 1 free built-in crew; workers you add only make it faster (nothing ever stops).
   (c) Strict, no compensation: start with 3 workers, every building's crew is a real worker taken from mining.
2. **Auto-staff default?**
   (a) **Crew**: auto fills only the first slot (production never stops by itself); extra staff is your choice *(recommended)*.
   (b) Fill: also fills the extra slots with idle workers whenever there is a queue.
   (c) Off: you staff everything yourself (a red icon warns you).
3. **Do staff count for population?**
   (a) **No**: workers inside are fed by the building; armies keep their size; slots cap the total *(recommended)*.
   (b) Yes, 1 pop each like outside (fewer soldiers when you staff).
   (c) Only extra staff count; the first crew of each building is free.
4. **What is the "specialist"?**
   (a) **A Master**: you promote a staff worker (100 crystals, 30 s); it counts as 2 staff and adds one perk; no new unit
   *(recommended)*.
   (b) A new specialist unit per kingdom (4 new units trained at the keep, new models).
   (c) No specialists: only workers, more of them = faster.
5. **Which buildings level up?**
   (a) **All but the Ice Wall** (Hall, Stables, Forge, Sanctum, Bazaar, House, Tower to 3; Lair, Grand Market to 2; keep =
   Stronghold / Citadel), and **house levels raise the pop cap** 40 -> 60 (Nature 50 -> 74): 36 building art tasks
   *(recommended)*.
   (b) All but the Ice Wall, but houses only gain HP (pop cap stays 40 / 50).
   (c) Production buildings only (no houses, no towers): 28 art tasks.
