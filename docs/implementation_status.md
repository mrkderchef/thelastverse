# Playable build — Act I: the complete study

Implemented on 2026-09-13 with the existing **Godot 4.7.2 stable standard** installation and matching export templates. The renderer remains Forward+. This build covers milestones 0–3 in code: the complete four-puzzle study. The milestone 3 playtest gate has not been run, and the rest of the chapter is not built.

## Play

Open `project.godot` in Godot and press Run Project (F5), or run:

```sh
godot --path .
```

The launcher shows chapter cards. Browse with ←/→ or the arrow buttons. Card I is *London Is Falling*; cards II and III read “??? · Currently unavailable”. Choose **Enter the chapter** and read the page on the desk. Then solve:

1. **Seven Ages** (left wall, brass dial). Earns the Skull Handle.
2. **Hamlet** (right wall, mirror cabinet). Needs the handle; earns the Moon Lens.
3. **Macbeth** (left wall, miniature banquet). Available any time; earns the Sun Lens.
4. **Romeo & Juliet** (right wall, model theatre). Needs both lenses.

Everything is solved in the room itself: E uses the object under the crosshair, and right click looks closer. Each puzzle reveals a letter card with position marks. Set the letter lock on the door to **HELP** and walk through to the London overlook. The ending names the current build boundary.

WASD moves, the mouse looks, E uses, right click looks closer (and turns lock wheels back), J opens the journal with letters, belongings, notes, and hints, and Escape pauses or returns. Reading a note and menus suspend movement and scenery; mechanisms animate live while exploring. Losing app focus pauses exploration.

## Implemented

- Launcher with chapter cards, arrow-key and button browsing, chapter status (not started / letters found / complete), resume and confirmed restart, and static-heavy placeholder cards for unwritten chapters.
- A study that reads as a normal room, with every piece of furniture against a wall and no floating text. **Back wall:** bookshelf, globe, the locked door, standing candelabra, a writing desk under the curtained window with the first page. **Left wall:** the Seven Ages dial over its sideboard, a fireplace with mantel candles, a turned painting and a burning fire, an armchair and side table, the Macbeth banquet sideboard, a four-poster bed. **Right wall:** wardrobe with a door ajar, the Hamlet mirror cabinet, a stopped grandfather clock, the Romeo & Juliet model theatre, a coat stand, a second bookshelf. **Front wall:** costume trunk, chest of drawers with washbasin and cracked mirror, a faceless dress form, masks, and prop crates. Also an iron chandelier, wall sconces, faceless portraits, loose sheets and book stacks, rigging, and stage tape.
- Direct interaction system: a focus ray with contextual prompts (“[E] Pick up the rose token”), right-click descriptions as fading captions, one puzzle piece carried in the hand (shown in view and named in the HUD), and key items in pockets. Mechanisms move, glow, and open in the world.
- Seven Ages wall dial (H), Hamlet mirror cabinet with handle socket, reflection, and symbol dials (E), Macbeth banquet with notched chairs, carried figures, and the unseen guest (L), Romeo & Juliet theatre with lens sockets, turning crossed lanterns, and beams (P). Each completion reveals a letter card with position marks, plays the solved sound, and shows a caption.
- A four-wheel letter lock on the door (HELP), a moving door, the safe backstage passage with its rain machine, suspended London flats, and a completion checkpoint.
- Readable notes appear as parchment props (scroll with wooden rollers, open two-page book, or letter with a wax seal) in a calligraphic serif, as short Early Modern English poems. E, Enter, or Escape lays them down.
- Journal with letters found, belongings, notes read, three-step hints per discovered puzzle, and loose lore pages.
- Pause, safe save-and-return and quit, and explicit save-failure messages.
- Independent settings for FOV, mouse sensitivity, invert Y, fullscreen, music volume, mechanism volume, and visual distortion (0 gives a clean image).
- Readable colour contrast inside the degraded look: bottle-green walls, walnut furniture, a crimson rug, royal-blue velvet, brass, and bone. Warm-white candles and chandelier, an orange fire, and cool moonlight plus fill lights keep every object visible. HUD text has a dark outline.
- Deliberately degraded early-3D art direction: unfiltered procedural noise textures, lens stars on lights, a pixelated storm sky with a blood moon over a burning London, and a screen pass (low virtual resolution, oversharpening, compression blocks, warp, grain, look smear, rare torn scanlines). The UI stays above the pass. Torn scanlines and colour fringing grow with progress.
- *London Bridge Is Falling Down* as five escalating loops that crossfade with progress (first page, then one, three, and four letters, then the open door). Vocals are a non-commercial placeholder; see the asset register.
- English strings behind stable translation keys in `localization/strings.csv`.
- Versioned JSON save with validation of types, ranges, piece conservation, and dependencies; temporary-file replacement, last-good backup, and corruption recovery. Rewards derive from completion flags and cannot duplicate.

## Acts II–III — bright London, the fall, and the dark below

- **Mood arc:** the study and streets are bright and cheerful, with a sunlit study, pastel timber houses, a blue day sky, bunting, and clean visuals (distortion `dread` 0). The music is a major-key nursery rhyme: melody only at first, sung after the first letter is read. When London Bridge falls the picture decays (`dread` 0.6 in the sewer, 0.9 in the Shadow's street) and the music moves to the broken minor loops.
- **Act II streets:** Balcony Lane (Romeo & Juliet props), the Witches' Square (Macbeth brew), and the riverside (Julius Caesar's Ides of March on the bridge engine). **London Bridge** has a gatehouse, a drawbridge, and four spans lined with houses, all of which collapse into the Thames when the player walks onto them.
- **Act III sewer:** plague rats, corpses, plague doctors, a plague cemetery, and the crypt-marking puzzle, then a ladder out.
- **Act III streets:** the Uncast Shadow glimpsed at two authored cues in a foggy Victorian slum. No threat mechanics.
- **Street life:** cobblestones use a procedural tileable texture. Houses vary in colour, height, jetties, roof colour and shape (eave or front gable), timbering, shutters, flower boxes, chimneys, painted doors, trade signs with pictograms, awnings, and barrels. Neighbours stand in doorways or lean out of windows, some waving. Washing lines hang with sheets and shirts on thick sagging ropes, and bunting crosses the street. The square has market stalls with sellers, crates, a well, and a bell post. Pigeon flocks scatter when approached or when the bell rings, and gulls circle the river.
- **Loose trinkets** (apple, pear, bread, bottle, tankard, book, cabbage, fish, candle, bone, cup, coin purse) lie about every act. E picks one into the left hand, alongside any puzzle piece in the right; Q throws it as a physics object. Trinkets are not saved. Doors can be knocked on (varied replies), and the well can be used.
- **Borders:** invisible walls line the bridge approach, the gatehouse, the spans, and the gap under a raised drawbridge. Every act also recovers a player who falls below the set, returning them to their last safe footing.
- **Picture:** the degradation pass renders at a 600-line virtual resolution (was 360), with less compression smear, grain, warp, and oversharpening. The day streets use a warmer filmic grade with stronger saturation.
- **Leaving the study:** the red backstage passage is gone. Behind the door is a short sunlit gallery with wall candles and a painting of London on a spring day. Using the painting fades to white and loads the streets.
- **Why the bridge falls:** the immurement legend. The mason's confession on the gatehouse tells of the fair lady walled into the pier. The witches sing the rhyme audibly as a positional voice (`witches_chant.wav`, with music ducking nearby). On the bridge the girl bursts from the bricks, glowing, and sings (`fair_lady.wav`) as the spans shake and fall.
- **Actors:** jointed Elizabethan players with porcelain comedy or tragedy masks, ruffs, peascod doublets with gold buttons and trim, puffed and slashed sleeves, elbows and knees, trunk-hose, stockings, boots, gowns with front panels, and gloves.
- Four act scenes (`StudyRoom`, `LondonStreet`, `PlagueSewer`, `RipperStreet`) share `ActScene`. The main scene loads the act from `StudyState.act()`, runs the collapse and climb transitions with a fade, and routes interactions. See [puzzle contracts](puzzle_specs/streets.md).

## State and ownership

`StudyState` owns mutable run data and consequential puzzle rules. It has no scene dependencies. `SaveStore` validates and writes plain JSON. `StudyRoom` presents the world and safe spawn anchors, places the four station models (`AgesDialModel`, `MirrorCabinetModel`, `BanquetModel`, `BalconyModel`) and the `LetterLockModel` against the walls, and applies state to them after every change. `StudyDressing` builds furniture, clutter, and lore pages. `PropKit` owns the shared materials, primitives, notes, and letter cards. `StudyInteractable` carries an interaction id, index, and argument; the main scene maps these to state calls and prompts. `StudyPlayer` owns movement and the focus ray. `PuzzleView` emits UI actions to the state. The main scene owns the run, local signal wiring, menus, input context, and save requests. No unused autoload services or Steam scaffolding are added.

Save paths are `user://london_is_falling.json`, `.bak`, and `user://study_settings.cfg`. On macOS the normal directory is `~/Library/Application Support/Godot/app_userdata/The Last Verse/`. Content version is `london-study-2`, schema 3. Saves from earlier builds are rejected and the chapter starts fresh; the old `study_prototype.json` file is left untouched. Incompatible saves are rejected with a message. Scene reload restores the study entrance until the reveal has been reached, then restores the overlook. Opening a menu does not reposition the player.

Tests use uniquely named temporary saves and do not overwrite player progress. Headless runs skip audio playback. Normal rendered runs include audio; the normal quit path lets the audio thread release stopped playback before shutdown.

## Scope and remaining work

The geometry, mirror diagram, audio, and UI are prototype assets. The physical mirror uses a readable diagram rather than a rendered reflection. Token shapes, object outlines, prop inspection rotation, rain audio/animation, the final commissioned art/audio, in-game key rebinding, UI scaling, brightness calibration, controller support, and the full settings list remain future work. Input actions are already configured in Godot's Input Map; displayed bindings currently describe the defaults.

The Uncast Shadow encounter, the London Bridge finale, the backstage spotlight puzzle from the README, credits, achievements, and Steam integration are not implemented. The locked launcher cards deliberately depart from README section 12 at the owner’s request. The Macbeth ghost has no separate reduced-intensity variant yet; it is a quiet translucent figure without flashes or sound. The letter lock is gated by knowing the word, not by solved-puzzle flags. Controller input for looking at small objects (lock wheels, tokens) is untested. No chapter duration, release date, minimum specification, or platform compatibility claim is established by this build.

The milestone 3 gate still requires independent first-time playtests of the full dependency chain, recorded clue/interaction feedback, a Windows-device playthrough, accessibility expansion, and a target-hardware performance pass.

See [the verification record](verification.md) for actual results, screenshot locations, and measured limits.

## Verification commands

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_study.gd
godot --headless --path . --script tests/test_playthrough.gd
# Run the same scene test with actual rendering and capture PNGs:
godot --path . --script tests/test_playthrough.gd
# Build for the intended Windows platform:
godot --headless --path . --export-debug "Windows Desktop"
# Create an engine-loadable pack and run it locally:
godot --headless --path . --export-pack "Windows Desktop" builds/the_last_verse.pck
godot --main-pack builds/the_last_verse.pck
```

The scene test writes screenshots to `builds/qa/`. Build output and QA captures are ignored by Git and Godot's asset scanner. Test scripts are excluded from exports through `tests/.gdignore` but can be run directly using `--script` in this checkout.


## September 14 — bridge transition, scenery and False Exit

The bridge collapse now cuts to black before the deck drops, plays an original synthesized water impact, and reveals the sewer with movement locked until the fade completes. Actor leaning pivots at the waist, kneeling legs articulate above ground, headwear follows head pose, and market sellers, witches and dark-street residents face their subjects. Shared masonry has staggered brickwork; sewer tunnels have curved vaults, stone ribs, pipes, wet ledges and animated water with edge foam. The dark-act picture filter is reduced for clarity.

Whitechapel now includes the False Exit observation puzzle: three lantern settings, interrupted/continuous ground shadows, three shutter levers, verse clue, plain-text inspection feedback, journal hints, persistent partial progress and a gated ending. Existing saves migrate. The full Act IV finale and final production art/audio are still pending.


## September 14 — continuation to the Metropolitan Railway

The fair lady now emerges at full scale from a controlled opening in the bridge niche, faces the player, and has a separate child-sized model with a plain dress and a visible face framed by hair. Random flying bricks and the miniature-to-giant scaling entrance are removed.

Whitechapel continues into a new service court with walkable stairs, a furnished remembered Dyer house and a history record. A black-faded floor collapse leads to the roofless celestial nursery. Its linked puzzle requires constellation counting, a unique four-keeper logical assignment, reversed sight for two keepers, and a walked sequence of back marks. It includes inspectable signs, accessible atlas text, three hints, partial saving and migration. Solving it grants a playable Metropolitan Railway platform with a steam train and the current end card. The continuation contract and historical sources are in `puzzle_specs/celestial.md`.


## September 14 — revised house route, departure finale and HUD

Owner revision supersedes the earlier floor-collapse transition: the upstairs baby-farm room now has a five-note memory puzzle, with audible tones, flashing labelled bells, captions, replay and partial saves. Solving it moves a bookcase and opens a directly walkable secret corridor into the great star room.

The Metropolitan Railway platform now contains the final puzzle: isolate and clamp a leaking feed, restore flow, balance two related gauges, release the brake and board. The player rides in the accelerating locomotive before the level-complete card and final save. Merely reaching the platform no longer finishes the level. Existing route saves migrate to the new final tasks.

HUD chapter, objective, study letters, captions, prompt, held-item text, controls and save status now share the horizontal centre. Separate vertical bands keep controls and save messages apart; the completion card is centred too.

## Narrative and Whitechapel revision — 2026-09-14

The launcher now presents **Shakespeare and London Times** on an aged title page with an original teaser poem. B opens the traveller's book; pages unlock with act progression and distinguish the visitor from Shakespeare. The held volume is a separate visual from carried puzzle pieces. Scrolls identify themselves as mechanism manuscripts, with wrapped ink typography; letters and books retain distinct presentations.

Seven English act introductions use locally synthesized Daniel narration, paired with temporary screen titles and captions. Narration follows effects volume and ducks music. The historical timeline remains deliberately dreamlike rather than presenting the environments as contemporary to one another.

## Second narrative pass — 2026-09-14

- **Launcher:** a full-screen aged title leaf with a ruled border and fleurons: *The First Chapter, called Shakespeare and London Times*, a seven-line teaser poem that ends on the escape question, and ink entries with manicules.
- **Framing:** the player is a reader, not Shakespeare, trying to escape his London. A new run opens the traveller's book first. Each leaf is a twelve-line verse chronicle of one act.
- **Narrator:** each act opens with a cinematic title card (letterbox, act number, glowing title) and a six-line spoken poem that always ends on a question. It is captioned line by line. The voice is regenerated with pauses and a warm room reverb by `shared/audio/generate_narration.py`, which prefers an installed Premium/Enhanced English voice and falls back to Daniel.
- **Readables:** scrolls (turned rollers, torn paper, drop caps, fleuron rule), letters (wax seal), book (two-page spread on leather) and tablets are now drawn as distinct, textured objects.
- **Whitechapel:** a much larger, darker act. A 3×3 street grid with nine landmarks, rain, rats, heartbeat, whisper and footsteps. The Shadow moves only while the gas is dim and walks a six-stop route. Every stop must be seen in person, then reported in order on the constable's street plan. See `puzzle_specs/streets.md`.
- **Dyer house:** the bells hang over each bed inside a dreamcatcher whose charm (lamp, moon, cradle, door) names the bell, and they swing when rung. A veiled dead woman sits in a rocking chair that rocks by itself, flies circle her, porcelain dolls turn their heads only while unwatched, and an empty cot rocks. Wallpaper is torn and there are scratches. No children's bodies are shown.
- **London Bridge scenery:** `thames_scenery.gd` builds everything in view of the bridge. The quay walls run 700 m. Both banks are built up to the horizon. Downstream (left) is a merchant harbour with warehouses, jetties, swinging treadwheel cranes, moored ships and a mole with a beacon. Upstream (right) is a pound lock with mitre gates, a weir, the keeper's cottage and a water mill. The far bank has the southern gate with its pikes, the Globe, a cathedral spire, a white keep, windmills on the hills, and a river bend at both ends. Galleons, hoys, sailing barges, a state barge and rowed wherries sail looped courses, and swans and gulls move around them. Static geometry is merged into one mesh per material (~46 ms to build).

## Title menu, HUD and bridge attack — 2026-09-14

- **Title menu:** the title page (Play / Settings / Exit) and chapter page sit over `SceneSlides`, a slow Ken Burns dissolve through eight rendered stills of the chapter (`shared/menu/london_*.jpg`) with the act name inked in the corner. ←/→ turns to the two unwritten chapters. The chapter page offers Begin/Resume, Begin Anew, **Hints** (every discovered riddle, revealed one hint at a time) and Back.
- **Menus in one style:** Settings (now including the key list), Pause (*Intermission*), Journal, restart confirmation and the level-end card are all parchment leaves with a ruled border and inked entries.
- **HUD:** the bottom key bar and the top objective text are gone. The top shows only the act (e.g. *ACT II · The Borrowed Stage*). Interaction prompts, captions and save status remain.
- **Whitechapel:** the Shadow is invisible in bright gaslight and appears only while the lamps gutter and dim.
- **London Bridge:** the day darkens and the girl climbs over the parapet instead of stepping out of a wall. She crawls, lunges into a close-up and drags the player down with the collapsing spans; the player falls during the blackout.

## Walled-in girl, fire brew and co-op — 2026-09-14

- **London Bridge:** the girl is visibly immured. There is a bricked arch in the parapet with a cross, chain and padlock, flowers, a child's shoe and scratches. Knocking from inside, a hand through the bricks, then the wall bursts and she crawls out of the chamber.
- **Witches' brew:** each ingredient must go in on the right fire, set with the bellows. The heats come from three scraps held by the witches.
- **Play Together (two players):** direct-IP co-op over ENet, port 24613.
  - **Menu:** chapter page → *Play Together* → *Host a Game* (shows the LAN address) or *Join a Game* (type the address). The host chooses *Begin together*.
  - **Host authority:**
    - The host keeps and saves the run and sends the whole `StudyState` after every change.
    - The companion's interactions are sent to the host and performed there. Captions, notes and the police plan appear only for the player who acted; solved riddles are announced to both.
    - Reading notes, looking closer, trinkets, knocking and similar small actions stay local; the host records any discoveries.
  - **Shared world:**
    - Both players see each other as a caped traveller with a lantern (`CompanionAvatar`), 20 pose updates per second.
    - The host runs the Whitechapel Shadow and streams his pose and the gas clock. The companion's sightings and walked star plates are sent to the host.
    - Cinematics (painting, bridge collapse with each player's own lunge, climbing out, act transitions, train departure) play on both screens.
  - **One carried piece:** only one puzzle piece can be in hand at a time, and only its carrier can place it; the other player is told their companion is carrying it.
  - **Leaving:** if the host leaves, the companion returns to the title and their own untouched save. If the companion leaves, the host keeps playing.
  - **Limitations:** no NAT traversal or Steam lobby yet (internet play needs port forwarding). Trinkets and physics props are not shared. Pausing or reading on the host pauses the host's world, including the Shadow.

## Neural narration — 2026-09-14

All seven narrator poems use local Kokoro British English `bm_george` instead of macOS Daniel. The generator preserves the written verses, varies synthesis pace gently, leaves deliberate pauses before the closing question, and removes the old echo processing. Generated cue starts drive subtitles from the audio playback position, so line changes wait during paused playback. Tooling and model weights are excluded from the Godot project; the game needs only the WAVs and generated cue script. Reproduction: `docs/narration.md`.

## Anthology interface — 2026-09-14

The main menu now has a neutral dark identity, clear typography and an animated abstract threshold motif. Chapter selection introduces each chapter's material: Shakespeare remains a manuscript over London scenes; later unavailable entries use poster/minimal previews. `ChapterCatalog` stores those presentation choices. Shared settings, pause, multiplayer and journal panels use `InterfaceTheme`; physical documents keep `ParchmentView`.

The HUD has corner-based context/shortcuts, a focused interaction plate and separate carried-item text. Scrolls/book pages have finer borders; scrolls include a wax stamp and documents support longer scrolling content. Settings keep Apply & return outside the scroll region. See `docs/interface.md`.
