# Better Gun Jam

Developer notes for the Project Zomboid b42 mod that prevents firearm jams above a given condition threshold.

## Quick start

### Requirements
Bash, Make, JDK 16 or newer.

### Layout
- `../ProjectZomboid`: link to a b42 game installation.
- `./dist_workshop`: link to `<USER HOME>/Zomboid/Workshop/<the workshop root e.g. better_gun_jam>`.
- `./DESCRIPTION`: raw content of the mod's description in steam workshop.
- `./sync_description.py`: script to sync `./DESCRIPTION` with `./dist_workshop/workshop.txt`. run `python3 sync_description.py --help` for usage.
- `./41`, `./42`, `./tests`, `./Makefile`, `./preview.png`: trivial

### Make Targets
- `make test`: Run the Kahlua behavior suite. The tests execute the shared production Lua in the game’s bundled Kahlua runtime and model the vanilla authoritative weapon-state synchronization seam.
- `make dist`: Copy the mod files to `./dist_workshop` for publication through the game's gui.

## Multiplayer model

- Shared Lua loads on dedicated servers, listen servers, and singleplayer.
- The authoritative server suppresses eligible jam rolls before vanilla mutates and synchronizes the weapon.
- Multiplayer clients do not apply the mod independently; vanilla's server-to-client weapon sync resolves prediction.
- Rack actions stay server-authoritative through vanilla's networked timed-action path.
