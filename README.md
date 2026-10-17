# ZukFireLines

An RS3 plugin that highlights TzKal-Zuk's fire lines on the floor as they sweep across the arena. Created by **6ing**. Version **1.0.0**.

Part of [6ing's RS3 plugins](https://github.com/6inq/rs3-plugins).

## What it does
- As a fire line moves, the tiles where it is **right now** are highlighted. The highlight follows it and disappears when it passes.
- Each line is shown as a row **3 or 5 tiles wide** across its direction of travel, your choice.
- Tiles can be **any colour**, including transparency.
- Only what is on screen is shown. Nothing is predicted and no safe spots are marked, keeping within Jagex's plugin rules.

## How to use
1. Enable the plugin.
2. Open the settings (gear icon): pick 3 or 5 tiles and a colour.
3. Fight Zuk. When a fire line appears, its tiles light up and follow it.

## Status: fire-line ids to confirm in game
Jagex hasn't documented what the fire lines are inside the client. They could be NPCs, scenery, or effects. So the plugin finds them by **config id**, and those ids still need to be read in game:
1. In the settings, turn on **Arena inspector**.
2. Fight Zuk. The panel (ribbon icon) lists the NPCs and scenery around you, **moving things first**. Fire lines move every tick, so they should sit at the top.
3. Type those ids into **Fire-line ids** in the settings. They work immediately.
4. Send them over so they can be built into the plugin (`src/data/fire_ids.lua`) for everyone.

If the fire lines turn out to be neither NPCs nor scenery (for example projectiles or ground effects), the inspector won't list them. Detection will then need Jagex's documentation for those object types.

## Layout
```
plugin.json, main.lua      entry point and manifest (requires PrettyUI)
src/core/lines.lua         pure: fire positions -> rows of tiles (3 or 5 wide), id parsing
src/core/inspector.lua     pure: summarises nearby things, moving ones first
src/core/store.lua         settings
src/game/scanner.lua       finds nearby NPCs (Event.EntityDraw) and scenery (LocList.Filter)
src/game/tile_renderer.lua draws the tiles on the ground (ShapeList, as Tilemarkers does)
src/ui/                    ribbon panel (status + inspector) and settings
src/data/fire_ids.lua      built-in fire-line ids (empty until confirmed in game)
```

## Tests
Install the test dependency:
```bash
python -m pip install lupa
```

Then run the suite:
```bash
python tests/run.py
```

The suite has 28 tests:
- row geometry in every direction, for widths 3 and 5
- the highlight following the fire and vanishing when it passes
- several lines merged without duplicate tiles
- a full boot of `main.lua`, including:
  - a fire line sweeping across the arena
  - settings changes applied instantly
  - ids typed into the settings taking effect
  - fire made of scenery being found too
  - the inspector putting moving things first
  - cleanup on shutdown

## Building
```bash
python tools/build.py
```
The output is `dist/zuk-fire-lines-1.0.0.zip`.
