@tool
extends EditorScript

# ── Item indices (coridor_mesh_library.tres order) ────────────────────────────
const BOX             = 0   # CoridorBox            — fully enclosed
const CORNER          = 1   # CoridorCorner         — 90° bend
const END             = 2   # CoridorEnd            — dead end cap
const END_FL          = 3   # CoridorEndFloorless
const END_STAIRS      = 4   # CoridorEndStairs      — dead end, stairs going up
const STRAIGHT        = 5   # CoridorStraight       — straight passage
const STRAIGHT_FL     = 6   # CoridorStraightFloorless
const STRAIGHT_STAIRS = 7   # CoridorStraightStairs — passage ramping up one Y level
const T_JCT           = 8   # CoridorT              — T-junction
const TOPLESS         = 9   # CoridorTopless
const T_FL            = 10  # CoridorTFloorless
const T_TOPLESS       = 11  # CoridorTTopless
const OPEN            = 12  # CoridorOpen           — 4-way cross

# ── Orientations (Y-axis rotations, Godot orthogonal basis indices) ───────────
# Assumed conventions — adjust if tiles face the wrong way in-editor:
#
#   Straight:  R0/R2 runs along Z;  R1/R3 runs along X
#   End:       R0 opens toward -Z   R1 opens toward +X
#              R2 opens toward +Z   R3 opens toward -X
#   Corner:    R0 (-Z,+X)  R1 (+X,+Z)  R2 (+Z,-X)  R3 (-X,-Z)
#   T-jct:     R0 opens (-Z,+X,-X)  stub at +Z
#              R1 opens (+X,+Z,-Z)  stub at -X
#              R2 opens (+Z,+X,-X)  stub at -Z
#              R3 opens (-X,+Z,-Z)  stub at +X
const R0 = 0   # default
const R1 = 10  # 90° CW from above
const R2 = 16  # 180°
const R3 = 22  # 270° CW

# ─────────────────────────────────────────────────────────────────────────────

func _run() -> void:
	var grid_map: GridMap = get_scene().find_child("GridMap")
	if not grid_map:
		push_error("GridMap not found — make sure main.tscn is the open scene.")
		return
	grid_map.clear()
	_main_floor(grid_map)
	_upper_floor(grid_map)
	print("Map generated: %d cells placed." % grid_map.get_used_cells().size())


func _p(g: GridMap, x: int, y: int, z: int, item: int, rot: int) -> void:
	g.set_cell_item(Vector3i(x, y, z), item, rot)


# ── Layer y = 1  (main floor) ─────────────────────────────────────────────────
#
#  z\x  0  1  2  3  4  5  6  7  8  9 10 11 12 13
#   0            ↑stairs
#   1            Sz
#   2            Sz
#   3   E  Sx Sx T  Sx Sx T  Sx Sx T  Sx Sx T  Sx Sx E
#                |                 |              |
#   4            |              Sz Sz          Sz Sz
#   5            |              Sz Sz          Sz Sz
#   6            E  (dead end)  Cx─────────────Cx
#
#  Sz = straight, runs Z   Sx = straight, runs X
#  T  = T-junction         C  = corner
#
func _main_floor(g: GridMap) -> void:
	var y := 1

	# ── East-West spine at z = 3 ──────────────────────────────────────────────
	_p(g,  0, y, 3,  END,      R1)  # west dead end, opens east
	_p(g,  1, y, 3,  STRAIGHT, R1)
	_p(g,  2, y, 3,  T_JCT,    R0)  # north branch (stub at +Z, opens -Z/+X/-X)
	_p(g,  3, y, 3,  STRAIGHT, R1)
	_p(g,  4, y, 3,  STRAIGHT, R1)
	_p(g,  5, y, 3,  T_JCT,    R2)  # south dead-end branch (stub at -Z)
	_p(g,  6, y, 3,  STRAIGHT, R1)
	_p(g,  7, y, 3,  STRAIGHT, R1)
	_p(g,  8, y, 3,  T_JCT,    R2)  # south loop branch — west leg
	_p(g,  9, y, 3,  STRAIGHT, R1)
	_p(g, 10, y, 3,  STRAIGHT, R1)
	_p(g, 11, y, 3,  T_JCT,    R2)  # south loop branch — east leg
	_p(g, 12, y, 3,  STRAIGHT, R1)
	_p(g, 13, y, 3,  END,      R3)  # east dead end, opens west

	# ── North spur (x = 2, going -Z) → staircase to upper floor ──────────────
	_p(g,  2, y, 2,  STRAIGHT,   R0)
	_p(g,  2, y, 1,  STRAIGHT,   R0)
	_p(g,  2, y, 0,  END_STAIRS, R2)  # stairs ascend toward -Z; opens south (+Z)

	# ── South dead-end spur (x = 5, going +Z) ────────────────────────────────
	_p(g,  5, y, 4,  STRAIGHT, R0)
	_p(g,  5, y, 5,  STRAIGHT, R0)
	_p(g,  5, y, 6,  END,      R2)  # opens north (toward main corridor)

	# ── South loop (x = 8 → east → x = 11, closes back at spine) ────────────
	_p(g,  8, y, 4,  STRAIGHT, R0)
	_p(g,  8, y, 5,  STRAIGHT, R0)
	_p(g,  8, y, 6,  CORNER,   R0)  # came from -Z, turns east  (-Z, +X)
	_p(g,  9, y, 6,  STRAIGHT, R1)
	_p(g, 10, y, 6,  STRAIGHT, R1)
	_p(g, 11, y, 6,  CORNER,   R3)  # came from -X, turns north (-X, -Z)
	_p(g, 11, y, 5,  STRAIGHT, R0)
	_p(g, 11, y, 4,  STRAIGHT, R0)


# ── Layer y = 2  (upper floor, reached via stairs at (2,1,0)) ─────────────────
#
#  z\x  0  1  2  3  4  5  6  7
#  -1   E  Sx Sx Sx T  Sx Sx E
#   0            Sz    Sz
#   1            Sz    Sz
#   2            Cx────Cx
#
#  Player climbs EndStairs at (2,1,0) and arrives at (2,2,0) Straight,
#  which leads north into the E-W corridor at z = -1.
#  A small loop runs from the T at x=4 down and back.
#
func _upper_floor(g: GridMap) -> void:
	var y := 2

	# ── Stair landing: connects EndStairs below to corridor at z = -1 ─────────
	_p(g,  2, y,  0,  STRAIGHT, R0)  # stair top landing, runs Z

	# ── East-West upper corridor at z = -1 ───────────────────────────────────
	_p(g,  0, y, -1,  END,      R1)  # west dead end
	_p(g,  1, y, -1,  STRAIGHT, R1)
	_p(g,  2, y, -1,  STRAIGHT, R1)  # connects to landing below at (2,y,0)
	_p(g,  3, y, -1,  STRAIGHT, R1)
	_p(g,  4, y, -1,  T_JCT,    R2)  # south branch into small loop (stub at -Z)
	_p(g,  5, y, -1,  STRAIGHT, R1)
	_p(g,  6, y, -1,  STRAIGHT, R1)
	# (7, y, -1) is the loop return corner — placed below, not an End

	# ── Small loop off the T at (4, y, -1) ───────────────────────────────────
	# Path: T → south → corner east → east → corner north → north → corner west → done
	_p(g,  4, y,  0,  STRAIGHT, R0)
	_p(g,  4, y,  1,  STRAIGHT, R0)
	_p(g,  4, y,  2,  CORNER,   R0)  # came from -Z (north), turns east  (-Z,+X)
	_p(g,  5, y,  2,  STRAIGHT, R1)
	_p(g,  6, y,  2,  STRAIGHT, R1)
	_p(g,  7, y,  2,  CORNER,   R3)  # came from -X (west),  turns north (-X,-Z)
	_p(g,  7, y,  1,  STRAIGHT, R0)
	_p(g,  7, y,  0,  STRAIGHT, R0)
	_p(g,  7, y, -1,  CORNER,   R2)  # came from +Z (south), turns west  (+Z,-X)
