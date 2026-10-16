extends "res://art/units/ice/rime_colossus.gd"
## The Hollow King as a model scene (hollow_king.tscn = the Rime Colossus scene with this script): the Colossus rig,
## animations and hooks, dressed by HollowKingArt once its parts are merged. For the Art Lab, the shots and a
## UnitType `model_scene` later; the mission itself dresses its Colossus unit with HollowKingArt.dress(unit).


func _ice_ready() -> void:
	super._ice_ready()
	HollowKingArt.dress_model(self)
