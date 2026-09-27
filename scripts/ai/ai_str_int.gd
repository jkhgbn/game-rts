class_name AIStrInt
extends RefCounted
## Bot rule for the STR / INT path (docs/design/level-boons.md "STR / INT path"): which path an AI wizard
## (or a headless / test player wizard) takes at 0:00. By kingdom, so the choice suits the wizard's kit:
## - Fire (Vessa, Fireball nukes) and Ice (Torvald, control + Rime Bolt) -> INT (spell power, mana, Snow Shield);
## - Shadow (Malrik, life drain, fights up close) and Nature (Ysolde, sustain in long fights) -> STR
##   (attack, HP, Vigor regeneration).
## Unknown kingdom -> STR (the safer pick for a bot that does not cast well).

const BY_KINGDOM := {&"fire": &"int", &"ice": &"int", &"shadow": &"str", &"nature": &"str"}


static func choose(kingdom: StringName) -> StringName:
	return BY_KINGDOM.get(kingdom, &"str")
