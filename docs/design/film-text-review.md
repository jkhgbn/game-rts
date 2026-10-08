# Film and scene text review (2026-10-08)

For the game designer: every spoken line of the films and in-mission scenes built on the nights of 2026-10-07 and
2026-10-08, so each one can be approved or rewritten. Nothing here changes the story by itself: the lines are in the
game now (voiced by Voice Forge, French in `data/i18n/fr/campaign.po` / `dialogue.po`), and the points in section 1
are open questions, not decisions.

How to read the tables (section 3):
- **Id** = `<scene id>.<n>` (n = order in the scene). The text lives in `data/cinematics/src/<scene id>.cine`; for
  between-scenes also in `data/voice/lines/<scene id>.json`; for in-mission scenes the same text is a line of the
  mission script (`CINE_LINES` / `DIALOGUE`).
- **Beat** = the shot id and the scene author's note on that shot (the spec beat it stages). The scene's spec source
  is under its heading.
- **In a design doc?** = "yes" when the English text (minus its final `.`, `!` or `?`) appears word for word in a
  `docs/design/*.md` file (spec line or draft quote); "**no**" = written by the scene author (or reworded): read those
  first. 220 lines, 178 found in a doc, 42 not.
- French: written by the scene authors (Quebec register, names kept in English per the glossary), not yet reviewed by
  a French reader.

To change a line: edit the `.cine` (and the lines `.json` / mission script holding the same text), then re-run
`tools\voice_forge\run_voice_forge.ps1 build match=<scene id>`, `tools/i18n/extract_strings.gd -- merge` + the French,
and `tools\cine\run_cine.ps1 build <scene id>` (+ `tools/cine/cine_stage_export.gd -- <id>` for a between-scene).

## 1. Open questions for the designer (story, flagged, not decided)

| # | Scene | Point | Why it is flagged |
|---|---|---|---|
| 1 | `c_e2_ashes` | The spec gives beats only: all 12 lines were written tonight (3 of them, "Not tonight.", "Keep it until the wood can." and "On the way down.", are spec words). | Every line needs approval. |
| 2 | `c_e2_ashes` | Ysolde counts "Forty-one. Forty-two. Forty-three." over her dead. | The number of Nature's dead is invented. |
| 3 | `c_e2_ashes` | The beat "Vey and Vessa: 'On the way down.'" is staged as Vessa "You still owe me a story, old man." / Vey "On the way down." | `c_e2_stair` pays the same words off ("And when were you going to tell me?" / "On the way down."): is the echo wanted, or should one of them change? |
| 4 | `c_e2_ashes` | Ysolde's joining is said outright: "The wood can't fight this winter. I can." ... "Then it's enough. We march with Fire." | The spec says she joins Fire; the wording of that decision is new. |
| 5 | `c_e2_ashes` | The seed pod: she hands it to Vessa ("Keep it until the wood can."). | The spec says "gives Vessa the seed-pod token back": no earlier scene shows Vessa holding it. |
| 6 | `c_e2_lodge` | Lines built from the spec's draft quotes; Vessa's opener "All three of them, pointing at the floor." and "Then we walk in blind." are new. | Approve wording. |
| 7 | `c_e2_lodge` | The last beat "cut to the salt road at dawn" is not in the film (e2m3's own first scene `e2m3_road` shows the road). Pell is only his cart (no Pell model). | Staging cut, confirm. |
| 8 | `c_e2_stair` | New lore: "Ashby says the seal was older than the keep." / Vey "Older than the kingdom. He sealed it the day he took the throne." | The day the Master sealed the stair is not in any doc. |
| 9 | `c_e2_stair` | Vey's half-story lines ("Before the four of you, there was a sword. I was the sword." / "I stood behind his throne when kings still knelt to it.") paraphrase the spec beat; "And the lightning? No kingdom throws lightning." leads into the spec quote. | Approve wording. |
| 10 | `c_e2_stair` | Vey's last line "Mind the seventh step. It bites." (dry humour, the film's button). | Added, not in the beats. |
| 11 | `c_e2_stair` | Wren speaks for the first time ("Vessa! Word from Ysolde." / "Nature's army follows you down. All of it that can still walk."), with the voice of `ep2_opening`'s messenger (alias `wren` in `data/voice/cast.json`). | Assumes Wren is that messenger (`ep2_opening.cine` says so); confirm the voice. |
| 12 | `c2_two_fronts` | Shot 4 (Pell's branch, flag `m1_peddler_freed`) is not in the film: StoryFlow cannot branch a film. | Needs a branch in StoryFlow (or two film variants): a lead decision. |
| 13 | `c3_parley` | The companion branch (the first-hired living champion behind Vessa) and the four banner bearers are not in the film. | Same as 12. |
| 14 | `c1_offer`, `c2_two_fronts`, `c3_parley` | Four spec lines longer than the 2 x 48 subtitle limit were split in two at a sentence break (c1 shot 7, c2 shot 5, c3 shots 3 and 5). Words unchanged. | Confirm the split points. |
| 15 | `c1_offer` | The Rime Keep throne hall (19.V7) is not built: the scene plays in the Ice keep's open court at night, Torvald before an ice throne prop. Malrik's "Cold in here." is said outdoors. | Either accept the stand-in or build the hall set; the line may read oddly outside. |
| 16 | `c3_parley` | The Fallen Colossus parley ground (19.V9) is a stand-in (the Emberfall watch-keep's south road + a fallen stone-face prop); the last shot (camp fires on both banks of the Hollowmere, the amber glow under the isle) became a night grade over the empty stone with one amber pulse. | Set and last shot differ from the spec. |
| 17 | `c2_two_fronts` | The war camp / command tent (19.V8) is the watch-keep court at night (table by a brazier); the grove shots use Ysolde's prologue set. | Stand-in sets. |
| 18 | `m3_parting` | The narrator line is the reworded one in `mission_03.gd` today ("Fire is at war with Shadow, while Ice and Nature watch. Under the world, something is counting."), not the spec's ("Fire at war with Shadow. Ice and Nature watching. And under the world, something counting."). | The rewording is another agent's uncommitted change in `mission_03.gd` / `campaign.po`; the film follows it. |
| 19 | `ep2_ending` | Its 9 lines had no French (no lines file); `data/voice/lines/ep2_ending.json` and their French were added tonight. "All four of you, or none." = "Vous quatre, ou personne." | The episode's key line: check the French. |
| 20 | `c_e3_knife` | 7 of its 9 lines are not in a doc (the scene author wrote them from the beats on 2026-10-07): Malrik's father and the grave clay, the axle pins, "Sleep well, Bishop. Someone won't." | Approve, like 1. |
| 21 | `c_e3_doubt` | Aldra's report lines and Torvald's "He is counting us." / "What did it cost you, Malrik? In Duskbarrow." are new wording around the spec quotes. | Approve wording. |

## 2. Counts

| Group | Scenes | Lines | Not in a doc |
|---|---|---|---|
| Written tonight (Ep1 between, Ep2 between, m3_parting) | 7 | 84 | 27 |
| Last two nights (Ep3 between and intros, e2 / e3 / m1 / m3 / m4 in-mission scenes, ep2 / ep3 endings) | 43 with lines (46 scenes) | 136 | 15 |

## 3. Every line

## Written tonight (2026-10-08): Episode 1 between-scenes

### `c1_offer` (source: docs/design/story-episode-1.md 7.2 `c1_offer`, mission-02.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c1_offer.1 | narrator | Two days after Emberfall, the Bishop of Shadow went north. | Deux jours après Emberfall, l'Évêque de l'Ombre est monté vers le nord. | O1: Along the outer wall in the snow: the guards at the gate, wind | yes |
| c1_offer.2 | malrik | Cold in here. You should let Vessa redecorate. She's very keen on fire. | Il fait froid ici. Tu devrais laisser Vessa refaire la déco. Elle adore le feu. | O2: From behind the throne, down the court: violet mist at the gate, Malrik steps out of it | yes |
| c1_offer.3 | torvald | You sent knives after her in the night, and missed. You call that a visit? | Tu as envoyé des couteaux après elle en pleine nuit, et tu l'as ratée. Tu appelles ça une visite ? | O3: CU Torvald: he does not move | yes |
| c1_offer.4 | malrik | Your lake holds the second relic. She'll come for it. Help me stop her. | Ton lac garde la deuxième relique. Elle va venir la chercher. Aide-moi à l'arrêter. | O4: Beside Malrik as he walks to the map table; the violet marker on Glasswater Mere | yes |
| c1_offer.5 | torvald | Ice does not march for your mistakes, Bishop. | La Glace ne marche pas pour réparer tes erreurs, l'Évêque. | O5: Two-shot over the table | yes |
| c1_offer.6 | malrik | Not mistakes. Opportunities. Just until the relics are in sensible hands. | Pas des erreurs. Des occasions. Juste le temps que les reliques soient entre des mains raisonnables. | O5: Two-shot over the table | yes |
| c1_offer.7 | torvald | Sensible hands. Yours. | Des mains raisonnables. Les tiennes. | O6: CU Torvald, three seconds of silence first | yes |
| c1_offer.8 | malrik | Ours, if you like. | Les nôtres, si tu préfères. | O6: CU Torvald, three seconds of silence first | yes |
| c1_offer.9 | torvald | No. My lake stays out of your war. | Non. Mon lac reste en dehors de ta guerre. | O7: Low angle: Torvald rises; frost crawls over the table and seals the marker in ice | yes |
| c1_offer.10 | torvald | And hear me: some doors under Crown Hollow are closed for a reason. | Et écoute-moi bien : certaines portes sous Crown Hollow sont fermées pour une raison. | O7: Low angle: Torvald rises; frost crawls over the table and seals the marker in ice | yes |
| c1_offer.11 | malrik | For now, then. Doors are only closed until someone opens them. | Pour l'instant, alors. Une porte n'est fermée que jusqu'à ce que quelqu'un l'ouvre. | O8: Over Torvald's shoulder on Malrik, half-turned: he melts into mist | yes |
| c1_offer.12 | narrator | Ice said no. For now. | La Glace a dit non. Pour l'instant. | O9: Wide of the court, Torvald alone; the sealed marker glows through the ice | yes |

### `c2_two_fronts` (source: docs/design/story-episode-1.md 7.2 `c2_two_fronts`, mission-02.md / mission-03.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c2_two_fronts.1 | narrator | Two relics. One enemy. One very tired army. | Deux reliques. Un ennemi. Une armée très fatiguée. | S1: the war camp at night | yes |
| c2_two_fronts.2 | ashby | Shadow is massing on the Dusk road. Ice keeps to its lakes. Nature has closed its borders. | L'Ombre se masse sur la route de Dusk. La Glace reste à ses lacs. La Nature a fermé ses frontières. | S2: Over the war table: red tokens in the south-west, violet massing in the east, blue and green apart | yes |
| c2_two_fronts.3 | vessa | So it's me and Malrik. | Donc c'est moi contre Malrik. | S3: - | yes |
| c2_two_fronts.4 | ashby | And whatever he sends in the night, my queen. | Et tout ce qu'il enverra dans la nuit, ma reine. | S4: - | yes |
| c2_two_fronts.5 | vessa | His scouts are already in Ysolde's wood. The third relic sleeps there. | Ses éclaireurs sont déjà dans le bois d'Ysolde. La troisième relique y dort. | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.6 | vessa | I go before he gets it. | J'y vais avant qu'il la prenne. | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.7 | ashby | Ysolde doesn't take sides. | Ysolde ne prend pas parti. | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.8 | vessa | Then she won't mind. I'll ask nicely. | Alors ça ne la dérangera pas. Je vais demander gentiment. | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.9 | ashby | With fire? | Avec du feu ? | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.10 | vessa | Nicely. With fire. | Gentiment. Avec du feu. | S5: Dolly around the table: Vessa taps the forest between the fronts | yes |
| c2_two_fronts.11 | whisper | The third sleeps in the old tree. Bring them together, and you'll never need a friend again. | La troisième dort dans le vieil arbre. Réunis-les, et tu n'auras plus jamais besoin d'un ami. | S6: By the campfire, Vessa alone; the crown and the orb on a cloth beside her pulse in time | yes |
| c2_two_fronts.12 | vessa | Who's there? ...Great. Now the jewellery talks. Vey would have laughed at me. | Qui est là ? ...Super. Maintenant les bijoux parlent. Vey aurait ri de moi. | S7: CU Vessa looking around: the fire pops, nobody there | yes |
| c2_two_fronts.13 | ysolde | Not you, Vessa. Not Malrik. Not ever. | Pas toi, Vessa. Pas Malrik. Jamais. | S8B: - | yes |
| c2_two_fronts.14 | narrator | The war was coming to the Sighing Wood, invited or not. | La guerre arrivait au Sighing Wood, invitée ou non. | S9: Wide on the moonlit forest, wind in the canopy | yes |

### `c3_parley` (source: docs/design/story-episode-1.md 7.2 `c3_parley`, mission-03.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c3_parley.1 | narrator | For the first time since the Master left, the four apprentices stood in one place. | Pour la première fois depuis le départ du Maître, les quatre apprentis se tenaient au même endroit. | P1: Crane down past the Fallen Colossus's stone face: four banners around a flat stone | yes |
| c3_parley.2 | malrik | Look at us. The Master would weep. Mostly at your outfits. | Regardez-nous. Le Maître en pleurerait. Surtout à cause de vos tenues. | P2: Wide, high: the four walk in from four directions and stop around the stone | yes |
| c3_parley.3 | vessa | The relics aren't a prize. They're a lock. | Les reliques ne sont pas un trophée. C'est une serrure. | P3: CU Vessa | yes |
| c3_parley.4 | vessa | Someone is under Crown Hollow, and he's been whispering to me since Emberfall. | Quelqu'un est sous Crown Hollow, et il me chuchote à l'oreille depuis Emberfall. | P3: CU Vessa | yes |
| c3_parley.5 | ysolde | Obren. The first apprentice. Every battle over the relics feeds him. | Obren. Le premier apprenti. Chaque bataille pour les reliques le nourrit. | P4: CU Ysolde | yes |
| c3_parley.6 | ysolde | And something down there is still fighting him. I feel it through the roots. | Et quelque chose, là-dessous, le combat encore. Je le sens à travers les racines. | P4: CU Ysolde | yes |
| c3_parley.7 | malrik | A secret apprentice under the lake. | Un apprenti secret sous le lac. | P5: CU Malrik, amused | yes |
| c3_parley.8 | malrik | And the cure is that I stop the war I'm winning. How convenient. | Et le remède, c'est que j'arrête la guerre que je suis en train de gagner. Comme c'est pratique. | P5: CU Malrik, amused | yes |
| c3_parley.9 | torvald | She is not lying, Bishop. I have felt it under the ice. Something counting. | Elle ne ment pas, l'Évêque. Je l'ai senti sous la glace. Quelque chose qui compte. | P6: Two-shot Torvald / Malrik | yes |
| c3_parley.10 | malrik | Then let it count. Whoever holds the Hollow holds the Master's seat. I intend to sit in it. | Alors qu'il compte. Qui tient le Hollow tient le siège du Maître. J'ai l'intention de m'y asseoir. | P6: Two-shot Torvald / Malrik | yes |
| c3_parley.11 | vessa | You sent knives in the night. You took Vey from me. You'll have to go through me. | Tu as envoyé des couteaux dans la nuit. Tu m'as pris Vey. Il va falloir me passer sur le corps. | P7: Profile two-shot: Vessa steps nose to nose with Malrik | yes |
| c3_parley.12 | malrik | That was always the plan, little ember. | C'était le plan depuis le début, petite braise. | P7: Profile two-shot: Vessa steps nose to nose with Malrik | yes |
| c3_parley.13 | vessa | Help me stop him. | Aidez-moi à l'arrêter. | P8: Vessa turns to the other two | yes |
| c3_parley.14 | torvald | Ice stays out of this war. | La Glace reste en dehors de cette guerre. | P8: Vessa turns to the other two | yes |
| c3_parley.15 | ysolde | Nature too. Win it or lose it without us. | La Nature aussi. Gagnez-la ou perdez-la sans nous. | P8: Vessa turns to the other two | yes |
| c3_parley.16 | malrik | Crown Hollow. At dawn. | Crown Hollow. À l'aube. | P9: Wide as the four walk apart; the banners pulled up | yes |
| c3_parley.17 | vessa | Bring your army. I'll bring mine. | Amène ton armée. J'amènerai la mienne. | P9: Wide as the four walk apart; the banners pulled up | yes |
| c3_parley.18 | narrator | At dawn, the war would come home to where it started. | À l'aube, la guerre rentrerait là où elle avait commencé. | P10: Night over the empty stone: one amber pulse under it | yes |

## Written tonight (2026-10-08): Episode 2 between-scenes

### `c_e2_ashes` (source: docs/design/mission-e2-01.md Cinematic hooks `c_e2_ashes`, campaign-outline.md 3.2)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e2_ashes.1 | ysolde | Forty-one. Forty-two. Forty-three. | Quarante et un. Quarante-deux. Quarante-trois. | A2: MS Ysolde at the burn, counting | **no** |
| c_e2_ashes.2 | ysolde | No jokes tonight? | Pas de blagues ce soir ? | A3: Vessa walks up and stops beside her; no joke | **no** |
| c_e2_ashes.3 | vessa | Not tonight. | Pas ce soir. | A3: Vessa walks up and stops beside her; no joke | yes |
| c_e2_ashes.4 | ysolde | Torvald didn't come for my wood. He came for your relics. | Torvald n'est pas venu pour mon bois. Il est venu pour tes reliques. | A4: Ysolde turns to her: Torvald, the relics, the Hollow | **no** |
| c_e2_ashes.5 | ysolde | Malrik told him the Hollow is waking. He's right. I hear it under the roots. | Malrik lui a dit que le Hollow s'éveille. Il a raison. Je l'entends sous les racines. | A4: Ysolde turns to her: Torvald, the relics, the Hollow | **no** |
| c_e2_ashes.6 | vessa | Then don't stand here alone. Come with us. | Alors ne reste pas seule ici. Viens avec nous. | A5: - | **no** |
| c_e2_ashes.7 | ysolde | The wood can't fight this winter. I can. | Le bois ne peut pas combattre cet hiver. Moi, je peux. | A6: Two-shot: the seed pod | **no** |
| c_e2_ashes.8 | ysolde | Keep it until the wood can. | Garde-la jusqu'à ce que le bois puisse la garder. | A6: Two-shot: the seed pod | yes |
| c_e2_ashes.9 | maelis | This is all of us who can still hold a bow. | Voici tous ceux d'entre nous qui peuvent encore tenir un arc. | A7: Wide from the burn: Maelis walks out of the dark with the survivors | **no** |
| c_e2_ashes.10 | ysolde | Then it's enough. We march with Fire. | Alors ça suffit. Nous marchons avec le Feu. | A8: - | **no** |
| c_e2_ashes.11 | vessa | You still owe me a story, old man. | Tu me dois encore une histoire, vieil homme. | A9: Vey and Vessa, aside | **no** |
| c_e2_ashes.12 | vey | On the way down. | En descendant. | A9: Vey and Vessa, aside | yes |

### `c_e2_lodge` (source: docs/design/mission-e2-02.md Cinematic hooks `c_e2_lodge`, campaign-outline.md 3.2)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e2_lodge.1 | vessa | All three of them, pointing at the floor. | Les trois. Et elles pointent toutes le plancher. | L2: CU the relics: crown, orb, signet, each driving a thin light DOWN through the map | **no** |
| c_e2_lodge.2 | vey | Not the floor. Under it. The old Warden roads run down there. | Pas le plancher. En dessous. Les vieilles routes des Wardens passent là-dessous. | L3: Vey at the table's east end | **no** |
| c_e2_lodge.3 | vey | Nobody living has walked them. | Personne de vivant ne les a parcourues. | L3: Vey at the table's east end | **no** |
| c_e2_lodge.4 | vessa | Then we walk in blind. | Alors on y va à l'aveugle. | L4: Wide three-shot: Vessa across the table, Ysolde and Vey at the ends | **no** |
| c_e2_lodge.5 | vey | Not quite. The Greywater Lodge has mapped the deep for a hundred years. | Pas tout à fait. Le Greywater Lodge cartographie les profondeurs depuis cent ans. | L4: Wide three-shot: Vessa across the table, Ysolde and Vey at the ends | **no** |
| c_e2_lodge.6 | vey | They sell that map to nobody. | Cette carte, ils ne la vendent à personne. | L4: Wide three-shot: Vessa across the table, Ysolde and Vey at the ends | **no** |
| c_e2_lodge.7 | ysolde | They sell everything to somebody. | Ils vendent tout à quelqu'un. | L5: - | yes |
| c_e2_lodge.8 | vey | Gold. Six wagons of it, delivered to their door, past the Magpies and Malrik's knives. | De l'or. Six chariots, livrés à leur porte, au nez des Magpies et des couteaux de Malrik. | L6: - | yes |
| c_e2_lodge.9 | vessa | Gold? We have crystals. Lots of crystals. | De l'or ? On a des cristaux. Plein de cristaux. | L7: - | **no** |
| c_e2_lodge.10 | pell | Did somebody say a trade road? | Quelqu'un a parlé d'une route de commerce ? | L8: Over the table toward the gate: a cart rattles in out of the dark | yes |

### `c_e2_stair` (source: docs/design/mission-e2-03.md Cinematic hooks `c_e2_stair`, campaign-outline.md 3.2)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e2_stair.1 | vessa | Ashby says the seal was older than the keep. | Ashby dit que le sceau était plus vieux que le donjon. | T2: From the steps, looking up at Vessa on the rim | **no** |
| c_e2_stair.2 | vey | Older than the kingdom. He sealed it the day he took the throne. | Plus vieux que le royaume. Il l'a scellé le jour où il a pris le trône. | T3: Two-shot, they turn to each other | **no** |
| c_e2_stair.3 | vessa | You talk about the Master like you knew him before we did. | Tu parles du Maître comme si tu l'avais connu avant nous. | T4: CU Vessa: she knows that tone | **no** |
| c_e2_stair.4 | vey | Before the four of you, there was a sword. I was the sword. | Avant vous quatre, il y avait une épée. J'étais cette épée. | T5: CU Vey: the sword before the four | **no** |
| c_e2_stair.5 | vey | I stood behind his throne when kings still knelt to it. | Je me tenais derrière son trône quand les rois s'y agenouillaient encore. | T5: CU Vey: the sword before the four | **no** |
| c_e2_stair.6 | vessa | And the lightning? No kingdom throws lightning. | Et la foudre ? Aucun royaume ne lance la foudre. | T6: Two-shot: the lightning | **no** |
| c_e2_stair.7 | vey | It's his storm, not mine. He lent it to me to keep you four alive. | C'est sa tempête, pas la mienne. Il me l'a prêtée pour vous garder en vie, tous les quatre. | T6: Two-shot: the lightning | yes |
| c_e2_stair.8 | vessa | And when were you going to tell me? | Et tu comptais me le dire quand ? | T7: - | yes |
| c_e2_stair.9 | vey | On the way down. | En descendant. | T8: - | yes |
| c_e2_stair.10 | wren | Vessa! Word from Ysolde. | Vessa ! Un message d'Ysolde. | T9: From the stair toward the gate: Wren runs in from the road | **no** |
| c_e2_stair.11 | wren | Nature's army follows you down. All of it that can still walk. | L'armée de la Nature te suit en bas. Tout ce qui peut encore marcher. | T10: - | **no** |
| c_e2_stair.12 | vessa | Then we don't keep them waiting. | Alors on ne les fait pas attendre. | T11: - | **no** |
| c_e2_stair.13 | vey | Mind the seventh step. It bites. | Attention à la septième marche. Elle mord. | T12: High behind them over the rim: they start down the steps into the glow (crosses the axis after a dip to black) | **no** |

## Written tonight (2026-10-08): m03 in-mission scene

### `m3_parting` (source: docs/design/story-episode-1.md 7.2, mission-03.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m3_parting.1 | ysolde | I warned you. You didn't listen. Neither did he. | Je t'avais prévenue. Tu n'as pas écouté. Lui non plus. | P1: WIDE: the gate's dust settling, Ysolde out of the roots beside Vessa | yes |
| m3_parting.2 | vessa | Then help me stop it. Please. | Alors aide-moi. Je t'en prie. | P2: Over Ysolde's shoulder on Vessa | yes |
| m3_parting.3 | ysolde | Nature doesn't take sides, Vessa. | La Nature ne prend pas parti, Vessa. | P2: Over Ysolde's shoulder on Vessa | yes |
| m3_parting.4 | ysolde | But when your war comes for my wood, and it will, remember that I warned you both. | Mais quand ta guerre viendra pour mon bois, et elle viendra, rappelle-toi que je vous ai prévenus. | P3: CU Ysolde: the warning | yes |
| m3_parting.5 | narrator | Fire is at war with Shadow, while Ice and Nature watch. Under the world, something is counting. | Le Feu est en guerre contre l'Ombre, et la Glace et la Nature regardent. Sous le monde, quelque chose compte. | P4: Vessa alone with the Signet: Ysolde sinks into the roots, slow orbit out | **no** |

## Last two nights: Episode 3 between-scenes

### `c_e3_knife` (source: docs/design/mission-e3-02.md, Cinematic hooks `c_e3_knife`; beats for its writer E3M2.D1, campaign-outline.md 3.3 "Hush and Malrik after Evenmead")

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e3_knife.1 | malrik | Ford mud. My father said the same of grave clay: it never comes off. | La boue du gué. Mon père disait la même chose de la glaise des tombes : ça ne part jamais. | K2: Malrik scrapes the ford mud off his boots | **no** |
| c_e3_knife.2 | malrik | You missed her, at Emberfall. | Tu l'as manquée, à Emberfall. | K3: Hush is already behind him; he does not turn | yes |
| c_e3_knife.3 | hush | Once. | Une fois. | K3: Hush is already behind him; he does not turn | yes |
| c_e3_knife.4 | hush | Once is enough to remember, Bishop. Who is it tonight? | Une fois, ça suffit pour s'en souvenir, Évêque. C'est qui, ce soir ? | K4: - | **no** |
| c_e3_knife.5 | malrik | Not who. What. Four wagons on the south hill, one token each. | Pas qui. Quoi. Quatre chariots sur la colline sud, un jeton chacun. | K5: The map of the south camp; four wooden tokens, one per wagon | **no** |
| c_e3_knife.6 | malrik | Bring me back their axle pins. | Rapporte-moi leurs goupilles d'essieu. | K5: The map of the south camp; four wooden tokens, one per wagon | **no** |
| c_e3_knife.7 | torvald | You send a knife at farmers' carts, Malrik. | Tu envoies un couteau contre des charrettes de paysans, Malrik. | K6: Torvald watches from his pavilion | **no** |
| c_e3_knife.8 | malrik | At an army's supper, Torvald. Hungry soldiers go home. | Contre le souper d'une armée, Torvald. Les soldats affamés rentrent chez eux. | K7: - | **no** |
| c_e3_knife.9 | hush | Sleep well, Bishop. Someone won't. | Dors bien, Évêque. Quelqu'un, lui, ne dormira pas. | K8: Hush takes the tokens and is gone | **no** |

### `c_e3_price` (source: docs/design/mission-e3-02.md, Cinematic hooks `c_e3_price`; beats for its writer E3M2.D1)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e3_price.1 | malrik | I did not ask you anything. | Je ne t'ai rien demandé. | P2: Malrik alone; the stone pulses without being asked | **no** |
| c_e3_price.2 | shade | Duskbarrow, Bishop. The barrow candles have gone out. The dead are walking. | Duskbarrow, Évêque. Les chandelles des tertres se sont éteintes. Les morts marchent. | P3: A rider in Shadow colours comes up the ridge | yes |
| c_e3_price.3 | malrik | Whose dead? | Les morts de qui ? | P4: - | yes |
| c_e3_price.4 | shade | Yours. | Les vôtres. | P5: - | yes |
| c_e3_price.5 | hush | Shall I come? | Je viens ? | P7: Hush is behind him, as always | yes |
| c_e3_price.6 | malrik | Always. | Toujours. | P7: Hush is behind him, as always | yes |
| c_e3_price.7 | torvald | Go. I will keep your ridge cold. | Va. Je garderai ta crête froide. | P8: Torvald at his door | yes |

### `c_e3_doubt` (source: docs/design/mission-e3-03.md, Cinematic hooks `c_e3_doubt`; beats for its writer E3M3.D1)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| c_e3_doubt.1 | aldra | The old storm-sword crossed the river twice today. | La vieille épée-tempête a traversé la rivière deux fois aujourd'hui. | D2: Torvald's pavilion: Aldra's report | **no** |
| c_e3_doubt.2 | aldra | He only looked at the ridge. Then he went back. | Il a seulement regardé la crête. Puis il est reparti. | D2: Torvald's pavilion: Aldra's report | **no** |
| c_e3_doubt.3 | torvald | He is counting us. | Il nous compte. | D3: - | **no** |
| c_e3_doubt.4 | torvald | What did it cost you, Malrik? In Duskbarrow. | Combien ça t'a coûté, Malrik ? À Duskbarrow. | D6: - | **no** |
| c_e3_doubt.5 | malrik | A little. Less than you would think. | Un peu. Moins que tu le penses. | D7: "A little." The stone glows again as he says it | yes |
| c_e3_doubt.6 | aldra | It glowed when he lied. | Elle a brillé quand il a menti. | D8: He leaves; Aldra speaks once he is gone | yes |
| c_e3_doubt.7 | torvald | I know. I saw. | Je sais. Je l'ai vu. | D8: He leaves; Aldra speaks once he is gone | yes |

## Last two nights: Episode 3 intro scenes

### `e3m2_slip` (source: docs/design/mission-e3-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m2_slip.1 | narrator | Night on Lark Hill. Two armies asleep in their armour, and one woman who never sleeps. | La nuit sur Lark Hill. Deux armées endormies dans leurs armures, et une femme qui ne dort jamais. | S1: WIDE from the north-east bank: moonlight on the water, the squad crouched at its marks beyond it | yes |

### `e3m3_homecoming` (source: docs/design/mission-e3-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m3_homecoming.1 | narrator | Duskbarrow. The city of the dead, where Malrik learned to read by tombstone light. | Duskbarrow. La cité des morts, où Malrik a appris à lire à la lueur des pierres tombales. | H1: CRANE down from above the Seat: candle-lit windows, the city falling away south | yes |

### `e3m4_return` (source: docs/design/mission-e3-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m4_return.1 | narrator | Three days later. Malrik came back from Duskbarrow to a ridge that smelled of thunder. | Trois jours plus tard. Malrik est revenu de Duskbarrow vers une crête qui sentait l'orage. | R1: WIDE crane from the east bank: the trampled valley, the black fords, the spoiled wagons on the hill | yes |
| e3m4_return.2 | torvald | Every dusk the old man walks down to the river and looks at us. Then he walks away. | Chaque soir, le vieux descend à la rivière et nous regarde. Puis il s'en va. | R2: MS Torvald at his post, frost on his beard | yes |
| e3m4_return.3 | malrik | Looks. Not crosses? | Il regarde. Il ne traverse pas ? | R3: MS Malrik at the Dusk Keep, 3/4-left | yes |
| e3m4_return.4 | torvald | Not yet. I think he was waiting for you. He is polite like that. | Pas encore. Je crois qu'il t'attendait. Il est poli comme ça. | R4: Long lens south up Lark Hill: a lone old figure on the crest, a storm cloud gathering above him | yes |

## Last two nights: Episode 3 in-mission scenes

### `e3m1_ford` (source: docs/design/mission-e3-01.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m1_ford.1 | malrik | The ford is mine. Write it down, Ysolde. You like things that last. | Le gué est à moi. Écris-le, Ysolde. Tu aimes les choses qui durent. | F2: MS the banner-bearer on the ford bar: the violet standard goes in, a violet ring sweeps the zone | yes |

### `e3m1_standard` (source: docs/design/mission-e3-01.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m1_standard.1 | obren | The flag falls. The tree is right there. Take it. TAKE it. | Le drapeau tombe. L'arbre est juste là. Prends-le. PRENDS-LE. | T1: MS the standard: it tips, the green banner falls into the flowers | yes |
| e3m1_standard.2 | torvald | Malrik. Your hand is shaking. Is that you, or the stone? | Malrik. Ta main tremble. C'est toi, ou la pierre ? | T2: Long lens from the standard's base up Lark Hill to the golden tree; the stone beats in Malrik's hand, soft, cl | yes |
| e3m1_standard.3 | malrik | It is me, Torvald. It has always been me. | C'est moi, Torvald. Ça a toujours été moi. | T2: Long lens from the standard's base up Lark Hill to the golden tree; the stone beats in Malrik's hand, soft, cl | yes |

### `e3m1_dusk`

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m1_dusk.1 | malrik | The ford is mine. The tree is not. Not today. | Le gué est à moi. L'arbre, non. Pas aujourd'hui. | D2: MS Malrik, 3/4-left (east of the axis) | yes |
| e3m1_dusk.2 | narrator | The ford fell at dusk. The golden tree still stood. Both hills called it a victory. | Le gué est tombé au crépuscule. L'arbre doré tenait toujours. Les deux collines ont crié victoire. | D4: Long lens up Lark Hill: the crest under the golden tree, one white-gold flicker behind it (Vey) | yes |
| e3m1_dusk.3 | malrik | Tell me to stop again tomorrow, Ysolde. I will not stop. | Dis-moi encore d'arrêter demain, Ysolde. Je n'arrêterai pas. | D5: CU Malrik, front: L23 (the ep3_opening echo), then black | yes |

### `e3m2_embers` (source: docs/design/mission-e3-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|

### `e3m2_dawn` (source: docs/design/mission-e3-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m2_dawn.1 | ysolde | Then the people go south today. All of them. The road is safer than this hill. | Alors les gens partent vers le sud aujourd'hui. Tous. La route est plus sûre que cette colline. | W2: Frontal two-shot on the crest's north face | yes |
| e3m2_dawn.2 | hush | There is always another night, Bishop. | Il y a toujours une autre nuit, Évêque. | W3: Long lens north across the valley to the ridge | yes |
| e3m2_dawn.3 | malrik | And every one of them is mine. | Et chacune d'elles est à moi. | W3: Long lens north across the valley to the ridge | yes |

### `e3m3_offer` (source: docs/design/mission-e3-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m3_offer.1 | obren | They are mine now, Bishop. Ask me nicely, and they kneel. | Ils sont à moi, maintenant, Évêque. Demande-le gentiment, et ils s'agenouillent. | O1: ECU the stone in his hand | yes |
| e3m3_offer.2 | malrik | You raised my dead, and now you sell me the shovel. | Tu as levé mes morts, et maintenant tu me vends la pelle. | O2: MS around him: the Wardens turn their heads toward the stone at once | yes |
| e3m3_offer.3 | obren | Not sell. Lend. You will hardly notice the price. | Pas vendre. Prêter. Tu remarqueras à peine le prix. | O2: MS around him: the Wardens turn their heads toward the stone at once | yes |

### `e3m3_sexton` (source: docs/design/mission-e3-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m3_sexton.1 | obren | Forty years he dug here. Let me give him a body. | Quarante ans qu'il a creusé ici. Laisse-moi lui donner un corps. | X2: The gravestones fly to the yard; the old spade rises | yes |
| e3m3_sexton.2 | malrik | He had one. He wore it out honestly. | Il en avait un. Il l'a usé honnêtement. | X3: LOW: the Sexton stands up and turns toward the crypt | yes |

### `e3m3_rest` (source: docs/design/mission-e3-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m3_rest.1 | hush | Light it, Bishop. Just this once. | Allume-la, Évêque. Juste cette fois. | R3: Two-shot Malrik and Hush, 3/4-left: the taper, the candle put away | yes |
| e3m3_rest.2 | malrik | Not yet. Not while it is listening. | Pas encore. Pas tant qu'elle écoute. | R3: Two-shot Malrik and Hush, 3/4-left: the taper, the candle put away | yes |
| e3m3_rest.3 | narrator | The vigils burned again in Duskbarrow. In the Bishop's pocket, the stone kept count. | Les veilles brûlaient de nouveau à Duskbarrow. Dans la poche de l'Évêque, la pierre tenait le compte. | R4: WIDE: the four vigils burn violet at the barrow doors; the stone pulses once | yes |

### `e3m4_whisper` (source: docs/design/mission-e3-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m4_whisper.1 | obren | Torvald. Old frost. You feel it too. Join us, and nothing will ever melt. | Torvald. Vieux givre. Tu le sens aussi. Rejoins-nous, et plus rien ne fondra jamais. | H2: CU Malrik's coat: amber light through the cloth | yes |
| e3m4_whisper.2 | torvald | ...It knows my name. | ...Elle connaît mon nom. | H3: MS Torvald, 3/4-left, turning his head toward the voice | yes |
| e3m4_whisper.3 | malrik | It knows everyone's name. It is a stone with nothing else to do. | Elle connaît le nom de tout le monde. C'est une pierre qui n'a rien d'autre à faire. | H3: MS Torvald, 3/4-left, turning his head toward the voice | yes |

### `e3m4_field` (source: docs/design/mission-e3-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e3m4_field.1 | vey | That's enough. My storm is borrowed, and I've spent the loan. | Ça suffit. Ma tempête est empruntée, et j'ai dépensé le prêt. | F1: MS Vey on one knee in the trampled grass, the runes going dark | yes |
| e3m4_field.2 | vessa | Vey! Get up! We're not done! | Vey ! Relève-toi ! On n'a pas fini ! | F2: Vessa runs to him; his hand on her shoulder | yes |
| e3m4_field.3 | vey | We are today, girl. Today the ridge is his. | Aujourd'hui, si, ma petite. Aujourd'hui, la crête est à lui. | F2: Vessa runs to him; his hand on her shoulder | yes |
| e3m4_field.4 | malrik | The ridge is mine. The valley next. I will not stop. | La crête est à moi. La vallée ensuite. Je n'arrêterai pas. | F4: MS Malrik on the Bishop's Crest, 3/4-left, the stone glowing in his hand | yes |
| e3m4_field.5 | torvald | No. I don't think you can. | Non. Je ne crois pas que tu le puisses. | F5: MS Torvald at Birch Watch, apart from his Rimeshields, looking at Malrik | yes |
| e3m4_field.6 | narrator | The ridge fell to Shadow. Torvald had heard the stone say his name. He did not forget it. | La crête est tombée aux mains de l'Ombre. Torvald avait entendu la pierre dire son nom. Il ne l'a pas oublié. | F6: Long lens across the valley: the golden tree, untouched | yes |

## Last two nights: Episode 2 in-mission scenes

### `e2m1_arrival` (source: docs/design/mission-e2-01.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m1_arrival.1 | narrator | The Sighing Wood kept out of every quarrel for a century. Now it is ash, and the ash is frozen. | Le Sighing Wood est resté à l'écart de toutes les querelles pendant un siècle. Le voilà en cendres, et la cendre a gelé. | A1: CRANE down over the burned, frosted wood onto the column | yes |
| e2m1_arrival.2 | vessa | Fire AND frost. They didn't just burn it. They made sure it stayed dead. | Le feu ET le givre. Ils ne l'ont pas juste brûlé. Ils se sont assurés qu'il reste mort. | A2: Vessa walks in among the ashes | yes |
| e2m1_arrival.3 | messenger | The Heartwood is past the old tree. She's inside it. | Le Heartwood est derrière le vieil arbre. Elle est dedans. | A3: Slow push north to the dead Oldroot; a faint green pulse at its foot | yes |

### `e2m1_frostwarden` (source: docs/design/mission-e2-01.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m1_frostwarden.1 | aldra | Hold the rime. When the green stops beating, the wood is ours. | Tenez le givre. Quand le vert cessera de battre, le bois sera à nous. | F1: MS Aldra, staff raised; three blue beams into the Heartwood | yes |
| e2m1_frostwarden.2 | torvald | So the little ember comes to warm the wood. You are late, child. Winter got here first. | Alors la petite braise vient réchauffer le bois. Tu arrives trop tard, petite. L'hiver est passé avant toi. | F2: WS over the glade: Torvald on the snow ridge, turning away | yes |

### `e2m1_ysolde` (source: docs/design/mission-e2-01.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m1_ysolde.1 | ysolde | You came. I told you to remember. I didn't think you'd listen. | Tu es venue. Je t'avais dit de te souvenir. Je ne pensais pas que tu écouterais. | Y2: Ysolde steps out and falls to one knee; Vessa catches her | yes |
| e2m1_ysolde.2 | vessa | I never listen. I just show up. | Je n'écoute jamais. Je me présente, c'est tout. | Y2: Ysolde steps out and falls to one knee; Vessa catches her | yes |

### `e2m2_muster` (source: docs/design/mission-e2-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m2_muster.1 | narrator | Nature had no kingdom left, only seed. Fire had a border, and a frost fort sitting on it. | La Nature n'avait plus de royaume, seulement des graines. Le Feu avait une frontière, et un fort de givre assis dessus. | M1: CRANE over the frosted west bank, the Hollowmere dark below, Rimehold's rime beyond the Fire base | yes |
| e2m2_muster.2 | ysolde | Three groves along your line, Vessa. Give me those, and I can give you a kingdom back. | Trois bosquets le long de ta ligne, Vessa. Donne-moi ça, et je peux te redonner un royaume. | M2: MS Ysolde at the Stumpwood ring, the seed-carriers' lanterns | yes |
| e2m2_muster.3 | vessa | Three trees? I can do three trees. Torvald brought a whole fort. That one's mine. | Trois arbres? Je peux faire trois arbres. Torvald a amené un fort au complet. Celui-là est à moi. | M3: From behind Vessa, looking east to Rimehold's spires | yes |

### `e2m2_first_grove` (source: docs/design/mission-e2-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m2_first_grove.1 | maelis | Stumpwood breathes again. The forest remembers who froze it. | Stumpwood respire encore. La forêt se souvient de qui l'a gelée. | G2: MS Maelis touching the Giant's Stump: a green pulse through the roots | **no** |

### `e2m2_heartwood` (source: docs/design/mission-e2-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m2_heartwood.1 | ysolde | Three groves. Enough roots to stand on. Rise. | Trois bosquets. Assez de racines pour tenir debout. Lève-toi. | H2: LOW: the Heartwood bursts out of the snow and grows | yes |
| e2m2_heartwood.2 | vessa | Huh. You grow a castle out of a seed. I have to build mine out of rocks. | Ben voyons. Toi, tu fais pousser un château avec une graine. Moi, je dois bâtir le mien avec des roches. | H3: MS two-shot Vessa and Ysolde at the Heartseed ring | yes |
| e2m2_heartwood.3 | ysolde | Then we each keep the other's. Fire and Nature, one front. | Alors chacune garde celui de l'autre. Le Feu et la Nature, un seul front. | H3: MS two-shot Vessa and Ysolde at the Heartseed ring | yes |

### `e2m2_two_banners` (source: docs/design/mission-e2-02.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m2_two_banners.1 | ysolde | You came when I called, Vessa. Next time, I come when you do. | Tu es venue quand j'ai appelé, Vessa. La prochaine fois, c'est moi qui viens quand tu appelles. | B2: MS Vessa and Ysolde side by side at the Wayshrine | yes |
| e2m2_two_banners.2 | vessa | Deal. And next time, I'll leave your trees alone. | Marché conclu. Et la prochaine fois, je laisse tes arbres tranquilles. | B2: MS Vessa and Ysolde side by side at the Wayshrine | **no** |

### `e2m3_road` (source: docs/design/mission-e2-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m3_road.1 | narrator | The Salt Road runs from Emberfall to the sea. Everything on it has a price, even the road. | La route du sel va d'Emberfall jusqu'à la mer. Tout ce qui s'y trouve a un prix, même la route. | R1: CRANE along the ring road to the north-west corner, salt cairns passing | yes |
| e2m3_road.2 | vessa | Six wagons of gold. I don't own one wagon of gold. I own a lot of rocks. Shiny ones. | Six chariots d'or. J'ai même pas un chariot d'or. J'ai plein de roches. Des brillantes. | R2: MS Vessa at the keep, Pell's cart rattling in behind her | yes |
| e2m3_road.3 | pell | Rocks become gold at a post, my queen. Gold becomes everything else. Trust a professional. | Les roches deviennent de l'or au comptoir, ma reine. L'or devient tout le reste. Faites confiance à un professionnel. | R3: WS: the Lodge's antler gable and the Den's washing lines across the road | yes |

### `e2m3_lodge` (source: docs/design/mission-e2-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m3_lodge.1 | bettany | One wagon. Five to go. The hunters count slow and they count twice. | Un chariot. Encore cinq. Les chasseurs comptent lentement, et deux fois. | L1: MS Bettany at the Lodge door, counting coins | yes |
| e2m3_lodge.2 | vessa | What do they even want all this gold for? | Qu'est-ce qu'ils veulent faire avec tout cet or, au juste? | L2: Wider: Vessa (when she is near) and Bettany | yes |
| e2m3_lodge.3 | bettany | Arrows, mostly. And never having to go down there again. | Des flèches, surtout. Et ne plus jamais avoir à redescendre là. | L2: Wider: Vessa (when she is near) and Bettany | yes |

### `e2m3_paid` (source: docs/design/mission-e2-03.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m3_paid.1 | bettany | Six. Paid in full. Here's your road down: a stair under Emberfall, the Sunrise Road. | Six. Payé au complet. Voici votre route vers le bas : un escalier sous Emberfall, la route de l'Aube. | P1: CU the barrel: an old hide map, a stair under a burnt observatory, a white-gold sun at the bottom | yes |
| e2m3_paid.2 | bettany | Two of ours will guide you. Nobody else has walked it since the Master. | Deux des nôtres vont vous guider. Personne d'autre ne l'a prise depuis le Maître. | P2: MS the two Greywater Trackers shouldering packs | yes |
| e2m3_paid.3 | malrik | A map to the deep. How generous. I'll take it off your body. | Une carte des profondeurs. Comme c'est généreux. Je la prendrai sur ton cadavre. | P3: WS from the Tollgate side: Malrik's army forming up, Malrik looking at the Lodge | yes |

### `e2m4_descent` (source: docs/design/mission-e2-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m4_descent.1 | narrator | The Sunrise Road. The Master cut it before the kingdoms had names. No one has walked it since. | La route de l'Aube. Le Maître l'a taillée avant que les royaumes aient des noms. Personne ne l'a parcourue depuis. | D1: TOP-DOWN down the stair shaft into black | yes |
| e2m4_descent.2 | vessa | It's so dark. Good thing I'm the brightest person I know. | Il fait tellement noir. Heureusement que je suis la personne la plus brillante que je connaisse. | D2: MS Vessa stepping off the last step, her halo lighting the first carvings | yes |
| e2m4_descent.3 | vey | Stay close to the light, girl. Down here the dark has teeth. | Reste près de la lumière, petite. Ici-bas, le noir a des dents. | D3: MS two-shot Vey and Vessa, the quartz veins brightening around Vey | yes |

### `e2m4_first_warden` (source: docs/design/mission-e2-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m4_first_warden.1 | vey | Up, old friend. Your master's walking again. Well. His sword is. | Debout, vieil ami. Ton maître marche de nouveau. Enfin. Son épée, oui. | W2: MS the Warden steps out of its alcove and bows to Vey | yes |

### `e2m4_forge` (source: docs/design/mission-e2-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m4_forge.1 | vessa | The hearth's lit. Ashby, it's yours. Make me things that hit harder. | Le foyer est allumé. Ashby, il est à toi. Fabrique-moi des choses qui frappent plus fort. | F1: LOW: the anvil-altar catches fire from Vessa's hand | yes |
| e2m4_forge.2 | ashby | A Master's forge! My grandad would weep. Then he'd charge you for it. | Une forge du Maître ! Mon grand-père en pleurerait. Puis il vous la facturerait. | F2: WS the work crew coming down the gallery, Ashby at the front | yes |

### `e2m4_hush` (source: docs/design/mission-e2-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m4_hush.1 | hush | The little ember, in the dark. You're a long way from your braziers. | La petite braise, dans le noir. Tu es bien loin de tes braseros. | H2: MS Hush stepping out of the smoke, the amber splinter at her mask | yes |

### `e2m4_sunrise` (source: docs/design/mission-e2-04.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m4_sunrise.1 | narrator | And for the first time in twelve years, the Sunrise Road saw its sunrise. | Et pour la première fois en douze ans, la route de l'Aube a vu son aube. | S1: CU their hands on the carved sun, lightning running into the stone | yes |
| e2m4_sunrise.2 | vey | He's down there. I can feel him. And he's tired, girl. So very tired. | Il est en bas. Je le sens. Et il est fatigué, petite. Tellement fatigué. | S3: MS Vey, eyes closed, listening | yes |
| e2m4_sunrise.3 | vessa | Then we go faster. Wardens, with me. We're going to fetch the Master. | Alors on va plus vite. Gardiens, avec moi. On va chercher le Maître. | S3: MS Vey, eyes closed, listening | yes |
| e2m4_sunrise.4 | malrik | Go on, then. Run ahead. I'll be right behind you, with the key you lack. | Vas-y, alors. Cours devant. Je serai juste derrière, avec la clé qui te manque. | S4: ECU in the dark tunnel north: Malrik's hand around the amber shard | yes |

### `e2m5_cavern` (source: docs/design/mission-e2-05.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m5_cavern.1 | narrator | Under the roots of the world, a door. And on the other side of it, the one who made it. | Sous les racines du monde, une porte. Et de l'autre côté, celui qui l'a faite. | C1: CRANE down from the stair mouth into the cavern: warm wind, the Door's god-rays | yes |
| e2m5_cavern.2 | vessa | That's it. That's the door. Vey, he's right there. Under my feet. | C'est elle. C'est la porte. Vey, il est juste là. Sous mes pieds. | C2: MS Vessa at the stair foot, light on her face | yes |
| e2m5_cavern.3 | vey | Four seals. Wake them with the relics and the door stands. Let Malrik break them and it falls. | Quatre sceaux. Réveille-les avec les reliques et la porte tient. Laisse Malrik les briser et elle tombe. | C3: WS the dais: four grey seals, the Warden host standing still, the jailer-statue over the Door | yes |
| e2m5_cavern.4 | malrik | Good evening, Vessa. Mind the statue. It's been waiting a hundred years to stretch its legs. | Bonsoir, Vessa. Attention à la statue. Elle attend depuis cent ans de se dégourdir les jambes. | C4: Across the Rift: Malrik on his own stair, the amber shard glowing in his fist | yes |

### `e2m5_wake` (source: docs/design/mission-e2-05.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m5_wake.1 | narrator | A hundred years the jailer stood over the door. Tonight Malrik's stone told it to open it. | Cent ans, le geôlier a veillé sur la porte. Ce soir, la pierre de Malrik lui a dit de l'ouvrir. | K1: MS Malrik at the statue's foot, the shard to its ankle; amber light races up the seams | yes |
| e2m5_wake.2 | malrik | Open it, Mason. Let me see what the Master was so busy guarding. | Ouvre-la, Maçon. Que je voie ce que le Maître gardait si jalousement. | K1: MS Malrik at the statue's foot, the shard to its ankle; amber light races up the seams | yes |
| e2m5_wake.3 | vessa | Everyone on the door! Nobody touches it but us! | Tout le monde sur la porte ! Personne n'y touche, à part nous ! | K4: MS Vessa raising the Crown; the seals she holds blaze white-gold | yes |

### `e2m5_answer` (source: docs/design/mission-e2-05.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m5_answer.1 | vey | Feel that? He's pushing back from below. The spark first, Vessa. Then the storm. | Tu sens ça ? Il repousse d'en bas. L'étincelle d'abord, Vessa. Puis l'orage. | A1: CU the Door's surface: white-gold cracks push back the amber | yes |
| e2m5_answer.2 | vessa | Then let's give him something to push with. Door! Light! NOW! | Alors donnons-lui de quoi pousser. Porte ! Lumière ! MAINTENANT ! | A2: MS Vessa and Vey at the rim: his blade blazing, her hands raised | yes |

### `e2m5_fall` (source: docs/design/mission-e2-05.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| e2m5_fall.1 | malrik | Keep your door, Vessa. I have the key, and all the time in the world. | Garde ta porte, Vessa. J'ai la clé, et tout le temps du monde. | F2: MS Malrik at the north ramp, the shard dim, turning away into the dark | yes |
| e2m5_fall.2 | ysolde | It held. Vessa. It held. | Elle a tenu. Vessa. Elle a tenu. | F3: MS Ysolde catching Vessa's arm at the Door | yes |

### `e2m5_breach` (source: docs/design/mission-e2-05.md, Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|

## Last two nights: Episode 1 in-mission scenes (m01, m03, m04)

### `m1_westwatch` (source: docs/design/mission-01.md, events E5)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m1_westwatch.1 | narrator | The Westwatch fire rises. Riders who remember the old kingdom ride to meet it. | Le feu de Westwatch s'élève. Des cavaliers qui se souviennent du vieux royaume accourent. | W1: LOW on the brazier: the flame climbs into the dusk | yes |
| m1_westwatch.2 | malrik | Light all the candles you like. The dark just gets a better view. | Allume toutes les bougies que tu veux. Le noir n'en voit que mieux. | W2: WS: the riders come out of the light, the watch burning behind them | yes |

### `m1_seal` (source: docs/design/mission-01.md events E6; cinematics.md PAUSE list)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m1_seal.1 | narrator | Three flames answer. The seal cracks, and the old wardens wake up grumpy. | Trois flammes répondent. Le sceau se fend, et les vieux gardiens se réveillent grognons. | S1: CU the crown: the seal cracks in white-gold light | yes |
| m1_seal.2 | vessa | I'm here for the crown, not a lecture. Fine. Both. | Je viens pour la couronne, pas pour un sermon. Bon. Les deux. | S3: MS Vessa | yes |

### `m1_crown` (source: docs/design/mission-01.md events E7)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m1_crown.1 | malrik | Put it down. That crown was never meant for someone who throws fire at her problems. | Pose-la. Cette couronne n'a jamais été faite pour qui règle ses problèmes au feu. | C1: MS Vessa crowned: the fire answers the crown | yes |
| m1_crown.2 | vessa | Then it's in the right hands. I throw fire at ALL my problems. | Alors elle est en bonnes mains. Je règle TOUS mes problèmes au feu. | C2: MCU Vessa answering | yes |

### `m1_watchers` (source: docs/design/mission-01.md events E8)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m1_watchers.1 | malrik | Keep it warm for me. The other three will come for it now. | Garde-la au chaud pour moi. Les trois autres vont venir la chercher. | H1: MS Vessa, crowned, the Shadow host pulling back behind her | yes |
| m1_watchers.2 | narrator | Far away, three apprentices feel the crown wake up, and begin to worry. | Au loin, trois apprentis sentent la couronne s'éveiller, et s'inquiètent. | H2: High over Emberfall: four flames far off on the horizon | yes |

### `m3_oldroot` (source: docs/design/story-episode-1.md 7.2, mission-03.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|

### `m3_plea` (source: docs/design/story-episode-1.md 7.2, mission-03.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m3_plea.1 | ysolde | Vessa. Stop. Please. | Vessa. Arrête. Je t'en prie. | Y1: LOW on the roots beside the tree: Ysolde rises out of them | yes |
| m3_plea.2 | vessa | NOW you want to talk? Your wood tried to eat me. | MAINTENANT tu veux parler ? Ton bois a voulu me manger. | Y2: Over Ysolde's shoulder on Vessa | yes |
| m3_plea.3 | ysolde | My wood tries to eat everyone. It's very fair. | Mon bois veut manger tout le monde. C'est très juste. | Y2: Over Ysolde's shoulder on Vessa | yes |
| m3_plea.4 | ysolde | Those relics aren't a prize. They're a lock. | Ces reliques ne sont pas un trophée. C'est une serrure. | Y3: CU Ysolde: the relics are a lock | yes |
| m3_plea.5 | ysolde | Put three together near the Hollow and the door opens. | Réunis-en trois près du Hollow et la porte s'ouvre. | Y3: CU Ysolde: the relics are a lock | yes |
| m3_plea.6 | vessa | Everyone says that about the things I want. And if I leave it, Malrik takes it. | Tout le monde dit ça de ce que je veux. Et si je la laisse, Malrik la prend. | Y4: Two-shot, slow push: Vessa turns to the glowing split | yes |

### `m4_war` (source: docs/design/story-episode-1.md 7.2, mission-04.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m4_war.1 | narrator | Crown Hollow. Where the Master once sat, two armies wait for the sun. | Crown Hollow. Là où siégeait le Maître, deux armées attendent le soleil. | W1: CRANE from 40 m high over the isle down toward the west bank | yes |
| m4_war.2 | malrik | Three relics, little ember. Hand them over and I'll let you keep the hat. | Trois reliques, petite braise. Donne-les et je te laisse le chapeau. | W2: CU Malrik at the east bank | yes |
| m4_war.3 | vessa | Come and take them, Bishop. You owe me for Emberfall. And for Vey. | Viens les prendre, l'Évêque. Tu me dois Emberfall. Et Vey. | W3: CU Vessa | yes |
| m4_war.4 | whisper | Yes. Come, both of you. Fight on my roof. | Oui. Venez, tous deux. Battez-vous sur mon toit. | W4: Vessa along her front line; the moat water shivers amber for a beat | yes |

### `m4_fall` (source: docs/design/story-episode-1.md 7.2, mission-04.md Cinematic hooks)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| m4_fall.1 | obren | The Hollow... remembers... | Le Hollow... se souvient... | F1: CU the heart: cracks race across it | yes |

## Last two nights: episode endings

### `ep2_ending` (source: docs/design/mission-e2-05.md "Cinematic hooks" ep2_ending, campaign-outline 3.2)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| ep2_ending.1 | vessa | Master. Open it. Please. | Maître. Ouvre-la. Je t'en prie. | S2: - | yes |
| ep2_ending.2 | master | My joy. You came all this way. | Ma joie. Tu es venue jusqu'ici. | S4: - | yes |
| ep2_ending.3 | master | I cannot open it. If I let go, what is under me comes up. | Je ne peux pas l'ouvrir. Si je lâche, ce qui est sous moi remonte. | S4: - | yes |
| ep2_ending.4 | master | It takes four hands to turn this lock. | Il faut quatre mains pour tourner cette serrure. | S5: - | yes |
| ep2_ending.5 | vessa | Then tell me how! | Alors dis-moi comment ! | S6: - | yes |
| ep2_ending.6 | master | All four of you, or none. | Vous quatre, ou personne. | S7: - | yes |
| ep2_ending.7 | vey | Especially Malrik. He always said that. | Surtout Malrik. Il disait toujours ça. | S8: the empty stair | yes |
| ep2_ending.8 | narrator | The door held. The war went looking for open ground, | La porte a tenu. La guerre est partie chercher un terrain ouvert, | U1: up into spring | yes |
| ep2_ending.9 | narrator | and found the last green country: Evenmead. | et a trouvé le dernier pays vert : Evenmead. | U1: up into spring | yes |

### `ep3_ending` (source: docs/design/mission-e3-04.md, Cinematic hooks `ep3_ending`; beats for its writer E3M4.D1)

| Id | Speaker | English | French | Beat (shot: the scene's own note) | In a design doc? |
|---|---|---|---|---|---|
| ep3_ending.1 | aldra | You heard it. | Tu l'as entendue. | T03: Torvald by the Ice side; Aldra off screen | yes |
| ep3_ending.2 | torvald | I heard it ask. I did not hear him say no. | Je l'ai entendue demander. Je ne l'ai pas entendu dire non. | T03: Torvald by the Ice side; Aldra off screen | yes |
| ep3_ending.3 | obren | Now the tree. | Maintenant, l'arbre. | N07: Malrik alone on the crest (the N07 mark): the stone whispers | yes |
| ep3_ending.4 | malrik | Tomorrow. | Demain. | N13: Close: he closes his fist on it | yes |
| ep3_ending.5 | malrik | I have heard “stop” all my life. | J'ai entendu « arrête » toute ma vie. | N12: Long lens across the valley to Lark Hill: one white-gold flicker; the old man is still there | **no** |
