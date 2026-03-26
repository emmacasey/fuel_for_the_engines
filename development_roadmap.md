# Fuel For The Engines — Development Todo

A phased plan for building out the test level and mechanics, ordered to avoid rework and get the feel right fast. Each phase ends with a playtest checkpoint where you loop the level and tune before moving on.

---

## A Note on Godot

Godot 4 is the right call here. Your game leans heavily on atmosphere manipulation — tinting the viewport, swapping audio buses, adjusting post-processing — and Godot's scene/signal architecture handles that elegantly. The main pain point will be 3D asset creation (modelling corridors, enemies, etc.), not engine limitations. For that, lean on Kenney asset packs (free, CC0, surprisingly good sci-fi sets), CSGMesh3D nodes for quick blockouts, and Blender only when you absolutely must. Claude Code can help you write GDScript and configure scenes, but can't push polygons around in a 3D viewport — so the todo below is designed to defer "real" 3D art as long as possible.

---

## Phase 0: Foundational Systems
*Do these first. Everything else plugs into them. Skipping ahead here means rewriting later.*

### 0.1 — Fuel Architecture Refactor
Your fuel currently drives jump height and music. Before adding 20 more mechanics, the system needs to be event-driven and extensible.

- [ ] Create an autoload singleton `FuelManager` (or refactor your existing one)
- [ ] It should hold `player_fuel: float` and `ship_fuel: float` (0.0–1.0 normalised range)
- [ ] Emit signals: `player_fuel_changed(old, new)`, `ship_fuel_changed(old, new)`
- [ ] Emit threshold signals: `player_fuel_crossed_threshold(threshold_name, direction)` — where thresholds are named tiers like `"critical"` (0.15), `"low"` (0.35), `"medium"` (0.55), `"high"` (0.75), `"full"` (0.95)
- [ ] Add a `transfer_to_ship(amount)` method — this is the core player action
- [ ] Add a `ship_drain_rate: float` that passively ticks ship fuel down (this is the pressure source)
- [ ] Add a `player_drain_rate: float` (starts at 0 or very low; some mechanics may add passive player drain)
- [ ] Fuel from killing enemies goes to `player_fuel` only — the player must actively choose to transfer

**Why this matters:** Every mechanic in your brainstorm doc is essentially "connect to a fuel signal, do something." If the architecture is right, adding a new mechanic is ~15 lines of code. If it isn't, every mechanic is a bespoke hack.

### 0.2 — Mechanic Registry Pattern
A lightweight way to toggle mechanics on and off, so you can A/B test them during development.

- [ ] Create a `MechanicsManager` autoload that holds a dictionary of active mechanics
- [ ] Each mechanic is a script that implements `activate()`, `deactivate()`, and `on_fuel_changed()`
- [ ] A debug menu (even just keyboard shortcuts) lets you toggle any mechanic mid-play
- [ ] This also lets you control which mechanics unlock at which fuel thresholds

### 0.3 — The Transfer Action
The single most important interaction in the game. It needs to feel costly and deliberate.

- [ ] Bind transfer to a dedicated key (not a menu — a physical press, like holding `F`)
- [ ] Add a hold-to-transfer with a visible progress arc/bar (1–2 seconds)
- [ ] Player is vulnerable during transfer (can't move or shoot)
- [ ] Visual: fuel visibly drains from a suit indicator and flows toward the ship (even a simple particle stream)
- [ ] Audio: a mechanical whirr that pitches up as transfer completes, then a satisfying clunk
- [ ] The amount transferred should be tunable — start with fixed chunks, not continuous flow

**Playtest checkpoint:** Loop the level. Kill the enemy, get fuel, transfer it. Does the transfer feel like a sacrifice? Does holding onto fuel feel empowering? If not, tune the hold duration, the vulnerability window, the audio.

---

## Phase 1: Make the Level Worth Looping
*Your grid corridor system is the right instinct, but one enemy in a tiny box isn't enough stimulus to feel the fuel tension.*

### 1.1 — Expand the Grid
- [ ] Build 8–12 corridor modules using CSGBox3D and CSGCylinder3D (no Blender needed yet):
  - Straight corridor (already have)
  - T-junction (already have)
  - L-bend
  - Dead end (with item/lore placement spot)
  - Large room (combat arena, 3x3 grid cells)
  - Vertical shaft (requires jump to traverse — first test of player fuel value)
  - Narrow crawlspace (slow movement, tension builder)
  - Observation room (large window — placeholder for ship fuel reward later)
- [ ] Arrange these into a loop that takes 3–5 minutes to traverse
- [ ] The loop should require backtracking through at least one area — this makes the "ship fuel affects environment" mechanics hit harder because you re-experience changed spaces

### 1.2 — Enemy Spawning System
- [ ] Create a `SpawnPoint` node that can be placed in any corridor module
- [ ] `SpawnManager` autoload tracks active enemies and respawns on a timer
- [ ] Enemies should respawn in rooms the player isn't currently in (prevents spawn-camping, encourages movement)
- [ ] Start with 4–6 simultaneous enemies in the loop
- [ ] Each kill grants a fixed fuel amount to `player_fuel`
- [ ] Spawn rate should quietly scale with `ship_fuel` level — lower ship fuel = more enemies (from your brainstorm). Wire this up now even if the effect is subtle

### 1.3 — Basic Enemy Behaviour
Your placeholder enemy needs just enough AI to create pressure.

- [ ] Idle/patrol: walk between two points in their corridor
- [ ] Alert: on seeing/hearing player, move toward them
- [ ] Attack: melee lunge when close (simple damage)
- [ ] Death: brief animation (even just scaling to zero), fuel orb drops
- [ ] Fuel orb: a glowing pickup the player walks over (satisfying audio chime)

### 1.4 — Player Combat Basics
- [ ] A hitscan weapon with limited range (keeps combat close and tense)
- [ ] Muzzle flash and impact particles (CSG or simple sprites)
- [ ] Screen shake on firing (subtle) and on taking damage (less subtle)
- [ ] Health system: take damage, heal over time slowly (or not at all — test both)
- [ ] Death and respawn: restart the loop, fuel levels persist (this is important — dying shouldn't reset your fuel economy decisions)

**Playtest checkpoint:** Loop the level 10 times. Is there a natural rhythm of explore → fight → collect → decide (keep or transfer)? Does the loop feel too long or too short? Adjust corridor count and enemy density.

---

## Phase 2: Ship Fuel Atmosphere (The Gut Punch)
*This is where your game becomes your game. The ship fuel side is what makes the concept work — it's what makes people transfer fuel even when they shouldn't.*

### 2.1 — Lighting System (Highest Priority Ship Mechanic)
This single system carries several of your brainstorm items at once.

- [ ] Create a `ShipAtmosphere` autoload that listens to `ship_fuel_changed`
- [ ] Define a lighting gradient tied to ship fuel:
  - **High fuel:** Warm white/amber `DirectionalLight3D` + `OmniLight3D` fill lights in corridors. Feels safe.
  - **Medium fuel:** Lights dim. Colour temperature shifts cooler. Some lights flicker (random `OmniLight3D` energy animation).
  - **Low fuel:** Emergency red. Most corridor lights off. Only red strips remain. Strobing in some rooms (use `AnimationPlayer` on light energy).
  - **Critical fuel:** Near-blackout. Player's suit headlamp is primary light source. Red pulses.
- [ ] Use Godot's `WorldEnvironment` node: adjust `ambient_light` colour/energy, `tonemap_exposure`, `glow` intensity based on fuel
- [ ] This alone covers "The Lights Come On," "Lighting Strobes Red," and "Colour Returns/Drains" from your brainstorm

### 2.2 — Audio Atmosphere
- [ ] Create an `AudioManager` autoload with layered `AudioStreamPlayer` nodes:
  - **Music layer:** Gentle ambient track at high fuel, crossfading to distorted/atonal version at low fuel (same stems, different processing — or two separate tracks crossfaded)
  - **Alarm layer:** Silent at high fuel, fading in a klaxon loop at low fuel. Not a sudden switch — a gradual creep that's maddening precisely because you can't pinpoint when it started
  - **Ship ambience layer:** Healthy engine hum at high fuel, stressed groaning at low fuel
  - **Intercom layer:** Warm announcements at high fuel ("Good morning. Oxygen is nominal."), static/frantic warnings at low fuel
- [ ] Use Godot's `AudioBus` system: create a "Ship Atmosphere" bus with filters. Low-pass filter increases as fuel drops (everything sounds muffled and wrong)
- [ ] This covers "The Soundtrack Plays," "Alarms Don't Stop," "The Ship Groans," "The Music Becomes Wrong," "The Intercom Blares Static," "Warm Announcements"

### 2.3 — Post-Processing / Colour
- [ ] On the `WorldEnvironment`, use the `Environment` resource:
  - Saturation: 1.0 at high fuel → 0.2 at low fuel (your "Colour Drains / Colour Returns")
  - Contrast: slight increase at low fuel (harsh, clinical look)
  - Vignette: subtle at high fuel, heavy at low fuel (claustrophobic)
- [ ] Consider a subtle film grain shader at low fuel (Godot has built-in or trivial custom shaders for this)

### 2.4 — First "Wow" Ship Reward: The Observation Deck
Pick one reward that's visually dramatic to prove the concept works emotionally.

- [ ] One of your corridor modules becomes the observation room
- [ ] At low ship fuel: blast shutters are closed (a flat wall)
- [ ] Cross a ship fuel threshold: shutters open (animated), revealing a `PanoramaSky` or a starfield shader through a large window
- [ ] Add a subtle swell in the music when this happens
- [ ] The player should be able to stand here. No gameplay purpose. Just beauty.

**Playtest checkpoint:** This is the big one. Loop the level. Fight enemies. Let ship fuel drain until the alarms start and the lights go red. Then transfer fuel. Watch the lights warm. Hear the alarm fade. See the observation deck open. *Does it feel good?* Does it feel good enough that you'd sacrifice your double jump for it? If yes, the core concept is proven. If not, tune the contrast between high and low states — make low more miserable, make high more beautiful.

---

## Phase 3: Player Fuel Mechanics (Easiest First)
*Now that the "why" of transferring fuel is felt, build the "what you lose" side.*

### 3.1 — Movement Tier System
These are the simplest to implement because they modify existing CharacterBody3D properties.

- [ ] **Jump Height** (already have — refine it): tie to fuel curve, not linear. The drop from "good jump" to "bad jump" should have a noticeable cliff around 0.4 fuel
- [ ] **Sprint:** Add a sprint key. Available above 0.5 player fuel. Below 0.5, movement speed is baseline. The difference should be dramatic — sprint should feel *fast*
- [ ] **No Sprint → Slow:** Below 0.2 player fuel, movement speed drops below baseline. The ship feels enormous. This is your "No Sprint" mechanic
- [ ] **Stumble:** Below 0.15 player fuel, random small interruptions to movement (brief velocity zero + camera bob). Subtle but infuriating

### 3.2 — Combat Degradation
- [ ] **Weapon Drift:** Add a small random offset to the aim point that scales inversely with player fuel. At full fuel, aim is true. At low fuel, crosshair wanders. Use a smooth noise function, not random jitter
- [ ] **Weak Strikes (if you add melee later):** Melee stagger only works above a fuel threshold
- [ ] **Combat Cooldowns:** If you add abilities with cooldowns, multiply cooldown duration by `(1.5 - player_fuel)` — so at 0.5 fuel, cooldowns are normal; at 0.0, they're 50% longer

### 3.3 — HUD Degradation
- [ ] **Vision Static:** At low player fuel, overlay a subtle static shader on the HUD (not the world — important distinction, it's your *suit* failing, not reality)
- [ ] **Fuel Gauge Inaccuracy:** Below 0.3 player fuel, the displayed player fuel number jitters randomly ±10%. The player can't be sure of their actual level. Devious.
- [ ] **Intrusive Readouts:** Below 0.25 player fuel, the HUD periodically flashes "LOW FUEL" warnings that partially obscure the view. The suit is nagging you.
- [ ] **Tunnel Vision:** At very low fuel, a vignette closes in on the player camera (separate from the ship vignette — this one is tighter and darker)

### 3.4 — Double Jump & Dash
These are your first "unlock" mechanics — abilities that feel great and only exist at higher fuel.

- [ ] **Double Jump:** Available above 0.6 player fuel. Standard air jump. Place one platform in the test level that's only reachable with double jump, with a fuel canister on it — a tangible reward for keeping your fuel high
- [ ] **Dash:** Available above 0.5 player fuel. Short-range directional blink (teleport the player ~3m forward with a brief invincibility frame). Costs a small amount of player fuel per use. Essential for dodging in combat

**Playtest checkpoint:** Play the loop at various player fuel levels. Is there a sweet spot where you feel powerful but tempted to transfer? Is the degradation at low fuel annoying enough to motivate hunting enemies but not so punishing that it's not fun? The fuel gauge inaccuracy in particular — does it create genuine anxiety, or is it just noise?

---

## Phase 4: The Feedback Loop (Where the Addiction Forms)
*This is the systemic layer that makes the player keep transferring even when they know they shouldn't.*

### 4.1 — Ship Fuel Passive Drain
- [ ] Ship fuel drains at a constant rate (this should already be in from Phase 0)
- [ ] Make the drain rate visible somehow — maybe a subtle downward-trending indicator on the HUD
- [ ] The drain rate should be tuned so that the player can *almost* keep up by killing enemies and transferring, but not quite. There should always be a slight deficit. The ship is always slipping.

### 4.2 — Immediate vs. Delayed Feedback
This is the core psychological trick. Get this right.

- [ ] **Ship fuel changes are instant:** The moment you transfer, lights brighten, music softens, alarms fade. The relief is immediate. The dopamine is immediate.
- [ ] **Player fuel changes are gradual:** When you lose player fuel, your abilities don't vanish instantly. Jump height decreases smoothly. Weapon drift increases smoothly. You don't notice the exact moment you lost double jump — it just... wasn't there when you needed it. Implement this as a ~3-5 second interpolation on player fuel effects, versus instant application for ship fuel effects.
- [ ] This asymmetry is everything. The reward is a spike; the cost is a slope.

### 4.3 — Transfer Prompt Pressure
- [ ] When ship fuel is low and alarms are blaring, add a HUD prompt: "HOLD [F] TO TRANSFER FUEL TO SHIP"
- [ ] The prompt should pulse. It should feel urgent.
- [ ] There should be NO equivalent prompt telling you to keep your fuel. Nobody is advocating for your long-term wellbeing.
- [ ] When ship fuel is critically low, NPCs (even before you have real NPCs) could have text barks: "Please, the lights..." "The children are scared." Social pressure.

### 4.4 — The Ratchet
- [ ] Each time you transfer fuel, the ship drain rate increases by a tiny amount (invisible to the player)
- [ ] This means each "fix" lasts slightly less time than the last
- [ ] The player has to transfer more often, keeping their own fuel lower on average
- [ ] This is the addiction ramp. Don't make it too steep or the game becomes unwinnable. ~2% per transfer is a good starting point.

**Playtest checkpoint:** Play for 15 minutes straight. Are you transferring fuel compulsively? Are you aware you're doing it more than you should? Can you articulate *why* you keep doing it even though your jump height is garbage? If you can feel the mechanism working on you, it's working.

---

## Phase 5: Ship Flavour & Crew
*With the core systems proven, start adding the rewards that make high ship fuel feel like home.*

### 5.1 — Crew NPCs (Static First)
- [ ] Place 2-3 simple NPC models (use Godot's CSGBox3D humanoid shapes or free assets) in specific rooms
- [ ] They have idle animations (or just slowly rotate in place as a placeholder)
- [ ] At high ship fuel: they face each other, text bark dialogue ("Did you hear the engines? Sounds healthy." / "Almost feels normal again.")
- [ ] At low ship fuel: they cower, face walls, say nothing or whimper

### 5.2 — Ship Cat
- [ ] A small orange CSGBox3D (or a sprite billboard) that follows the player at high ship fuel
- [ ] At low ship fuel: the cat disappears (despawn with a brief "running away" animation)
- [ ] The cat has no gameplay function. It's pure emotional texture.
- [ ] Give it a quiet purring audio loop

### 5.3 — Environmental Micro-Rewards
- [ ] **Coffee machine:** An interactable in one room. Above a fuel threshold, press E to trigger a 5-second sit-and-sigh animation (lock player input, play a contented audio clip, slight camera settle)
- [ ] **Save station glow:** If you have save points, they shift from cold blue/clinical to warm amber based on ship fuel
- [ ] **Gravity flickers at low fuel:** Occasional brief zero-g moments (disable gravity on CharacterBody3D for 0.5 seconds, then snap back). Disorienting.

---

## Phase 6: Advanced Player Mechanics (Medium Difficulty)
*These require new systems but don't demand fundamental rework.*

### 6.1 — Scanner Pulse
- [ ] Activated ability (costs player fuel per use)
- [ ] Sends out a visible expanding sphere (shader or particle effect)
- [ ] Highlights enemies through walls (outline shader or UI marker) for ~5 seconds
- [ ] Also reveals hidden passages (certain wall segments become transparent or marked)
- [ ] Available above 0.65 player fuel

### 6.2 — Wall Grip
- [ ] Raycasts from player detect wall surfaces
- [ ] When airborne and touching a wall + holding jump, player clings (velocity zeroed, gravity paused)
- [ ] Stamina-limited: grip lasts 2–3 seconds before sliding
- [ ] Available above 0.55 player fuel
- [ ] Place at least one route in the test level that requires wall grip to access

### 6.3 — Grapple Tether
- [ ] Place anchor points (glowing nodes) at specific positions in the level
- [ ] Player can fire a tether (raycast toward anchor, if hit, lerp player position toward it)
- [ ] Available above 0.7 player fuel — this is a premium ability, loss is felt hard
- [ ] Makes traversal feel incredible and fast. Losing it feels like losing flight.

### 6.4 — Melee Strike
- [ ] Close-range attack, short cooldown, costs NO fuel (important — it's the baseline fallback)
- [ ] Staggers enemies above 0.4 player fuel, doesn't stagger below
- [ ] Useful when weapon drift makes ranged combat frustrating at low fuel

---

## Phase 7: The Narrator
*This is a major feature that ties the whole experience together. Don't start it until the mechanics feel right without it.*

### 7.1 — Text-Based Narrator (First Pass)
- [ ] Create a `NarratorManager` autoload
- [ ] Narrator delivers lines via a text box at the top of the screen (like a subtitle bar)
- [ ] Lines are triggered by game events: first kill, first transfer, fuel thresholds, entering new rooms, finding the observation deck
- [ ] At high ship fuel, narrator is calm and encouraging: "Good. The ship needs you."
- [ ] At low ship fuel, narrator becomes anxious and pushy: "The fuel. Please. The crew can't—"
- [ ] The narrator ALWAYS encourages transferring fuel. Never once suggests keeping it.
- [ ] The narrator refers to enemies exclusively as "parasites" — dehumanising language that makes killing feel like maintenance

### 7.2 — Narrator Doubt Seeds (For Later)
- [ ] After the player has killed ~50 enemies, the narrator occasionally hesitates: "Another one. Good. That's... yes, that's good."
- [ ] If the player lingers near an enemy without attacking, the narrator says nothing for an uncomfortable beat, then: "...well?"
- [ ] These are breadcrumbs toward the plot revelation. Don't overdo them.

---

## Phase 8: Systems Polish & Edge Cases

### 8.1 — Fuel Balancing Pass
- [ ] Create a debug overlay that shows real-time fuel curves, transfer history, and drain rates
- [ ] Run 20-minute play sessions and graph the fuel economy
- [ ] Tune: enemy fuel drop amount, transfer amount, ship drain rate, ratchet rate
- [ ] Target feel: the player should be able to maintain ~0.5 in both for the first 10 minutes, then the pressure should force them to choose

### 8.2 — Save System
- [ ] Save fuel levels, mechanic states, enemy kill count, ratchet rate
- [ ] Save stations should be in the level (2-3 of them in the loop)
- [ ] Consider: save station availability tied to ship fuel (from your brainstorm — "Save Stations Offline"). Powerful but punishing. Maybe save this for a later difficulty layer.

### 8.3 — Death & Respawn Tuning
- [ ] On death: respawn at nearest save point
- [ ] Fuel levels restore to last save state
- [ ] This means a bad transfer decision before saving is permanent — you live with your choices
- [ ] If no save points are available (low ship fuel), death is more costly. This creates organic difficulty scaling.

### 8.4 — Interaction Polish
- [ ] **Door Struggle:** At low player fuel, doors require a brief button-mash minigame instead of a single press
- [ ] **Interaction Lag:** All button/terminal presses have a short struggling animation at low fuel
- [ ] **Carry Capacity:** If you add collectible fuel canisters, limit how many the player can hold based on fuel level

---

## Phase 9: Audio & Visual Polish (When Mechanics Are Locked)
*Only do this when you've stopped changing mechanics. Art polish on a moving target is wasted work.*

### 9.1 — Asset Upgrade
- [ ] Replace CSGBox3D corridors with proper mesh-based modular pieces (Kenney Sci-Fi Kit or similar)
- [ ] Add floor/wall/ceiling detail textures
- [ ] Add pipes, wiring, panels to corridor walls (even as simple extruded boxes — visual noise makes spaces feel real)

### 9.2 — Particle & Shader Work
- [ ] Fuel transfer particle effect (suit → ship visual)
- [ ] Enemy death particles
- [ ] Low-fuel suit sparks and smoke
- [ ] Post-processing: bloom at high ship fuel (warmth), chromatic aberration at low ship fuel (wrongness)

### 9.3 — Sound Design
- [ ] Footstep variations (metal corridor, grate, puddle)
- [ ] Suit sounds: healthy hum vs. clicking/hissing at low fuel
- [ ] Enemy audio: movement sounds, alert screech, death sound
- [ ] UI sounds: fuel pickup chime, transfer complete, ability unlock/lose stingers

---

## Parking Lot (Mechanics to Try After Core Is Solid)
These are from your brainstorm but either harder to implement or lower priority for proving the concept. Pick from these once you're bored of tuning the core loop.

- **Overclock (bullet time):** Requires custom time-scale management; fun but complex
- **Terminal Access / Hacking:** Needs a minigame system; save for when you're designing puzzles
- **Thermal Sight:** Outline shader through walls; medium difficulty, very cool feel
- **Proximity Alert:** UI indicator system; easy but needs enemy awareness AI to be solid first
- **Auto-Stabiliser (no fall damage):** Easy toggle, but you need vertical level design to matter first
- **Resonance Map (auto-map):** Needs a map UI; significant work
- **The Hologram Lounge / Galley / Shower:** Narrative micro-scenes; save for when you have real assets
- **Archive Unlocks (lore library):** Needs a text UI and content; save for plot phase
- **Deep Lung (oxygen):** Needs an oxygen system; don't build one unless the level design demands it
- **Weapon Augment (charged fire):** Needs a weapon system more complex than hitscan; defer

---

## One Last Thought

Your design note about item 1 and item 20 forming pairs is sharp — but there's an even more important pairing buried in your mechanics list that I'd keep front of mind during all of this. The ship cat and weapon drift. One is something you love having around that quietly goes away when things get bad. The other is something you barely notice creeping in until it ruins your day. That's not just a mechanic pairing, it's the emotional thesis of the game: the things you sacrifice for comfort disappear gently, and the costs arrive so slowly you blame yourself for not noticing sooner.

Build toward that feeling. Everything else is tuning.
