# Verification — 2026-09-13

Environment: Godot **4.7.2.stable.official.ed1daf0bf**, macOS, Apple M5 Pro (Apple9), Metal / Forward+. All checks use the engine already installed for this project.

## Results

| Check | Result |
| --- | --- |
| State and persistence suite | **63 checks passed**: wrong inputs, dependency gates, idempotent rewards, socket ownership, immutable completed mechanisms, partial/solved JSON roundtrips, malformed data, corrupt-save fallback, and write failure |
| Scene playthrough | **25 checks passed**, headless and rendered: first page reach, wall occlusion, closed-door collision, token button swaps, hints, journal return, handle installation, mirror dropdowns, exit order, door animation/collision clearing, walking to the reveal, settings persistence, completed-world reload |
| Packaged scene playthrough | **25 checks passed** loading the exported PCK from outside the checkout, with the external test harness |
| Visual QA | Reviewed native screenshots of title/resume, study, note, both puzzles including hint/feedback states, journal, exit, ending, London overlook, and settings; captures are in `builds/qa/` |
| UI smoke check | Opened the project in Godot, launched it, entered the room through the title button, and verified the first-person view and note prompt |
| Windows debug export | Generated `builds/windows/the_last_verse.exe`, `.console.exe`, and `.pck`; export completed without warnings/errors |
| Native packaged boot | Exported pack loads its title, 3D world, translations, and audio using the macOS engine; normal quit completes cleanly |

**Painting, fair lady, and actors (2026-09-14):** the scene playthrough passes **242 checks**. It now walks up to the gallery painting without leaving, steps into it and waits for the streets to load, and on the bridge checks that the lady wakes (caption, locked controls, visible figure) before her song brings the bridge down and the sewer loads. The state suite passes 162 checks. Rendered samples stay about 120 FPS. The sung audio was checked for length only, not by ear. Screenshot review dimmed the gallery light and the lady's flare, removed skirt pleats that looked like sticks, removed ruffs from non-porcelain skins, and enlarged the mask features.

**Borders, street life, and picture (2026-09-14):** after a playtest fall off the bridge approach, invisible walls and general fall recovery were added. The scene playthrough now passes **239 checks**. New checks cover at least 20 trinkets in the streets, picking up and throwing an apple with Q, knocking on a door, pigeon flocks, the market bell, falling out of the set and being recovered, walking sideways on the bridge approach, and walking into a raised drawbridge. The state suite still passes 162 checks. Streets render at about 120 FPS. Screenshot review removed diagonal timber braces that crossed windows.

**Bright London and the fall (2026-09-14):** the state suite passed **162 checks**, adding the bridge fall, crypt marking and scrubbing, the permanent brush, climbing out, act routing, and Act III save validation. The scene playthrough passed **224 checks** headless and rendered. It runs from the launcher through the study, the three street puzzles, and walking onto London Bridge, confirms the collapse caption, locked movement, and the load into the sewer, then solves the crypts only by interaction, climbs out, triggers the Shadow's first cue, reaches the end of the street, and reloads into the Ripper's streets. Rendered samples stay about 121 FPS. Screenshot review led to toning down the study window's glow and the neon sludge, lighting the plague cemetery more, and adding a cold rim light so the Shadow reads against the fog.

**Act II streets pass (2026-09-14):** the state suite passed **141 checks**. New coverage: prop hands, returning a spare prop on completion, wrong and interrupted brews, calendar wrapping and locking, the lever, far-bank completion, roundtrips at each step, and street save validation. The scene playthrough passed **200 checks** headless and rendered. It continues from the study lock through the curtain into the loaded street scene, confirms no non-diegetic Label3D, checks that both gates block walking, reaches every prop slot, jar, cauldron, engine wheel, lever, and note with the focus ray, solves all three puzzles by interaction only, waits for the gates to lift and the bascules to lower, walks across, and reloads at the far bank. Rendered sample: 122.0 FPS in the streets at 1280×720 on the M5 Pro. Screenshot review led to dimmer facade windows and lamp flares, smaller puddles, and a taller tower arch so the raised bascules read from the riverside.

**Physical study pass (same day):** after the redesign to in-world interaction, a HELP letter lock, wall-mounted stations, and a fuller room, the state suite passed **107 checks**: hand and slot rules, returning carried pieces, rewards and pockets, lantern rules, the lock, JSON roundtrips including a piece in hand, and 38 malformed or impossible save variants. The scene playthrough passed **136 checks** both headless and rendered. It asserts that no Label3D in the room carries more than a single letter, reaches every station and pickup with the focus ray from the room side, solves all four puzzles only by emitting E and right-click interactions on objects, checks the in-hand model, HUD, prompts and captions, sets HELP on the lock, walks to the overlook, and reloads. Rendered samples: 121.7 FPS (study) and 120.9 FPS (overlook) at 1280×720 on the M5 Pro. The review of screenshots led to a softer solved-dial glow, upright letter cards, and a lit in-hand view.

**Complete study pass (same day, superseded):** after the launcher, Macbeth, the balcony theatre, the four-sigil exit, lore pages, and room dressing were added, the state suite passed **101 checks**. It covers all four puzzles, lens sockets, receiver rules, the dependency chain, JSON roundtrips of every stage, and 33 malformed or impossible save variants. The scene playthrough passed **72 checks** both headless and rendered: launcher browsing by arrow keys, every station reached by the focus ray, wrong and correct inputs for all puzzles, lens fitting, a lore page, visible world changes (ghost, compartment, curtain, walkway, door), the full walk to the overlook, settings, and completed-world reload. The rendered boot/quit smoke test passed. Rendered samples: 121.4 FPS (study) and 121.5 FPS (overlook) at 1280×720 on the M5 Pro. New screenshots are `01b_locked_chapter`, `13_macbeth`, `13b_banquet_world`, `14_balcony`, and `14b_balcony_world`. A review of extra camera angles found the stage plan above the door unreadable through the screen effect, so it was moved onto the door at a larger size.

**Art/audio pass (same day):** after the degraded art direction, fog, lens stars, sky, and staged London Bridge music were added, the state suite (63), headless and rendered scene playthroughs (25 each), and the rendered boot/quit smoke test passed again with no warnings. The rendered sample measured 121.6 FPS (study) and 122.1 FPS (overlook) at 1280×720 on the same machine. Volumetric fog and shadowed omni lights have not been profiled on Windows or lower-end GPUs. The music loops were checked for level, length, and loop seams, but have not yet been judged by ear.

The first render review found a bookshelf obstructing the title camera, clipped puzzle footers, and an overly narrow view of London. Those were corrected and the affected screens re-rendered. A shutdown check also found retained audio playback references on immediate exit; the normal quit path now stops playback and allows the audio thread to settle before closing.

## Small rendering samples

A 120-frame sample per view at **1280×720** measured:

| View | Average throughput | Average frame interval |
| --- | --- | --- |
| Study | 122.4 FPS | 8.17 ms |
| London overlook | 123.2 FPS | 8.12 ms |

These are short local smoke measurements on the M5 Pro, with the editor open. They do not establish 1080p target-PC performance, worst-case frame time, or minimum system requirements.

## Outstanding acceptance work

- Run the Windows executable on actual Windows hardware, including save/load and the full puzzle route.
- Conduct at least three first-time playtests and record where players hesitate or need hints.
- Validate comfortable mouse-look over sustained play, rebinding, UI scaling, brightness, and controller support as those features are implemented.
- Replace placeholder meshes, mirror presentation, audio, and final licensing/credits before release preparation.

The native PCK checks validate packaging on the development machine. They are not Windows runtime validation or an end-to-end human playtest.


## September 14 — False Exit and visual refinement

- State/persistence: **170 checks, 0 failures**, including locked completion, wrong shutters, unlit real exit, partial lamp save/reload, solved control immutability and migration of existing saves.
- Full native rendered playthrough: **256 checks, 0 failures**. Checks include blackout while the bridge camera remains above the deck, landing with controls restored, reachability of the lantern/letter/all three levers, physical shutter blocking, wrong-input preservation, saved lamp aim, shutter opening, Shadow disappearance and crossing to the ending.
- Render samples: study **122.0 FPS**, street **121.1 FPS**, 1280×720 on the existing M5 Pro setup. These are short samples, not platform performance guarantees.
- Reviewed final supplemental native captures `27_sewer_final`, `28_false_exit_final`, `29_actor_final` after reducing oversharpening, colour fringing and grain. Reviewed animated-water shader rendering, vaulted masonry, outlined passage shadow readability and the kneeling actor. A mesh-bounds check exposed a remaining 2 cm boot intersection; the kneeling root was raised 3 cm.
- Splash is an original 2.8-second synthesized WAV. Timing/asset loading checked; sound quality still needs an in-game listening pass. Windows exports were not rebuilt in this pass.


## September 14 — complete route, revised house and departure finale

- Existing state suite: **170 checks, 0 failures**.
- Celestial deduction suite: **22 checks, 0 failures**, including exhaustive uniqueness among 1,296 assignments, backward sight, walked sequence, partial saves and migration.
- House/railway suite: **21 checks, 0 failures**. Covers required record, repeated memory notes, wrong inputs, permanent secret passage, isolated repair, unique coupled-gauge solution, brake gating, prepared-train saves, completion validation and older platform-ending migration.
- Full native rendered playthrough: **339 checks, 0 failures**. Runs study → bridge girl facing player → blackout/sewer → False Exit → walkable staircase → history record → replay and bells → physical bookcase passage → complete celestial puzzle → locomotive repair and gauges → brake → boarding and moving cab → saved level completion. Checks all HUD text for horizontal centering and the new mechanisms for focus-ray reachability.
- Visual QA: reviewed secret passage, constellation sky, repaired train, cab departure, HUD and completion card at 1280×720. Supplemental `38_completion_layout` confirms both end buttons fit without scrolling; `39_departure_layout` confirms travel shows only the narration instead of stale movement/boarding prompts.
- Render samples in the full run: study **122.0 FPS**, streets **121.6 FPS** on the existing M5 Pro setup.
- The new bell and train cues are original synthesized placeholders; timing and loading were tested, but listening quality and first-time puzzle-solving difficulty still need a human playtest. Windows export was not rebuilt in this pass.


## September 14 — second narrative pass, Whitechapel watch, Dyer house, Thames

- Full headless playthrough: **339 checks, 0 failures**. It opens the traveller's book on a new run, closes it, and checks the act card. It witnesses all six Whitechapel stops with the lamps dim, files a wrong report that is rejected, then the correct one, and continues through the Dyer house, stars and railway.
- State suite **171**, celestial **22**, house/railway **21** checks with 0 failures. Whitechapel visibility suite passes: every stop visible, masonry blocks sight, looking away does not count, frozen in bright light, walks when dim. Boot smoke test passes.
- Visual QA at 1280×720: title leaf, scroll, police plan, Whitechapel arrival/grid/gate, Dyer beds with dreamcatcher bells, the rocking-chair corpse, and London Bridge from the approach, drawbridge and deck in both directions. Screenshot review moved the rocking chair out from behind a bed, shrank the held book, and loosened the title poem's line spacing. The horizontal torn band in street screenshots is the intentional `cursed_post` scanline effect.
- `ThamesScenery.build` takes about 46 ms headless. Not listened to by ear: regenerated narration, rain, heartbeat and whisper. Windows export not rebuilt.

## September 14 — title menu, HUD, Whitechapel visibility, bridge attack

- Full headless playthrough: **344 checks, 0 failures**. New checks:
  - The title page offers Play, Settings and Exit.
  - Play opens the chapter page over its scene slideshow.
  - Hints are offered from the chapter page.
  - The girl climbs and starts crawling, faces the player while crawling, and gets closer before the lunge.
  - The player actually falls (y drops more than 1 m) before the blackout completes.
- State suite **171**, celestial **22**, house/railway **21** checks with 0 failures. Watch suite passes, including a new check that the Shadow is invisible (and cannot be witnessed) in bright light. Boot smoke test passes.
- Visual QA at 1280×720: title page, chapter page, locked chapter, hints, settings with the key list, pause, and HUD with the act name only. Frames from the bridge attack: the parapet climb in darkening weather, the crawl, the lunge close-up and the backwards fall. Review fixed a reversed lunge orientation, shiny bar-like hair, an emoji-like face, and the scroll bar and caption overlapping the leaves.
- Not judged by ear: `bridge_crack.wav`, `lady_lunge.wav`. Windows export not rebuilt.

## September 14 — walled-in girl, fire brew, co-op

- Full headless playthrough: **351 checks, 0 failures**. The witches' square now works the bellows to the right heat before every ingredient and checks that all three witches hold readable scraps. The bridge sequence runs through the new bricked-arch escape.
- State suite **173** checks with 0 failures, including new checks that the wrong fire spoils the brew and that the bellows cycle their heat. Celestial **22**, house/railway **21**, watch suite PASS, boot smoke test passes.
- New `tests/test_coop.gd`: **18 checks, 0 failures**. It runs two full games in one process on separate multiplayer branches over localhost. It covers:
  - hosting, joining and beginning together;
  - the companion's lock wheel performed by the host and synced back, with the companion's save untouched;
  - the single carried piece (the carrier sees it; the other player cannot place it; setting it down frees it);
  - reading on the companion's screen with the clue recorded by the host;
  - each player seeing the other's avatar at the right position;
  - the painting transition taking both to London;
  - the companion returning to the title and their own run when the host leaves.
- Found and fixed while testing:
  - An engine crash from closing the ENet peer inside its own disconnect signal (now deferred).
  - A painting transition flag that briefly blocked input after arriving in the streets.
- Visual QA: bricked arch before and during the escape, the crawl, the lunge and fall; co-op pages (Play Together, Host with LAN address, Join with address field); the companion avatar in the street.
- Not tested: two separate machines on a real network or over the internet, latency, and an ear check of the new sounds.

## September 14 — neural narrator

- Generated all seven act poems with local Kokoro `bm_george`, 24 kHz mono PCM16, 23.0–24.6 seconds each. Validated finite samples, leading silence and peak levels (0.472–0.555 full scale); no clipped samples.
- Godot headless editor import completed successfully for all seven replacement recordings and the generated cue script.
- `tests/test_narrator.gd` checks all seven recording lengths and ordered cue bounds, then verifies first/second subtitle cues against actual playback and pause/resume. Headless QA supplies an AudioStreamPlayer because the game normally skips audio setup in headless mode.
- Audio quality has been checked structurally, not auditioned by ear in this session. The user can audition `shared/audio/narrator/study.wav`; the previous version is in `builds/narration-original/study.wav`.
- Windows export was not rebuilt; these changes are in the source Godot project.

## September 14 — anthology interface

- `tests/test_interface.gd`: native rendering of title, Shakespeare chapter, poster/minimal future previews, settings, book, scroll, HUD and pause. Verifies actual right-arrow key navigation, distinct chapter presenters and the visible settings apply action.
- Visually reviewed 1280×720 screenshots and 1152×648 title/scroll screenshots. The chapter previews are explicitly unavailable; no future playable content was added.
- Rechecked narrator playback/caption pause-resume after the HUD layering changes.
- All new visuals are procedural or reuse the existing project paper/scene assets. Windows export not rebuilt.
