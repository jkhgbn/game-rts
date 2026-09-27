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
