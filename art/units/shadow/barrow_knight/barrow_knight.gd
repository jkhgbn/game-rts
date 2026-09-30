class_name BarrowKnightModel
extends GloamRiderModel
## Barrow Knight (stables.md 2, Shadow C, tier 2 line breaker; rank-3 research "Barrow Dreadlord"): the unit's model
## (data/units/barrow_knight.tres model_scene / model_path). The Gloam Rider's two-model root (GloamRiderModel: every unit
## hook, the charge, the dances through MountedDance), scaled x0.94 in the scene (the Dusk Steed is tall: the helm stays
## under the HP bar), with its own pair:
##   "Steed" = parts/barrow_steed.tscn: the Dusk Steed always in its tarnished-silver barding, a bone skull mask with
##             horns, a long tattered team shroud with a bone crescent, bone charms on the cantle;
##   "Rider" = parts/barrow_knight_rider.tscn (BarrowKnightRider): the grave-knight in blackened iron, a barbute with a
##             barrow crown, a team kite shield and a swinging flail (attack `flail_smash`).
## set_rank(rank) is the real rank-3 look (the rider's "RankCrest": a taller crown of bone spikes round a violet gem).
## get_lance_tip() (forwarded) is the flail ball.
## Reads apart from the Gloam Rider (Z): a crowned helm instead of the reaper cowl, a shield and a flail instead of the
## long barbed lance, a barded horse with a skull mask and a long shroud.


func _ready() -> void:
	super()
	# Check the distance tier on the first frame (see PyrehoofLancerModel): no close-face pop on far spawns.
	if _parts():
		_steed.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


## Stables16 rank-3 look (Barrow Dreadlord): the rider's bone-spiked crown. Idempotent.
func set_rank(rank: int) -> void:
	if _parts():
		_rider.call(&"set_rank", rank)
	set_meta(&"rank", rank)
