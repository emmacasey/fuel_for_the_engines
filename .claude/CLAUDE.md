# Fuel For The Engines

# Fuel For The Engines
## Concept
The narrator of this scifi adventure game tells you your spaceship is slowly losing power, without power many important systems which the crew depend on will not function. You can feed fuel from your own suit to top up the ship, but this will reduce your own abilities unless you refuel yourself. There are many parasites on the ship, killing them will give you a bit more power.
In fact the game is an exploration of how psychological coping mechanisms, even ones that are harmful long term, can become addicting. We train the player to do a thing which makes the game harder and worse to play, because doing that makes things better immediately and the downsides are harder to see.

## Primary Gameplay Loop
The main mechanic is "fuel", it is gained by killing enemies, and transferred to the ship. When the player has more fuel they gain more abilities like powerful weapons, tools, double jump etc. When the ship has more fuel the environment becomes easier to navigate, less distracting etc. Low ship fuel is *immediately unpleasant and annoying* with warning sirens and bad lighting, whereas low player fuel is more challenging but can be handled with effort. The psychological incentives are to push fuel to the ship as much as possible.

## Plot
The game opens with the player being told to kill parasites in order to fuel the engines. They explore the ship and challenge gradually ramps up, the ship is losing fuel faster, there's fewer parasites, and so the tradeoff between personal fuel and ship fuel gets starker. Eventually the player notices that the narration insists that parasites are causing the fuel loss, but fuel loss is greater now there are fewer of them. Long term the existence of the parasites give the ship more fuel than you gain from killing them, killing them solves the immediate temporary problem but costs in the long run. The player has been effectively tutorialised into making the game harder. 

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
Plot
a) Write plot
b) Write narration
c) Design side quests, level structure etc

## Stage 3
Mechanics
a) Build the narrator (a voiceover? text?)
b) handle saving etc
c) build any additional mechanics for side quests etc

## Stage 4
Wrap it up.
a) final level design
b) title screen etc
c) better assets, (double check licences etc)

# File Structure

## Scenes (`scenes/`)
Full game scenes and their attached scripts.
- `main.tscn` — the main gameplay scene; corridor layout built from GridMap + MeshLibrary tiles
- `main-environment.tres` — WorldEnvironment resource for main.tscn
- `environment.gd` — script on the WorldEnvironment node; manages ship fuel level, drain from parasites, lighting/music reactions
- `title.tscn` + `title.gd` — title/start screen

## Objects (`objects/`)
Reusable scene prefabs (nodes + attached scripts).
- `player.tscn` + `player.gd` — FPS player: movement, shooting, fuel drain/gain, health, signals
- `enemy.tscn` + `enemy.gd` — floating parasite enemy: sine movement, shooting at player, emits `enemy_destroyed(value)` on death
- `blaster.tscn` — weapon model scene (no script; configured via Weapon resource)
- `impact.tscn` + `impact.gd` — bullet impact sprite, frees itself after animation
- `wall_high.tscn`, `wall_low.tscn` — wall props kept as potential obstacles

## Maps (`maps/`)
Level/environment construction assets.
- `Coridor_MeshLibrary_Source.tscn` — source scene used to bake `coridor_mesh_library.tres`
- `coridor_mesh_library.tres` — MeshLibrary used by the GridMap in `scenes/coridor.tscn`

## Scripts (`scripts/`)
Standalone scripts with no paired scene: singletons and resource class definitions.
- `audio.gd` — Audio autoload singleton; pooled AudioStreamPlayer, supports comma-separated random sound paths
- `weapon.gd` — `Weapon` Resource class definition (model, stats, sounds, crosshair)
- `hud.gd` — CanvasLayer HUD script; updates health and fuel display labels

## Assets (`assets/`)
All raw game assets grouped by type.
- `assets/models/` — 3D models: corridor tile set (`coridor_*.obj`, 13 variants), weapon GLBs, enemy GLB, platformer-era GLBs. Note: "coridor" is a consistent typo throughout.
- `assets/sounds/` — OGG/WAV/MP3 audio: weapons, enemy, player movement, music tracks
- `assets/sprites/` — 2D sprites: crosshairs, muzzle flash spritesheet (`burst_animation.tres`), impact, blob shadow
- `assets/fonts/` — `lilita_one_regular.ttf`
- `assets/weapons/` — Weapon resource instances (`blaster.tres`, `blaster-repeater.tres`), data defined by `scripts/weapon.gd`

## Addons (`addons/starlight/`)
Third-party star field generator addon.

## Source/Excluded Folders
- `vector/` — `.fla` source file for sprites (`.gdignore` so Godot ignores it)


