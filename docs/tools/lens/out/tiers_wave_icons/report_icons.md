# lens icons: tiers_wave_icons

2026-09-27 18:03:22 - `tools/lens/run_lens.ps1 icons tiers_wave_icons` - hash `f33b52364b50f407`

## Result: **PASS** - quality **88 / 100** (previous run 88, +0)

0 FAIL, 0 WARN, 11 PASS, 0 info, 0 skipped, 5 s

## Improve next

## Spec
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| P1 | spec | PASS 100 | 0 shots, 1 icon groups, 0 portraits | 0 errors |  |

## Icon framing (one rule: silhouette 55-75 % of the tile, centred +- 5 %)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| I_rimeling | rimeling framing | PASS 82 | cover 72 %, centre +0.0 / +0.0 % | 55-75 %, +- 5 % |  |
| I_hoarlight_magebow | hoarlight_magebow framing | PASS 80 | cover 72 %, centre +0.2 / -0.2 % | 55-75 %, +- 5 % |  |
| I_frost_mortar | frost_mortar framing | PASS 82 | cover 72 %, centre +0.0 / +0.0 % | 55-75 %, +- 5 % |  |
| I_thistle_darter | thistle_darter framing | PASS 80 | cover 72 %, centre +0.0 / -0.2 % | 55-75 %, +- 5 % |  |
| I_greenheart_oathkeeper | greenheart_oathkeeper framing | PASS 80 | cover 72 %, centre +0.2 / -0.2 % | 55-75 %, +- 5 % |  |

## Legibility at 48 px (UI Lab rule)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| U_rimeling | rimeling at 48 px | PASS 100 | fill 17 %, L 4.72:1, dE 45 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_hoarlight_magebow | hoarlight_magebow at 48 px | PASS 100 | fill 14 %, L 4.38:1, dE 43 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_frost_mortar | frost_mortar at 48 px | PASS 100 | fill 30 %, L 4.73:1, dE 45 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_thistle_darter | thistle_darter at 48 px | PASS 100 | fill 12 %, L 4.04:1, dE 40 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |
| U_greenheart_oathkeeper | greenheart_oathkeeper at 48 px | PASS 100 | fill 15 %, L 2.58:1, dE 29 | silhouette >= 10 % of the 48 px tile and contrast >= 1.4:1 or dE >= 12 |  |

## Images
- rimeling: [../../../../../art/icons/lens/units/rimeling.png](../../../../../art/icons/lens/units/rimeling.png)
- hoarlight_magebow: [../../../../../art/icons/lens/units/hoarlight_magebow.png](../../../../../art/icons/lens/units/hoarlight_magebow.png)
- frost_mortar: [../../../../../art/icons/lens/units/frost_mortar.png](../../../../../art/icons/lens/units/frost_mortar.png)
- thistle_darter: [../../../../../art/icons/lens/units/thistle_darter.png](../../../../../art/icons/lens/units/thistle_darter.png)
- greenheart_oathkeeper: [../../../../../art/icons/lens/units/greenheart_oathkeeper.png](../../../../../art/icons/lens/units/greenheart_oathkeeper.png)
- sheet: [icons_sheet.png](icons_sheet.png)

## Notes
- Icons written to art/icons/lens/<kind>/<id>.png (256 px, kingdom background from art/icons/icon_painter.gd). The icon libraries adopt them later (their owner); nothing existing was overwritten.
