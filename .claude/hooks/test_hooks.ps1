# Self-test for the hook scripts: pipes sample tool calls into each hook and checks the exit code (0 = allowed, 2 = blocked).
#   powershell -NoProfile -File .claude\hooks\test_hooks.ps1      -> "hooks: N/N OK" (exit 1 on any mismatch)
# Run it after changing a hook or owners.json. Never launches Godot.
$h = $PSScriptRoot
$root = Split-Path (Split-Path $h -Parent) -Parent
$env:CLAUDE_PROJECT_DIR = $root
$cases = @(
	# guard_shell: Godot gate
	@{ hook = "guard_shell"; want = 2; name = "godot exe direct"; j = @{ tool_input = @{ command = '& "C:\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s tests/smoke_test.gd' } } },
	@{ hook = "guard_shell"; want = 2; name = "GODOT shorthand"; j = @{ tool_input = @{ command = '$GODOT --headless --path . --import' } } },
	@{ hook = "guard_shell"; want = 0; name = "godot via gate"; j = @{ tool_input = @{ command = '& tools\godot_run.ps1 --headless --path . -s tests/smoke_test.gd --quit-after 7000' } } },
	@{ hook = "guard_shell"; want = 0; name = "lab script"; j = @{ tool_input = @{ command = 'tools\ci\ci_quick.ps1 -Changed' } } },
	@{ hook = "guard_shell"; want = 0; name = "exe path read only"; j = @{ tool_input = @{ command = 'Test-Path C:\Godot\Godot_v4.7.2-stable_win64_console.exe' } } },
	# guard_shell: git
	@{ hook = "guard_shell"; want = 0; name = "lead git commit"; j = @{ tool_input = @{ command = 'git commit -m "x"' } } },
	@{ hook = "guard_shell"; want = 2; name = "agent git commit"; j = @{ agent_id = "a1"; agent_type = "fw-art-medium"; tool_input = @{ command = 'git add . ; git commit -m x' } } },
	@{ hook = "guard_shell"; want = 2; name = "agent git.exe -C"; j = @{ agent_id = "a1"; agent_type = "gameplay-coder"; tool_input = @{ command = '& "C:\Program Files\Git\cmd\git.exe" -C . stash' } } },
	@{ hook = "guard_shell"; want = 2; name = "agent git status"; j = @{ agent_id = "a1"; agent_type = "ui-coder"; tool_input = @{ command = 'cd x; git status' } } },
	@{ hook = "guard_shell"; want = 0; name = "reviewer git diff"; j = @{ agent_id = "a1"; agent_type = "contract-reviewer"; tool_input = @{ command = 'git diff -- scripts/units' } } },
	@{ hook = "guard_shell"; want = 2; name = "reviewer git commit"; j = @{ agent_id = "a1"; agent_type = "contract-reviewer"; tool_input = @{ command = 'git commit -am x' } } },
	@{ hook = "guard_shell"; want = 0; name = "agent word digit"; j = @{ agent_id = "a1"; agent_type = "ui-coder"; tool_input = @{ command = 'Select-String -Pattern legit scripts' } } },
	# guard_edit
	@{ hook = "guard_edit"; want = 2; name = "edit .import"; j = @{ tool_input = @{ file_path = "$root\art\x.png.import" } } },
	@{ hook = "guard_edit"; want = 2; name = "edit .godot"; j = @{ tool_input = @{ file_path = "$root\.godot\editor\x.cfg" } } },
	@{ hook = "guard_edit"; want = 0; name = "lead edits anything"; j = @{ tool_input = @{ file_path = "$root\scripts\units\unit.gd" } } },
	@{ hook = "guard_edit"; want = 0; name = "owner in folder"; j = @{ agent_id = "a1"; agent_type = "gameplay-coder"; tool_input = @{ file_path = "$root\scripts\units\unit.gd" } } },
	@{ hook = "guard_edit"; want = 0; name = "owner own test"; j = @{ agent_id = "a1"; agent_type = "gameplay-coder"; tool_input = @{ file_path = "$root\tests\test_x.gd" } } },
	@{ hook = "guard_edit"; want = 0; name = "owner handoff"; j = @{ agent_id = "a1"; agent_type = "ui-coder"; tool_input = @{ file_path = "$root/docs/handoff/for-lead.md" } } },
	@{ hook = "guard_edit"; want = 2; name = "owner outside"; j = @{ agent_id = "a1"; agent_type = "ui-coder"; tool_input = @{ file_path = "$root\scripts\units\unit.gd" } } },
	@{ hook = "guard_edit"; want = 2; name = "ui-designer non-ui doc"; j = @{ agent_id = "a1"; agent_type = "ui-designer"; tool_input = @{ file_path = "$root\docs\design\items.md" } } },
	@{ hook = "guard_edit"; want = 0; name = "unlisted agent type"; j = @{ agent_id = "a1"; agent_type = "fw-art-medium"; tool_input = @{ file_path = "$root\scripts\units\unit.gd" } } },
	@{ hook = "guard_edit"; want = 0; name = "outside repo"; j = @{ agent_id = "a1"; agent_type = "ui-coder"; tool_input = @{ file_path = "C:\Users\x\AppData\Local\Temp\scratch.txt" } } },
	@{ hook = "guard_edit"; want = 2; name = "reviewer writes"; j = @{ agent_id = "a1"; agent_type = "contract-reviewer"; tool_input = @{ file_path = "$root\scripts\units\unit.gd" } } },
	# check_gd
	@{ hook = "check_gd"; want = 0; name = "typed vars"; j = @{ tool_input = @{ file_path = "$root\scripts\units\x.gd"; new_string = "var hp: float = 10.0`nvar n := 3`n@export var speed: float = 2.0`nconst K = 4`nif a == b:" } } },
	@{ hook = "check_gd"; want = 2; name = "untyped var"; j = @{ tool_input = @{ file_path = "$root\scripts\units\x.gd"; new_string = "`tvar target = null" } } },
	@{ hook = "check_gd"; want = 2; name = "untyped export var"; j = @{ tool_input = @{ file_path = "$root\scripts\units\x.gd"; content = "@export var speed = 2.0" } } },
	@{ hook = "check_gd"; want = 0; name = "untyped escape"; j = @{ tool_input = @{ file_path = "$root\tests\test_x.gd"; new_string = "var h = main.hero   # untyped: Wizard fields" } } },
	@{ hook = "check_gd"; want = 2; name = "parent chain"; j = @{ tool_input = @{ file_path = "$root\scripts\ui\x.gd"; new_string = "var m: Node = get_node(`"../../Main`")" } } },
	@{ hook = "check_gd"; want = 2; name = "get_parent chain"; j = @{ tool_input = @{ file_path = "$root\scripts\ui\x.gd"; new_string = "var m: Node = get_parent().get_parent()" } } },
	@{ hook = "check_gd"; want = 2; name = "class_name autoload"; j = @{ tool_input = @{ file_path = "$root\scripts\core\x.gd"; content = "extends Node`nclass_name Events" } } },
	@{ hook = "check_gd"; want = 2; name = "Events in test"; j = @{ tool_input = @{ file_path = "$root\tests\test_x.gd"; new_string = "`tEvents.unit_died.connect(_on)" } } },
	@{ hook = "check_gd"; want = 0; name = "Events comment in test"; j = @{ tool_input = @{ file_path = "$root\tests\test_x.gd"; new_string = "# listens to Events.unit_died`nvar ev: Node = get_node_or_null(^`"/root/Events`")" } } },
	@{ hook = "check_gd"; want = 0; name = "not gd"; j = @{ tool_input = @{ file_path = "$root\docs\x.md"; new_string = "var target = null" } } }
)
$ok = 0; $bad = 0
foreach ($c in $cases) {
	$json = $c.j | ConvertTo-Json -Depth 6 -Compress
	$err = $json | powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $h "$($c.hook).ps1") 2>&1
	$code = $LASTEXITCODE
	if ($code -eq $c.want) { $ok++ } else { $bad++; Write-Host "MISMATCH $($c.hook) '$($c.name)': want $($c.want) got $code $err" }
}
Write-Host "hooks: $ok/$($cases.Count) OK"
if ($bad) { exit 1 }
