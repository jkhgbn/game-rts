extends RefCounted
## Data Lab: every number and list the checks use (docs/plan/data-lab.md section 3). Tune here, never in the checks.
## "hard" bounds FAIL (the value is broken: it would crash, divide by zero or make the unit useless); "soft" outliers
## only WARN (derived from the data's own spread: more than SPREAD_FACTOR x away from the median of its group).

## Folders scanned (every .tres below them must load).
const DATA_DIRS: Array[String] = ["res://data/units/", "res://data/buildings/", "res://data/champions/",
	"res://data/champion_classes/", "res://data/items/", "res://data/spells/", "res://data/ai/"]

## Hard bounds per kind: field -> [min, max] (inclusive). A value outside = FAIL.
const HARD_BOUNDS := {
	"unit": {"max_hp": [1.0, 20000.0], "move_speed": [0.0, 15.0], "attack_damage": [0.0, 1000.0],
		"attack_range": [0.0, 40.0], "attack_cooldown": [0.1, 20.0], "aggro_range": [0.0, 40.0], "radius": [0.1, 5.0],
		"body_height": [0.2, 12.0], "cost": [0.0, 2000.0], "pop": [0.0, 10.0], "train_time": [0.0, 300.0],
		"armor": [-50.0, 300.0], "projectile_speed": [1.0, 200.0], "kill_xp": [0.0, 2000.0], "sight_radius": [0.0, 60.0],
		"idle_regen_pct": [0.0, 20.0], "lifetime": [0.0, 600.0]},
	"building": {"max_hp": [1.0, 20000.0], "cost": [0.0, 2000.0], "build_time": [0.0, 600.0], "height": [0.2, 30.0],
		"attack_damage": [0.0, 500.0], "attack_range": [0.0, 40.0], "attack_cooldown": [0.1, 20.0],
		"sight_radius": [0.0, 60.0], "pop_bonus": [0.0, 100.0], "max_count": [0.0, 50.0], "aura_radius": [0.0, 40.0],
		"idle_regen_pct": [0.0, 20.0], "max_keep_distance": [0.0, 200.0]},
	"champion": {"max_hp": [1.0, 5000.0], "move_speed": [1.0, 15.0], "attack_damage": [0.0, 500.0],
		"attack_range": [0.5, 40.0], "attack_cooldown": [0.1, 10.0], "aggro_range": [0.0, 40.0],
		"sight_radius": [1.0, 60.0], "growth_pct": [0.0, 0.5], "flee_pct": [0.0, 1.0], "pop": [0.0, 10.0],
		"armor": [-50.0, 300.0], "bounty_threshold": [0.0, 1000.0]},
	"class": {"attack_damage": [0.0, 500.0], "attack_cooldown": [0.1, 10.0], "attack_range": [0.5, 40.0],
		"projectile_speed": [0.0, 200.0], "flee_delta": [-0.5, 0.5]},
	"item": {"cost": [0.0, 10000.0], "active_cooldown": [0.0, 600.0], "stack_max": [1.0, 99.0]},
	"spell": {"mana_cost": [0.0, 1000.0], "cooldown": [0.0, 600.0], "cast_range": [0.0, 60.0], "radius": [0.0, 30.0],
		"damage": [0.0, 2000.0], "duration": [0.0, 120.0], "tick_interval": [0.05, 10.0], "heal_ratio": [0.0, 5.0],
		"max_rank": [1.0, 5.0]},
}

## Fields that must be set (non-empty / non-zero) per kind.
const REQUIRED := {
	"unit": ["id", "display_name", "max_hp"],
	"building": ["id", "display_name", "faction", "kind", "max_hp"],
	"champion": ["id", "title", "names", "role", "max_hp", "ability_ids", "class_weights", "barks", "model_scene"],
	"class": ["id", "display_name", "attack_style", "ability_ids", "bounty_kind", "icon_abbrev", "tooltip"],
	"item": ["id", "display_name", "icon_abbrev"],   # tooltip only when the item has a passive / active (F5)
	"spell": ["id", "display_name", "hotkey_label", "icon_abbrev", "tooltip"],
}

const FACTIONS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
const UNIT_FACTIONS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature", &"neutral", &""]
const BUILDING_KINDS: Array[StringName] = [&"keep", &"barracks", &"house", &"tower", &"wall", &"market", &"stables"]
const SUPPORT_KINDS: Array[StringName] = [&"", &"shield", &"heal"]
const ATTACK_STYLES: Array[StringName] = [&"spear_thrust", &"sword_slash", &"great_cleave", &"staff_bolt"]
## Documented sentinel values allowed below 0 (field -> value): AIProfile.first_scout_time -1 = use scout_interval.
const SENTINELS := {"first_scout_time": -1.0}
## Keeps / barracks allowed to train nothing (id -> the reason, shown as INFO). Only mission-only types that no build
## menu offers (`is_buildable()` false); a buildable one still FAILs F5 "trains nothing".
const NON_TRAINER_BUILDINGS := {
	"fire_watch_keep": "mission 0 watch-keep (mission-00.md 19.C7a: 2 000 HP, shoots, cannot train, no tier button)",
}
## Statuses Unit.STATUSES does not list but code applies by name (spell / item specials).
const EXTRA_STATUSES: Array[StringName] = [&"smoulder", &"glacier_shell"]

## levels.md victim table: soldiers give about cost / 2 XP; outside [cost x 0.3, cost x 0.8] = WARN.
const KILL_XP_RATIO: Array[float] = [0.3, 0.8]

## Spread outliers (WARN): a stat more than this factor above / below the median of its group.
const SPREAD_FACTOR := 2.5
## Groups need at least this many members before spread outliers are flagged.
const SPREAD_MIN_GROUP := 4

## Hotkeys. Training slots use Z X C V B N M , by card index (CLAUDE.md Keys, SelectionManager.SLOT_KEYS: 8 on a Hall with
## its bowman and new units), the build menu reads hotkey_label; UnitType.card_key = the letter of the unit's slot.
const TRAIN_SLOT_KEYS: Array[String] = ["Z", "X", "C", "V", "B", "N", "M", ","]
const BUILD_MENU_KEYS: Array[String] = ["Z", "X", "C", "V", "B", "N"]   # command_card.gd BUILD_KEY_SLOTS (N = Stables)
const SPELL_KEYS: Array[String] = ["F", "Q", "E"]
## CLAUDE.md Keys: "Letters W A S D Q E F are never used for anything else" (Hero WASD walks, F / Q / E spells).
const RESERVED_LETTERS: Array[String] = ["W", "A", "S", "D", "Q", "E", "F"]
## Global keys while units are selected (X attack-move, C stop, H hold, G gather, B build, R bounty, Y tavern,
## U trade, T shop): a unit card_key must not reuse them. Building cards own Z X C V B while a building is selected.
const GLOBAL_UNIT_KEYS: Array[String] = ["X", "C", "H", "G", "B", "R", "Y", "U", "T"]

## Text. Width is measured with the project font (else the engine fallback font) at the HUD sizes.
const NAME_FONT_SIZE := 18          ## selection_panel / tooltip title size
const NAME_MAX_PX := 240.0          ## selection_panel HERO_WIDTH 300 minus the portrait margin
const TOOLTIP_FONT_SIZE := 13       ## ui_style.gd TooltipLabel
const TOOLTIP_WIDTH_PX := 300.0     ## tooltip panel inner width
const TOOLTIP_MAX_LINES := 6        ## wrapped lines above this = WARN (tooltip too tall)
const ABBREV_MAX := 3               ## icon_abbrev letters on a 56 px icon
const PLACEHOLDER_RE := "(?i)\\b(todo|tbd|fixme|xxx+|lorem|placeholder text|test test)\\b"
const MOJIBAKE_RE := "Â|Ã|â€"
## UI scripts scanned for hard-coded strings (INFO list for the French pass).
const UI_DIRS: Array[String] = ["res://scripts/ui/", "res://scripts/ui/menus/", "res://scripts/ui/mission/"]

## AI knobs: field -> [min, max] (FAIL outside; documented ranges from ai_profile.gd comments and ai.md).
const AI_BOUNDS := {
	"decision_interval": [0.1, 5.0], "reaction_delay": [0.0, 10.0], "build_delay": [0.0, 30.0],
	"worker_target_home": [1, 30], "worker_target_expanded": [1, 40], "worker_target_x2": [1, 50],
	"queue_depth": [1, 5], "attack_ratio": [0.5, 3.0], "min_attack_pop": [1, 99], "attack_ratio_floor": [0.3, 3.0],
	"attack_patience": [0.0, 600.0], "attack_full_pop": [0, 200], "first_attack_by": [0.0, 1800.0],
	"memory_seconds": [10.0, 600.0], "scout_interval": [10.0, 900.0], "potion_stock": [0, 5],
	"defend_radius": [5.0, 80.0], "retreat_hp": [0.0, 1.0], "tower1_time": [0.0, 1800.0], "tower2_time": [0.0, 1800.0],
	"expand_time": [0.0, 1800.0], "champion_max": [0, 3], "champion_earliest": [0.0, 1800.0],
	"bounty_budget_pct": [0.0, 1.0], "bounty_max_flags": [0, 10], "explore_unseen": [0.0, 900.0],
	"trade_start": [0.0, 1800.0], "caravan_target": [0, 12], "caravan_target_late": [0, 12],
	"far_route_caravans": [0, 12], "gold_exchange_above": [0, 5000], "creep_start": [0.0, 1800.0],
	"creep_ratio": [0.5, 5.0], "capture_squad": [0, 10], "steal_points_ratio": [0.0, 5.0], "shrine_lead": [0.0, 120.0],
	"beast_ratio": [0.0, 5.0], "beast_hunt_stake": [0, 1000], "regrow_hp": [0.0, 1.0], "regrow_wait": [0.0, 300.0],
	"heavy_crystals": [0, 2000], "first_scout_time": [-1.0, 1800.0], "heavy_soldier_pop": [0, 100], "wall_path_ratio": [1.0, 5.0],
}
## Difficulty order: easy -> normal -> hard must move this way ("down" = hard is lower / faster). WARN if not.
const AI_MONOTONIC := {"decision_interval": "down", "reaction_delay": "down", "build_delay": "down",
	"attack_ratio": "down", "worker_target_home": "up", "champion_max": "up", "memory_seconds": "up"}
const AI_SPELL_ORDER_RE := "^[FQE][1-3]$"
const AI_BUILD_ROW_RE := "^[A-Z][0-9]$"
const AI_FLAG_RE := "^B[0-9]+$"
const AI_MIX_KEYS: Array[String] = ["mix_default", "mix_vs_ranged", "mix_vs_melee"]
const AI_MIX_SUM_TOLERANCE := 0.02

## Balance table: an EHP-per-cost or DPS-per-cost cell more than this factor from its row median = WARN.
const BALANCE_FACTOR := 1.6
