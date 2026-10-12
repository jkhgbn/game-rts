# Art experiments kept as patches (not applied)

| Patch | What | Why not applied |
|---|---|---|
| `rigid_skin_cavalry_2026-10-12.patch` | glade_outrider + stagrunner: moving rider parts drawn by their parent mesh through a light skeleton (`rigid_skin.gd`), 20 -> 16 mesh instances, Art Lab B2 FAIL -> PASS (+1 overall) | Measured cost: ~+1.9 ms render CPU and +0.25 ms GPU per 100 stagrunners (same load), glade_outrider ~+3 ms. A budget score is not worth a real frame-time loss. Apply with `git apply` if the B2 rule or the renderer changes. |
