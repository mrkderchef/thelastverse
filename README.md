# The Last Verse

## Project status

**Working title:** The Last Verse  
**First chapter:** London Is Falling — William Shakespeare  
**Genre:** Single-player, first-person dark-fantasy escape-room adventure  
**Engine:** Godot 4, standard edition, typed GDScript  
**Intended release:** Steam, initially targeting Windows PC  
**Language:** English for all player-facing content, code, and documentation

A playable build is implemented in Godot 4.7.2 stable: the study, bright streets and bridge collapse, plague sewer, the Whitechapel watch for the Uncast Shadow, the remembered Dyer house and celestial nursery, and access to the Metropolitan Railway. The rest of this README remains the design and production blueprint; it does not imply a complete chapter, Steam integration, commissioned assets, or a release date. The working title requires clearance before commercial use. Puzzle solutions below are developer spoilers.

> Wake inside a playwright's abandoned study. Solve the stories he left unfinished. Beyond the door, London is a theatre collapsing into its own nightmares—and the bridge is waiting for its final cue.

## Run the current build

Open `project.godot` in Godot and press **F5**, or run `godot --path .`. The title page has three entries: **Play**, **Settings** and **Exit**. Play opens the chapter page, *Shakespeare and London Times*, over a slideshow of its scenes. Turn to the unwritten chapters with ←/→. From there you can **Begin/Resume the Tale**, start anew, or open **Hints** for the riddles found so far. **Play Together** lets two players share a tale over the network: one hosts (their address is shown), the other joins by typing it. The host's progress is saved, and only one puzzle piece is carried at a time. The in-game HUD shows only the act's name, and the key list lives in Settings. You are not Shakespeare but a reader trapped in his London: a new run opens the traveller's book (B at any time), and every act begins with a spoken verse that ends on a question. The study looks like an ordinary lived-in room; its four puzzles (Seven Ages, Hamlet, Macbeth, Romeo & Juliet) are built into the furniture and solved by handling objects directly. Each reveals one letter; the door’s letter lock opens on **HELP**. Walk through the curtain into the streets of London, open three gates guarded by frozen Shakespeare scenes (Romeo & Juliet props, the Macbeth witches’ brew, and Julius Caesar’s Ides of March on the bridge engine), then step onto London Bridge as it falls. Escape the plague sewer. In Whitechapel, follow the Shadow, who moves only while the gaslight dims, witness all six stops of his route, and report them in order on the constable's street plan. Escape into a back court, climb the stairs into a remembered Amelia Dyer house, solve the room’s memory-bell puzzle to open a secret passage into The Uncounted Stars, then repair the Metropolitan Railway locomotive and depart to complete the level.

**Controls:** WASD move, mouse look, E use or pick up, right click look closer (turns lock wheels back), Q throw what you carry, J journal and hints, Escape pause/back. Partial puzzle progress saves automatically. The menu offers resume and a confirmed restart. Art, audio, and the mirror diagram are placeholders.

**Launcher deviation:** section 12 advises against fake locked chapters. By the project owner’s request, the launcher shows two “??? · Currently unavailable” cards. They do not suggest paid content. Revisit before release.

**Study deviation (owner’s direction):** section 6 below describes sigils, puzzle panels, and a four-sigil exit. The implemented study instead uses physical in-world interaction, no floating labels, and a four-letter lock (H-E-L-P, one letter per puzzle). The mechanisms, clues, and dependency chain otherwise follow section 6. The bridge finale’s use of the study sigils (section 9) must be redesigned around this before Act IV. See [study puzzle contracts](docs/puzzle_specs/study.md) and [street puzzle contracts](docs/puzzle_specs/streets.md).

**Clue style:** every readable note is a short poem in Early Modern English, presented as a parchment scroll, open book, or sealed letter. See section 4.

**Chapter shape (owner’s direction, supersedes sections 7–9):** London begins bright and cheerful. The study is sunlit, the streets are pastel houses under a blue sky with bunting, and the song plays first as a plain melody, then as an ordinary happy nursery rhyme in major. The player leaves the study by stepping into a painting of spring-time London. Three physical street puzzles lead to old **London Bridge**. Its builders once walled a girl, the song’s “fair lady”, into a pier. The witches’ song wakes her, and when the player walks onto the bridge she rises from the stones and sings it down. The player drops into the darker, broken London below: a plague sewer with plague rats, shrouded dead, a plague cemetery, and plague doctors, where the song returns in broken minor versions. Climbing out leads into fog-choked Victorian streets where the Uncast Shadow (the fictional Jack the Ripper presence) is glimpsed at authored cues and never attacks. Tower Bridge is no longer used. The bridge-restoration finale in section 9 must be redesigned around this route.

See [implementation status and verification](docs/implementation_status.md) and [puzzle contracts](docs/puzzle_specs/study.md). First-time playtests and Windows hardware validation are still required.

## 1. Vision and game pillars

The Last Verse is an anthology of self-contained escape adventures inspired by famous writers and historical personalities. Each map transforms its subject's ideas, imagery, and contradictions into a physical place. Release with one complete, satisfying chapter; add further chapters only after the core experience succeeds.

| Pillar | Design commitment |
| --- | --- |
| Understandable literary puzzles | Every required fact exists inside the game. Familiarity with Shakespeare adds recognition, never a prerequisite. |
| A world that behaves like a stage | Scenery moves, props acquire new meanings, and lighting reveals alternate realities. These transformations also explain puzzle rules. |
| Dread with room to think | Horror comes from atmosphere, anticipation, and spatial uncertainty. Players can examine clues without constant pursuit. |
| Tactile, consequential discovery | Turning a dial, aligning a lantern, or placing a prop visibly changes the room or opens a route. |
| A manageable anthology | Reuse interaction, save, UI, and puzzle systems while giving each chapter a distinct visual and narrative identity. |

**Initial boundaries:** no combat, multiplayer, open world, procedural puzzles, crafting tree, survival meters, or mandatory precision platforming. Do not promise additional chapters or paid DLC before production planning.

## 2. Narrative premise

The player is an unnamed visitor drawn into the **Unfinished Theatre**, a supernatural archive where stories become rooms and forgotten fears become actors. The visitor is not Shakespeare and needs no established biography.

An unseen, unnamed presence leaves short stage directions in unsigned letters (the earlier working name “the Prompter” is no longer used anywhere in the game). It wants the player to complete a performance, but its motives remain uncertain. Guidance should clarify actions without narrating every solution.

Chapter I initially resembles London around 1606. It is explicitly a dream interpretation, not a reconstruction of Shakespeare's actual home or a historically accurate encounter. Once the study opens, centuries overlap: Jacobean timber fronts rotate to reveal Victorian streets. Jack the Ripper belongs to this later layer, not Shakespeare's lifetime.

The chapter's central question is whether people must repeat the roles written for them. Its resolution is a practical act of restoring a passage through the city, rather than solving a real historical criminal case.

## 3. Core gameplay loop

1. Enter a small, readable space and identify an immediate obstacle.
2. Examine objects, readable text, lighting, and environmental changes.
3. Collect a limited set of meaningful props and journal clues.
4. Form a hypothesis using information available nearby.
5. Manipulate a mechanism or use a prop on an appropriate target.
6. Receive clear success or failure feedback; keep useful discoveries.
7. Unlock a route, reveal a narrative fragment, and reach a checkpoint.

Exploration should alternate between close observation, a moment of interpretation, and an atmospheric payoff. Optional lore deepens the setting without concealing required instructions.

## 4. Puzzle design principles

- **Teach before testing.** Demonstrate each interaction with a low-pressure example.
- **No literature quizzes.** Supply readable summaries, diagrams, and labels for every necessary association. Never require a quotation from memory.
- **Write every clue as verse.** Readable notes, letters, scrolls, and books are short poems in Early Modern English (thou, doth, ’tis), rhymed like Shakespeare, shown as parchment props rather than interface panels. No attribution lines, footers, or meta text appear on the page. Genuine Shakespeare lines may be woven in; their provenance is recorded in the asset register, not on screen.
- **Keep the verse unambiguous.** Old language is flavour, never obfuscation: each poem names the objects, order, or rule the player needs. The journal’s three-step hints stay in plain modern English as the accessible fallback.
- **Give each puzzle a clear question.** The player should understand what mechanism they are trying to operate even while its answer remains unknown.
- **Make answers deterministic.** Symbol mappings and ordering rules must identify one valid solution, unless multiple solutions are intentionally supported.
- **Avoid arbitrary codes.** Numbers belong to visible mechanisms or meaningful sequences, not unrelated books hidden across the map.
- **Keep essential clues revisitable.** The journal records discovered clue text and diagrams. Puzzle screens allow journal access.
- **Design out softlocks.** Incorrect inputs consume nothing; essential objects cannot be dropped out of reach; completed mechanisms remain completed.
- **Use redundant feedback.** Combine shape, text, sound, and movement. Never require color discrimination, perfect hearing, or tiny text.
- **Offer three optional hint levels:** point to the relevant area, explain the relationship, then state the action or solution. Hints have no achievement penalty.
- **Respect pauses.** Reading, inspecting, and using menus suspend any threat sequence. Mandatory puzzles have no real-time countdown.

For each implemented puzzle, document its stable ID, entry conditions, available clues, solution, wrong-input response, completion event, rewards, persistent state, hints, and reset behavior. Test with players who have not studied Shakespeare.

## 5. Chapter I: London Is Falling

The complete chapter targets roughly **60–90 minutes for a first playthrough**, subject to playtesting. This is a design target, not a marketing claim. The first vertical slice is substantially smaller.

| Act | Place | Main experience | Exit condition |
| --- | --- | --- | --- |
| I — The Unwritten Room | Shakespeare's study | Learn inspection, clues, and literary mechanisms | Complete the four study puzzles and open the study door |
| II — The City Is a Stage | Backstage passage and compact London street | Discover scenery transformations and restore a route | Align the street's stage lights |
| III — The Uncast Shadow | Victorian street overlay | Contain a fictional Ripper presence through observation and light | Release the bridge route and obtain the Lantern Sigil |
| IV — The Last Crossing | Impossible London Bridge | Combine learned rules in a final scenic transformation | Restore the bridge and cross |

Use a small sequence of connected spaces, not a simulated city. New acts can load as separate scenes behind doors, curtains, or fades.

## 6. Opening: Shakespeare's study

Begin seated or standing at a desk, with an optional brief fade-in. A candle illuminates a blank manuscript. Rain taps against a window showing an impossible bridge. The music introduces a sparse instrumental fragment of the nursery-rhyme melody.

A newly written note reads:

> The room remembers every part. Put the players in their places, and the door will remember yours.

The first interaction is a large, clearly visible folded page. Picking it up teaches interaction and readable text; opening its journal entry teaches recall. There is no threat during the tutorial.

The player then sees four recognizable stations: a miniature banquet, a skull cabinet, paired balcony models, and a circular life-stage dial. A stage diagram over the exit makes their shared purpose clear. Lighting and prop movement signal progress without cluttering the room with objective markers.

### Study puzzle A — The Seven Ages

**Inspiration:** the seven ages speech in *As You Like It*.  
**ID:** `study.seven_ages`  
**Mechanism:** seven labeled tokens fit into a clockwise dial.

The nearby illustrated booklet lists the sequence explicitly in accessible language: **Infant → Schoolchild → Lover → Soldier → Judge → Elder → Second Childhood**. Each token has a matching shape and label. A cradle symbol and clockwise arrow identify the starting slot and direction; the two childhood stages have distinct icons.

The challenge is translating the booklet into a physical arrangement, not recalling the speech. Incorrect submissions produce a soft mechanical reset of the confirmation lever while preserving token positions. Correct placement opens a drawer containing the **Skull Handle** and permanently records the **Hourglass Sigil** in the journal.

Hints: examine the illustrated booklet; follow its life sequence clockwise from the cradle; provide the complete order.

### Study puzzle B — Hamlet: The Witness in the Mirror

**ID:** `study.hamlet_mirror`  
**Prerequisite:** Skull Handle from Seven Ages.  
**Mechanism:** fit the handle into a skull pedestal, then rotate three symbol dials.

The handle reveals a mirror and a rehearsal card. The card instructs the actor to read the reflected props from left to right, using the arrow engraved on the mirror frame. The reflection clearly shows **Ear → Crown → Cup**; the physical prop arrangement is reversed. Each dial supports these three symbols plus a few distinct decoys.

A short accompanying summary introduces suspicion, testimony, and a poisoned court without requiring knowledge of Hamlet's plot. The symbols are a designed mechanism, not a claim about an exact scene in the play. Entering the reflected order opens the cabinet, awarding the **Moon Lens** and **Skull Sigil**.

Hints: look into the revealed mirror; follow the mirror's reading arrow; enter Ear, Crown, Cup. A journal diagram reproduces the reflection, so the puzzle remains accessible without deciphering a visual effect.

### Study puzzle C — Macbeth: The Empty Seat

**ID:** `study.macbeth_banquet`  
**Mechanism:** arrange three labeled figures and leave one of four banquet seats empty.

A miniature stage contains four seats, numbered left to right from the player's marked viewing position. A rehearsal sheet states: “The crowned host takes seat two. Place the companion one seat farther right, following the arrow. The guest takes seat four. Leave the remaining place for the one nobody sees.” An engraved arrow points toward increasing seat numbers, removing ambiguity about whose right is intended.

The unique solution is **Empty → Crowned Host → Companion → Guest**. When confirmed, a ghostly silhouette occupies the empty seat. The effect has a gentle alternative when reduced-intensity settings are enabled. The table opens a compartment containing the **Sun Lens** and **Crown Sigil**.

The scene expresses guilt and haunting. No biography, murder reenactment, or quotation recall is needed. Wrong arrangements rattle the table softly and leave the figures available.

Hints: read the rehearsal sheet; place the host and companion first; provide the four-seat arrangement.

### Study puzzle D — Romeo & Juliet: Across the Divide

**ID:** `study.balcony_lights`  
**Prerequisites:** Moon Lens and Sun Lens.  
**Mechanism:** direct two adjustable lanterns toward balcony targets.

A model theatre separates two balconies with a black curtain. A diagram routes the **sun-marked lantern to the rose balcony** and the **moon-marked lantern to the ivy balcony**. Labels and shapes duplicate the color distinctions. Insert the lenses and rotate each lantern through clearly snapped positions until both receivers light up.

A summary introduces two people separated by their households. Solving the mechanism draws the curtain aside and joins the miniature balconies, producing the **Joined Hands Sigil**. The solution emphasizes connection rather than reenacting the lovers' deaths.

Hints: examine the routing diagram; match each lens to its receiver symbol; specify the two destinations. Incorrect directions simply leave the corresponding receiver unlit.

### Study exit — The cast is complete

The four earned sigils appear as reusable journal records and unlocked controls on the exit panel. They are not consumable inventory items. An illustrated stage plan above the door gives the order **Hourglass → Skull → Crown → Joined Hands**. Arrange the panel accordingly and pull the curtain cord.

Dependency flow:

```text
Seven Ages → Skull Handle → Hamlet → Moon Lens ─┐
Macbeth → Sun Lens ─────────────────────────────┴→ Romeo & Juliet
All four sigils → Study exit
```

Macbeth can be solved at any time. Essential rewards transfer automatically, preventing an opened-but-uncollected drawer from silently blocking progress. The diary retains all four sigils for the bridge finale.

## 7. London transition: behind the scenery

The study door opens onto a narrow backstage passage. From behind, the study window is painted canvas; the rain came from a suspended mechanism. Pulling a stage rope reveals a street beneath a ceiling of darkness.

The city feels like London assembled by a theatre dreaming of London: crooked timber facades, distant towers, suspended bridges, painted skies, visible rigging, and an orchestra pit where the Thames should be. Shadows occasionally move before their owners.

The first street puzzle teaches the next rule safely. Rotate three numbered spotlights to illuminate matching symbols on scenery panels. Lit panels turn into solid passages; unlit panels remain flat painted walls. A backstage cue sheet gives the spotlight-to-symbol mapping. No route can close while the player occupies it.

At completion, one facade rotates too far. Gas lamps and a fictional late-Victorian playbill appear behind the Jacobean scenery. The journal explicitly recognizes that the street belongs to a different century. This prepares the Ripper component and makes the anachronism deliberate.

## 8. Jack the Ripper integration

Jack the Ripper appears as **the Uncast Shadow**, an invented supernatural presence shaped by the city's fear and sensational stories. An optional journal note makes clear that this is a fictional interpretation of a historical horror, not a proposed identity or reconstruction of crimes.

Keep the figure peripheral: a silhouette across a foggy street, footsteps after the player stops, an empty coat beneath a streetlight. Avoid heroic framing, collectible weapons, kill rewards, suspect accusations, graphic remains, and real victims used as puzzle props. No playable murderer perspective. Fictional residents should be represented through ordinary belongings and evidence of community care rather than spectacle.

### Encounter: The False Exit

Three street arches look like possible exits. A lantern tutorial and cue sheet establish the rule: **a real passage casts a continuous shadow toward a brass floor marker; painted exits break the shadow at their seam**. A high-contrast outline and readable inspection description communicate the same distinction.

The player adjusts a fixed inspection lamp, identifies the solid passage, and follows three safe light pools to it. The Uncast Shadow moves only at authored cue points, with visible and audible warnings. It does not roam freely or attack while the player reads.

Entering an unsafe area triggers dimming light, footsteps, a brief fade, and return to the last safe pool. Keep collected clues and completed adjustments. No graphic attack or long replay. **Reduced Threat** mode removes the reset and leaves the scene as an atmospheric observation puzzle; it preserves all content and achievements.

At the final light pool, the player operates a shutter that closes the threatening figure behind an empty stage frame. This contains the fictional presence; it does not suggest solving the historical murders. The bridge route opens and the player records the **Lantern Sigil**.

## 9. Finale: London Bridge

The bridge hangs in disconnected pieces above a dark river. Its support towers resemble theatre wings. The nursery melody returns across separate instrumental voices as the player restores the crossing.

Five bridge mechanisms accept the four study sigils and the Lantern Sigil. An illuminated relief gives their complete arrangement through labeled scenes: **A life passes → A witness speaks → A ruler falls → Two hands meet → A light remains**. These map to **Hourglass → Skull → Crown → Joined Hands → Lantern**. All required information is visible here and available in the journal.

After setting the five symbols, operate one clearly marked stage lever. Bridge segments rotate and lock into place, the scenery tears open above the river, and the music resolves. The apparent collapse is theatrical animation; there is no hidden countdown or dexterity test. A short walk reaches the far door.

Crossing ends Chapter I and records completion. The player returns to chapter selection after a short epilogue: a new blank page in the Unfinished Theatre. The chapter must provide closure even if no further maps are ever produced.

## 10. Visual direction

Aim for stylized, painterly 3D with exaggerated silhouettes and tactile materials. Prioritize coherent composition over photorealism. Build modular walls, stage flats, street arches, and reusable props to control production cost.

The study uses candle amber, dusty parchment, dark wood, and restrained burgundy. London shifts toward cold blue, weathered stone, and dirty gold. The Victorian overlay introduces sickly lamplight without relying on color alone for navigation. The bridge combines these palettes as the story resolves.

Use readable pools of light, strong object silhouettes, subtle dust, and limited moving shadows. Darkness must not hide essential interaction targets. Provide exposure calibration, legible note overlays, scalable UI, and optional object highlighting. Avoid obligatory film grain, chromatic aberration, head bob, or motion blur.

No supplied reference image has been reviewed for this document; this direction is based on the written brief.

## 11. Audio direction

Commission or create an **original instrumental arrangement and original recording inspired by the public-domain melody “London Bridge Is Falling Down.”** No sung lyrics. Establish the exact historical melody source before production and document it in the asset register.

Suggested palette: felt piano, plucked strings, bowed bass, small bells, restrained music-box tones, and distant theatre machinery. Use sparse motifs in the study, incomplete phrases in London, low-texture tension around the Shadow, and a fuller resolution on the bridge. Leave silence between musical statements to reduce repetition.

Use positional footsteps, creaking wood, ropes, shutters, rain, and distant stage cues. Puzzle success sounds should differ clearly from ambient disturbances. Audio clues always have visual or text equivalents. Provide separate Master, Music, Effects, and Voice buses; captions cover meaningful non-speech sounds. Full voice acting is optional and outside the first slice.

## 12. Menus and chapter selection

The opening screen presents the working title over a slowly moving stage curtain:

```text
THE LAST VERSE

Continue          [shown only when a valid save exists]
Play
Settings
Credits
Quit
```

**Play** opens **Select a Chapter**. At first release there is exactly one playable card:

```text
CHAPTER I — LONDON IS FALLING
William Shakespeare
A London outside time

Enter Chapter / Resume Chapter
Restart Chapter
```

Show completion status and a short spoiler-free synopsis. Restart requires confirmation because it replaces that chapter's run progress. Selecting a card must never reset a save. An optional noninteractive “More stories may follow” panel is enough; avoid fake locked chapters suggesting purchased content is missing.

Possible future inspirations include Poe, Dante, Kafka, and Van Gogh. They remain ideas, with separate rights and scope reviews. The anthology format does not guarantee their production.

Pause menu: Resume, Journal, Settings, Save & Return to Menu, Restart from Checkpoint, and Quit to Desktop. Clearly indicate save completion before closing a session.

## 13. Player, inventory, and interactions

Use a grounded first-person controller with walking and mouse look. Begin without jumping or sprinting; author spaces around accessible walking routes. Add crouching only if a tested puzzle needs it.

| Default action | Keyboard / mouse |
| --- | --- |
| Move | WASD |
| Look | Mouse |
| Interact / pick up | E |
| Inspect focused object | Right mouse button |
| Confirm / use selected item | Left mouse button in an interaction context |
| Inventory | Tab |
| Journal | J |
| Pause / back | Escape |

All actions use Godot's Input Map and are remappable. Context prompts show current bindings. Menus and puzzle widgets require consistent keyboard focus; controller support is a planned release feature that must be tested before being advertised.

Interaction states are **Explore**, **Inspect**, **Puzzle**, **Menu**, and **Transition**. Only one owns input at a time. Inventory and journal are overlays within the appropriate state. Closing them restores the previous camera and cursor behavior.

Use a small named-item inventory with icons and descriptions. Allow rotation of suitable inspection props. No weight, durability, item dropping, or general crafting. Wrong item use provides a short contextual response and never consumes the item. Inserted key props become persistent socket state and cannot disappear during reload.

Distinguish physical inventory items from permanent clue/sigil records. Provide an optional interaction outline and readable object names; use raycast occlusion and a short configurable reach so players cannot interact through walls.

## 14. Saving, settings, and accessibility

Start with one local profile and one active chapter run. Save inventory, journal discoveries, puzzle progress including partial arrangements, chapter and checkpoint IDs, completion flags, and hint progress. Settings and earned achievements persist independently of chapter restarts.

Autosave after committed puzzle changes, awarded items, and safe scene transitions. Save & Return captures the latest committed state and restores the player at a safe anchor on resume. Do not serialize an animation halfway through execution. During transitions, defer leaving until a stable state is available.

Use a versioned save schema in `user://`, stable authored object IDs, a temporary-file write followed by replacement, and a last-known-good backup. Never save live node references. On load, validate data, restore state before enabling input, and avoid replaying rewards. Handle missing, damaged, and older saves with an intelligible recovery message.

Settings should include resolution, display mode, VSync, frame-rate cap, quality preset, brightness calibration, field of view, mouse sensitivity, invert Y, key rebinding, separate audio sliders, captions, text/UI scale, head-bob toggle, camera-shake toggle, reduced flashes, Reduced Threat, and optional highlighting. Unsupported graphics options must be hidden or disabled with a reason.

Use a comfortable default FOV and no mandatory camera shake. Ensure caption contrast, scalable clue text, symbol labels, no color-only answers, and no rapid button-mashing. Display a concise content notice for supernatural horror, threat, and references to historical violence.

## 15. Steam features and proposed achievements

The full game must run locally without a Steam client connection. Add Steam integration after the slice proves the game loop. Keep achievement requests behind a platform adapter with a local fallback; reconcile locally earned achievements when Steam becomes available.

| Stable achievement ID | Display name | Condition |
| --- | --- | --- |
| `ACH_FIRST_PAGE` | The First Page | Record the introductory study clue |
| `ACH_SEVEN_AGES` | A Lifetime in Pieces | Solve the Seven Ages dial |
| `ACH_STUDY_ESCAPE` | Exit, Pursued by Silence | Leave the study |
| `ACH_CITY_STAGE` | The City Is a Stage | Complete the street lighting puzzle |
| `ACH_SHADOW_CONTAINED` | A Light Remains | Complete the Shadow encounter in either threat mode |
| `ACH_BRIDGE_RESTORED` | London Still Stands | Restore the bridge |
| `ACH_CHAPTER_ONE` | The Last Crossing | Finish Chapter I |

Unlock each achievement once. Hints and accessibility settings never invalidate rewards. Avoid achievements based on historical murders, victim collectibles, or repeated failure. Optional lore completion can be added only when its tracking is reliable.

Potential release features include Steam Cloud and controller support. Cloud requires a deliberate save-path and conflict policy; it is not automatically supplied by local saves. Steam Deck compatibility and additional operating systems need device testing before any claim.

Plan store materials, content disclosures, build review, and release scheduling separately from coding. Valve documents onboarding and release requirements in the [Steamworks onboarding guide](https://partner.steamgames.com/doc/gettingstarted/onboarding); recheck the live requirements when preparing submission.

## 16. Technical architecture

### Engine and rendering

Use a stable Godot 4 standard build and typed GDScript. Record the exact chosen engine version in the repository and use matching export templates. Do not automatically upgrade a working project during a milestone.

Start with **Forward+** for the intended desktop 3D lighting, provided the development machine supports it. If the initial scene runs poorly, evaluate Mobile or Compatibility early. Renderer changes can require different lighting and effects; fog must never be the only carrier of a required clue. This recommendation follows Godot's [renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).

### Scene and service responsibilities

| Component | Responsibility |
| --- | --- |
| `Main` scene | Boot, menu presentation, and the active chapter container |
| `Player` scene | `CharacterBody3D`, camera, movement, focus ray, and interaction dispatch |
| `Interactable` component | Prompt, availability, inspect data, and interaction contract |
| Puzzle scene/controller | Local mechanism state, validation, feedback, and completion signal |
| Chapter controller | Local dependencies, scene cues, safe anchors, and act transitions |
| `GameSession` autoload | Authoritative serializable run state and chapter routing |
| `SaveService` autoload | Validation, migrations, backup, load/write operations |
| `SettingsService` autoload | Settings persistence and application |
| `AudioDirector` autoload | Music transitions and shared audio buses |
| `PlatformService` autoload | Achievement adapter and optional Steam integration |

Use typed custom Resources for immutable `ChapterDefinition`, `ItemDefinition`, `PuzzleDefinition`, and `HintDefinition` data. Keep mutable run state in the session rather than editing shared Resource defaults during play. Add services only when their functionality is implemented; avoid empty architecture scaffolding.

Prefer composition and explicit references. A puzzle emits a completion signal with its stable ID; the chapter controller commits the result, adds rewards once, updates exits, and requests a save. The UI observes state changes. A central global event bus is unnecessary for the first room.

Use stable IDs such as `london.study.macbeth`, not scene-tree paths, for persistence. Register persistent scene objects when loading. Validate duplicate IDs in development. Derive door availability from saved puzzle flags so transitions remain correct after reload.

For the Shadow, use an authored state machine—Dormant, Telegraph, Passage, Reset, Contained—with a few cue zones. Do not begin with a general enemy navigation system. Threat mode changes reset behavior without changing puzzle completion rules.

### Performance and platform scope

Prototype with simple collision shapes, modular meshes, modest textures, and few shadow-casting lights. Measure frame time in the study and the largest London view before adding expensive effects. Aim for 60 FPS at 1080p on a documented reference Windows PC; select that hardware and validate it before publishing minimum requirements.

Windows is the first shipping target. Development on macOS is supported by the chosen workflow, but Windows exports still require testing on actual Windows hardware. A successful editor run is not release validation. macOS and Linux releases remain optional scope decisions.

## 17. Recommended Godot 4 project structure

This is a proposed future layout, not a list of files already implemented. Group feature-specific scenes, scripts, and assets together, consistent with Godot's [project organization guidance](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html).

```text
the_last_verse/
├── README.md
├── project.godot
├── .gitignore
├── .gitattributes
├── export_presets.cfg
├── addons/                       # Reviewed third-party plugins
├── app/
│   ├── main.tscn
│   └── main.gd
├── autoload/
│   ├── game_session.gd
│   ├── save_service.gd
│   ├── settings_service.gd
│   ├── audio_director.gd
│   └── platform_service.gd
├── core/
│   ├── interaction/
│   ├── inventory/
│   ├── journal/
│   ├── puzzles/
│   ├── persistence/
│   └── data/                     # Resource class definitions
├── player/
│   ├── player.tscn
│   └── player_controller.gd
├── ui/
│   ├── main_menu/
│   ├── chapter_select/
│   ├── hud/
│   ├── inventory/
│   ├── journal/
│   ├── settings/
│   └── pause_menu/
├── chapters/
│   └── london_is_falling/
│       ├── chapter_definition.tres
│       ├── chapter_controller.gd
│       ├── study/
│       │   ├── study.tscn
│       │   ├── seven_ages/
│       │   ├── hamlet_mirror/
│       │   ├── macbeth_banquet/
│       │   └── balcony_lights/
│       ├── backstage/
│       ├── london_street/
│       ├── shadow_encounter/
│       ├── bridge/
│       └── data/                 # Item, clue, hint, and puzzle Resources
├── shared/
│   ├── props/
│   ├── materials/
│   ├── shaders/
│   ├── fonts/
│   └── audio/
├── localization/
├── tests/
│   ├── unit/
│   └── integration/
├── docs/                         # Add .gdignore
│   ├── puzzle_specs/
│   ├── asset_register.md
│   └── decisions.md
├── licenses/
└── builds/                       # Ignored by Git; add .gdignore
```

Track source assets, `.tscn`, `.tres`, scripts, `project.godot`, generated source-side `.uid` files, and relevant import configuration. Ignore `.godot/`, generated builds, temporary files, secrets, and local signing material. Keep nonsecret export presets under review. Configure Git LFS for selected large binary assets before their first commit. See Godot's [version control guidance](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html).

## 18. Vertical slice: the smallest convincing game

**Target:** approximately 10–15 minutes, ending with the study door opening onto a short theatrical London reveal.

Include one main menu, one chapter card, a compact study, first-person walking, reliable interaction, note reading, a minimal journal/inventory, **Seven Ages and Hamlet**, a two-sigil temporary exit panel, one atmospheric transformation, local save/load, pause, essential settings, and a placeholder original musical sketch.

The slice's two-sigil door is explicitly a temporary variant; the full chapter uses all four study puzzles. Store a content-version marker so prototype saves are not silently treated as release saves.

Defer Macbeth, Romeo & Juliet, the full street puzzle, the Shadow encounter, the bridge, live Steam integration, voice acting, and additional chapters. Prove one polished experience before expanding.

**Acceptance criteria:**

- A new player can launch, choose Chapter I, solve both puzzles from in-game clues, and reach the reveal.
- At least three first-time testers without required Shakespeare knowledge can finish using the supplied hint system; record where they become confused.
- Wrong inputs, repeated interactions, and loading during partial progress cannot lose an essential item or award duplicates.
- Reload after each puzzle and after the transition restores a coherent world and journal.
- Prompts, note text, cursor capture, and pause behavior work consistently.
- Music and effects sliders work; motion options persist between launches.
- The intended export launches outside the editor with no missing resources or runtime errors in the tested route.
- Performance is measured on a named test machine; unresolved frame-time problems are recorded before art expansion.

## 19. Roadmap and milestone gates

| Milestone | Deliverable | Gate before proceeding |
| --- | --- | --- |
| 0 — Foundation | Godot project, Git, input actions, test room | Walk, inspect, and export a basic scene |
| 1 — First puzzle | Seven Ages, journal, reward, persistence | Solve and reload without state loss |
| 2 — Vertical slice | Hamlet, menus, two-sigil exit, London reveal | Meet slice acceptance criteria |
| 3 — Complete study | Macbeth, balcony lights, final study door | Independent playtest of complete dependency chain |
| 4 — London | Backstage, street lighting, authored Shadow sequence | Threat modes and checkpoints remain fair |
| 5 — Complete chapter | Bridge, ending, full journal and hints | Full start-to-finish playtest without blockers |
| 6 — Production polish | Final art/audio, accessibility, performance, controller pass | Target-hardware and export checks pass |
| 7 — Steam preparation | Integration, store assets, disclosures, release candidate | Platform review and launch checklist completed |

Estimate time and budget after the slice. Keep each milestone playable. If scope grows, reduce scene count or optional effects before removing clue clarity, checkpoint reliability, or the chapter ending.

## 20. Assets, attribution, and legal notes

Maintain an asset register containing asset name/path, creator, source URL, exact license and version, acquisition date, modifications, attribution, commercial-use terms, and proof of permission where applicable.

- **Shakespeare:** base text use on verified public-domain sources. Modern translations, annotations, editions, performances, recordings, and visual adaptations require their own checks. Preserve provenance for every actual quotation; do not label newly written prose as authentic Shakespeare.
- **Music:** distinguish the traditional melody from a modern arrangement and its recording. Create or commission both the arrangement and recording; confirm rights for game distribution, trailers, promotional clips, and any soundtrack release. Do not copy a recognizable modern adaptation. The U.S. Copyright Office explains the distinction between composition and recording in [Circular 56](https://www.copyright.gov/circs/circ56.pdf); evaluate the selected source and intended territories before shipping.
- **Historical horror:** keep the Shadow fictional and respectful. Avoid real victim imagery, unsupported accusations, and unlicensed modern photographs or illustrations. Historical subject matter does not grant rights to an asset depicting it.
- **Art, fonts, audio, and plugins:** verify commercial distribution and attribution terms, including restrictions on redistribution of source assets. “Free to download” is not an adequate license record.
- **Generated assets:** record tool provenance and relevant terms; review for unwanted third-party likenesses, logos, and unusable details. Check current Steam content-survey requirements when submitting.
- **Godot:** its MIT license supports commercial projects, with required license notices. Include Godot and applicable third-party notices in the distributed credits/licenses. See the [official Godot license page](https://godotengine.org/license/).
- **Project ownership:** engine licensing does not choose a license for this game's code or artwork. Decide repository licensing and contributor/commission agreements explicitly before public distribution.
- **Branding:** The Last Verse is provisional. Check game-title and trademark availability before investing in store branding.

## 21. Coding conventions and Codex collaboration

Use this README as the shared design baseline. Keep current implementation status and approved deviations in project documentation. A planned feature must never be reported as complete merely because a stub or folder exists.

### Code and data conventions

- Use typed GDScript, explicit return types, and small functions with clear responsibilities.
- Use `snake_case` for files, folders, functions, variables, and signals; `PascalCase` for classes and nodes; `UPPER_SNAKE_CASE` for constants.
- Use tabs for GDScript indentation and consistent formatting. Avoid unrelated formatting changes.
- Use English identifiers, comments, UI text, and documentation. Store player-facing strings behind stable localization keys as UI systems are added.
- Use signals for local events and exported references for authored dependencies. Avoid brittle long node paths, magic strings scattered across scripts, and oversized global managers.
- Use Input Map actions instead of hardcoded physical keys. Use delta-aware movement and the physics update for character motion.
- Keep puzzle validation separate from animations. Commit rewards once, then play feedback; restoration must not fire the reward logic again.
- Save stable IDs and plain values, validate loaded data, and version schema changes. Never execute scripts or instantiate arbitrary resources from save contents.
- Explain non-obvious intent in comments. Favor readable implementation over premature frameworks.

### Working agreement

1. Inspect the existing project and relevant instructions before editing. Preserve the user's current work.
2. Define a bounded change with an observable outcome, such as “Picking up the Skull Handle updates inventory and survives reload.”
3. Build one playable increment. Reuse established systems before introducing new services or dependencies.
4. Keep scene edits focused. Avoid simultaneous manual and editor changes to the same scene; review serialized scene diffs for accidental changes.
5. Verify the changed path in Godot and, when relevant, in an exported build. If an environment prevents testing, state exactly what remains unverified.
6. Add focused automated tests for consequential logic: puzzle validation, item consumption, save migration, idempotent rewards, and chapter dependencies. Use manual checks for presentation and feel; avoid tests that merely duplicate implementation.
7. Report what changed, how it was checked, and any remaining issue. Update the README only when design or setup behavior changes.
8. Use small, meaningful Git commits. Do not silently reset work, upgrade the engine, add paid dependencies, or publish builds/accounts as a side effect of routine coding.

**Definition of done for a puzzle:** fair clues and hints; reachable inputs; deterministic validation; useful feedback; no item loss; correct partial and solved reload; accessible equivalents; chapter progression connected; developer notes updated.

## 22. Development setup

### Recommended environment

Use **Godot's editor plus typed GDScript** for the first milestone. Godot handles scenes, imports, animation, running, and debugging. Its built-in script editor is sufficient. VS Code is an optional text editor; Cursor is an alternative if already preferred, with its Godot integration verified separately. Git records changes, and a private GitHub repository can provide remote backup and collaboration.

### Install and create the project

1. Download a **stable Godot 4 standard build** from the [official download page](https://godotengine.org/download/). Choose your operating system. The .NET build is for C# support and is unnecessary for this GDScript plan.
2. On macOS, download the universal app, extract it, and move `Godot.app` into Applications. Open it normally; Godot is self-contained. On Windows, extract the official archive into a permanent tools folder and run the editor. See the [macOS download instructions](https://godotengine.org/download/macos/) or [Windows download instructions](https://godotengine.org/download/windows/).
3. In the Project Manager, create **The Last Verse** in a dedicated local folder. Select Forward+ if supported, and Git version-control metadata. Record the exact engine version selected.
4. Place this README in that project root. Create a basic 3D room and player scene, set the main scene, then run the project. The game systems in this document still need implementation.
5. Install Git using the [official Git installation guidance](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git). Initialize and make a first commit; generated ignore files alone are not a backup. Optionally connect a private GitHub repository and push the commit. Configure LFS before committing large assets.
6. If using VS Code, install the [Godot Tools extension maintained by the Godot organization](https://github.com/godotengine/godot-vscode-plugin), then set the external editor in Godot under **Editor → Editor Settings → Text Editor → External**. Keep the Godot project open for language-server features. See the [external editor guide](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html).
7. When preparing the first export, install **export templates matching the engine version** through Godot's export-template manager. Create a Windows export preset and test the resulting build on Windows before expanding content. See Godot's [exporting projects guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html).

**Next implementation task:** playtest the complete study (milestone 3 gate) with first-time players, address clue and interaction friction, and validate the Windows build before starting the backstage passage and London street. See the current implementation status above.


**Expanded route (owner direction, September 14):** after Whitechapel, a rear court and staircase lead into a dream of Amelia Dyer’s Reading house. A memory-bell puzzle opens a bookcase passage into the great star hall. A three-stage celestial deduction links visible stars, reverse-facing keepers and walked floor symbols; solving it opens the Metropolitan Railway, where repairing the locomotive and departing completes the level. This supersedes the old bridge-restoration Act IV outline. See [celestial puzzle contract](docs/puzzle_specs/celestial.md).
