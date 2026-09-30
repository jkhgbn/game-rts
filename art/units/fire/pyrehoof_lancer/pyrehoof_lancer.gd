class_name PyrehoofLancerModel
extends BlazeRiderModel
## Pyrehoof Lancer (stables.md 2, Fire C, tier 2 line breaker; rank-3 research "Pyrehoof Warlord"): the unit's model
## (data/units/pyrehoof_lancer.tres model_scene / model_path). The Blaze Rider's two-model root (BlazeRiderModel: every
## unit hook, the charge, the dances through MountedDance, the kit-audit accessors) with its own pair:
##   "Boar"  = parts/pyrehoof_boar.tscn: the Ember Boar with burning hooves (soft embers that flare on the charge), a long
##             quilted team trapper and team crupper drapes, a light bronze chanfron and peytral;
##   "Rider" = parts/pyrehoof_lancer_rider.tscn (PyrehoofLancerRider): the heavy lancer, low sallet with a transverse
##             team crest, team kite shield, the war lance carried low with a team gonfalon (see that script).
## Only change to the forwarded hooks: set_rank(rank) is the real rank-3 look (Pyrehoof Warlord: the rider's gilded
## "RankCrest" and the boar's full bronze barding) instead of MountedDance's placeholder ring.
## Reads apart from the Blaze Rider (Z): team skirts and fire at the hooves on the boar; a tall kite shield instead of the
## round one; a side-to-side team crest instead of horns; the lance low and forward with a square banner instead of
## raised with a pennon.


func _ready() -> void:
	super()
	# Both kit models pick their first distance-tier check at a random moment (0-0.5 s, spread per instance): check it on
	# the first frame instead, so a unit spawned far away shows its far (bold) face and frozen pose at once instead of
	# popping from the close face after a few frames.
	if _parts():
		_boar.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


## Stables16 rank-3 look (Pyrehoof Warlord): the rider's gilded crest + the boar's bronze barding. Idempotent.
func set_rank(rank: int) -> void:
	if _parts():
		_rider.call(&"set_rank", rank)
		_boar.call(&"set_barded", rank >= 3)
	set_meta(&"rank", rank)
