# Act I study puzzle contracts

Content version: `london-study-2`, save schema 3. Rules live in `core/puzzles/study_state.gd`.

Every puzzle is solved by acting directly on objects in the room. There are no puzzle screens. **E** uses the object under the crosshair. **Right click** gives a short spoken-style description; on the lock wheels it turns the wheel backwards instead. Reading a note opens it full-screen. Hints live in the journal (**J**), three per discovered puzzle.

Each finished puzzle reveals a paper card with one letter and one to four position marks. The door's four-wheel letter lock opens on **H-E-L-P**.

Save handling: older saves (`london-study-1`, `study-prototype-1`) are rejected and a fresh chapter starts. A piece carried in the hand is saved and restored. A chapter restart resets the run after confirmation; settings are kept.

```text
Seven Ages (H) → Skull Handle → Hamlet (E) → Moon Lens ─┐
Macbeth (L) → Sun Lens ─────────────────────────────────┴→ Romeo & Juliet (P)
H E L P → letter lock → door
```

## Hands and pockets

- **Hand:** one loose puzzle piece at a time (a dial token or a banquet figure). It appears at the bottom right of the view and is named in the HUD. Using a slot at the piece's own station places it there, swapping if the slot is occupied. Touching the other slot station first returns the carried piece to the empty slot it came from, so a piece can never be lost or stranded.
- **Pockets:** key items (Skull Handle, Moon Lens, Sun Lens). They are picked up from opened compartments and used on their sockets. They never occupy the hand.

## `study.seven_ages` — letter H (1 mark)

- Where: a brass dial on the left wall above a sideboard. The booklet lies on the sideboard.
- Inputs: seven sockets arranged clockwise, starting beneath a small gold arrow. Each holds a carved token: cradle, satchel, rose, sword, scales, cane, snuffed candle.
- Clue (booklet): the seven ages mapped to those tokens, in order. The opening line is quoted from *As You Like It*.
- Solution: clockwise from the arrow, cradle → satchel → rose → sword → scales → cane → candle. It completes automatically when the last token is placed.
- Completion: the dial glows, the drawer slides out, and the H card and Skull Handle appear inside. The dial locks.
- Hints: the booklet explains the tokens; start under the arrow and go clockwise; how to swap tokens plus the full order.

## `study.hamlet_mirror` — letter E (2 marks)

- Where: a tall cabinet against the right wall.
- Entry: fit the Skull Handle into the skull-shaped socket. The cloth falls and the mirror shows three glowing shapes, left to right: ear, crown, cup, with an arrow under them. Three physical props on top stand in the reverse order as a decoy.
- Inputs: three dials. Each use advances one symbol through ear, crown, cup, rose, bell. Before the handle is fitted, the dials do not turn.
- Clue: the rehearsal card in the mirror frame says to trust the glass, not the props.
- Solution: ear, crown, cup. It completes automatically.
- Completion: the lower door swings open, revealing the E card and the Moon Lens.
- Hints: find the handle and read the card; match the glowing shapes and ignore the props; ear, crown, cup.

## `study.macbeth_banquet` — letter L (3 marks)

- Where: a toy banquet on a sideboard against the left wall. A gold floor mark shows where to stand, and an arrow on the front edge points right.
- Inputs: four chairs carrying one to four notches. Three figures (crowned host, companion in a hat, guest) are picked up and placed like tokens; one chair stays empty.
- Clue: the rehearsal sheet on the backdrop: “The crowned host takes seat two. Place the companion one seat farther right… The guest takes seat four. Leave the remaining place for the one nobody sees.”
- Solution: notches 1 empty, 2 host, 3 companion, 4 guest. It is unique and completes automatically.
- Completion: a pale translucent figure sits in the empty chair (no flash, no sound sting). The drawer opens with the L card and the Sun Lens.
- Hints: read the sheet and count notches; host on two, companion to its right, guest on four; the full seating.

## `study.balcony_lights` — letter P (4 marks)

- Where: a model theatre on a table against the right wall, with a rose balcony (left), an ivy balcony (right), and a black curtain between them.
- Inputs: two crossed lanterns. The sun lantern (gold disc) is on the right, the moon lantern (pale crescent) on the left. Using a lantern fits its lens if you carry it; after that, each use turns it to the next of four snapped targets (rose balcony, curtain, ivy balcony, empty stalls). Beams are visible, and a receiver lights only for its own lantern.
- Clue: the routing diagram on the table: SUN → ROSES, MOON → IVY.
- Solution: sun on rose, moon on ivy. It completes automatically when both receivers are lit.
- Completion: the curtain rises, a walkway joins the balconies, and the P card stands on it.
- Hints: which lenses to fetch and the diagram; the pairing; fit both lenses and turn until the beams land.

## Exit — the letter lock

- Where: bolted to the study door.
- Inputs: four wheels A–Z. E turns a wheel forward, right click turns it back.
- Clue: the letter cards with their position marks, collected at the top of the journal and in the HUD.
- Solution: `HELP`. The lock does not check which puzzles were solved; knowing the word is what gates it.
- Completion: the shackle opens, the door swings in and its collision clears. Entering the overlook commits `completed` once.
- Hints: cards and marks; order by marks; H, E, L, P.

## Optional lore pages

`page_bed` (under the pillow), `page_cues` (on the rug), `page_costumes` (on the trunk), and `page_window` (nailed beside the window) are readable notes. They carry no required information.
