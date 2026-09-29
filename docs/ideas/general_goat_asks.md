# JS's asks and prompts: General GOAT list (Elo of Generals)

One place for every prompt and extra idea JS gave for the "greatest general of all time" project. Same format as `jss_asks.md`.
Newest at the top of each section. Status: `todo`, `doing`, `done`, `parked`.
This project is separate from Four Wizards. Its files live outside this repo (see "Where things are" at the bottom).

## Open

| Date | Ask (JS's words, short) | Status | Where |
|---|---|---|---|
| 2026-09-28 | Dynasty Elo with sub-categories, on the SAME site (not a separate one) | done | new "Dynasties" tab: type / region / era filters, family feuds, "Born to it?" lists (`dynasty.py`) |
| 2026-09-28 | Family tree for each general, plus birth / fame / dynasty scores and how much they overachieved from where they were born. Just an extra: must not change the Elo | done | `family.py`, "Family tree and origins" section in each general's popup |
| 2026-09-28 | Check all names and dates: who is the right person, which mistakes are Wikipedia's and which are mine | done | results in "Name and date audit" below; fixes rebuilt into the site |
| 2026-09-28 | Save all asks and prompts where the RTS game saves them, as a general GOAT list | done | this file |

## Done

| Date | Ask | Result |
|---|---|---|
| 2026-09-28 | Update Claude | No separate CLI on this PC; Claude Code updates with the desktop app (restart, or Help → Check for Updates) |
| 2026-09-28 | 10-minute video: top 10 generals from our research, with music, intro for each (before they were famous, why great, best win, worst loss), honorable mentions (5 picked by Claude), use free tools to improve it | `Top10_Generals_in_History.mp4`, 9:40, neural voice (edge-tts), code-generated music, Wikimedia portraits, subtitles. Top 10: Caesar, Napoleon, Wellington, Alexander, Suvorov, Montgomery, MacArthur, Khalid, Nobunaga, Frederick. Mentions: Hannibal, Genghis Khan, Subutai, Han Xin, Yi Sun-sin |
| 2026-09-28 | Popup: add an X so I don't have to scroll up to close | Fixed round × that stays visible while scrolling, plus click-outside and Esc |
| 2026-09-28 | Hand-checked source not loading | Fixed: it only exists in the new data, the Classic (v1) switch now falls back to it |
| 2026-09-28 | Look for the China-type problem in other languages, top 5 or 10 per language, check nobody is "lost" | Plain-text commander fix for all 12 languages; Muhammad and Tilly name links fixed; hand-checked battles for Wei Qing, Li Mu, Wang Jian, Xu Da, Qi Jiguang, Thutmose III, Stephen Báthory; "Battles" column in forum lists |
| 2026-09-28 | Time / era filter from 5000 BC to now (e.g. best general 200–100 BC) | Era presets + custom From/To on the leaderboard |
| 2026-09-28 | English name first, real name in brackets | Done everywhere; pinyin for Chinese names without an English label |
| 2026-09-28 | Add China by hand: ~100 great Chinese generals with extra info (then: use Chinese sources, the top 5 is enough) | Top 5 from Chinese Wikipedia (Han Xin, Li Jing, Yue Fei, Bai Qi, Huo Qubing) with bios; Baidu Baike blocks automated access |
| 2026-09-28 | Does China have its own wiki I don't know of? | Yes: Baidu Baike and Baike.com; both block scraping |
| 2026-09-28 | Crowd vote should be +1 / −1, not ±1000 | Done, with full vote history |
| 2026-09-28 | Rate the sources for bias the same way (who is fair, who can be trusted) | "Trust & bias" tab: Wikipedias as reporters (Dawid–Skene), every ranking scored for agreement, home bias, modern bias |
| 2026-09-28 | Install numpy if faster or more accurate | Installed, used for the prediction tests |
| 2026-09-28 | Check forums for what makes a general great, compare to v1 and the new Elo, improve it | 23 criteria from 24 sources → Great General Index; war records; prediction test (v2 Adjusted best, 70.2%) |
| 2026-09-28 | Elo ignores army size, training, cleverness (traps): update it, keep a save of the current one and show how it changes | v2 Adjusted Elo (army size, casualties, traps, lead commander); Classic kept as v1; "What changed" tab |
| 2026-09-28 | Add +/− on the site that everyone sees, keep all data | Crowd votes (shared database) with history |
| 2026-09-28 | Search for everything | Global search: any general or battle, any language, rank in every language |
| 2026-09-28 | Look at other GOAT lists, compare, verify, dig a little where different | 12 published lists incl. Ethan Arsht; Hannibal / Frederick / MacArthur dug into; campaign bug fixed |
| 2026-09-28 | Check the forums: does the Elo match what they say? | "Do forums agree with Elo?" section, correlation per language |
| 2026-09-28 | Easy top-10 lists, best average per fight (default 5 fights, adjustable), and other things forum people like | Cards: top 10, best average (slider), peak, undefeated, streaks, most battles, upsets, rivalries |
| 2026-09-28 | Give Elo to each fight, show "A +250 vs B" | Every battle log shows gains/losses per commander |
| 2026-09-28 | Search all history forums in all languages, rank generals per language; score every general on Wikipedia battles in all languages; say which language gives the most accurate view | 12 languages, 101,767 Wikipedia pages, forum lists per language, "Most accurate language" tab |

## Name and date audit (2026-09-28)

Checked the 244 people shown on the site (top 100, each language's top 10, all forum names, hand-checked set, the video's 15).

| Problem | Whose mistake | Fixed? |
|---|---|---|
| "Alexander the Great" credited with a battle in 541 AD (another Alexander linked to him); ~2,900 commander entries dated after death or before birth | Wikipedia links (some pages link the wrong person) | Yes: lifespan check drops a commander from a battle outside their life (century-precise dates get 100 years of slack) |
| Persian/Arabic dates like "824 ق" (Islamic calendar = 1421 AD) read as 824 BC; "25 Mehr 1320 ش" read as year 25 | Mine (date parsing) | Yes: Islamic lunar and Persian solar calendars converted |
| "Turenne" matched to a town in Corrèze; "Ariobarzanes" matched to a first name | Mine (name matching via Wikipedia titles) | Yes: now Marshal Turenne and Ariobarzanes of Persis |
| Nelson, Czarniecki, Thutmose III, Scharnhorst, Musashi shown with foreign-language names | Mine (matched through foreign titles) | Yes: matched through English titles |
| "Hannibal" and "Xiang Yu" matched to other people with the same name (an older Hannibal, a modern researcher) | Mine | Yes |
| Attila "born 500, died 453", Bahram Chobin, Cao Shen, Cyaxares impossible lifespans | Mine (Wikidata stores "5th century" as year 500 and I read it as exact) | Shown as "c." now; the lifespan check already allows the slack |
| Bai Qi born −250 in Wikidata (he was born c. 332 BC) | Wikidata | Not changed at the source; his battles are unaffected |
| Khalid ibn al-Walid given 2 losses (e.g. Hira, which he won) | Mine (result parsing) | Flagged on screen in the video; not auto-fixed |
| Cortés, Spartacus, Atatürk, du Guesclin flagged as "not military" | False alarm (my word filter) | Nothing to fix |
| Võ Nguyên Giáp lived 102 years | Correct (1911–2013) | Nothing to fix |
| Impossible careers (battles spread over 70+ years) | none left | — |
| Same battle, different years between languages (visible generals) | none left | — |

## Loose ideas (not asked yet, worth keeping)

- A proper Chinese dataset of ~100 generals if an agent run can be done later (the 5-agent launch failed once).
- Share the site with Contributor access so friends can vote.
- Re-run the audit after any data rebuild.

## Where things are

- Live site (private until shared): https://claude.ai/artifact/71rdmPxYVTo7c2LyfRDEA5
- Pipeline scripts and data: `C:\Users\elzzo\AppData\Local\Temp\gelo\` (temporary folder, copy it somewhere safe to keep it)
- Site files and video: the Claude session folder for this project (move it to a real folder to keep it)

## Prompts (JS's exact words, in order)

1. can u run all internet to do a search all history forum on the and make a rankings of make it big ass search i want all language cover than make a list per language and than i want u look all wikipedia battle for all langueage and give score to all general than lead a army or is name and i want a list per language of user the on fist look at forum than Wikipedia and u can make list of language whif the most accurate view of history
2. give elo to each fight and list like a +250 elo vs b if u think its the best way to ranking
3. make a ez list to see for the first 10 on leaderboard and a overall 10 best battle best aveage per fight default 5 fight but can change and other u think ppl who u the forum would like to see ez
4. once all data is over
5. look at other goat list and compare and verify and if different dig a lil
6. look at forum and see if most elo match what they say and how they compare
7. do china have its own wiki than i dont know off
8. that should be add
9. add something to +or- on the site and keep all date for exemple napoleon num1 +500 -1000 cause dont like him for some reason show to all on the site for all
10. add a seach for all
11. why is elo does not count have army size / how train they are and how off general to train and many thing other update the elo system keep a save of the current and see how they change
12. how smart and they could trap or othey thing to the ennemie
13. check a list off what make i general great compare to v1 off new elo system and see u can improve it on forum
14. instal numpy if faster or more accurute u have access
15. try to build similar system for source auteur evaluate bias and whif all current system and elo and look who more fair and u can trust
16. maybe when current one is finish
17. crown +1or-1 not +1k
18. add china mannuly like look for 100 great china general and look for extra info on all 100 something like that
19. use chinese source from the wedsite could not do all reseach the the top 5
20. try to find traduction of chineses for english when u click on 1 u see english name and (real name) after
21. add time or era on site like from 5kbc to now u can have for exemple best genreral from 100t200 bc
22. look for similar problem whif other lauguage
23. lost for top 5or 10 per lauguage
24. look not lost
25. hand checked not loading
26. add x to close for when i click on person i dont have to scrool up to close
27. make a 10 min video on how u got to the result
28. use all the free tools u can find to imporve the video
29. and the scrip here is top 10 general in history according my list a resarch u just did and that music and 10 general will a introduction why there great best win best lost and before what everyone just a quick honareble mention and i let u pick 5 that u think will keep there interest
30. update claude
31. last thing to check all name and date see who name who familiar who mint be wiki or ur mistake and save all in ask and prom in the place where the game rts save the same request
32. save it in like general goat list
33. can u make a script to run famely three and add some fame or dysnatie score add score to where everyone when they born and how much they overachieve in the bio dont make it impact the elo
34. make a famely three
35. make it just a extra
36. no add dynastie elo whif sub category similar no current site
37. its the same site just whif dynasties in it
