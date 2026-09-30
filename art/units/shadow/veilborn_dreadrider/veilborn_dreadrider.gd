class_name VeilbornDreadriderModel
extends GloamRiderModel
## Veilborn Dreadrider (stables.md 2, Shadow V, tier 3: the elite, the army's anchor): the unit's model
## (data/units/veilborn_dreadrider.tres model_scene / model_path). The Gloam Rider's two-model root (GloamRiderModel: every
## unit hook, the charge, the dances through MountedDance), scaled x1.03 in the scene, with its own pair:
##   "Steed" = parts/veil_steed.tscn: the Dusk Steed always barded, two obsidian horns on the chanfron, a long trailing
##             team veil with silver rune-eyes, smoke at the hooves;
##   "Rider" = parts/veilborn_dreadrider_rider.tscn (VeilbornDreadriderRider): the horned dread knight in obsidian plate
##             under a vast tattered team veil, the scythe-glaive with its glowing edge (attack `reap`).
## get_lance_tip() (forwarded) is the scythe's point. set_rank is a no-op (no rank research for a tier-3 unit).
## Reads apart from the Gloam Rider (Z) and the Barrow Knight (C): horns on rider and steed, a scythe with a hanging
## blade instead of a lance or a flail, a veil streaming back over a smoking, horned nightmare.


func _ready() -> void:
	super()
	# Check the distance tier on the first frame (see PyrehoofLancerModel): no close-face pop on far spawns.
	if _parts():
		_steed.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


func set_rank(rank: int) -> void:
	set_meta(&"rank", rank)
