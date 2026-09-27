# lens icons: tiers_wave_units

2026-09-27 18:08:13 - `tools/lens/run_lens.ps1 icons tiers_wave_units` - hash `0b348267f0b3addc`

## Result: **PASS** - quality **88 / 100** (previous run 88, +0)

0 FAIL, 0 WARN, 9 PASS, 0 info, 0 skipped, 4 s

## Improve next

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 0 shots, 1 icon groups, 0 portraits | 0 errors |  |

## Icon framing (one rule: silhouette 55-75 % of the tile, centred +- 5 %)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| I_scorchling | scorchling framing | PASS 76 | cover 73 %, centre +0.8 / -0.8 % | 55-75 %, +- 5 % |  |
| I_cinder_arbalest | cinder_arbalest framing | PASS 82 | cover 72 %, centre +0.0 / +0.0 % | 55-75 %, +- 5 % |  |
| I_barrow_ghoul | barrow_ghoul framing | PASS 82 | cover 72 %, centre -0.8 / +0.0 % | 55-75 %, +- 5 % |  |
| I_hollow_oathsworn | hollow_oathsworn framing | PASS 82 | cover 72 %, centre +0.0 / +0.0 % | 55-75 %, +- 5 % |  |

## Legibility at 48 px (UI Lab rule)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| U_scorchling | scorchling at 48 px | PASS 100 | fill 18 %, L 2.22:1, dE 29 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_cinder_arbalest | cinder_arbalest at 48 px | PASS 100 | fill 15 %, L 2.24:1, dE 32 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_barrow_ghoul | barrow_ghoul at 48 px | PASS 100 | fill 19 %, L 3.76:1, dE 39 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_hollow_oathsworn | hollow_oathsworn at 48 px | PASS 100 | fill 13 %, L 1.83:1, dE 19 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |

## Images
- scorchling: [../../../../../art/icons/lens/units/scorchling.png](../../../../../art/icons/lens/units/scorchling.png)
- cinder_arbalest: [../../../../../art/icons/lens/units/cinder_arbalest.png](../../../../../art/icons/lens/units/cinder_arbalest.png)
- barrow_ghoul: [../../../../../art/icons/lens/units/barrow_ghoul.png](../../../../../art/icons/lens/units/barrow_ghoul.png)
- hollow_oathsworn: [../../../../../art/icons/lens/units/hollow_oathsworn.png](../../../../../art/icons/lens/units/hollow_oathsworn.png)
- sheet: [icons_sheet.png](icons_sheet.png)

## Notes
- Icons written to art/icons/lens/<kind>/<id>.png (256 px, kingdom background from art/icons/icon_painter.gd). The icon libraries adopt them later (their owner); nothing existing was overwritten.
