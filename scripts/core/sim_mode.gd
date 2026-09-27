class_name SimMode
extends RefCounted
## Bot Lab "sim mode" (docs/plan/bot-lab.md): a headless bot-vs-bot run that skips what only draws. Off in the game;
## only tools/bot_lab/lab_match.gd turns it on, before the level is instanced. Gameplay stays identical: navmesh,
## colliders, fog, AI, economy, timings.
## Game code reads it through a preload (never the class name, so a stale class cache can't break a script):
##   const _SIM := preload("res://scripts/core/sim_mode.gd")   ...   if _SIM.enabled: ...
## Build-time hooks that read it (art spawn only; they save start-up time):
## - main.gd: no lighting rig / environment, no MapDressingArt, no CritterSystem, no EnvProps, no ground paint;
##   placeholder trees / rocks / pillars keep their colliders but get no meshes;
## - RiverSystem: build_visuals false (no water / ford / riverbed meshes, no bridge models; carve, colliders and
##   crossings stay);
## - NeutralCamp: no camp site art;  EpicBeasts: no lair art.
## Everything per-frame is done by lab_match.gd itself, so it also works on commits without these hooks: it removes
## the level's VFX / audio / horizon nodes, freezes every art script (character, building and prop models: process
## off; a unit's or building's model wakes up when it dies so death_finished / destroyed_finished keep their timing)
## and hides the HUD.

## True while a Bot Lab sim run is going. Never set it in the game.
static var enabled := false
