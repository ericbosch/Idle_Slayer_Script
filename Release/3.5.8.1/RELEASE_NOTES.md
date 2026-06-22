# Idle Runner 3.5.8.1

This release brings the 3.5.8 game update into Idle Runner and finishes several automation and reliability improvements.

## Highlights

- Reworked Circle Portals to detect the current dimension and visit all nine standard portal destinations in a fixed cycle.
- Added safe handling for portal cooldown dialogs, missing destinations, pause requests, and list scrolling.
- Added an Armory tab with options for selling selected Victor rings and excellent or non-excellent armor.
- Added an optional timed game restart.
- Added multi-skin player detection for Ascending Heights and per-skin run statistics.
- Improved Ascending Heights platform detection and result logging.
- Made Pause/Stop interrupt long-running purchases, portal searches, bonus stages, chest hunts, boss fights, and Ascending Heights runs.
- Prevented Auto Buy from selecting adjacent Vertical Magnet upgrades.
- Standardized GUI option labels and navigation artwork.

## Circle Portals

- Enable **Circle Portals** to cycle through Hills, Hot Desert, Jungle, Frozen Fields, Funky Space, Modern City, Factory, Mystic Valley, and Haunted Castle.
- Keep the in-game portal confirmation dialogue disabled, as described in the README settings.
- Village and bonus destinations are intentionally excluded from the automatic cycle.
- If Idle Runner cannot identify the current dimension or find the next destination, it logs the reason and cancels without advancing the saved cycle.

## Compatibility

- Steam version of Idle Slayer on Windows.
- Game resolution: 1280x720, windowed.
- Display scaling: 100%.
- Game language: English.
