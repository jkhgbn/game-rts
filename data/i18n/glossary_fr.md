# French (Québec) glossary

The terms every French string uses (`data/i18n/fr/*.po`). One English term = one French term, everywhere.
Register: natural Québec French, "vous" in instructions and menus ("Choisissez", "Appuyez"), short imperatives on
buttons ("Jouer", "Retour"). Québec usage: courriel (not e-mail), clavardage (chat), magasiner / boutique, fin de
semaine; no anglicisms when a common French word exists.

## Typography (applied by `tools/i18n/extract_strings.gd fix`)
- A no-break space (U+00A0) before `:` `;` `?` `!` and inside « guillemets ». The project fonts (Cinzel, Alegreya)
  have no narrow no-break space (U+202F), so U+00A0 is used everywhere (Godot would fall back to a system font).
- Decimal comma in running text (`1,5 s`); `Loc.num()` does it for numbers built in code. Thousands: no separator.
- Percent: `50 %` (no-break space before %). Times stay `2:00` (clock), durations `30 s`, `2 min`.
- Capitals: only the first word of a title or button ("Paramètres du jeu", "Retour au menu principal").
- Straight apostrophe `'` (the fonts have `’` too; keep `'` so search / replace stays simple).
- Key names stay as printed on the key (`Échap` for Esc, `Maj` for Shift, `Ctrl`, `Alt`, `Tab`, `Espace`, `Suppr`).

## Game terms
| English | Français (Québec) | Notes |
|---|---|---|
| wizard | sorcier / sorcière | Vessa, Isolde = sorcière; Malrik, Torvald = sorcier; generic = sorcier |
| apprentice | apprenti / apprentie | |
| master (the vanished master) | maître | |
| keep (building, tier 1) | donjon | the building name "Keep" = Donjon |
| Stronghold (tier 2) | Forteresse | tier names are capitalised |
| Citadel (tier 3) | Citadelle | |
| tier | palier | "Palier 2", short "P2" stays **T2** in badges (key-like labels) |
| hall (Ember Hall...) | salle | proper names keep English ("Ember Hall"); generic "a hall" = une salle |
| barracks | caserne | |
| house / hovel | maison / masure | building names stay English |
| tower / spire | tour / flèche | proper names stay English |
| wall | muraille | "Ice Wall" = Mur de glace |
| crystals | cristaux | resource; "crystal node" = gisement de cristaux |
| essence | essence | resource |
| gold | or | resource |
| population / pop | population / pop. | "Pop" badge stays "Pop" |
| worker | ouvrier | |
| soldier | soldat | |
| unit | unité | |
| army | armée | |
| caster (unit) | lanceur de sorts | |
| spell | sort | |
| mana | mana | (masculin: le mana) |
| cooldown | recharge | "Recharge : 12 s" |
| autocast | lancement auto | |
| champion | champion / championne | |
| helper | assistant | Wizard's helpers (T3) |
| titan | titan | |
| tavern | taverne | |
| bounty | prime | "bounty flag" = drapeau de prime |
| hire / revive / dismiss | engager / ranimer / renvoyer | |
| purse | bourse | champion's purse |
| trade | commerce | "Trade and guilds" = Commerce et guildes |
| trading post | comptoir | |
| caravan | caravane | |
| route | route | |
| Bazaar | Bazar | building name: "Ember Bazaar" stays English |
| guild | guilde | |
| shop | boutique | the item shop window = Boutique |
| item | objet | |
| artifact | artéfact | Québec spelling (OQLF) |
| recipe | recette | |
| inventory | inventaire | |
| level / XP | niveau / XP | "Niv. 3" in tight badges |
| spell point | point de sort | |
| veterancy | vétérance | rank names stay as written in the lore |
| attack-move | attaque-déplacement | |
| hold (position) | tenir la position | |
| stop | arrêter | |
| gather | récolter | |
| rally point | point de ralliement | |
| control group | groupe | |
| build / train / upgrade | construire / former / améliorer | |
| queue | file | "file d'attente" when space allows |
| cancel | annuler | |
| objective (primary / secondary) | objectif (principal / secondaire) | |
| briefing | briefing → **ordre de mission** | |
| mission / campaign | mission / campagne | |
| skirmish | escarmouche | "Skirmish 1v1" = Escarmouche 1 c. 1 → kept short: **Escarmouche 1v1** |
| Wave Strike | Wave Strike | mode name stays (proper name) |
| victory / defeat | victoire / défaite | |
| surrender / concede | abandonner | |
| score | pointage | Québec usage |
| difficulty Easy / Normal / Hard | Facile / Normal / Difficile | |
| settings | paramètres | |
| Unit Guide | Guide des unités | |
| kingdom | royaume | Fire / Ice / Nature / Shadow = Feu / Glace / Nature / Ombre |
| pros / cons | forces / faiblesses | Unit Guide |
| fog of war | brouillard de guerre | |
| minimap | minicarte | |
| map | carte | |
| watchtower / well / shrine | tour de guet / puits / sanctuaire | capture points |
| neutral camp | camp neutre | |
| beast | bête | |

## Proper names (never translated)
Characters (Vessa, Malrik, Torvald, Isolde, Old Vey...), unit, building, champion, item and spell names from the
lore, places (Crown Hollow, Thornwater, Greywater...), the Ember Crown, the Magpies. Exceptions (generic words used
as names): **Keep = Donjon**, **Caravan = Caravane**, **Ice Wall = Mur de glace**, the tier names above.
Voice audio stays English; subtitles (dialogue text) are translated.
