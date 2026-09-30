class_name DuskboltHarrierModel
extends GloamRiderModel
## Duskbolt Harrier (stables.md 2, Shadow X: the tier-1 mounted crossbow skirmisher): the unit's model
## (data/units/duskbolt_harrier.tres model_scene / model_path). The Gloam Rider's two-model root (GloamRiderModel: every
## unit hook, the charge, the dances through MountedDance), scaled x0.86 in the scene (the light rider on the tall Dusk
## Steed: the hood stays under the HP bar), with its own pair:
##   "Steed" = parts/duskbolt_steed.tscn: the Dusk Steed with a bolt case on each flank and a rolled blanket;
##   "Rider" = parts/duskbolt_harrier_rider.tscn (DuskboltHarrierRider): the hooded scout with the broad team mantle and
##             the one-hand crossbow (attack `bolt_shot`).
## Ranged: attack_windup 0.12 s in the scene (the Unit launches its bolt at the rider's release frame); play_attack()
## plays the shot on the rider only (the steed keeps running: no head toss for a shot). get_lance_tip() (forwarded) is
## the muzzle. set_rank: no rank research for the X harrier (no look).
## Reads apart from the Gloam Rider (Z): a tall pointed hood and a mantle instead of the reaper cowl, a crossbow held
## out instead of the long barbed lance, bolt cases at the steed's flanks.


func _ready() -> void:
	super()
	# Check the distance tier on the first frame (see PyrehoofLancerModel): no close-face pop on far spawns.
	if _parts():
		_steed.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


func play_attack() -> void:
	if _parts() and not _dead:
		_rider.call(&"play_attack")


func set_rank(rank: int) -> void:
	set_meta(&"rank", rank)
