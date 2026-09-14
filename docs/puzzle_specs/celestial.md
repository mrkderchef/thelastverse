# The house that remembers — The Uncounted Stars

Owner-directed continuation of the existing route: Whitechapel → service court → stairs → Dyer's remembered house → impossible nursery → Metropolitan Railway. This supersedes the earlier plan to end the playable route after Whitechapel. The world folds Reading in 1896 into London in 1863; it is not a literal historical itinerary.

## Arrival and narrative

Escaping the False Exit commits `ripper_completed` and loads `DyerCourtyard`. A continuous collision ramp beneath visible steps allows the existing first-person controller to climb the staircase. Inside, a record recounts that Amelia Dyer took infants into her care for money and was convicted of murder in 1896. Empty cots and domestic furniture frame the account. It does not reenact the killings or use identifiable victims as puzzle objects.

The player reads the record, then solves **The House’s Memory** upstairs. A fixed memory box plays five notes while the corresponding bells flash and captions name each one. Four fixed bells are labelled Lamp, Moon, Cradle and Door. The sequence is **Cradle → Lamp → Door → Moon → Lamp**. A wrong note resets only the attempted echo; replaying the box consumes nothing and can be repeated at any time. Five studs record accepted notes. There is no time limit or item carrying, and hearing is not required.

Solving the echo slides the back-wall bookcase aside. The player physically walks through the revealed passage, which leads directly into the great star hall. There is no floor collapse in this part of the route. The record, memory instructions and three journal hints remain available. Partial echo progress and the opened passage persist.

## `celestial` — one linked deduction in three stages

### Stage 1: count and assign

Six major constellations are visible in the open sky. Their silhouettes, connecting lines and countable stars are authored deterministically. Dim disconnected background stars are excluded by the written rule. The same glyphs appear in floor inlays and on the figures' backs. An accessible verse atlas repeats the shapes and counts:

| Constellation | Connected stars |
| --- | --- |
| Triangle | 3 |
| Diamond | 4 |
| Crown | 5 |
| Key | 6 |
| Eye | 7 |
| Serpent | 8 |

Four stone keepers are identified on their chests: Sun, Moon, Tide, Ash. The law and covenant are separate readable texts. Together with XXIII on the central seal they establish:

- Each keeper watches a different constellation.
- Their four counts total 23.
- Sun sees two stars more than Tide.
- Ash sees one star more than Moon.
- Tide sees the fewest of the four.

Unique assignment: **Sun 5/Crown, Moon 7/Eye, Tide 3/Triangle, Ash 8/Serpent**. The deduction test enumerates all 6^4 assignments and verifies uniqueness independently of the stored solution.

### Stage 2: interpret sight, not just body facing

Six engraved bearings surround each plinth and correspond to the sky's six directions. E rotates the entire keeper through them. Right click describes the figure and its back mark; it does not rotate it.

Sun and Tide see forward. Moon and Ash see behind their shoulders, requiring a 180° reversal of the constellation bearing. The law states this explicitly. Correct body-facing bearings: **Sun Crown, Moon Diamond, Tide Triangle, Ash Crown** (indices `[2, 1, 0, 2]`).

The central seal judges all four at once. Incorrect submission preserves the positions and gives no per-statue correctness oracle. Correct submission sounds feedback, locks the figures and activates the walked seal. There is no need to carry anything.

### Stage 3: read backs, then walk

| Keeper | Star count | Back mark |
| --- | --- | --- |
| Sun | 5 | Eye |
| Moon | 7 | Key |
| Tide | 3 | Diamond |
| Ash | 8 | Crown |

A third text directs the player to order the keepers by ascending star count, then use their **back marks**, rather than their constellations. The resulting floor sequence is **Diamond → Eye → Key → Crown**.

The player enters the sequence by walking onto large glyph plates. Interaction by hand cannot submit a step. Remaining on a plate never repeats input. A wrong glyph clears only the attempted walk; aligned figures remain locked. Four lamps on the central seal and the lit floor signs show accepted progress. No timer or running challenge is involved; reading and menus suspend input. A clear route between and around the tiles allows the player to avoid unintended signs.

## Reward and persistence

The last correct step permanently raises the metal door marked METROPOLITAN RAILWAY. Crossing it loads a brick-vaulted, gas-lit station with tracks, wooden carriage and steam locomotive. **Platform arrival does not end the level.** The final repair/departure puzzle is specified below. Railway access and actual level completion persist separately.

`StudyState.celestial` contains the house echo, opened bookcase, hall entry, four bearings, alignment, accepted floor steps, star solution, railway access, locomotive controls and actual departure completion. JSON loads normalize validated integral values before comparisons. Impossible progress, incomplete step prefixes, out-of-range/fractional bearings and invalid chapter prerequisites are rejected. Schema-5 saves lacking the newer extensions migrate with defaults and the additional hint tracks. Previously finished Whitechapel runs resume in the courtyard. Earlier star-hall or platform saves inherit an open house passage. Saves from the old platform ending retain railway access but still need the newly added repair and departure.

## Hints and accessibility

Three journal hints progress from where to observe, through the relational equations and reverse sight, to the complete facing and walking solutions. All major sky shapes have a plain-text count alternative. Keeper identities and back marks are inspectable, in addition to being visible. Colour, hearing, real astronomy knowledge and reaction speed are never required.

Difficulty is a design intention, not a measured duration. A first-time human playtest is still needed to establish solving time and clue clarity.

## Historical grounding

- [Reading Museum, object REDMG 1997.123.54](https://collections.readingmuseum.org.uk/index.asp?filename=REDMG&hitsStart=1967&mwsquery=%7Bcollection%7D%3D%7Bhistory%7D&page=record): arrest in April 1896, paid infant care, Reading and conviction at the Old Bailey. The game uses original paraphrase, not the sensational broadsheet text or imagery.
- [London Transport Museum library, Metropolitan Railway](https://library.ltmuseum.co.uk/Portal/Default/en-GB/RecordView/Index/108): public opening on 10 January 1863, world's first underground railway.
- [London Museum, Building a Victorian underground railway](https://www.londonmuseum.org.uk/collections/london-stories/building-victorian-underground-railway/): 1863 route linking Paddington and Farringdon through King's Cross and Euston.

The house layout, four keepers, stars, floor signs and supernatural transition are original fiction. No claim is made that Dyer used these signs or that the depicted house connected to the Metropolitan Railway.


## `railway` — The Last Train

The locomotive has a leaking feed union, its captive clamp, a red isolation wheel, two pressure-control knobs and a departure brake. Nothing must be picked up or carried. A driver’s repair book supplies the rule in verse; inspections, gauges, word labels and three journal hints duplicate the necessary information.

1. **Isolate and repair.** Shut the red feed wheel. Operate the attached union clamp. Trying to repair with the feed open leaves progress unchanged and gives an isolation caption. The repaired union is permanent; reopening the feed removes the visible leak.
2. **Balance two gauges.** Furnace and relief each cycle 0–3. Each furnace mark contributes two steam marks and one return mark; each relief mark removes one from both. The engraved targets are Steam III and Return I. The unique setting is **furnace 2, relief 1**. With feed shut or the union unrepaired, both gauges stay at zero. This is a fictional mechanical puzzle, not a locomotive operating specification.
3. **Release and depart.** Set the brake FREE. Use the green departure control beside the cab. Missing prerequisites give specific feedback without consuming anything.

On departure the player moves into the open cab and travels with the accelerating train. An original whistle/chuff cue plays. The picture fades before the camera can reach the end of the scenery, then the level-complete card appears. Completion is written only after this sequence. Closing the game earlier leaves a prepared locomotive at the platform, ready to depart on resume; it never saves a stranded moving-camera position. Returning to the platform or loading a completed run leaves the repair intact.

The memory and train audio is original deterministic synthesis (`shared/audio/generate_finale.py`); no historical recording is used.
