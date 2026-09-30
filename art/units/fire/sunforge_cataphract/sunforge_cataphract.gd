class_name SunforgeCataphractModel
extends BlazeRiderModel
## Sunforge Cataphract (stables.md 2, Fire V: the tier-3 elite, the army's anchor): the unit's model
## (data/units/sunforge_cataphract.tres model_scene / model_path). The Blaze Rider's two-model root (BlazeRiderModel: every
## unit hook, the charge, the dances through MountedDance, the kit-audit accessors), scaled x1.12 in the scene (the
## biggest Fire rider), with its own pair:
##   "Boar"  = parts/sunforge_boar.tscn: the Ember Boar in gilded plates (shoulders, chanfron, peytral, knee
##             cops), a standing sun-disc crest on its brow, a long team trapper and team crupper drapes;
##   "Rider" = parts/sunforge_cataphract_rider.tscn (SunforgeCataphractRider): the old sun-knight in gilded plate with the
##             SUN WHEEL on his back, a sun-ray crown and the glowing Sunforge maul (attack `sun_smash`).
## get_lance_tip() (forwarded) is the maul head. set_rank is a no-op (no rank-3 research for a tier-3 unit).
## Reads apart from the Blaze Rider (Z) and the Pyrehoof Lancer (C): gold instead of bronze, a big wheel on the back
## instead of a raised / lowered lance, a hammer over the shoulder, a sun disc on the boar's brow.


func _ready() -> void:
	super()
	# Check the distance tier on the first frame (see PyrehoofLancerModel): no close-face pop on far spawns.
	if _parts():
		_boar.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


func set_rank(rank: int) -> void:
	set_meta(&"rank", rank)
