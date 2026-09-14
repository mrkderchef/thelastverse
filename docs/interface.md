# Interface and chapter presentation

The global interface uses `ui/interface_theme.gd`: dark slate surfaces, clear system
sans-serif type, restrained serif headings, pale text and champagne focus indicators.
The title screen uses the animated, procedural `MenuBackdrop` threshold motif. No
Shakespeare paper, London scene images or period-specific title copy is used there.
Settings, pause, multiplayer, journal and hints share the same navigation language.

`ui/chapter_catalog.gd` defines chapter-select presentations independently of the
navigation shell. Chapter I has a manuscript and London scene backdrop. Chapter II
has an unannounced poster treatment; Chapter III uses a minimal dark treatment.
These are clearly unavailable previews, not promises of particular chapter content.
The arrow controls, keyboard browsing, back action and chapter count remain shared.
Future playable chapters still require their scene loader and save routing; changing
`available` alone does not implement a chapter.

In-game readable objects remain independent. `ParchmentView` keeps scroll, letter,
book and tablet materials and may be extended with a poster renderer for a future
chapter. The generic HUD does not assume a paper material. Documents now have fine
marginal rules, a wax stamp on scrolls, a brief fade-in and a scrollable reading area
for longer text. The existing book and document close/interaction routes are retained.

The HUD places the act at the upper left, book/journal/pause shortcuts at the upper
right, contextual actions on a dark plate near the bottom and carried items below.
The narrator caption renders above the act-title dimmer. The settings apply action
stays fixed below the scrollable options.

Verification images are under `builds/qa/interface_*.png`. Regenerate with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/test_interface.gd
```

The test uses an isolated save and checks keyboard chapter navigation, presentation
selection, the visible settings apply action, and renders menu/document/HUD screens
at 1280×720 and selected screens at the minimum 1152×648 window size.
