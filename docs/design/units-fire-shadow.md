# Units: Fire and Shadow (wave 1)

Source of truth for `data/units/*.tres` (task 1.G1), Malrik (1.G3), orders (1.G2) and mission 1 spawns.
Numbers match today's `UNIT_TYPES` in `scripts/world/main.gd` unless listed under "What changed".
Ranges and speeds are metres and metres/second. `attack_range` > 3.0 fires a projectile (existing rule).

## Fire (player). All trained at the keep in wave 1
| id | Display name | Role | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Colour | Cost | Pop | Train (s) | Card key |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `cinder_hand` | Cinder Hand | Worker | 50 | 4 | 1.4 | 1.2 | 4.6 | 0 | 0.4 | 1.4 | `(0.80, 0.60, 0.45)` | 50 | 1 | 12 | Q |
| `flame_guard` | Flame Guard | Melee line | 130 | 12 | 1.6 | 1.0 | 5.0 | 8 | 0.45 | 1.6 | `(0.85, 0.30, 0.12)` | 90 | 1 | 18 | W |
| `ember_archer` | Ember Archer | Ranged | 70 | 9 | 9.0 | 1.2 | 5.2 | 10 | 0.45 | 1.6 | `(0.95, 0.55, 0.20)`, bolt `(1.0, 0.75, 0.3)` | 100 | 1 | 20 | E |
| `blaze_rider` | Blaze Rider | Fast shock cavalry | 220 | 18 | 1.7 | 0.9 | 7.5 | 9 | 0.6 | 1.9 | `(0.95, 0.40, 0.05)` | 180 | 2 | 30 | R |
| `ash_hurler` | Ash Hurler | Long-range artillery | 60 | 24 | 12.0 | 2.2 | 4.0 | 12 | 0.45 | 1.6 | `(0.60, 0.35, 0.25)`, bolt `(0.5, 0.5, 0.5)` | 140 | 1 | 26 | T |

Worker: `aggro_range` 0 (never picks fights). Existing retaliation in `take_damage` is fine for wave 1.

## Shadow (enemy). Pre-placed in wave 1; costs and train times are for the wave 3 AI
| id | Display name | Role | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Colour | Cost | Pop | Train (s) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `gloom_thrall` | Gloom Thrall | Worker | 50 | 4 | 1.4 | 1.2 | 4.6 | 0 | 0.4 | 1.4 | `(0.50, 0.45, 0.55)` | 50 | 1 | 12 |
| `shade` | Shade | Melee line | 90 | 10 | 1.6 | 1.0 | 4.8 | 8 | 0.45 | 1.6 | `(0.42, 0.22, 0.60)` | 80 | 1 | 16 |
| `nightbolt` | Nightbolt | Ranged | 65 | 10 | 9.0 | 1.3 | 5.0 | 10 | 0.45 | 1.6 | `(0.55, 0.30, 0.70)`, bolt `(0.7, 0.4, 1.0)` | 100 | 1 | 20 |
| `grave_hound` | Grave Hound | Fast harasser | 60 | 8 | 1.4 | 0.7 | 7.0 | 9 | 0.4 | 1.0 | `(0.30, 0.28, 0.35)` | 70 | 1 | 14 |
| `shadow_knight` | Shadow Knight | Heavy elite | 420 | 26 | 1.9 | 1.4 | 4.0 | 10 | 0.7 | 2.4 | `(0.25, 0.12, 0.38)` | 300 | 3 | 45 |

## Wizards (pop 0, never trained, one per side)
| id | Display name | max_hp | dmg | range | cooldown | speed | aggro | radius | height | Body / hat / orb | Mana | Regen /s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `vessa` | Vessa, Fire Wizard | 350 | 14 | 7.0 | 1.3 | 4.6 | 9 | 0.5 | 2.0 | `(0.9, 0.35, 0.1)` / `(0.55, 0.08, 0.05)` / `(1.0, 0.45, 0.1)` | 100 | 4 |
| `malrik` | Malrik, Shadow Wizard | 400 | 16 | 7.0 | 1.3 | 4.4 | 9 | 0.5 | 2.0 | `(0.30, 0.12, 0.45)` / `(0.12, 0.05, 0.20)` / `(0.70, 0.30, 1.00)` | 100 | 4 |

### Vessa: Fireball (F, card slot row 2 col 1). Unchanged from today
| Mana | Damage | Radius | Range | Cooldown | Target |
|---|---|---|---|---|---|
| 40 | 60 | 3.5 | 16 | none (mana-limited) | Ground point; walks into range first |

### Malrik: Shadow Lance (AI-cast only in wave 1)
| Mana | Damage | Range | Cooldown | Heal | Target | Visual |
|---|---|---|---|---|---|---|
| 35 | 50 | 12 | 8 s | **50 % of damage actually dealt** (capped by the target's remaining HP) | One enemy unit | Straight purple bolt `(0.7, 0.3, 1.0)`, speed 30 m/s, 0.14 radius; Malrik flashes purple when healed |

Casting rules, checked every 0.5 s while alive and not on cooldown, mana >= 35, at least one player unit within 12 m:
1. If any player unit in range has HP <= 50: target the one with the **highest** HP among those (a kill that still heals the most).
2. Else if Malrik's HP < 60 % of max: target the player unit in range with the **highest** HP (full 25 heal guaranteed).
3. Else if Vessa is in range: target Vessa.
4. Else: target the nearest player unit.
Malrik otherwise fights like any unit (auto-target within `aggro_range`, leash 2x aggro to his anchor). He does not retreat in wave 1.

## Orders (task 1.G2), same for every unit
| Order | Key | Behaviour |
|---|---|---|
| Move | M then click, or right-click ground | Walk; ignore enemies |
| Attack-move | A then click ground (A then click an enemy = plain attack) | Walk to the point; engage any enemy within `aggro_range` on the way; when it dies, resume the walk |
| Hold position | H | Stay put forever; attack enemies in `attack_range` only; a move/attack order clears hold |
| Stop | S | Existing `command_stop` |
| Gather | G then click a node, or right-click a node (workers only) | See `economy.md` |
| Fireball | F then click | Existing `command_fireball`; `command_cast` replaces it in wave 2 |

## Mission 1 starting forces (relative offsets, x, z; y = 0)
Fire, 12 / 20 pop (3 workers + 5 guards + 4 archers; Vessa is 0). Same soldier positions as today.
| Unit | Count | Position |
|---|---|---|
| Vessa | 1 | `PLAYER_START` |
| Flame Guard | 5 | `PLAYER_START + (-3 + i*1.5, -2.5)` |
| Ember Archer | 4 | `PLAYER_START + (-2.25 + i*1.5, 2.0)` |
| Cinder Hand | 3 | `PLAYER_START + (-4 + i*1.2, 4 - i*1.2)`, spawned already gathering from the nearest node |

Shadow (14 units + Malrik). Enemies face `PI * 0.75` as today.
| Unit | Count | Position |
|---|---|---|
| Shade | 4 | `MID_CAMP + (cos(i*1.57)*2.5, sin(i*1.57)*2.5)` (today) |
| Grave Hound | 2 | `MID_CAMP + (-4, 0)` and `MID_CAMP + (0, 4)` |
| Shade | 5 | `ARTIFACT_POS` ring, radius 4, `a = i*TAU/5` (today) |
| Nightbolt | 2 | `ARTIFACT_POS + (5, 1)` and `ARTIFACT_POS + (1, -5)` |
| Shadow Knight | 1 | `ARTIFACT_POS + (-3, 3)` (today) |
| Malrik | 1 | `ARTIFACT_POS + (4, -4)` (behind the artifact, seen from the player's road) |

## What changed from today's numbers
- Nothing changed on Flame Guard, Ember Archer, Shade, Shadow Knight, Vessa or Fireball.
- New: Cinder Hand, Blaze Rider, Ash Hurler, Gloom Thrall, Nightbolt, Grave Hound, Malrik, Shadow Lance.
- New in mission 1: 3 workers, 2 Grave Hounds at the mid camp, 2 Nightbolts and Malrik at the artifact.
- The Fire Wizard's `unit_name` becomes "Vessa, Fire Wizard" (`display_name`); the class stays `Wizard`.

## Done when
- [ ] 1.G1: 10 `UnitType` resources + 2 wizards use exactly the tables above; nothing reads `UNIT_TYPES`.
- [ ] 1.G2: A, H, S, M work by physical keycode; an attack-moving group stops for enemies and resumes; a held unit never moves.
- [ ] 1.G3: Malrik casts Shadow Lance on rule 1-4, heals 25 on a full hit and less on an overkill, respects 8 s cooldown; killing him shows the message and does not end the mission.
- [ ] Mission 1 spawns the two tables above and the top bar reads 12 / 20 at start.
