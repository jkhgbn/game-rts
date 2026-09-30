class_name EmberdartHarrierModel
extends BlazeRiderModel
## Emberdart Harrier (stables.md 2, Fire X: the tier-1 mounted javelin skirmisher): the unit's model
## (data/units/emberdart_harrier.tres model_scene / model_path). The Blaze Rider's two-model root (BlazeRiderModel: every
## unit hook, the charge, the dances through MountedDance, the kit-audit accessors), scaled x0.92 in the scene (the
## light rider), with its own pair:
##   "Boar"  = parts/emberdart_boar.tscn: the Ember Boar with a javelin quiver on each flank and a breast strap;
##   "Rider" = parts/emberdart_harrier_rider.tscn (EmberdartHarrierRider): the lean skirmisher with the red topknot, the
##             team scarf and headband, a javelin quiver on the back and a javelin raised overhand.
## Ranged: attack_windup 0.12 s (the Unit launches its javelin at the rider's release frame, attack `javelin_throw`);
## play_attack() plays the throw on the rider only (the boar keeps running: no head toss for a thrown javelin).
## get_lance_tip() (forwarded) is the hand javelin's tip. set_rank: no rank research for the X harrier (no look).
## Reads apart from the Blaze Rider (Z): no lance, no shield, no helm: a raised javelin, a fan of shafts on the back and
## at the boar's flanks, a streaming scarf and a flame-red topknot.


func _ready() -> void:
	super()
	# Check the distance tier on the first frame (see PyrehoofLancerModel): no close-face pop on far spawns.
	if _parts():
		_boar.set(&"_tier_timer", 0.0)
		_rider.set(&"_tier_timer", 0.0)


func play_attack() -> void:
	if _parts() and not _dead:
		_rider.call(&"play_attack")


func set_rank(rank: int) -> void:
	set_meta(&"rank", rank)
