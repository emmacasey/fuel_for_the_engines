# Fuel For The Engines

## Concept

On the surface of this scifi adventure game the spaceship is slowly losing power, without power many important systems which the crew depend on will not function. You can feed fuel from your own suit to top up the ship, but this will reduce your own abilities unless you refuel yourself. There are many parasites on the ship, killing them will give you a bit more power.
In fact the game is an exploration of how psycological coping mechanisms, even ones that are harmful long term, can become addicting. We train the player to do a thing which makes the game harder and worse to play, because doing that makes things better immediately and the downsides are harder to see.

## Primary Gameplay Loop

The main mechanic is "fuel", it is gained by killing enemies, and transfered to the ship. When the player has more fuel they gain more abilities like powerful weapons, lights, double jump etc. When the ship has more fuel the environment becomes easier to navigate, less distracting etc. Low ship fuel is *immediatly unpleasant and annoying* with warning sirens and bad lighting, whereas low player fuel is more challenging but can be handled with effort. The psycological incentives are to push fuel to the ship as much as possible.

## Plot

The game opens with the player being told to kill parasites in order to fuel the engines. They explore the ship and challenge gradually ramps up, the ship is losing fuel faster, there's fewer parasites, and so the tradeoff between personal fuel and ship fuel gets starker. Eventually the player notices that the narration insists that parasites are causing the fuel loss, but fuel loss is greater now there are fewer of them. Long term the existance of the parasites give the ship more fuel than you gain from killing them, killing them solves the immediate temporary problem but costs in the long run. The player has been effectively tutorialised into making the game harder. 

## Controls

| Key | Command |
| --- | --- |
| <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> | Movement |
| <kbd>Spacebar</kbd> | Jump |
| <kbd>Left mouse button</kbd> | Shoot |
| <kbd>T</kbd> | Switch weapon |
| <kbd>E</kbd> | Fuel the Engines |



# Project Plan

## Stage 1
Focus on the primary gameplay loop.
a) build a testing environment with a few corridors, doors, jumps, enemies etc.
b) experiment with moving, killing, fueling engines etc
c) work out new abilities that player fuel provides, new problems that low ship fuel causes etc.
d) tweak the audio and visual experience to make increasing ship fuel vicerally/immediately rewarding

## Stage 2
Write plot, narration, narative structure etc. Build the narrator (a voiceover? text?)

## Stage 3
Design the ship etc.



# File Structure

## Scenes (`scenes/`)
Full game scenes and their attached scripts.
- `main.tscn` — the main gameplay scene
- `main-environment.tres` — WorldEnvironment resource for main.tscn
- `Fuel.gd` — script on the WorldEnvironment node in main.tscn; manages ship fuel level, drain from parasites, lighting/music reactions
- `title.tscn` + `title.gd` — title/start screen
- `coridor.tscn` — corridor level layout built from the MeshLibrary tiles

## Objects (`objects/`)
Reusable scene prefabs (nodes + attached scripts).
- `player.tscn` + `player.gd` — FPS player: movement, shooting, fuel drain/gain, health, signals
- `enemy.tscn` + `enemy.gd` — floating parasite enemy: sine movement, shooting at player, emits `enemy_destroyed(value)` on death
- `blaster.tscn` — weapon model scene (no script; configured via Weapon resource)
- `impact.tscn` + `impact.gd` — bullet impact sprite, frees itself after animation
- `platform.tscn`, `platform_large_grass.tscn`, `wall_high.tscn`, `wall_low.tscn` — leftover platformer-era props (may be unused in corridor layout)
- `Coridor_MeshLibrary_Source.tscn` — source scene used to bake `coridor_mesh_library.tres`
- `coridor_mesh_library.tres` — MeshLibrary used by the GridMap in `coridor.tscn`

## Scripts (`scripts/`)
Standalone scripts with no paired scene: singletons and resource class definitions.
- `audio.gd` — Audio autoload singleton; pooled AudioStreamPlayer, supports comma-separated random sound paths
- `weapon.gd` — `Weapon` Resource class definition (model, stats, sounds, crosshair)
- `hud.gd` — CanvasLayer HUD script; updates health and fuel display labels

## Weapons (`weapons/`)
Weapon resource instances (data only, defined by `scripts/weapon.gd`).
- `blaster.tres` — single-shot blaster config
- `blaster-repeater.tres` — rapid-fire repeater config

## Models (`models/`)
3D model source files.
- `coridor_*.obj` + `.mtl` — corridor tile set (13 variants: straight, corner, T-junction, end, stairs, open, floorless, topless, box). Note: "coridor" is a consistent typo throughout.
- `blaster.glb`, `blaster-repeater.glb` — weapon models
- `enemy-flying.glb` — parasite enemy model
- `platform.glb`, `platform-large-grass.glb`, `grass.glb`, `grass-small.glb`, `wall-high.glb`, `wall-low.glb` — older platformer-era models (may be unused)

## Sounds (`sounds/`)
OGG audio files: `blaster.ogg`, `blaster_repeater.ogg`, `enemy_attack.ogg`, `enemy_destroy.ogg`, `enemy_hurt.ogg`, `jump_a/b/c.ogg`, `land.ogg`, `walking.ogg`, `weapon_change.ogg`, alarm MP3, Vivaldi track.

## Sprites (`sprites/`)
2D sprites: `crosshair.png`, `crosshair-repeater.png`, `burst.png` (muzzle flash spritesheet → `burst_animation.tres`), `hit.png`, `blob_shadow.png`.

## Addons (`addons/starlight/`)
Third-party star field generator addon. `demo/` contains its demo scene — not game content.

## Source/Excluded Folders
- `vector/` — `.fla` source file for sprites (`.gdignore` so Godot ignores it)
- `screenshots/` — project screenshots (`.gdignore`)
- `fonts/` — `lilita_one_regular.ttf`
- `docs/` — currently contains `screenshot.jpg` plus unrelated files from a different project (`fits2exr.py`, `poppy psfs.ipynb`)

