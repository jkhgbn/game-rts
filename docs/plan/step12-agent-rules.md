# Step 12 (Fill the map): rules for every agent

Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Godot 4.7.2, GDScript, static types). Read `CLAUDE.md` first
(Run and test, Code style, Contracts), then `docs/design/map-fill.md` (the spec: the user's answers at the top —
river + Crown Isle with the Crown Steps, shrines wake in turn, underdog bonus, critters HUNTABLE, epic animals 4-8
kinds x 2 variants; section 10 = the art list with paths and hooks; the task list with files and "Done when").
Style: `docs/design/art-keep.md` section 0 (painted SC2/LoL look), `docs/art/lighting.md`, the latest art as reference
(`art/environment/nature_props/` shared painted material, `art/buildings/tavern/`, `art/buildings/nature/`).

1. Edit **only** the files / folders your task owns (map-fill.md section 10 row) plus your own `tests/test_12_<id>.gd`.
   Needs from another owner go to `docs/handoff/for-<agent>.md` + your report.
2. **Never run git.** The lead commits.
3. Other agents work in parallel (steps 10-12). Reach classes you don't own through `load()` guarded by
   `ResourceLoader.exists`, groups, `has_method()`; `is_instance_valid(x)` before `x is T`.
4. Godot: never kill a Godot process you did not start. Always `--fixed-fps 60 --quit-after N`. Windowed renders:
   stop only your own process if it hangs.
5. Art: 0 real lights unless the spec says so, merged / indexed meshes (`st.index()` after `generate_normals()`),
   shared materials, cheap enough for the whole map (visibility ranges, MultiMesh-friendly), no runtime materials.
   Render previews under `docs/art/screens/` and look at them yourself before reporting.
6. Original IP only. Quality first, no time box.
7. (refresh 2026-09-26) Contracts are now frozen in `CLAUDE.md` ("Map fill" bullet) = map-fill.md section 13 — code
   to them exactly; ask the lead (report) before changing a signature. Terrain (step 12b, `docs/design/terrain.md`)
   will plug in later through `RiverSystem.ford_modifier_enabled`.
8. Recent map work to keep intact: MAP.P1 (ground.gdshader patch_contrast / crisp edges / cliff_ao / outer_cool /
   `sun_dir`, `cliff_mat.tres`, cliff-foot clumps in `map_dressing_art.gd`, test `test_map_p1`), MAP.P2
   (`SiteGround` trodden-earth patches under neutral sites). Run their tests if you touch those files.
9. Colliders <= ~1.8 m tall so the runtime navmesh bake does not create islands on top; 0 real lights (the skirmish
    already has 15 omni lights, the cap); new art that must be clickable uses layer 2.
10. Final report (short): files, public API / hooks (exact signatures), test results, anything the lead must glue.

11. **Art Lab (every art task, docs/plan/art-lab.md).** When the asset is built, run the Art Lab windowed: `& $GODOT --path . -s res://tools/art_lab/art_lab.gd --quit-after 90000 -- scene=<scene / set / vfx script> kind=<kind> kingdom=<kingdom>`. Open docs/art/lab/<name>/contact_sheet.png and scorecard.md. Fix every FAIL and every sensible WARN (a kept WARN needs one line of reason), then apply at least the top 'Improve next' item and re-run until no FAIL and the quality score stops rising. Report: scorecard path, before / after quality score, what you changed, and end with 'Art Lab notes' (missed problems, false alarms with values, checks to add). Never edit tools/art_lab/.
