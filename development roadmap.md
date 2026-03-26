# Fuel For The Engines — Development Roadmap

A phased plan accounting for what already exists in the project. Each phase ends with a playtest checkpoint.

**Key design decisions already made:**
- Health IS player fuel. One pool for everything: abilities, taking damage, shooting, jumping. No split.
- Ship fuel is a much larger reservoir. Transfers from player to ship use a low multiplier (~1-10%), so filling the ship requires many refuels.
- Both fuels normalised to 0.0–1.0 internally.
- FuelManager and MechanicsManager singletons from the start.
- Transfer ceremony is TBD — we will implement and test three modes (instant, held, hybrid).
- The parasite drain/feed-back system (parasites drain ship fuel but also feed it back on a delay; killing them removes the long-term source) is already working and is the core plot mechanic. Preserve it.

---

## What Already Exists

Before starting, here's what's built and working:

- **FPS player** (player.gd): WASD movement, mouse look, gamepad support, jumping (including double jump gated at health > 50), hitscan shooting, two weapons with switching, health/fuel as a single integer pool, tiered abilities by health level, fuel-to-ship transfer on E press
- **Ship environment** (environment.gd): ship fuel float with continuous drain based on living enemies, 600-frame lagged fuel feedback from living parasites, stepped lighting response (background energy + ambient light), audio layers (Vivaldi happy music, spooky ambience, alarm)
- **Enemy** (enemy.gd): floating sine-wave parasite, looks at player, shoots on timer via raycast, drops fuel value on death
- **Audio singleton** (audio.gd): pooled SFX player, random sound selection
- **HUD** (hud.gd): health % label, ship fuel number label
- **Level**: GridMap with 13 corridor tile variants (straight, corner, T, end, stairs, floorless, topless, open, box), starfield decoration
- **Assets**: corridor .obj tileset, blaster + repeater weapon GLBs, enemy GLB, wall props, sound effects for weapons/enemy/movement/music, crosshair sprites, muzzle flash spritesheet
- **Title screen**: simple start button

---

## Phase 0: Foundational Refactor

*Restructure existing systems into the singleton architecture. Nothing new gameplay-wise — the game should play identically after this phase, just wired differently.*

### 0.1 — FuelManager Singleton

Create an autoload `FuelManager` that owns both fuel pools and all fuel logic.

- [ ] `player_fuel: float` (0.0–1.0). Replaces `player.health` as the authoritative source.
- [ ] `ship_fuel: float` (0.0–1.0). Replaces `environment.fuel`.
- [ ] Signals: `player_fuel_changed(old_value, new_value)`, `ship_fuel_changed(old_value, new_value)`
- [ ] Threshold signals: `player_fuel_crossed_threshold(name, direction)`, `ship_fuel_crossed_threshold(name, direction)` — thresholds at `"critical"` (0.15), `"low"` (0.35), `"medium"` (0.55), `"high"` (0.75), `"full"` (0.95)
- [ ] Methods: `drain_player(amount) -> bool` (returns false if insufficient — replaces `try_drain`), `add_player(amount)`, `drain_ship(amount)`, `add_ship(amount)`
- [ ] `transfer_to_ship(amount)` — applies a `transfer_multiplier` (start at 0.1) so transferring 0.1 player fuel only adds 0.01 ship fuel. This is the "ship is bigger than you" feeling. **Design note:** keep the multiplier as an exported var so we can tune it easily. The transfer method should be called by whatever transfer UI we settle on (instant/held/hybrid) — do not hardcode transfer ceremony here, just the fuel math.
- [ ] `ship_drain_rate: float` — passive ship fuel drain per second
- [ ] Migrate the parasite feedback system from environment.gd: the lagged-value array where living parasites feed fuel back on delay. This is critical — preserve the exact behaviour where killing parasites removes long-term fuel income.
- [ ] `player_drain_rate: float` (starts at 0, some future mechanics may add passive player drain)
- [ ] Enemy kills call `FuelManager.add_player(value)` instead of directly modifying player health

### 0.2 — MechanicsManager Singleton

A registry for toggling mechanics on/off, gated by fuel thresholds.

- [ ] Autoload `MechanicsManager` with a dictionary of registered mechanics
- [ ] Each mechanic is a script/resource implementing: `activate()`, `deactivate()`, `on_player_fuel_changed(old, new)`, `on_ship_fuel_changed(old, new)`
- [ ] Mechanics register themselves on `_ready()` and connect to FuelManager signals
- [ ] A simple debug toggle system (keyboard shortcuts or a debug panel) to force-enable/disable any mechanic mid-play
- [ ] Migrate existing tiered abilities from player.gd (movement speed, jump strength, double jump, alarm sound) into this system as the first registered mechanics

### 0.3 — Rewire Existing Systems

- [ ] player.gd: remove `health` int, read from `FuelManager.player_fuel` instead. Remove the tiered ability block (lines 109-124) — these are now mechanics in MechanicsManager.
- [ ] environment.gd: remove `fuel`, `drain`, `lagged_values` — ship fuel logic lives in FuelManager now. Keep the lighting/audio response code but have it listen to `FuelManager.ship_fuel_changed` instead of tracking its own fuel.
- [ ] enemy.gd: `enemy_destroyed` signal still fires, but the connection goes to FuelManager instead of player.
- [ ] hud.gd: listen to FuelManager signals for both displays.
- [ ] Smooth the lighting response: replace the stepped if/elif blocks with `lerp`/curves so lighting transitions feel continuous rather than jumping between 3 states.
- [ ] Smooth the audio response similarly: crossfade music layers rather than hard pause/unpause.

**Playtest checkpoint:** The game should feel identical to before, maybe slightly smoother on lighting/audio transitions. All the same mechanics, just cleaner wiring. If anything feels different, fix it before proceeding.

---

## Phase 1: The Transfer Action

*The single most important interaction. Three modes to test.*

### 1.1 — Transfer Infrastructure

- [ ] Create a `TransferAction` node/script on the player that handles the E key
- [ ] It calls `FuelManager.transfer_to_ship(amount)` — the amount depends on the active transfer mode
- [ ] Visual: a simple particle stream from player toward the nearest wall/floor (representing fuel flowing into the ship). Even a Line3D with a shader would work.
- [ ] Audio: a mechanical whirr + satisfying clunk on completion
- [ ] HUD element: show transfer amount preview when E is available ("E: Transfer X%")

### 1.2 — Three Transfer Modes (Implement All, Test Each)

**Mode A — Instant:** Press E, transfer a fixed chunk (e.g., 10% of current player fuel). Fast, impulsive, easy to spam. Fits the addiction metaphor — too easy to give in.

**Mode B — Held:** Hold E for 1.5-2 seconds. Progress arc visible. Player is immobile and vulnerable during transfer. Transfers a larger chunk. Each transfer is a deliberate, costly decision.

**Mode C — Hybrid:** Press E for a small instant transfer (5% of current player fuel). Hold E for a larger transfer (20%). The press-to-cross-a-threshold impulse is always available, but efficient transfers require commitment.

- [ ] Implement all three behind a simple toggle (debug menu or a setting)
- [ ] For held/hybrid modes: lock player movement and shooting during the hold
- [ ] For held/hybrid modes: add a visible progress arc on the HUD
- [ ] Playtest all three extensively. Pick one (or let the user pick via settings — though a single answer is probably better for the design)

**Playtest checkpoint:** For each mode, loop the level. Kill enemies, get fuel, transfer. Does the transfer feel like a sacrifice? Does the alarm pressure make you want to transfer? Does the mode encourage compulsive behaviour or deliberate choices — and which of those serves the game's thesis better?

---

## Phase 2: Ship Fuel Atmosphere

*This is where the game becomes the game. The ship fuel side is what makes people transfer even when they shouldn't.*

### 2.1 — Lighting System (Highest Priority)

The existing stepped lighting in environment.gd needs to become a smooth, dramatic gradient.

- [ ] Define a lighting curve tied to ship fuel (use Godot `Curve` resources for tunability):
  - **High (>0.75):** Warm white/amber DirectionalLight3D + OmniLight3D fills. Safe, inviting.
  - **Medium (0.35–0.75):** Lights dim, colour temperature shifts cooler, some lights flicker (animated OmniLight3D energy).
  - **Low (0.15–0.35):** Emergency red. Most lights off. Red strips remain. Strobing in some rooms.
  - **Critical (<0.15):** Near-blackout. Player's suit headlamp is primary light. Red pulses.
- [ ] Adjust `WorldEnvironment` properties continuously: `ambient_light` colour/energy, `tonemap_exposure`, `glow` intensity/bloom
- [ ] This single system covers: "The Lights Come On", "Lighting Strobes Red", "Colour Returns/Drains"

### 2.2 — Audio Atmosphere

Build on the existing 3-layer audio (happy music, spooky ambience, alarm).

- [ ] Refactor into an `ShipAtmosphere` manager (can be part of environment.gd or a new autoload) with layered AudioStreamPlayers:
  - **Music layer:** Gentle ambient at high fuel, crossfading to distorted at low fuel (not a hard switch — a gradual creep)
  - **Alarm layer:** Silent at high fuel, fading in at low fuel. The fade should be slow enough that you can't pinpoint when it started
  - **Ship ambience layer:** Healthy hum at high, stressed groaning at low
  - **Intercom layer (later):** Warm announcements at high, static/frantic at low
- [ ] Use Godot AudioBus with filters: low-pass increases as fuel drops (everything sounds muffled and wrong)
- [ ] Covers: "The Soundtrack Plays", "Alarms Don't Stop", "The Ship Groans", "The Music Becomes Wrong", "The Ship Hums", "The Ship Breathes Wrong"

### 2.3 — Post-Processing / Colour

- [ ] On the WorldEnvironment (main-environment.tres), drive with ship fuel:
  - Saturation: 1.0 at high → 0.2 at low ("Colour Drains / Colour Returns")
  - Contrast: slight increase at low (harsh, clinical)
  - Vignette: subtle at high, heavy at low (claustrophobic)
- [ ] Optional: subtle film grain shader at low fuel

### 2.4 — First "Wow" Reward: The Observation Deck

One dramatic reward to prove the emotional concept.

- [ ] Designate one corridor module as the observation room
- [ ] At low ship fuel: blast shutters closed (a flat wall with a "SEALED" label)
- [ ] Cross a ship fuel threshold (e.g., 0.7): shutters animate open, revealing a starfield/PanoramaSky through a large window
- [ ] Subtle music swell when this happens
- [ ] No gameplay purpose. Just beauty. The player can stand here.

**Playtest checkpoint:** This is the big one. Let ship fuel drain until alarms and red lights. Then transfer. Watch lights warm. Hear alarm fade. See the observation deck open. Does it feel good enough to sacrifice your double jump? If yes, core concept is proven. If not, increase the contrast between high and low states.

---

## Phase 3: Player Fuel Mechanics

*Now that the "why" of transferring is felt, build the "what you lose" side. These should all be registered as MechanicsManager mechanics.*

### 3.1 — Movement Tiers (Refine Existing)

The current stepped system in player.gd already does this. Refine it:

- [ ] **Jump height:** Tie to a fuel curve (not linear). Noticeable cliff around 0.4. Currently steps at 50/25/10 — make it a smooth curve.
- [ ] **Double jump:** Available above 0.6 (currently 0.5 via health > 50). Costs a small fuel amount per use (already does — 5 units, convert to normalised).
- [ ] **Sprint:** New. Add sprint key (Shift). Available above 0.5. Below 0.5, speed is baseline. Should feel noticeably fast.
- [ ] **Slow crawl:** Below 0.2, speed drops below baseline (already exists at health < 10, adjust threshold).
- [ ] **Stumble:** Below 0.15, occasional brief velocity-zero + camera bob interruptions.

### 3.2 — Combat Degradation

- [ ] **Weapon drift:** Small random aim offset scaling inversely with player fuel. Full fuel = perfect aim. Low fuel = crosshair wanders. Use smooth noise, not jitter.
- [ ] **Combat cooldowns:** Multiply weapon cooldown by `(1.5 - player_fuel)`. At 0.5 fuel, normal. At 0.0, 50% longer.

### 3.3 — HUD Degradation

- [ ] **Fuel gauge inaccuracy:** Below 0.3 player fuel, the displayed number jitters +/-10%. You can't trust your own readout.
- [ ] **Intrusive warnings:** Below 0.25, periodic "LOW FUEL" flashes on HUD that partially obscure view.
- [ ] **Vision static:** At low fuel, subtle static shader on the HUD (not the world — it's your suit failing).
- [ ] **Tunnel vision:** Very low fuel, a tight dark vignette on the player camera (separate from the ship atmosphere vignette).

### 3.4 — Dash (New Ability)

- [ ] Available above 0.5 player fuel.
- [ ] Short-range directional blink (~3m forward), brief invincibility frame.
- [ ] Costs a small fuel amount per use.
- [ ] Essential for dodging in combat. Losing it hurts.

**Playtest checkpoint:** Play at various player fuel levels. Is there a sweet spot where you feel powerful but tempted to transfer? Is low-fuel degradation annoying enough to motivate hunting enemies, but not so punishing it's unfun? Does fuel gauge inaccuracy create genuine anxiety?

---

## Phase 4: Level & Enemies

*Expand the test environment to support the fuel tension loop.*

### 4.1 — Expand the Grid

The existing corridor tileset (13 variants) is solid. Build out:

- [ ] Arrange existing tiles into a loop that takes 3-5 minutes to traverse
- [ ] Include at least one vertical shaft (requires good jump to traverse — tests player fuel value)
- [ ] Include a dead end with a fuel canister reward
- [ ] The loop should require backtracking through at least one area (so ship fuel atmosphere changes hit harder on revisit)
- [ ] Place the observation deck module along the route

### 4.2 — Enemy Spawning

Currently there's one enemy placed manually. Scale up:

- [ ] Create `SpawnPoint` nodes placeable in any corridor module
- [ ] `SpawnManager` (autoload or node) tracks active enemies and respawns on a timer
- [ ] Enemies respawn in rooms the player isn't in
- [ ] 4-6 simultaneous enemies in the loop
- [ ] Each kill grants fuel to player via FuelManager
- [ ] Spawn rate scales with ship fuel — lower ship fuel = more enemies (from brainstorm). Wire into FuelManager signals.
- [ ] **Critical:** new enemies must integrate with the parasite feedback system. Living enemies feed the ship on delay; killing them removes that income. SpawnManager must register/deregister enemies with FuelManager.

### 4.3 — Enemy Behaviour Polish

The current enemy is functional but minimal. Add:

- [ ] Idle/patrol: walk between two points in their corridor (instead of floating in place)
- [ ] Alert: on seeing/hearing player, move toward them
- [ ] Death: brief animation (scale to zero works), fuel orb drops as a glowing pickup (satisfying chime)
- [ ] Currently enemies shoot through walls via raycast — add a visibility check

**Playtest checkpoint:** Loop the level 10 times. Is there a natural rhythm of explore, fight, collect, decide (keep or transfer)? Is the loop too long or too short? Adjust corridor count and enemy density.

---

## Phase 5: The Feedback Loop

*The systemic layer that makes the player keep transferring compulsively.*

### 5.1 — Immediate vs Delayed Feedback

This is the core psychological trick.

- [ ] **Ship fuel changes are instant:** The moment you transfer, lights brighten, music softens, alarms fade. Immediate dopamine.
- [ ] **Player fuel changes are gradual:** When you lose player fuel, abilities don't vanish instantly. Jump height decreases over 3-5 seconds. Weapon drift increases smoothly. You don't notice the exact moment you lost double jump. Implement as a ~3-5 second interpolation on player fuel effects, versus instant application for ship effects.
- [ ] The reward is a spike; the cost is a slope.

### 5.2 — Transfer Prompt Pressure

- [ ] When ship fuel is low, show a pulsing HUD prompt: "HOLD [E] TO TRANSFER FUEL TO SHIP" (or whatever transfer mode we've chosen)
- [ ] The prompt pulses. It feels urgent.
- [ ] There is NO equivalent prompt telling you to keep your fuel. Nobody advocates for your long-term wellbeing.
- [ ] At critically low ship fuel, text barks from crew: "Please, the lights..." / "The children are scared." Social pressure.

### 5.3 — The Ratchet

- [ ] Each transfer invisibly increases the ship drain rate by a tiny amount (~2% per transfer)
- [ ] Each "fix" lasts slightly less time than the last
- [ ] Player must transfer more often, keeping their own fuel lower on average
- [ ] This is the addiction ramp. Don't make it too steep or the game is unwinnable.

**Playtest checkpoint:** Play 15 minutes. Are you transferring compulsively? Are you aware you're doing it more than you should? Can you feel the mechanism working on you?

---

## Phase 6: Ship Flavour & Crew

*Rewards that make high ship fuel feel like home.*

### 6.1 — Crew NPCs (Static First)

- [ ] 2-3 simple NPC shapes in specific rooms
- [ ] High ship fuel: face each other, text barks ("Did you hear the engines? Sounds healthy.")
- [ ] Low ship fuel: cower, face walls, whimper

### 6.2 — Ship Cat

- [ ] Small orange shape/billboard that follows player at high ship fuel
- [ ] Disappears at low ship fuel (runs away)
- [ ] No gameplay function. Pure emotional texture.
- [ ] Quiet purring audio loop

### 6.3 — Environmental Micro-Rewards

- [ ] **Coffee machine:** Interactable. Above a fuel threshold, press E for a 5-second sit-and-sigh. Lock input, play contented audio.
- [ ] **Save station glow:** Save points shift from cold blue to warm amber based on ship fuel.
- [ ] **Gravity flickers at low fuel:** Occasional brief zero-g moments (disable gravity for 0.5s). Disorienting.

---

## Phase 7: Advanced Player Mechanics

*New abilities that feel great at high fuel and devastating to lose.*

### 7.1 — Scanner Pulse
- [ ] Activated ability (costs player fuel), available above 0.65
- [ ] Expanding sphere reveals enemies through walls + hidden passages for ~5 seconds

### 7.2 — Wall Grip
- [ ] Cling to walls when airborne + holding jump, available above 0.55
- [ ] Stamina-limited (2-3 seconds)
- [ ] Place at least one route requiring wall grip

### 7.3 — Grapple Tether
- [ ] Fire tether at anchor points, pull player toward them
- [ ] Available above 0.7 — premium ability, loss is felt hard
- [ ] Makes traversal feel incredible. Losing it feels like losing flight.

### 7.4 — Melee Strike
- [ ] Close-range attack, short cooldown, costs NO fuel (baseline fallback when you're broke)
- [ ] Staggers enemies above 0.4 fuel, doesn't stagger below

---

## Phase 8: The Narrator

*Don't start until mechanics feel right without it.*

### 8.1 — Text-Based Narrator (First Pass)
- [ ] `NarratorManager` autoload
- [ ] Subtitle-bar text triggered by events: first kill, first transfer, fuel thresholds, entering rooms, finding observation deck
- [ ] High ship fuel: calm and encouraging ("Good. The ship needs you.")
- [ ] Low ship fuel: anxious and pushy ("The fuel. Please. The crew can't--")
- [ ] ALWAYS encourages transferring. Never suggests keeping fuel.
- [ ] Refers to enemies exclusively as "parasites"

### 8.2 — Doubt Seeds
- [ ] After ~50 kills, occasional hesitations: "Another one. Good. That's... yes, that's good."
- [ ] If player lingers near enemy without attacking: uncomfortable silence, then "...well?"
- [ ] Breadcrumbs toward the plot revelation. Don't overdo.

---

## Phase 9: Systems Polish

### 9.1 — Fuel Balancing
- [ ] Debug overlay: real-time fuel curves, transfer history, drain rates
- [ ] Target: player maintains ~0.5 in both for first 10 minutes, then pressure forces a choice

### 9.2 — Save System
- [ ] Save fuel levels, mechanic states, kill count, ratchet rate
- [ ] 2-3 save stations in the loop
- [ ] Save station availability optionally tied to ship fuel (powerful but punishing — maybe later difficulty layer)

### 9.3 — Death & Respawn
- [ ] Respawn at nearest save point, fuel restored to last save state
- [ ] Bad transfer decisions before saving are permanent
- [ ] No save points at low ship fuel = higher death stakes (organic difficulty scaling)

---

## Phase 10: Audio & Visual Polish

*Only when mechanics are locked. Art on a moving target is wasted.*

### 10.1 — Asset Upgrade
- [ ] Replace CSG corridors with proper mesh pieces (or keep the existing OBJ tileset, which is already decent)
- [ ] Floor/wall/ceiling detail textures
- [ ] Pipes, wiring, panels on corridor walls

### 10.2 — Particles & Shaders
- [ ] Fuel transfer particle effect
- [ ] Enemy death particles
- [ ] Low-fuel suit sparks
- [ ] Bloom at high ship fuel, chromatic aberration at low

### 10.3 — Sound Design
- [ ] Footstep variations (metal, grate)
- [ ] Suit sounds: healthy hum vs clicking/hissing
- [ ] Enemy audio polish
- [ ] UI stingers: ability unlock/lose

---

## Parking Lot

Mechanics to try once the core loop is solid:

- **Overclock (bullet time):** Custom time-scale management; fun but complex
- **Terminal Access / Hacking:** Needs a minigame system
- **Thermal Sight:** Outline shader through walls; medium difficulty, cool feel
- **Proximity Alert:** UI indicator; needs solid enemy awareness AI first
- **Auto-Stabiliser (no fall damage):** Easy toggle, needs vertical level design
- **Resonance Map (auto-map):** Needs a map UI; significant work
- **Hologram Lounge / Galley / Shower:** Narrative micro-scenes; need real assets
- **Archive Unlocks (lore library):** Needs text UI and content
- **Deep Lung (oxygen):** Needs an oxygen system; only if level design demands it
- **Weapon Augment (charged fire):** Needs more complex weapon system; defer

---

## Design Pairing to Keep in Mind

The ship cat and weapon drift. One is something you love having around that quietly goes away when things get bad. The other is something you barely notice creeping in until it ruins your day. The things you sacrifice for comfort disappear gently, and the costs arrive so slowly you blame yourself for not noticing sooner. Build toward that feeling.
