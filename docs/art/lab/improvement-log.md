# Art Lab improvement log

One row per lab run (`tools/art_lab/art_lab.gd`, docs/plan/art-lab.md). Quality 0-100 (higher is better); the delta is against the previous run in the same out folder.

Rows of 2026-09-26 = lab v1.0 validation runs (the calibration re-runs were folded into the last row per asset).

| When | Asset | Kind / tier | Quality | Result | Top suggestions | Scorecard |
|---|---|---|---|---|---|---|
| 2026-09-26 21:50:55 | mossback | unit / heavy | 84 (-2) | WARN (0F 4W) | Contrast vs ground (meadow); Glow points at 40 m; Vertices | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 21:51:56 | mirefang | unit / creature | 87 (-1) | WARN (0F 1W) | Glow placement; Tops light, bottoms dark; Detail density 25 m / 40 m | docs/art/lab/mirefang/scorecard.md |
| 2026-09-26 21:52:54 | frost_dragon | titan / titan | 97 (+1) | WARN (0F 1W) | Meshes built per instance; Tops light, bottoms dark; Idle / attack beats | docs/art/lab/frost_dragon/scorecard.md |
| 2026-09-26 21:53:31 | dusk_steed | mount / mount | 98 (+3) | PASS (0F 0W) | Distinct from references (black masks); Idle / attack beats; Detail density at 25 m | docs/art/lab/dusk_steed/scorecard.md |
| 2026-09-26 21:54:25 | unit_fire_gun_vfx | vfx / family | 100 (+6) | PASS (0F 0W) | Read in 0.3 s; Team / kingdom colour; Cost | docs/art/lab/unit_fire_gun_vfx/scorecard.md |
| 2026-09-26 21:55:58 | thornling | unit / soldier | 96 (-2) | PASS (0F 0W) | Contrast vs ground (meadow); Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/thornling/scorecard.md |
| 2026-09-26 21:57:44 | deer | critter / deer | 98 | PASS (0F 0W) | Detail density 25 m / 40 m; Idle / attack beats; Detail density at 25 m | docs/art/lab/deer/scorecard.md |
| 2026-09-26 22:01:58 | colossus | landmark / landmark | 86 (+7) | WARN (0F 1W) | Glow points at 40 m; Silhouette hook; Contrast vs ground (meadow) | docs/art/lab/colossus/scorecard.md |
| 2026-09-26 22:02:51 | heath | decor_set / set | 86 (+3) | WARN (0F 2W) | Units still read on this decor; Units hidden by decor at 40 m; Decor coverage at 40 m | docs/art/lab/heath/scorecard.md |
| 2026-09-26 22:05:34 | fire_keep | building / keep | 83 (+1) | FAIL (2F 1W) | Unique materials; Vertices; Glow points at 40 m | docs/art/lab/fire_keep/scorecard.md |
| 2026-09-26 22:15:21 | mossback | unit / heavy | 84 (+0) | WARN (0F 4W) | Contrast vs ground (meadow); Glow points at 40 m; Vertices | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:28:09 | fire_keep | building / keep | 89 (+6) | WARN (0F 1W) | Glow points at 40 m; Materials built per instance; Distinct from references (black masks) | docs/art/lab/fire_keep/scorecard.md |
| 2026-09-26 22:29:58 | mossback | unit / heavy | 89 (+6) | PASS (0F 0W) | Glow placement; Silhouette hook; Tops light, bottoms dark | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:30:36 | fire_keep | building / keep | 89 (+0) | WARN (0F 1W) | Glow points at 40 m; Materials built per instance; Distinct from references (black masks) | docs/art/lab/fire_keep/scorecard.md |
| 2026-09-26 22:31:57 | mossback | unit / heavy | 92 (+3) | PASS (0F 0W) | Silhouette hook; Asymmetric secondary shape; Contrast on the other grounds | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:33:44 | mossback | unit / heavy | 93 (+1) | PASS (0F 0W) | Silhouette hook; Asymmetric secondary shape; Contrast on the other grounds | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:35:25 | mossback | unit / heavy | 93 (+0) | PASS (0F 0W) | Silhouette hook; Asymmetric secondary shape; Contrast on the other grounds | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:36:31 | mossback | unit / heavy | 93 (+0) | PASS (0F 0W) | Silhouette hook; Asymmetric secondary shape; Contrast on the other grounds | docs/art/lab/mossback/scorecard.md |
| 2026-09-26 22:50:46 | vessa | unit / wizard | 86 | FAIL (1F 3W) | Authored meshes; Parts above body_height + 0.4; Vertices | docs/art/lab/vessa/scorecard.md |
| 2026-09-26 22:50:48 | torvald | unit / wizard | 90 | FAIL (1F 3W) | Authored meshes; Parts above body_height + 0.4; Vertices | docs/art/lab/torvald/scorecard.md |
| 2026-09-26 22:51:47 | malrik | unit / wizard | 84 | FAIL (1F 6W) | Authored meshes; Feet on the ground; Parts above body_height + 0.4 | docs/art/lab/malrik/scorecard.md |
| 2026-09-26 22:51:45 | ysolde | unit / wizard | 78 | FAIL (2F 6W) | Allocations after _ready (actions); Authored meshes; Glow points at 40 m | docs/art/lab/ysolde/scorecard.md |
| 2026-09-26 22:52:17 | standing_stones | landmark / landmark | 94 | WARN (0F 1W) | Glow points at 40 m; Tops light, bottoms dark; Contrast vs ground (meadow) | docs/art/lab/standing_stones/scorecard.md |
| 2026-09-26 22:52:15 | aqueduct | landmark / landmark | 98 | PASS (0F 0W) | Contrast on the other grounds; Contrast vs ground (meadow); Dominant vertical + asymmetric secondary | docs/art/lab/aqueduct/scorecard.md |
| 2026-09-26 22:52:56 | thornling | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast vs ground (meadow); Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/thornling/scorecard.md |
| 2026-09-26 22:53:15 | barge | landmark / landmark | 95 | PASS (0F 0W) | Tops light, bottoms dark; Contrast vs ground (meadow); Contrast on the other grounds | docs/art/lab/barge/scorecard.md |
| 2026-09-26 22:53:19 | rimeshield | unit / soldier | 90 | FAIL (1F 2W) | Authored meshes; Tops light, bottoms dark; Distinct from references (black masks) | docs/art/lab/rimeshield/scorecard.md |
| 2026-09-26 22:53:31 | rime_hauler | unit / worker | 94 | FAIL (1F 1W) | Authored meshes; HP bar over the body at 40 m; Silhouette hook | docs/art/lab/rime_hauler/scorecard.md |
| 2026-09-26 22:53:40 | sprigling | unit / worker | 86 | FAIL (1F 4W) | Authored meshes; Contrast vs ground (meadow); Parts above body_height + 0.4 | docs/art/lab/sprigling/scorecard.md |
| 2026-09-26 22:53:53 | cinder_hand | unit / worker | 91 | FAIL (1F 1W) | Authored meshes; Glow placement; Tops light, bottoms dark | docs/art/lab/cinder_hand/scorecard.md |
| 2026-09-26 22:54:03 | ash_hurler | unit / soldier | 95 | WARN (0F 1W) | Parts above body_height + 0.4; Tops light, bottoms dark; Contrast on the other grounds | docs/art/lab/ash_hurler/scorecard.md |
| 2026-09-26 22:54:03 | ember_archer | unit / soldier | 92 | WARN (0F 1W) | Silhouette hook; Tops light, bottoms dark; Idle / attack beats | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 22:54:13 | gloom_thrall | unit / worker | 96 | WARN (0F 1W) | Silhouette hook; Idle / attack beats; Detail density at 25 m | docs/art/lab/gloom_thrall/scorecard.md |
| 2026-09-26 22:54:13 | shade | unit / soldier | 98 | PASS (0F 0W) | Tops light, bottoms dark; Idle / attack beats; Detail density at 25 m | docs/art/lab/shade/scorecard.md |
| 2026-09-26 22:54:23 | grave_hound | unit / soldier | 94 | PASS (0F 0W) | Tops light, bottoms dark; Detail density 25 m / 40 m; Contrast on the other grounds | docs/art/lab/grave_hound/scorecard.md |
| 2026-09-26 22:54:23 | shadow_knight | unit / heavy | 96 | WARN (0F 1W) | Parts above body_height + 0.4; Idle / attack beats; Detail density at 25 m | docs/art/lab/shadow_knight/scorecard.md |
| 2026-09-26 22:54:33 | nightbolt | unit / soldier | 89 | WARN (0F 1W) | Glow placement; Tops light, bottoms dark; Silhouette hook | docs/art/lab/nightbolt/scorecard.md |
| 2026-09-26 22:54:33 | flame_guard | unit / soldier | 94 | WARN (0F 1W) | Tops light, bottoms dark; Silhouette hook; Detail density 25 m / 40 m | docs/art/lab/flame_guard/scorecard.md |
| 2026-09-26 22:54:45 | vessa | unit / wizard | 89 (+2) | WARN (0F 3W) | Parts above body_height + 0.4; Vertices; Glow placement | docs/art/lab/vessa/scorecard.md |
| 2026-09-26 22:54:45 | malrik | unit / wizard | 86 (+2) | WARN (0F 6W) | Feet on the ground; Parts above body_height + 0.4; Looping particles alive | docs/art/lab/malrik/scorecard.md |
| 2026-09-26 22:55:10 | torvald | unit / wizard | 92 (+2) | WARN (0F 3W) | Parts above body_height + 0.4; Vertices; Distinct from references (black masks) | docs/art/lab/torvald/scorecard.md |
| 2026-09-26 22:55:11 | ysolde | unit / wizard | 83 (+5) | FAIL (1F 5W) | Allocations after _ready (actions); Parts above body_height + 0.4; Vertices | docs/art/lab/ysolde/scorecard.md |
| 2026-09-26 22:55:36 | frostrune_rifleman | unit / soldier | 90 | FAIL (2F 1W) | Authored meshes; Vertices; Glow points at 40 m | docs/art/lab/frostrune_rifleman/scorecard.md |
| 2026-09-26 22:55:37 | rime_colossus | unit / heavy | 89 | FAIL (1F 1W) | Authored meshes; Glow placement; Tops light, bottoms dark | docs/art/lab/rime_colossus/scorecard.md |
| 2026-09-26 22:55:57 | rime_seer | unit / soldier | 94 | FAIL (1F 1W) | Authored meshes; Parts above body_height + 0.4; Tops light, bottoms dark | docs/art/lab/rime_seer/scorecard.md |
| 2026-09-26 22:55:58 | bramblehorn | unit / heavy | 87 | FAIL (1F 1W) | Authored meshes; Contrast vs ground (meadow); Tops light, bottoms dark | docs/art/lab/bramblehorn/scorecard.md |
| 2026-09-26 22:56:18 | shardcaster | unit / soldier | 91 | FAIL (1F 1W) | Authored meshes; Glow placement; Silhouette hook | docs/art/lab/shardcaster/scorecard.md |
| 2026-09-26 22:56:21 | sapling | unit / soldier | 86 | FAIL (1F 1W) | Contrast vs ground (meadow); Glow placement; Team-colour visibility at 40 m | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 22:56:39 | burr_slinger | unit / soldier | 89 | FAIL (1F 2W) | Authored meshes; Contrast vs ground (meadow); Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 22:56:44 | bloomtender | unit / soldier | 92 | WARN (0F 2W) | Parts above body_height + 0.4; Contrast vs ground (meadow); Contrast on the other grounds | docs/art/lab/bloomtender/scorecard.md |
| 2026-09-26 22:57:01 | heath | decor_set / set | 89 (+3) | WARN (0F 1W) | Units still read on this decor; Units hidden by decor at 40 m; Decor coverage at 40 m | docs/art/lab/heath/scorecard.md |
| 2026-09-26 22:57:06 | frost_dragon | titan / titan | 96 (-1) | PASS (0F 0W) | Glow placement; Idle / attack beats; Detail density at 25 m | docs/art/lab/frost_dragon/scorecard.md |
| 2026-09-26 22:57:21 | colossus | landmark / landmark | 90 (+3) | PASS (0F 0W) | Silhouette hook; Contrast vs ground (meadow); Distinct from references (black masks) | docs/art/lab/colossus/scorecard.md |
| 2026-09-26 22:57:21 | vessa | unit / wizard | 89 (+0) | WARN (0F 3W) | Parts above body_height + 0.4; Vertices; Glow placement | docs/art/lab/vessa/scorecard.md |
| 2026-09-26 22:57:47 | giant_stump | landmark / landmark | 91 | PASS (0F 0W) | Silhouette hook; Tops light, bottoms dark; Distinct from references (black masks) | docs/art/lab/giant_stump/scorecard.md |
| 2026-09-26 22:57:43 | torvald | unit / wizard | 92 (+0) | WARN (0F 3W) | Parts above body_height + 0.4; Vertices; Distinct from references (black masks) | docs/art/lab/torvald/scorecard.md |
| 2026-09-26 22:57:48 | ysolde | unit / wizard | 83 (+0) | WARN (0F 6W) | Glow points at 40 m; Parts above body_height + 0.4; Vertices | docs/art/lab/ysolde/scorecard.md |
| 2026-09-26 22:58:22 | mirefang | unit / creature | 90 (+3) | PASS (0F 0W) | Glow placement; Tops light, bottoms dark; Detail density 25 m / 40 m | docs/art/lab/mirefang/scorecard.md |
| 2026-09-26 22:58:22 | frost_dragon | titan / titan | 96 (+0) | PASS (0F 0W) | Glow placement; Idle / attack beats; Detail density at 25 m | docs/art/lab/frost_dragon/scorecard.md |
| 2026-09-26 22:58:15 | crown_pedestal | landmark / landmark | 87 | WARN (0F 2W) | Glow points at 40 m; Unique materials; Materials built per instance | docs/art/lab/crown_pedestal/scorecard.md |
| 2026-09-26 22:58:51 | cinder_hand | unit / worker | 95 (+4) | WARN (0F 1W) | Tops light, bottoms dark; Contrast on the other grounds; Idle / attack beats | docs/art/lab/cinder_hand/scorecard.md |
| 2026-09-26 22:58:51 | ember_archer | unit / soldier | 94 (+2) | WARN (0F 1W) | Silhouette hook; Tops light, bottoms dark; Idle / attack beats | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 22:59:28 | grave_hound | unit / soldier | 94 (+1) | PASS (0F 0W) | Detail density 25 m / 40 m; Tops light, bottoms dark; Contrast on the other grounds | docs/art/lab/grave_hound/scorecard.md |
| 2026-09-26 22:59:13 | malrik | unit / wizard | 90 (+3) | WARN (0F 4W) | Parts above body_height + 0.4; Vertices; Looping particle systems | docs/art/lab/malrik/scorecard.md |
| 2026-09-26 22:59:28 | nightbolt | unit / soldier | 94 (+5) | WARN (0F 1W) | Silhouette hook; Idle / attack beats; Detail density at 25 m | docs/art/lab/nightbolt/scorecard.md |
| 2026-09-26 22:59:42 | colossus | landmark / landmark | 90 (+0) | PASS (0F 0W) | Silhouette hook; Contrast vs ground (meadow); Distinct from references (black masks) | docs/art/lab/colossus/scorecard.md |
| 2026-09-26 22:59:41 | sapling | unit / soldier | 91 (+5) | WARN (0F 2W) | Contrast vs ground (meadow); Team-colour visibility at 40 m; Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:00:00 | burr_slinger | unit / soldier | 89 (+0) | FAIL (1F 2W) | Authored meshes; Contrast vs ground (meadow); Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:00:00 | bramblehorn | unit / heavy | 89 (+2) | FAIL (1F 0W) | Authored meshes; Tops light, bottoms dark; Silhouette hook | docs/art/lab/bramblehorn/scorecard.md |
| 2026-09-26 23:00:40 | ember_archer | unit / soldier | 95 (+1) | WARN (0F 1W) | Silhouette hook; Idle / attack beats; Detail density at 25 m | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 23:00:24 | ysolde | unit / wizard | 88 (+4) | WARN (0F 4W) | Parts above body_height + 0.4; Vertices; Looping particle systems | docs/art/lab/ysolde/scorecard.md |
| 2026-09-26 23:00:50 | cinder_hand | unit / worker | 95 (+0) | WARN (0F 1W) | Contrast on the other grounds; Tops light, bottoms dark; Idle / attack beats | docs/art/lab/cinder_hand/scorecard.md |
| 2026-09-26 23:01:01 | nightbolt | unit / soldier | 97 (+2) | PASS (0F 0W) | Silhouette hook; Idle / attack beats; Detail density at 25 m | docs/art/lab/nightbolt/scorecard.md |
| 2026-09-26 23:00:56 | crown_pedestal | landmark / landmark | 87 (+0) | WARN (0F 2W) | Glow points at 40 m; Unique materials; Materials built per instance | docs/art/lab/crown_pedestal/scorecard.md |
| 2026-09-26 23:01:12 | sprigling | unit / worker | 88 (+3) | FAIL (1F 3W) | Authored meshes; Parts above body_height + 0.4; HP bar over the body at 40 m | docs/art/lab/sprigling/scorecard.md |
| 2026-09-26 23:01:39 | colossus | landmark / landmark | 91 (+1) | PASS (0F 0W) | Silhouette hook; Contrast vs ground (meadow); Distinct from references (black masks) | docs/art/lab/colossus/scorecard.md |
| 2026-09-26 23:01:50 | cinder_hand | unit / worker | 97 (+2) | PASS (0F 0W) | Silhouette hook; Tops light, bottoms dark; Contrast on the other grounds | docs/art/lab/cinder_hand/scorecard.md |
| 2026-09-26 23:02:09 | grave_hound | unit / soldier | 94 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Tops light, bottoms dark; Idle / attack beats | docs/art/lab/grave_hound/scorecard.md |
| 2026-09-26 23:02:16 | sapling | unit / soldier | 90 (-1) | WARN (0F 2W) | Contrast vs ground (meadow); Team-colour visibility at 40 m; Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:02:20 | burr_slinger | unit / soldier | 89 (+0) | FAIL (1F 2W) | Authored meshes; Contrast vs ground (meadow); Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:03:15 | standing_stones | landmark / landmark | 94 (+0) | WARN (0F 1W) | Glow points at 40 m; Tops light, bottoms dark; Contrast vs ground (meadow) | docs/art/lab/standing_stones/scorecard.md |
| 2026-09-26 23:03:12 | sapling | unit / soldier | 91 (+1) | WARN (0F 2W) | Contrast vs ground (meadow); Team-colour visibility at 40 m; Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:03:12 | burr_slinger | unit / soldier | 89 (+0) | FAIL (1F 2W) | Authored meshes; Contrast vs ground (meadow); Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:03:30 | ember_archer | unit / soldier | 95 (+0) | WARN (0F 1W) | Silhouette hook; Idle / attack beats; Detail density at 25 m | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 23:03:37 | frost_dragon | titan / titan | 96 (+0) | PASS (0F 0W) | Glow placement; Idle / attack beats; Detail density at 25 m | docs/art/lab/frost_dragon/scorecard.md |
| 2026-09-26 23:03:54 | sapling | unit / soldier | 91 (+0) | WARN (0F 2W) | Contrast vs ground (meadow); Team-colour visibility at 40 m; Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:03:56 | burr_slinger | unit / soldier | 89 (+0) | FAIL (1F 2W) | Authored meshes; Contrast vs ground (meadow); Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:04:23 | standing_stones | landmark / landmark | 94 (+0) | WARN (0F 1W) | Glow points at 40 m; Tops light, bottoms dark; Contrast vs ground (meadow) | docs/art/lab/standing_stones/scorecard.md |
| 2026-09-26 23:04:39 | burr_slinger | unit / soldier | 90 (+1) | FAIL (1F 1W) | Authored meshes; Tops light, bottoms dark; Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:05:38 | sapling | unit / soldier | 90 (-1) | WARN (0F 2W) | Glow points at 40 m; Team-colour visibility at 40 m; Contrast vs ground (meadow) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:06:07 | sapling | unit / soldier | 90 (+0) | WARN (0F 2W) | Glow points at 40 m; Team-colour visibility at 40 m; Contrast vs ground (meadow) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:08:19 | sapling | unit / soldier | 93 (+3) | WARN (0F 1W) | Contrast vs ground (meadow); Team-colour visibility at 40 m; Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:08:20 | sprigling | unit / worker | 88 (+0) | FAIL (1F 3W) | Authored meshes; Parts above body_height + 0.4; HP bar over the body at 40 m | docs/art/lab/sprigling/scorecard.md |
| 2026-09-26 23:08:20 | bramblehorn | unit / heavy | 89 (+0) | FAIL (1F 0W) | Authored meshes; Tops light, bottoms dark; Silhouette hook | docs/art/lab/bramblehorn/scorecard.md |
| 2026-09-26 23:08:53 | bramblehorn | unit / heavy | 89 (+0) | FAIL (1F 0W) | Authored meshes; Tops light, bottoms dark; Asymmetric secondary shape | docs/art/lab/bramblehorn/scorecard.md |
| 2026-09-26 23:10:01 | rime_colossus | unit / heavy | 90 (+1) | FAIL (1F 1W) | Authored meshes; Glow placement; Silhouette hook | docs/art/lab/rime_colossus/scorecard.md |
| 2026-09-26 23:10:36 | rimeshield | unit / soldier | 91 (+2) | FAIL (1F 2W) | Authored meshes; Distinct from references (black masks); Tops light, bottoms dark | docs/art/lab/rimeshield/scorecard.md |
| 2026-09-26 23:11:17 | rimeshield | unit / soldier | 89 (-2) | FAIL (1F 2W) | Authored meshes; Tops light, bottoms dark; Distinct from references (black masks) | docs/art/lab/rimeshield/scorecard.md |
| 2026-09-26 23:11:18 | burr_slinger | unit / soldier | 90 (+0) | FAIL (1F 1W) | Authored meshes; Tops light, bottoms dark; Silhouette hook | docs/art/lab/burr_slinger/scorecard.md |
| 2026-09-26 23:11:18 | bramblehorn | unit / heavy | 89 (+0) | FAIL (1F 0W) | Authored meshes; Tops light, bottoms dark; Silhouette hook | docs/art/lab/bramblehorn/scorecard.md |
| 2026-09-26 23:46:56 | sapling | unit / soldier | 91 (-3) | WARN (0F 2W) | Glow points at 40 m; Glow placement; Contrast vs ground (meadow) | docs/art/lab/sapling/scorecard.md |
| 2026-09-26 23:48:31 | ember_archer | unit / soldier | 91 (-4) | FAIL (1F 2W) | Frame cost; Contrast in every team colour (meadow); Silhouette hook | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 23:49:32 | fire_keep | building / keep | 90 (+1) | WARN (0F 1W) | Glow points at 40 m; Materials built per instance; Tops light, bottoms dark | docs/art/lab/fire_keep/scorecard.md |
| 2026-09-26 23:54:33 | ember_archer | unit / soldier | 91 (+0) | FAIL (1F 2W) | Frame cost; Contrast in every team colour (meadow); Silhouette hook | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 23:56:39 | ember_archer | unit / soldier | 91 (+0) | FAIL (1F 2W) | Frame cost; Contrast in every team colour (meadow); Silhouette hook | docs/art/lab/ember_archer/scorecard.md |
| 2026-09-26 23:58:30 | sapling | unit / soldier | 92 (+1) | WARN (0F 2W) | Glow points at 40 m; Contrast vs ground (meadow); Distinct from references (black masks) | docs/art/lab/sapling/scorecard.md |
| 2026-09-27 07:41:49 | mirefang | unit / creature | 95 (+4) | PASS (0F 0W) | Detail density 25 m / 40 m; Contrast on the other grounds; Tops light, bottoms dark | docs/art/lab/mirefang/scorecard.md |
| 2026-09-27 10:41:55 | fire_tower | building / small | 85 | FAIL (1F 3W) | Real lights; Materials built per instance; Unique materials | docs/art/lab/fire_tower/scorecard.md |
| 2026-09-27 10:42:08 | nature_keep | building / keep | 75 | FAIL (3F 4W) | Contrast vs ground (meadow); Vertices; Unique materials | docs/art/lab/nature_keep/scorecard.md |
| 2026-09-27 10:44:28 | fire_tower | building / small | 89 (+3) | WARN (0F 2W) | Unique materials; Materials built per instance; Silhouette hook | docs/art/lab/fire_tower/scorecard.md |
| 2026-09-27 10:45:11 | shadow_tower | building / small | 92 | WARN (0F 3W) | Silhouette area at 40 m; Materials built per instance; Unique materials | docs/art/lab/shadow_tower/scorecard.md |
| 2026-09-27 10:46:35 | fire_tower | building / small | 89 (+0) | WARN (0F 2W) | Unique materials; Materials built per instance; Silhouette hook | docs/art/lab/fire_tower/scorecard.md |
| 2026-09-27 10:47:04 | shadow_tower | building / small | 92 (+0) | WARN (0F 3W) | Silhouette area at 40 m; Materials built per instance; Unique materials | docs/art/lab/shadow_tower/scorecard.md |
| 2026-09-27 10:45:18 | nature_keep | building / keep | 79 (+4) | FAIL (2F 5W) | Vertices; Unique materials; Contrast vs ground (meadow) | docs/art/lab/nature_keep/scorecard.md |
| 2026-09-27 10:48:21 | nature_keep | building / keep | 82 (+3) | FAIL (2F 4W) | Vertices; Unique materials; Contrast in every team colour (meadow) | docs/art/lab/nature_keep/scorecard.md |
| 2026-09-27 10:51:07 | vinelasher | unit / soldier | 95 | WARN (0F 1W) | Contrast on the home ground (old_wood); Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/low/scorecard.md |
| 2026-09-27 10:49:23 | nature_keep | building / keep | 82 (+0) | FAIL (3F 3W) | Vertices; Unique materials; Frame cost | docs/art/lab/nature_keep/scorecard.md |
| 2026-09-27 10:52:07 | nature_keep | building / keep | 85 (+3) | FAIL (2F 3W) | Vertices; Unique materials; Glow points at 40 m | docs/art/lab/nature_keep/scorecard.md |
| 2026-09-27 10:52:19 | vinelasher | unit / soldier | 95 (+0) | WARN (0F 1W) | Contrast on the home ground (old_wood); Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/low/scorecard.md |
| 2026-09-27 10:53:24 | vinelasher | unit / soldier | 95 (+0) | WARN (0F 1W) | Contrast on the home ground (old_wood); Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/low/scorecard.md |
| 2026-09-27 10:53:50 | vinelasher | unit / soldier | 93 | FAIL (1F 0W) | Vertices; Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 10:55:19 | vinelasher | unit / soldier | 93 (+0) | PASS (0F 0W) | Glow placement; Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 10:56:42 | vinelasher | unit / soldier | 94 (+1) | WARN (0F 1W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Detail density 25 m / 40 m | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 10:57:58 | vinelasher | unit / soldier | 95 (+1) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Detail density 25 m / 40 m | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 10:58:55 | vinelasher | unit / soldier | 91 | WARN (0F 2W) | Contrast vs ground (meadow); Contrast in every team colour (meadow); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 10:59:17 | vinelasher | unit / soldier | 94 (-1) | PASS (0F 0W) | Detail density 25 m / 40 m; Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 11:00:34 | vinelasher | unit / soldier | 95 (+1) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Detail density 25 m / 40 m | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 11:01:41 | vinelasher | unit / soldier | 96 | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:03:11 | vinelasher | unit / soldier | 95 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Detail density 25 m / 40 m | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 11:03:53 | vinelasher | unit / soldier | 95 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Detail density 25 m / 40 m | docs/art/lab/effort-trial/medium/scorecard.md |
| 2026-09-27 11:03:56 | vinelasher | unit / soldier | 94 (+3) | WARN (0F 1W) | Team colours for colour-blind players; Contrast vs ground (meadow); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:05:54 | vinelasher | unit / soldier | 95 (+1) | PASS (0F 0W) | Style bible: golden autumn (style-autumn.md 3); Contrast on the other grounds; Contrast vs ground (meadow) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:06:23 | vinelasher | unit / soldier | 93 (-2) | WARN (0F 2W) | Contrast on the other grounds; Contrast on the home ground (old_wood); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:07:43 | vinelasher | unit / soldier | 94 (-1) | FAIL (1F 0W) | Vertices; Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:08:36 | vinelasher | unit / soldier | 95 (+1) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:08:45 | vinelasher | unit / soldier | 96 (+3) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:10:06 | vinelasher | unit / soldier | 94 (-2) | WARN (0F 1W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:11:12 | vinelasher | unit / soldier | 95 (+2) | PASS (0F 0W) | Style bible: golden autumn (style-autumn.md 3); Contrast on the other grounds; Contrast vs ground (meadow) | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:11:48 | vinelasher | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:13:28 | vinelasher | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:13:38 | vinelasher | unit / soldier | 95 (+0) | PASS (0F 0W) | Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow); Contrast on the other grounds | docs/art/lab/effort-trial/high/scorecard.md |
| 2026-09-27 11:15:58 | vinelasher | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:17:26 | vinelasher | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:18:44 | vinelasher | unit / soldier | 96 (+0) | PASS (0F 0W) | Contrast on the other grounds; Style bible: golden autumn (style-autumn.md 3); Contrast vs ground (meadow) | docs/art/lab/effort-trial/xhigh/scorecard.md |
| 2026-09-27 11:33:33 | hexweaver | unit / soldier | 93 | FAIL (1F 1W) | Vertices; Glow points at 40 m; Shape richness (secondary shapes) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:34:15 | pyre_adept | unit / soldier | 93 | WARN (0F 3W) | Contrast in every team colour (meadow); Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:34:59 | frostbow | unit / soldier | 61 | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:35:10 | hexweaver | unit / soldier | 95 (+2) | FAIL (1F 0W) | Vertices; Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:35:37 | pyre_adept | unit / soldier | 61 (-32) | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:35:42 | frostbow | unit / soldier | 94 (+33) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:36:06 | pyre_adept | unit / soldier | 96 (+35) | WARN (0F 1W) | Team colours for colour-blind players; Shape richness (secondary shapes); Distinct from references (black masks) | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:36:15 | hexweaver | unit / soldier | 96 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Contrast in every team colour (meadow) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:37:38 | frostbow | unit / soldier | 92 (-2) | FAIL (1F 0W) | Vertices; Surfaces per instance; Idle / attack beats | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:37:16 | pyre_adept | unit / soldier | 97 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Detail density 25 m / 40 m | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:37:47 | hexweaver | unit / soldier | 92 (-4) | FAIL (1F 0W) | Vertices; Surfaces per instance; Idle / attack beats | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:38:41 | pyre_adept | unit / soldier | 97 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Detail density 25 m / 40 m | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:38:49 | frostbow | unit / soldier | 95 (+3) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Contrast in every team colour (meadow) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:39:24 | hexweaver | unit / soldier | 96 (+4) | PASS (0F 0W) | Detail density 25 m / 40 m; Contrast in every team colour (meadow); Surfaces per instance | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:40:16 | pyre_adept | unit / soldier | 97 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Frame cost; Detail density 25 m / 40 m | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:40:21 | frostbow | unit / soldier | 95 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Contrast in every team colour (meadow) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:40:55 | hexweaver | unit / soldier | 95 (-1) | PASS (0F 0W) | Detail density 25 m / 40 m; Palette depth (close-up); Contrast in every team colour (meadow) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:41:13 | frostbow | unit / soldier | 96 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Contrast in every team colour (meadow) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:41:39 | pyre_adept | unit / soldier | 97 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Frame cost; Detail density 25 m / 40 m | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:42:07 | hexweaver | unit / soldier | 96 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Contrast in every team colour (meadow) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:42:30 | frostbow | unit / soldier | 95 (-1) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Contrast in every team colour (meadow) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:42:54 | pyre_adept | unit / soldier | 97 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Surfaces per instance; Idle / attack beats | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:43:11 | hexweaver | unit / soldier | 95 (-1) | PASS (0F 0W) | Palette depth (close-up); Detail density 25 m / 40 m; Asymmetric secondary shape | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:43:36 | frostbow | unit / soldier | 96 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Contrast in every team colour (meadow); Distinct from references (black masks) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:44:07 | pyre_adept | unit / soldier | 97 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Surfaces per instance; Idle / attack beats | docs/art/lab/new-units/pyre_adept/scorecard.md |
| 2026-09-27 11:44:19 | hexweaver | unit / soldier | 95 (+0) | PASS (0F 0W) | Palette depth (close-up); Detail density 25 m / 40 m; Contrast in every team colour (meadow) | docs/art/lab/new-units/hexweaver/scorecard.md |
| 2026-09-27 11:44:50 | scorchbow | unit / soldier | 61 | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/new-units/scorchbow/scorecard.md |
| 2026-09-27 11:45:16 | frostbow | unit / soldier | 94 (-2) | PASS (0F 0W) | Glow placement; Shape richness (secondary shapes); Detail density 25 m / 40 m | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:45:32 | scorchbow | unit / soldier | 93 (+32) | PASS (0F 0W) | Shape richness (secondary shapes); Glow placement; Silhouette hook | docs/art/lab/new-units/scorchbow/scorecard.md |
| 2026-09-27 11:46:13 | frostbow | unit / soldier | 96 (+2) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Contrast in every team colour (meadow) | docs/art/lab/new-units/frostbow/scorecard.md |
| 2026-09-27 11:49:50 | bleakbow | unit / soldier | 94 | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/new-units/bleakbow/scorecard.md |
| 2026-09-27 11:55:33 | wildwood_archer | unit / soldier | 92 | FAIL (1F 0W) | Vertices; Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 11:57:03 | wildwood_archer | unit / soldier | 91 (-1) | WARN (0F 2W) | Glow points at 40 m; Contrast under every light preset (meadow); Detail density 25 m / 40 m | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 11:57:03 | scorchbow | unit / soldier | 93 (+0) | WARN (0F 1W) | Team colours for colour-blind players; Glow placement; Shape richness (secondary shapes) | docs/art/lab/new-units/scorchbow/scorecard.md |
| 2026-09-27 11:59:19 | scorchbow | unit / soldier | 95 (+2) | PASS (0F 0W) | Shape richness (secondary shapes); Silhouette hook; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/new-units/scorchbow/scorecard.md |
| 2026-09-27 12:00:33 | wildwood_archer | unit / soldier | 92 (+1) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Inner detail (close-up / 25 m) | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 12:02:12 | bleakbow | unit / soldier | 93 (-1) | WARN (0F 1W) | Glow points at 40 m; Shape richness (secondary shapes); Detail density 25 m / 40 m | docs/art/lab/new-units/bleakbow/scorecard.md |
| 2026-09-27 12:02:56 | wildwood_archer | unit / soldier | 93 (+1) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 12:04:20 | bleakbow | unit / soldier | 94 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Contrast on the other grounds | docs/art/lab/new-units/bleakbow/scorecard.md |
| 2026-09-27 12:05:50 | wildwood_archer | unit / soldier | 93 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 12:08:28 | bleakbow | unit / soldier | 93 (-1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/new-units/bleakbow/scorecard.md |
| 2026-09-27 12:10:01 | wildwood_archer | unit / soldier | 94 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Contrast on the other grounds | docs/art/lab/new-units/wildwood_archer/scorecard.md |
| 2026-09-27 12:11:34 | scorchbow | unit / soldier | 95 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Silhouette hook; Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/new-units/scorchbow/scorecard.md |
| 2026-09-27 12:13:25 | bleakbow | unit / soldier | 94 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Detail density 25 m / 40 m; Palette depth (close-up) | docs/art/lab/new-units/bleakbow/scorecard.md |
| 2026-09-27 15:01:08 | vessa | unit / wizard | 91 (+2) | WARN (0F 4W) | Head height vs body_height; Contrast in every team colour (meadow); Team colours for colour-blind players | docs/art/lab/vessa/scorecard.md |
| 2026-09-27 15:08:32 | vessa | unit / wizard | 91 (+0) | WARN (0F 4W) | Head height vs body_height; Contrast in every team colour (meadow); Vertices | docs/art/lab/vessa/scorecard.md |
| 2026-09-27 15:09:54 | vessa | unit / wizard | 91 (+0) | WARN (0F 4W) | Head height vs body_height; Contrast in every team colour (meadow); Vertices | docs/art/lab/vessa/scorecard.md |
| 2026-09-27 17:22:11 | ashveil_saboteur | unit / soldier | 89 | FAIL (1F 2W) | Vertices; Glow points at 40 m; Contrast on the home ground (ash) | docs/art/lab/ashveil_saboteur/scorecard.md |
| 2026-09-27 17:22:23 | shardguard | unit / heavy | 94 | WARN (0F 1W) | Weapon reach at the strike; Shape richness (secondary shapes); Tops light, bottoms dark | docs/art/lab/shardguard/scorecard.md |
| 2026-09-27 17:23:55 | ashveil_saboteur | unit / soldier | 90 (+1) | FAIL (1F 1W) | Vertices; Contrast on the home ground (ash); Glow placement | docs/art/lab/ashveil_saboteur/scorecard.md |
| 2026-09-27 17:24:45 | shardguard | unit / heavy | 96 (+2) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Team-colour visibility at 40 m | docs/art/lab/shardguard/scorecard.md |
| 2026-09-27 17:25:46 | ashveil_saboteur | unit / soldier | 90 (+0) | FAIL (1F 1W) | Vertices; Contrast on the home ground (ash); Glow placement | docs/art/lab/ashveil_saboteur/scorecard.md |
| 2026-09-27 17:25:50 | nightblood_reaver | unit / soldier | 89 | FAIL (1F 1W) | Vertices; Footprint vs selection radius; Palette depth (close-up) | docs/art/lab/nightblood_reaver/scorecard.md |
| 2026-09-27 17:27:39 | briar_roc | unit / heavy | 86 | WARN (0F 6W) | Footprint vs selection radius; Team-colour visibility at 40 m; Parts above body_height + 0.4 | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:28:04 | helper_vey | unit / wizard | 94 | WARN (0F 2W) | Vertices; Glow points at 40 m; Distinct from references (black masks) | docs/art/lab/helper_vey/scorecard.md |
| 2026-09-27 17:28:53 | scorchling | unit / soldier | 61 | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/scorchling/scorecard.md |
| 2026-09-27 17:28:59 | ashveil_saboteur | unit / soldier | 90 (+0) | WARN (0F 1W) | Contrast on the home ground (ash); Glow placement; Shape richness (secondary shapes) | docs/art/lab/ashveil_saboteur/scorecard.md |
| 2026-09-27 17:29:40 | nightblood_reaver | unit / soldier | 90 (+1) | FAIL (1F 0W) | Vertices; Palette depth (close-up); Shape richness (secondary shapes) | docs/art/lab/nightblood_reaver/scorecard.md |
| 2026-09-27 17:30:19 | aldra | unit / wizard | 91 (-4) | WARN (0F 2W) | Contrast on the home ground (snow); Vertices; Palette depth (close-up) | docs/art/lab/aldra/scorecard.md |
| 2026-09-27 17:30:45 | briar_roc | unit / heavy | 88 (+2) | WARN (0F 4W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:31:01 | scorchling | unit / soldier | 92 | PASS (0F 0W) | Inner detail (close-up / 25 m); Detail density 25 m / 40 m; Tops light, bottoms dark | docs/art/lab/scorchling/scorecard.md |
| 2026-09-27 17:31:40 | cinder_arbalest | unit / soldier | 61 | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 17:32:03 | nightblood_reaver | unit / soldier | 90 (+0) | FAIL (1F 0W) | Vertices; Palette depth (close-up); Shape richness (secondary shapes) | docs/art/lab/nightblood_reaver/scorecard.md |
| 2026-09-27 17:32:27 | helper_hush | unit / wizard | 92 | WARN (0F 2W) | Vertices; Glow points at 40 m; Detail density 25 m / 40 m | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:32:35 | rimeling | unit / soldier | 95 | PASS (0F 0W) | Inner detail (close-up / 25 m); Silhouette hook; Contrast on the home ground (snow) | docs/art/lab/rimeling/scorecard.md |
| 2026-09-27 17:32:43 | aldra | unit / wizard | 94 (+3) | WARN (0F 1W) | Vertices; Palette depth (close-up); Tops light, bottoms dark | docs/art/lab/aldra/scorecard.md |
| 2026-09-27 17:33:16 | hoarlight_magebow | unit / soldier | 94 | FAIL (1F 0W) | Vertices; Shape richness (secondary shapes); Silhouette hook | docs/art/lab/hoarlight_magebow/scorecard.md |
| 2026-09-27 17:33:22 | briar_roc | unit / heavy | 89 (+1) | WARN (0F 4W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:34:07 | cinder_arbalest | unit / soldier | 93 | WARN (0F 1W) | Glow points at 40 m; Shape richness (secondary shapes); Palette depth (close-up) | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 17:34:09 | barrow_ghoul | unit / soldier | 93 | WARN (0F 2W) | Glow points at 40 m; Team colours for colour-blind players; Inner detail (close-up / 25 m) | docs/art/lab/barrow_ghoul/scorecard.md |
| 2026-09-27 17:34:31 | helper_vey | unit / wizard | 94 (+0) | WARN (0F 2W) | Vertices; Glow points at 40 m; Detail density 25 m / 40 m | docs/art/lab/helper_vey/scorecard.md |
| 2026-09-27 17:34:56 | nightblood_reaver | unit / soldier | 89 (-1) | PASS (0F 0W) | Palette depth (close-up); Shape richness (secondary shapes); Tops light, bottoms dark | docs/art/lab/nightblood_reaver/scorecard.md |
| 2026-09-27 17:34:55 | stormbottle_genie | unit / heavy | 91 | PASS (0F 0W) | Palette depth (close-up); Inner detail (close-up / 25 m); Vertex use vs budget | docs/art/lab/stormbottle_genie/scorecard.md |
| 2026-09-27 17:36:00 | helper_hush | unit / wizard | 93 (+1) | WARN (0F 2W) | Vertices; Glow points at 40 m; Detail density 25 m / 40 m | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:36:19 | hoarlight_magebow | unit / soldier | 93 (-1) | FAIL (1F 0W) | Vertices; Shape richness (secondary shapes); Silhouette hook | docs/art/lab/hoarlight_magebow/scorecard.md |
| 2026-09-27 17:36:54 | frost_mortar | unit / heavy | 95 | PASS (0F 0W) | Shape richness (secondary shapes); Palette depth (close-up); Silhouette hook | docs/art/lab/frost_mortar/scorecard.md |
| 2026-09-27 17:36:58 | briar_roc | unit / heavy | 88 (-1) | WARN (0F 4W) | Footprint vs selection radius; Parts above body_height + 0.4; Contrast in every team colour (meadow) | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:37:31 | thistle_darter | unit / soldier | 61 | FAIL (2F 1W) | Silhouette area at 40 m; Contrast vs ground; Standard hooks | docs/art/lab/thistle_darter/scorecard.md |
| 2026-09-27 17:37:51 | ashveil_saboteur | unit / soldier | 93 (+3) | PASS (0F 0W) | Glow placement; Palette depth (close-up); Detail density 25 m / 40 m | docs/art/lab/ashveil_saboteur/scorecard.md |
| 2026-09-27 17:38:00 | scorchling | unit / soldier | 95 (+3) | PASS (0F 0W) | Detail density 25 m / 40 m; Inner detail (close-up / 25 m); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/scorchling/scorecard.md |
| 2026-09-27 17:38:31 | stormbottle_genie | unit / heavy | 91 (+0) | PASS (0F 0W) | Palette depth (close-up); Inner detail (close-up / 25 m); Vertex use vs budget | docs/art/lab/stormbottle_genie/scorecard.md |
| 2026-09-27 17:38:48 | hollow_oathsworn | unit / soldier | 91 | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Palette depth (close-up) | docs/art/lab/hollow_oathsworn/scorecard.md |
| 2026-09-27 17:39:09 | briar_roc | unit / heavy | 87 (-1) | WARN (0F 4W) | Footprint vs selection radius; Parts above body_height + 0.4; Contrast in every team colour (meadow) | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:40:03 | maelis | unit / wizard | 88 | WARN (0F 4W) | Contrast on the other grounds; Distinct from references (black masks); Parts above body_height + 0.4 | docs/art/lab/maelis/scorecard.md |
| 2026-09-27 17:41:11 | hoarlight_magebow | unit / soldier | 94 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Silhouette hook; Palette depth (close-up) | docs/art/lab/hoarlight_magebow/scorecard.md |
| 2026-09-27 17:41:09 | helper_vey | unit / wizard | 94 (+0) | WARN (0F 1W) | Vertices; Glow placement; Detail density 25 m / 40 m | docs/art/lab/helper_vey/scorecard.md |
| 2026-09-27 17:41:46 | thistle_darter | unit / soldier | 91 (+30) | FAIL (1F 0W) | Vertices; Detail density 25 m / 40 m; Inner detail (close-up / 25 m) | docs/art/lab/thistle_darter/scorecard.md |
| 2026-09-27 17:42:18 | greenheart_oathkeeper | unit / heavy | 91 | WARN (0F 1W) | Contrast on the other grounds; Tops light, bottoms dark; Vertex use vs budget | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 17:43:16 | briar_roc | unit / heavy | 88 (+1) | WARN (0F 4W) | Footprint vs selection radius; Team-colour visibility at 40 m; Parts above body_height + 0.4 | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:44:13 | cinder_arbalest | unit / soldier | 95 (+2) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 17:44:25 | helper_hush | unit / wizard | 94 (+1) | WARN (0F 1W) | Vertices; Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:45:39 | nightblood_reaver | unit / soldier | 92 (+3) | PASS (0F 0W) | Shape richness (secondary shapes); Palette depth (close-up); Detail density 25 m / 40 m | docs/art/lab/nightblood_reaver/scorecard.md |
| 2026-09-27 17:45:39 | barrow_ghoul | unit / soldier | 92 (-1) | WARN (0F 1W) | Glow points at 40 m; Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/barrow_ghoul/scorecard.md |
| 2026-09-27 17:46:39 | stormbottle_genie | unit / heavy | 93 (+2) | PASS (0F 0W) | Palette depth (close-up); Contrast on the other grounds; Surfaces per instance | docs/art/lab/stormbottle_genie/scorecard.md |
| 2026-09-27 17:46:54 | briar_roc | unit / heavy | 89 (+1) | WARN (0F 3W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:47:48 | hollow_oathsworn | unit / soldier | 91 (+0) | PASS (0F 0W) | Palette depth (close-up); Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/hollow_oathsworn/scorecard.md |
| 2026-09-27 17:47:58 | hoarlight_magebow | unit / soldier | 94 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Silhouette hook; Distinct from references (black masks) | docs/art/lab/hoarlight_magebow/scorecard.md |
| 2026-09-27 17:48:33 | thistle_darter | unit / soldier | 93 (+2) | FAIL (1F 0W) | Vertices; Detail density 25 m / 40 m; Inner detail (close-up / 25 m) | docs/art/lab/thistle_darter/scorecard.md |
| 2026-09-27 17:48:48 | briar_roc | unit / heavy | 90 (+1) | WARN (0F 3W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:48:45 | maelis | unit / wizard | 88 (+0) | WARN (0F 4W) | Contrast on the other grounds; Distinct from references (black masks); Parts above body_height + 0.4 | docs/art/lab/maelis/scorecard.md |
| 2026-09-27 17:49:07 | greenheart_oathkeeper | unit / heavy | 90 (-1) | WARN (0F 1W) | Contrast on the other grounds; Shape richness (secondary shapes); Tops light, bottoms dark | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 17:49:47 | barrow_ghoul | unit / soldier | 94 (+2) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Inner detail (close-up / 25 m) | docs/art/lab/barrow_ghoul/scorecard.md |
| 2026-09-27 17:49:47 | frost_mortar | unit / heavy | 95 (+0) | PASS (0F 0W) | Palette depth (close-up); Shape richness (secondary shapes); Silhouette hook | docs/art/lab/frost_mortar/scorecard.md |
| 2026-09-27 17:50:08 | stormbottle_genie | unit / heavy | 95 (+2) | PASS (0F 0W) | Palette depth (close-up); Contrast on the other grounds; Surfaces per instance | docs/art/lab/stormbottle_genie/scorecard.md |
| 2026-09-27 17:50:52 | briar_roc | unit / heavy | 87 (-3) | WARN (0F 3W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:51:50 | hollow_oathsworn | unit / soldier | 92 (+1) | PASS (0F 0W) | Palette depth (close-up); Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/hollow_oathsworn/scorecard.md |
| 2026-09-27 17:52:02 | briar_roc | unit / heavy | 87 (+0) | WARN (0F 3W) | Footprint vs selection radius; Parts above body_height + 0.4; Team colours for colour-blind players | docs/art/lab/briar_roc/scorecard.md |
| 2026-09-27 17:52:21 | rimeling | unit / soldier | 95 (+0) | PASS (0F 0W) | Inner detail (close-up / 25 m); Silhouette hook; Contrast on the home ground (snow) | docs/art/lab/rimeling/scorecard.md |
| 2026-09-27 17:53:00 | thistle_darter | unit / soldier | 93 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Inner detail (close-up / 25 m); Contrast vs ground (meadow) | docs/art/lab/thistle_darter/scorecard.md |
| 2026-09-27 17:53:32 | greenheart_oathkeeper | unit / heavy | 90 (+0) | WARN (0F 1W) | Contrast on the other grounds; Shape richness (secondary shapes); Tops light, bottoms dark | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 17:54:50 | aldra | unit / wizard | 95 (+1) | WARN (0F 1W) | Vertices; Palette depth (close-up); Tops light, bottoms dark | docs/art/lab/aldra/scorecard.md |
| 2026-09-27 17:54:50 | helper_vey | unit / wizard | 94 (+0) | WARN (0F 1W) | Vertices; Glow placement; Contrast on the other grounds | docs/art/lab/helper_vey/scorecard.md |
| 2026-09-27 17:55:34 | helper_hush | unit / wizard | 93 (-1) | WARN (0F 2W) | Vertices; Glow points at 40 m; Detail density 25 m / 40 m | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:56:38 | greenheart_oathkeeper | unit / heavy | 92 (+2) | WARN (0F 1W) | Contrast on the other grounds; Vertex use vs budget; Shape richness (secondary shapes) | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 17:57:46 | helper_vey | unit / wizard | 94 (+0) | WARN (0F 1W) | Vertices; Glow placement; Contrast on the other grounds | docs/art/lab/helper_vey/scorecard.md |
| 2026-09-27 17:58:04 | helper_hush | unit / wizard | 93 (+0) | WARN (0F 2W) | Vertices; Glow points at 40 m; Detail density 25 m / 40 m | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:58:35 | greenheart_oathkeeper | unit / heavy | 93 (+1) | WARN (0F 1W) | Contrast on the other grounds; Vertex use vs budget; Shape richness (secondary shapes) | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 17:59:41 | helper_hush | unit / wizard | 95 (+2) | WARN (0F 1W) | Vertices; Detail density 25 m / 40 m; Distinct from references (black masks) | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 17:59:13 | hoarlight_magebow | unit / soldier | 94 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Silhouette hook; Distinct from references (black masks) | docs/art/lab/hoarlight_magebow/scorecard.md |
| 2026-09-27 17:59:24 | barrow_ghoul | unit / soldier | 95 (+1) | PASS (0F 0W) | Detail density 25 m / 40 m; Shape richness (secondary shapes); Contrast on the other grounds | docs/art/lab/barrow_ghoul/scorecard.md |
| 2026-09-27 17:59:50 | frost_mortar | unit / heavy | 95 (+0) | PASS (0F 0W) | Palette depth (close-up); Shape richness (secondary shapes); Silhouette hook | docs/art/lab/frost_mortar/scorecard.md |
| 2026-09-27 17:59:59 | hollow_oathsworn | unit / soldier | 92 (+0) | PASS (0F 0W) | Palette depth (close-up); Detail density 25 m / 40 m; Shape richness (secondary shapes) | docs/art/lab/hollow_oathsworn/scorecard.md |
| 2026-09-27 18:00:44 | helper_hush | unit / wizard | 94 (-1) | WARN (0F 1W) | Vertices; Detail density 25 m / 40 m; Tops light, bottoms dark | docs/art/lab/helper_hush/scorecard.md |
| 2026-09-27 18:01:38 | greenheart_oathkeeper | unit / heavy | 93 (+0) | WARN (0F 1W) | Contrast on the other grounds; Vertex use vs budget; Shape richness (secondary shapes) | docs/art/lab/greenheart_oathkeeper/scorecard.md |
| 2026-09-27 18:02:08 | aldra | unit / wizard | 95 (+0) | WARN (0F 1W) | Vertices; Tops light, bottoms dark; Distinct from references (black masks) | docs/art/lab/aldra/scorecard.md |
| 2026-09-27 18:02:38 | cinder_arbalest | unit / soldier | 94 (-1) | WARN (0F 1W) | Footprint vs selection radius; Shape richness (secondary shapes); Distinct from references (black masks) | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 18:03:07 | maelis | unit / wizard | 88 (+0) | WARN (0F 4W) | Contrast on the other grounds; Distinct from references (black masks); Parts above body_height + 0.4 | docs/art/lab/maelis/scorecard.md |
| 2026-09-27 18:03:45 | cinder_arbalest | unit / soldier | 95 (+1) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 18:04:51 | cinder_arbalest | unit / soldier | 95 (+0) | PASS (0F 0W) | Shape richness (secondary shapes); Distinct from references (black masks); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/cinder_arbalest/scorecard.md |
| 2026-09-27 18:05:00 | maelis | unit / wizard | 88 (+0) | WARN (0F 4W) | Contrast on the other grounds; Distinct from references (black masks); Parts above body_height + 0.4 | docs/art/lab/maelis/scorecard.md |
| 2026-09-27 18:05:48 | scorchling | unit / soldier | 94 (-1) | WARN (0F 1W) | Footprint vs selection radius; Detail density 25 m / 40 m; Inner detail (close-up / 25 m) | docs/art/lab/scorchling/scorecard.md |
| 2026-09-27 18:06:49 | scorchling | unit / soldier | 95 (+1) | PASS (0F 0W) | Detail density 25 m / 40 m; Inner detail (close-up / 25 m); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/scorchling/scorecard.md |
| 2026-09-27 18:06:30 | maelis | unit / wizard | 88 (+0) | WARN (0F 4W) | Contrast on the other grounds; Distinct from references (black masks); Parts above body_height + 0.4 | docs/art/lab/maelis/scorecard.md |
| 2026-09-27 18:07:19 | scorchling | unit / soldier | 95 (+0) | PASS (0F 0W) | Detail density 25 m / 40 m; Inner detail (close-up / 25 m); Style bible: golden autumn (style-autumn.md 3) | docs/art/lab/scorchling/scorecard.md |
| 2026-09-28 19:37:10 | malrik | unit / wizard | 91 (+1) | WARN (0F 3W) | Vertices; Parts above body_height + 0.4; Looping particle systems | docs/art/lab/malrik/scorecard.md |
| 2026-09-28 19:37:35 | torvald | unit / wizard | 93 (+1) | WARN (0F 3W) | Contrast on the home ground (snow); Parts above body_height + 0.4; Vertices | docs/art/lab/torvald/scorecard.md |
| 2026-09-28 19:38:01 | ysolde | unit / wizard | 92 (+4) | WARN (0F 3W) | Vertices; Parts above body_height + 0.4; Looping particle systems | docs/art/lab/ysolde/scorecard.md |
| 2026-09-28 19:38:28 | helper_aldra | unit / soldier | 93 | FAIL (1F 1W) | Vertices; Parts above body_height + 0.4; Palette depth (close-up) | docs/art/lab/helper_aldra/scorecard.md |
| 2026-09-28 19:53:52 | vessa | unit / wizard | 90 (-1) | WARN (0F 5W) | Head height vs body_height; Contrast in every team colour (meadow); Meshes built per instance | docs/art/lab/vessa/scorecard.md |
| 2026-09-28 19:54:15 | malrik | unit / wizard | 90 (-1) | WARN (0F 4W) | Vertices; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/malrik/scorecard.md |
| 2026-09-28 19:54:38 | torvald | unit / wizard | 92 (-1) | WARN (0F 3W) | Contrast on the home ground (snow); Parts above body_height + 0.4; Vertices | docs/art/lab/torvald/scorecard.md |
| 2026-09-28 19:55:03 | ysolde | unit / wizard | 89 (-3) | WARN (0F 5W) | Contrast on the other grounds; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/ysolde/scorecard.md |
| 2026-09-28 19:55:26 | aldra | unit / wizard | 94 (-1) | WARN (0F 2W) | Vertices; Meshes built per instance; Palette depth (close-up) | docs/art/lab/aldra/scorecard.md |
| 2026-09-28 19:57:56 | vessa | unit / wizard | 90 (+0) | WARN (0F 5W) | Head height vs body_height; Contrast in every team colour (meadow); Meshes built per instance | docs/art/lab/vessa/scorecard.md |
| 2026-09-28 19:58:20 | malrik | unit / wizard | 90 (+0) | WARN (0F 4W) | Vertices; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/malrik/scorecard.md |
| 2026-09-28 19:58:42 | torvald | unit / wizard | 92 (+0) | WARN (0F 4W) | Contrast on the home ground (snow); Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/torvald/scorecard.md |
| 2026-09-28 19:59:06 | ysolde | unit / wizard | 90 (+1) | WARN (0F 5W) | Contrast on the other grounds; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/ysolde/scorecard.md |
| 2026-09-28 19:59:29 | aldra | unit / wizard | 94 (+0) | WARN (0F 2W) | Vertices; Meshes built per instance; Palette depth (close-up) | docs/art/lab/aldra/scorecard.md |
| 2026-09-28 20:00:38 | vessa | unit / wizard | 90 (+0) | WARN (0F 5W) | Head height vs body_height; Contrast in every team colour (meadow); Meshes built per instance | docs/art/lab/vessa/scorecard.md |
| 2026-09-28 20:01:02 | malrik | unit / wizard | 90 (+0) | WARN (0F 4W) | Vertices; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/malrik/scorecard.md |
| 2026-09-28 20:01:25 | torvald | unit / wizard | 92 (+0) | WARN (0F 4W) | Contrast on the home ground (snow); Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/torvald/scorecard.md |
| 2026-09-28 20:01:49 | ysolde | unit / wizard | 91 (+1) | WARN (0F 4W) | Vertices; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/ysolde/scorecard.md |
| 2026-09-28 20:02:12 | aldra | unit / wizard | 94 (+0) | WARN (0F 2W) | Vertices; Meshes built per instance; Palette depth (close-up) | docs/art/lab/aldra/scorecard.md |
| 2026-09-28 20:08:13 | vessa | unit / wizard | 90 (+0) | WARN (0F 5W) | Head height vs body_height; Contrast in every team colour (meadow); Meshes built per instance | docs/art/lab/vessa/scorecard.md |
| 2026-09-28 20:08:43 | malrik | unit / wizard | 91 (+1) | WARN (0F 4W) | Vertices; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/malrik/scorecard.md |
| 2026-09-28 20:09:11 | torvald | unit / wizard | 92 (+0) | WARN (0F 4W) | Contrast on the home ground (snow); Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/torvald/scorecard.md |
| 2026-09-28 20:09:40 | ysolde | unit / wizard | 89 (-2) | WARN (0F 5W) | Contrast on the other grounds; Parts above body_height + 0.4; Meshes built per instance | docs/art/lab/ysolde/scorecard.md |
| 2026-09-28 20:10:09 | aldra | unit / wizard | 94 (+0) | WARN (0F 2W) | Vertices; Meshes built per instance; Palette depth (close-up) | docs/art/lab/aldra/scorecard.md |
