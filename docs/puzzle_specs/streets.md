# Act II and III puzzle contracts

Content version: `london-chapter-4`, save schema 5. Rules live in `core/puzzles/study_state.gd` alongside the study. The streets load after the study's closing card (`completed`). Reloads spawn at the start of the furthest unlocked section.

The bright afternoon street runs from the stage door toward London Bridge through three gates. As in the study, everything is solved by direct interaction: E uses, right click looks closer (and turns calendar wheels back), and hints live in the journal. Frozen actors are scenery; only the actors' hands and the listed objects are interactive.

## `street.props` — Balcony Lane (Romeo & Juliet)

- Scene: Juliet leans from her balcony, Romeo kneels below with his hand raised, and Friar Laurence waits by his chapel door. Mercutio and Tybalt are frozen mid-duel.
- Inputs: a prop cart with five props (rose, sealed letter, vial, skull, tin crown) and the three empty actor hands, all slots of one hand station. Picking up a prop and using another slot places or swaps it.
- Clue: the playbill beside the cart: Romeo offers a rose, Juliet holds a letter, Friar Laurence keeps the sleeping-potion vial. The skull and crown belong to other plays.
- Solution: Romeo rose, Juliet letter, Friar vial. It completes automatically; a spare prop still in hand returns to the cart.
- Completion: stage lights come up on the three actors, and the iron safety curtain at the end of the lane rises.

## `street.brew` — the Witches' Square (Macbeth), revised with fire

- **Revision (owner direction, 2026-09-14):** dropping jars in order alone was too easy. Each ingredient must now go in on the right fire.
- Inputs:
  - The bellows at the front of the cauldron (`bellows`) cycle `heat`: 0 embers → 1 steady flame → 2 roaring blaze → 0.
  - The flames and hearth light grow with the heat.
- Clues:
  - The torn page still gives the order ("Eye of newt and toe of frog, / Wool of bat and tongue of dog") and says each sister holds the heat for her part.
  - Each witch holds a readable scrap (`witch_scrap_0..2`):
    - The eye opens only on embers.
    - The frog's toe needs a blaze, and the bat's wool a middle fire.
    - The dog's tongue needs the hottest fire.
- Solution: `RECIPE_HEAT` = [0, 2, 1, 2] alongside `RECIPE` = [eye, toe, wool, tongue].
- Failure: a wrong ingredient **or** the wrong heat spits every added jar back. The heat stays where it is.
- Save: `heat` is saved. Older saves load with embers.
- Hints: read the page and all three scraps; the bellows change the fire; the full recipe with heats.

## Original `street.brew` contract (superseded by the fire revision above)

- Scene: three witches bend over a green-lit cauldron. King Lear rages on a crate stage beside his Fool, Hamlet holds a skull in a graveyard corner, and Titania sleeps beside Bottom in his donkey head.
- Inputs: six jars on an apothecary stall (eye of newt, toe of frog, wool of bat, tongue of dog, raven feather, mandrake root), carried one at a time and dropped into the cauldron with E.
- Clue: the torn prompt-book page, quoting “Eye of newt and toe of frog, / Wool of bat and tongue of dog”, with a margin note to add them in the order spoken.
- Solution: eye of newt, toe of frog, wool of bat, tongue of dog. A wrong ingredient at any point spits every added jar back onto the stall; nothing is lost.
- Completion: green smoke rises and the portcullis lifts.

## `street.bridge` — the riverside (Julius Caesar)

- Scene: the soothsayer points at Caesar while Brutus hides a dagger. Old London Bridge, a stone gatehouse and spans crowded with pastel houses, stands over the Thames with its drawbridge raised.
- Inputs: the bridge engine's month wheel and day wheel (E forward, right click back) and its lever.
- Clues: the tender's orders (set the day Caesar was warned of, then pull the lever), the soothsayer's scroll quoting “Beware the ides of March”, and an almanac page (the Ides fall on the 15th of March).
- Solution: MAR and 15, then the lever. A wrong date rattles the lever back with a caption.
- Completion: the drawbridge swings down.

## The fall of London Bridge

- Why it falls: the mason's confession, a tablet in verse set into the gatehouse wall, tells how the builders walled a young girl (“my fair lady”) into a pier so the river would let the bridge stand. The witches' incantation adds that when their pot sings, the lady wakes. The witches can be heard clearly singing “London Bridge is falling down” from the market square; the background music ducks as the player nears them.
- **Walled-in revision (third pass):** she is not climbing up from the river any more; she escapes from where she was immured.
  - Before anything happens, segment 1's left parapet is broken by a tall **bricked-up arch**. Its hurried brickwork is darker than the stone, with an iron cross above it and a chain and padlock across the bricks. Dead flowers and a small velvet shoe lie at its foot, and there are scratch marks down the jamb. A hollow stone chamber is built out over the river behind it.
  - When the player steps onto the spans, something knocks three times from inside and the bricks shiver.
  - A hand punches through the middle, then the whole wall bursts outward across the deck and the chain drops.
  - She drags herself out of the dark chamber head first, then crawls and lunges as below.
- **Revised sequence (second pass):** walking onto the spans locks movement. A cloud crosses the sun (`LondonStreet.darken`), and stone cracks (`bridge_crack.wav`). Wet hands close over the parapet as the girl hauls herself up the outside of the pier, and loose parapet stones tumble into the river. She drops onto the deck and crawls toward the player on all fours in jerky bursts, singing, while the camera cannot look away. She stops just out of reach and the song cuts off. Then she springs into the player's face (`lady_lunge.wav`) and holds on. The spans collapse, and the player is dragged backwards off the deck, actually falling while the sky swings past, as the picture goes black. The splash follows, and then the sewer. The superseded description follows.
- Old sequence: walking onto the spans (`COLLAPSE_Z`) locks movement and turns the camera toward the pier. Its sealed masonry sinks into the pier and a full-sized pale girl emerges from the recess, turning toward the player while singing the rhyme (`fair_lady.wav`). The entrance uses no random brick projectiles or scale animation. Captions narrate each beat. The spans tremble and begin to crack. A 0.3-second black fade closes before the scenery drops; the player camera stays above the deck. An original splash and muffled underwater tail play during 1.6 seconds of darkness. The run commits `bridge_fallen`, the sewer loads, and a 1.6-second reveal finishes before movement returns. Menu inputs and focus-loss pausing cannot interrupt this transition.

## `sewer.plague` — the plague sewer (Act III)

- Scene: a torch-lit brick sewer with a sludge channel, dozens of plague rats (some scurrying), shrouded corpses, a dead-cart, a plague pit, and beaked plague doctors. A buried plague cemetery has graves, crosses, candles, and four crypt doors.
- Inputs: a brush from a pot of red paint (a pocket item), then the four crypt doors. Using a door paints a red plague cross; using it again scrubs the cross off.
- Clue: the plague-master’s warrant: “A plague o’ both your houses!” Mark the Rose of Capulet and the Ivy of Montague; spare the Crown and the Bell. Each door carries its crest.
- Solution: crosses on the rose and ivy doors only. It completes automatically.
- Completion: the iron gate rises and the ladder becomes usable. Using the ladder commits `climbed_out`, fades, and loads the Shadow's street.
- Hints: read the warrant and take the brush; rose and ivy are the feuding houses; paint exactly those two.

## The Uncast Shadow’s street (Act III)

- Scene: a foggy night slum with soot-black tenements, gas lamps, washing lines, a pub, a bobby, and frozen residents.
- The Shadow is a tall faceless figure in a top hat with a cold rim light. He appears at authored cues only: at the end of a dead-end alley, then walking across a side street. He vanishes when approached or after a few seconds. There is no pursuit, damage, or failure state.

## `ripper.shadow` — The False Exit

- Three framed passages stand at the end of the street. A waist-high inspection lantern cycles left → middle → right. Each setting illuminates an outlined ground shadow leading toward a brass marker. The side shadows have a visible gap; the middle shadow is continuous. These are authored scenic projections, independent of GPU shadow settings.
- The letter beside the lamp explains the rule in verse. Inspecting the lamp and shutters and turning the lamp also describe the distinction in plain text. Reading the letter or using the mechanism unlocks three journal hints.
- Solution: aim the lantern at the middle passage, then use its shutter lever. Wrong levers and an unlit middle passage leave the mechanism and inventory unchanged. There is no timer, pursuit or damage.
- Completion: the metal shutter rises, the Shadow disappears, and the real passage opens. Crossing beyond it continues into the Dyer courtyard; see `celestial.md`.
- Save state: `shadow_lamp` (0–2), `shadow_solved`, and the tenth hint track. Solved controls lock. Existing schema-5 saves migrate without losing previous progress; old finished runs retain their progress and resume in the new courtyard.
- This implements the observation/light/shutter core of the README's False Exit. The proposed unsafe-area resets and Lantern Sigil reward are not part of this build.

## `ripper.watch` — the constable's route (replaces the False Exit)

- Scene: a closed three-by-three grid of rain-soaked Whitechapel streets (`ripper_street.gd`) with four tenement blocks, a police Watch Post with a blue lamp, and eight other landmarks, each marked by a hanging painted sign: Cooper's Yard, The Crooked Crown, Bell Passage, Chapel Steps, Widow's Well, Rag Market, Tanner's Row and the Mourning Gate in the south wall. Rain, ripples, rats, laundry, masked residents, a whisper when the lamps fail, a heartbeat that rises as the Shadow gets closer, and footsteps that follow his figure.
- Light cycle (`CYCLE` 11.5 s): the gas burns bright for 4.5 s, gutters, then dims. **The Shadow exists only in the dark.** He is invisible while the gas burns bright, stutters into view as the flames gutter (`manifest()`), and walks only while the street is dim. Sightings count only while he is visible.
- Route: from the Watch Post he walks `WATCH_ROUTE` = Cooper's Yard → Bell Passage → Chapel Steps → Widow's Well → Tanner's Row → Mourning Gate, waits one light cycle at each stop, rests at the gate, and starts again. The Crooked Crown and Rag Market are decoys he never visits; he passes the Rag Market once close by in the dark (`SHADOW_CLOSE`).
- Sighting: a stop counts only if the player sees him standing there, within 26 m, inside the camera view and with a clear physics ray (masonry blocks it). Each sighting is confirmed with a caption and saved.
- Input: the street plan on the Watch Post desk (`inspection_lamp`, `ui/police_map.gd`). Pins are marked in order from the Watch Post; *Blot out the route* clears, *File the report* submits.
- Solution: all six stops witnessed in person, and the six pins in the order above. A report before all six are seen is refused; a wrong order is rejected. Neither erases sightings.
- Book: B lists places seen so far alphabetically, never in order.
- Completion: the Mourning Gate opens into Dyer's court; see `celestial.md`.
- Save state: `watch_seen` (at most eight places, no duplicates) and `shadow_solved`. Sightings from the earlier four-stop route that are not on the new route are dropped on load; solved saves stay open.
- Hints: read the notice at the Watch Post; follow at a distance and wait at stops; the full route.
