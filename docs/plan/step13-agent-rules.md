# Step 13 (Cavalry, titans, mounts): rules for every art agent started early

Project: `C:\Users\elzzo\Documents\four-wizards-rts` (Godot 4.7.2, GDScript). Read `CLAUDE.md` (Run and test, Code
style), then `docs/design/cavalry-mounts.md` (the spec; section 10 = art list with paths and hooks). User decisions:
titans as proposed (Fire Cinder Dragon, Shadow Nightmare Knight, Ice War Mammoth, Nature Elder Treant), true flyer,
mounts travel-only, Stables tier 2; **"make it EPIC"**: the titans are the showpieces of the game — top quality.
Style: `docs/design/art-units.md`, `art-keep.md` section 0 (painted SC2/LoL), the champion models and kit
(`art/units/kit/`, `art/units/champions/`) as quality reference.

1. Edit only your task's folder / new files plus your own `tests/test_13_<id>.gd`. Do NOT edit
   `art/units/kit/character_model.gd` (other steps use it); new kit files are fine if your task says so.
2. Never run git. Never kill a Godot process you did not start. Always `--fixed-fps 60 --quit-after N`.
3. Code gameplay for these units doesn't exist yet: build the models with the hooks the spec lists, test them headless.
4. 0 real lights, merged / indexed meshes, budgets from the spec, no runtime materials; render previews under
   `docs/art/screens/` (game camera 40 m + close-ups + black silhouette) and look at them yourself.
5. Original IP only. Quality first, no time box. Final report: files, hooks (exact signatures), budgets, test results.

11. **Art Lab (every art task, docs/plan/art-lab.md).** When the asset is built, run the Art Lab windowed: `& $GODOT --path . -s res://tools/art_lab/art_lab.gd --quit-after 90000 -- scene=<scene / set / vfx script> kind=<kind> kingdom=<kingdom>`. Open docs/art/lab/<name>/contact_sheet.png and scorecard.md. Fix every FAIL and every sensible WARN (a kept WARN needs one line of reason), then apply at least the top 'Improve next' item and re-run until no FAIL and the quality score stops rising. Report: scorecard path, before / after quality score, what you changed, and end with 'Art Lab notes' (missed problems, false alarms with values, checks to add). Never edit tools/art_lab/.
