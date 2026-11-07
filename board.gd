@tool
class_name Board
extends Node2D
# Globals
@export var square_h: float = 80
@export var square_v: float =  80
@export var square_color: Color = Color("#9b0a22")
@export var square_alt_color: Color = Color("#d9e1cc")
const PIECE_SCENE = preload("res://piece.tscn")
enum Tile {EMPTY, BURGER, BURGER_KING, HOTDOG, HOTDOG_KING}
enum Team {NONE, BURGER, HOTDOG}
var grid: Array[Array] = []
const NO_CELL := Vector2i(-1, -1)
var selected_cell: Vector2i = NO_CELL
var current_turn: Team = Team.BURGER  # BURGERs start first
var pieces: Dictionary = {}
var must_continue: Vector2i = NO_CELL
var game_over := false
const DRAW_LIMIT := 40
var moves_since_capture := 0
signal turn_changed(team: Team)
signal piece_captured(by_team: Team, total: int)
signal multi_jump(active: bool)
signal game_ended(winner: Team)
signal message(msg: String)
signal piece_selected
signal piece_moved
signal piece_crowned
signal message_sound
var captured := { Team.BURGER: 0, Team.HOTDOG: 0 }   # pieces each team has taken
@export var vs_computer := true
@export var computer_team: Team = Team.HOTDOG
@export_range(1, 6) var ai_depth := 3          # difficulty: 1 easy, 3 medium, 5 hard
const THINK_TIME := 0.9      # a little longer than the 0.8 s hop
var computer_busy := false
var planned := []



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		init_grid()
		spawn_pieces()
		print_grid()
		if is_computer_turn(): computer_move.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if game_over: return
	if is_computer_turn():
		return
	if not (event is InputEventMouseButton): 
		return  # if it isn't a click, then exit function
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: 
		return # reject right button clicks
	var local_pos := get_local_mouse_position()
	var cell := screen_to_grid(local_pos)
	if cell == NO_CELL:
		return
	if must_continue != NO_CELL:
		if is_capture(must_continue, cell):
			handle_capture(cell)
		return
	var tapped_team := team_of(grid[cell.y][cell.x])
	if tapped_team == current_turn:
		selected_cell = NO_CELL if cell == selected_cell else cell
		piece_selected.emit(cell)
		queue_redraw()
	elif selected_cell != NO_CELL and is_capture(selected_cell, cell) :
		play_move(selected_cell, cell)
		message.emit("Captured!")
	elif selected_cell != NO_CELL and is_simple_move(selected_cell, cell):
		if team_has_capture(current_turn):
			message.emit("You must capture!")
			message_sound.emit(selected_cell)
		else:
			play_move(selected_cell, cell)
			message.emit("")
	print_grid() # for debugging
	
# Painting
func _draw() -> void:
	for y in 8:
		var color1 = square_alt_color if (y % 2 == 0) else square_color
		var color2 = square_color if (y % 2 == 0) else square_alt_color
		for x in 4:
			draw_rect(Rect2((x * square_h * 2), y * square_v, square_h, square_v), color1)
			draw_rect(Rect2((x * square_h * 2) + square_h, y * square_v, square_h, square_v), color2)
	if selected_cell != NO_CELL:
		var size := Vector2(square_h, square_v)
		var top_left := grid_to_screen(selected_cell) - size / 2.0
		draw_rect(Rect2(top_left, size), Color(0.78, 0.517, 0.062, 1.0))
			
func init_grid():
	grid.clear()
	for y in range(8):
		grid.append([])
		for x in range(8):
			grid[y].append(Tile.EMPTY) 					# Place empty square first

			
func spawn_pieces():
	for y in 8:
		for x in 8:
			var cell := Vector2i(x, y)
			var is_dark := (x + y) % 2 != 0   						 # dark square on odd numbers
			var skip_rows = true if (y < 3 or y > 4) else false      # rows to skip 
			var piece_side = "hotdog" if (y < 3) else "burger"
			if (is_dark and skip_rows): spawn(cell, piece_side)
			
func spawn(cell: Vector2i, piece_side: String):
	var p = PIECE_SCENE.instantiate()
	p.position = grid_to_screen(cell)
	p.side = piece_side
	pieces[cell] = p
	var the_piece = Tile.HOTDOG if (piece_side == "hotdog") else Tile.BURGER
	grid[cell.y][cell.x] = the_piece
	add_child(p)
	
# Grid cells are Vector2i(col, row): x = column, y = row
func screen_to_grid(pos: Vector2) -> Vector2i:
	var col := floori(pos.x / square_h)
	var row := floori(pos.y / square_v)
	var cell := Vector2i(col, row)
	if not is_on_board(cell):
		return Vector2i(-1, -1)
	return cell
	
# Center of a grid square, in Board-local pixels. cell = Vector2i(col, row)
func grid_to_screen(cell: Vector2i) -> Vector2:
	var x := cell.x * square_h + square_h/2
	var y := cell.y * square_v + square_v/2
	return Vector2(x, y)

func is_on_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < 8 and cell.y >= 0 and cell.y < 8

func crown_row(team: Team) -> int:
	return 0 if team == Team.BURGER else 7

func is_king(cell: Tile) -> bool:
	return cell == Tile.BURGER_KING or cell == Tile.HOTDOG_KING

func king_of(team: Team) -> Tile:
	return Tile.BURGER_KING if team == Team.BURGER else Tile.HOTDOG_KING

func try_crown(cell: Vector2i) -> bool:
	var tile: Tile = grid[cell.y][cell.x]
	var team := team_of(tile)
	if is_king(tile) or cell.y != crown_row(team):
		return false
	grid[cell.y][cell.x] = king_of(team)
	pieces[cell].crown()
	piece_crowned.emit(team)
	return true
	

# HELPER FUNCTIONS
func team_of(team: Tile) -> Team:
	match team:
			Tile.BURGER, Tile.BURGER_KING :
				return Team.BURGER
			Tile.HOTDOG, Tile.HOTDOG_KING :
				return Team.HOTDOG
			_:
				return Team.NONE

#MOVING PIECES
func forward_of(team: Team) -> int:
	return -1 if team == Team.BURGER else 1
	
# for kings
func row_dirs(cell: Vector2i) -> Array[int]:
	var tile: Tile = grid[cell.y][cell.x]
	if is_king(tile):
		return [-1, 1]
	return [forward_of(team_of(tile))]

# check for legal simple move
func is_simple_move(from: Vector2i, to: Vector2i) -> bool:
	if not is_on_board(to):
		return false
	if grid[to.y][to.x] != Tile.EMPTY :
		return false
	var step := to - from
	return abs(step.x) == 1 and step.y in row_dirs(from)

func simple_moves_from(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dy in row_dirs(cell):
		for dx in [-1, 1]:
			var to := cell + Vector2i(dx, dy)
			if is_simple_move(cell, to):
				result.append(to)
	return result
	
func team_has_any_move(team: Team) -> bool:
	for cell in pieces.keys():
		if team_of(grid[cell.y][cell.x]) != team:
			continue
		if not captures_from(cell).is_empty() or not simple_moves_from(cell).is_empty():
			return true
	return false
	
func end_turn() -> void :
	current_turn = Team.BURGER if current_turn == Team.HOTDOG else Team.HOTDOG
	moves_since_capture += 1
	if moves_since_capture >= DRAW_LIMIT :
		game_over = true
		var draw = "DRAW!"
		game_ended.emit(Team.NONE)
		print("It's a DRAW!")
		return
	if not team_has_any_move(current_turn):
		game_over = true
		var winner := Team.BURGER if current_turn == Team.HOTDOG else Team.HOTDOG
		print(Team.keys()[winner], " WINS!")
		game_ended.emit(winner)
		return
	turn_changed.emit(current_turn)
	if is_computer_turn(): computer_move()
	print("Turn: ", Team.keys()[current_turn])
	

func move_piece(from: Vector2i, to: Vector2i) -> void :
	# data
	grid[to.y][to.x] = grid[from.y][from.x]
	grid[from.y][from.x] = Tile.EMPTY
	# lookup in pieces Dictionary
	var node = pieces[from]
	pieces.erase(from)
	pieces[to] = node
	# move it visually to reflect change in grid
	node.hop()
	var tween := create_tween()
	tween.tween_property(node, "position", grid_to_screen(to), 0.8)
	
	


# CAPTURES
func is_enemy(tile: Tile, my_team: Team) -> bool:
	var t := team_of(tile)
	return t != Team.NONE and t != my_team
	
func is_capture(from: Vector2i, to: Vector2i) -> bool:
	if not is_on_board(to) or grid[to.y][to.x] != Tile.EMPTY:
		return false
	var team := team_of(grid[from.y][from.x])
	var step := to - from
	if abs(step.x) != 2 or not((step.y/2) in row_dirs(from)):
		return false
	var middle := from + step / 2
	return is_enemy(grid[middle.y][middle.x], team)

func remove_piece(cell: Vector2i) -> void:
	grid[cell.y][cell.x] = Tile.EMPTY
	var node = pieces[cell]
	pieces.erase(cell)
	node.queue_free()
	
func capture(from: Vector2i, to: Vector2i) -> void:
	var middle := from + (to - from) / 2
	move_piece(from, to)
	remove_piece(middle)
	captured[current_turn] += 1
	piece_captured.emit(current_turn, captured[current_turn])
	print(pieces.keys())

func captures_from(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	#var team := team_of(grid[cell.y][cell.x])
	for dy in row_dirs(cell):
			for dx in [-2, 2]:
				var to := cell + Vector2i(dx, 2 * dy)
				if is_capture(cell, to):
					result.append(to)
	return result
	
func team_has_capture(team: Team) -> bool:
	for cell in pieces.keys():
		if team_of(grid[cell.y][cell.x]) == team and not captures_from(cell).is_empty():
			return true
	return false
	
func handle_capture(cell: Vector2i) -> void:
	capture(selected_cell, cell)
	moves_since_capture = 0
	var crowned := try_crown(cell)
	if not crowned and not captures_from(cell).is_empty():
		must_continue = cell
		selected_cell = cell
		multi_jump.emit(true)
		if is_computer_turn(): computer_move()
	else:
		must_continue = NO_CELL
		selected_cell = NO_CELL
		multi_jump.emit(false)
		end_turn()
	queue_redraw()
	

# Utility Functions
func print_grid():
	# To help with debugging, print grid to console
	var line := ""
	for y in 8:
		line = ""
		for x in 8:
			match grid[y][x]:
				Tile.EMPTY: line += ". "
				Tile.BURGER: line += "b "
				Tile.HOTDOG: line += "h "
				Tile.BURGER_KING: line += "B "
				Tile.HOTDOG_KING: line += "H "
		print(line)

# ===========================
# PLAYER V COMPUTER FUNCTIONS
# ===========================

func is_computer_turn() -> bool:
	return vs_computer and current_turn == computer_team and not game_over

# Plays a legal move. Returns false (and does nothing) if it isn't legal.
func play_move(from: Vector2i, to: Vector2i) -> bool:
	if is_capture(from, to):
		selected_cell = from
		handle_capture(to)
		return true
	if is_simple_move(from, to) and not team_has_capture(current_turn):
		move_piece(from, to)
		piece_moved.emit()
		selected_cell = NO_CELL
		try_crown(to)
		queue_redraw()
		end_turn()
		return true
	return false
	
func legal_moves(team: Team) -> Array:
	var captures := []
	var steps := []
	# During a multi-jump, only further captures by that plant count
	if must_continue != NO_CELL:
		for to in captures_from(must_continue):
			captures.append({ "from": must_continue, "to": to })
		return captures
	for cell in pieces.keys():
		if team_of(grid[cell.y][cell.x]) != team:
			continue
		for to in captures_from(cell):
			captures.append({ "from": cell, "to": to })
		for to in simple_moves_from(cell):
			steps.append({ "from": cell, "to": to })
	# Forced capture: if any capture exists, only captures are legal
	return captures if not captures.is_empty() else steps
	
func computer_move() -> void:
	if computer_busy:
		return
	computer_busy = true
	await get_tree().create_timer(THINK_TIME).timeout
	computer_busy = false
	if not is_computer_turn():
		return                        # game ended or mode changed while waiting
	if planned.is_empty():
		planned = best_path(current_turn)          # think once, at the start of the turn
	if planned.size() < 2:
		planned = []
		return
	var from: Vector2i = planned[0]
	var to: Vector2i = planned[1]
	planned.remove_at(0)                           # next time, continue from the landing square
	if planned.size() < 2:
		planned = []
	play_move(from, to)
	var moves := legal_moves(current_turn)
	if moves.is_empty():
		return
	#var move: Dictionary = moves.pick_random()
	#play_move(move.from, move.to)
	
func cells_of(team: Team) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in 8:
		for x in 8:
			if team_of(grid[y][x]) == team:
				result.append(Vector2i(x, y))
	return result


# Every complete jump sequence starting from cell. Each path starts with cell.
func jump_paths(cell: Vector2i) -> Array:
	var paths := []
	for to in captures_from(cell):
		var middle := cell + (to - cell) / 2
		var me: Tile = grid[cell.y][cell.x]
		var victim: Tile = grid[middle.y][middle.x]
		# make the hop on the grid
		grid[to.y][to.x] = me
		grid[cell.y][cell.x] = Tile.EMPTY
		grid[middle.y][middle.x] = Tile.EMPTY
		var crowned := not is_king(me) and to.y == crown_row(team_of(me))
		var more := [] if crowned else jump_paths(to)     # ← the function calls itself
		# undo the hop (backtracking)
		grid[cell.y][cell.x] = me
		grid[middle.y][middle.x] = victim
		grid[to.y][to.x] = Tile.EMPTY
		if more.is_empty():
			paths.append([cell, to])                  # this sequence ends here
		else:
			for rest in more:
				paths.append([cell] + rest)           # cell + the rest of the sequence
	return paths


func all_moves(team: Team) -> Array:
	var jumps := []
	var steps := []
	for cell in cells_of(team):
		jumps.append_array(jump_paths(cell))
		for to in simple_moves_from(cell):
			steps.append([cell, to])
	return jumps if not jumps.is_empty() else steps   # forced capture
	
func apply_path(path: Array) -> void:
	var me: Tile = grid[path[0].y][path[0].x]
	for i in range(1, path.size()):
		var a: Vector2i = path[i - 1]
		var b: Vector2i = path[i]
		grid[a.y][a.x] = Tile.EMPTY
		if abs(b.x - a.x) == 2:                      # a jump: remove the victim
			var mid := a + (b - a) / 2
			grid[mid.y][mid.x] = Tile.EMPTY
		grid[b.y][b.x] = me
	var end: Vector2i = path[-1]                     # [-1] = last element
	if not is_king(me) and end.y == crown_row(team_of(me)):
		grid[end.y][end.x] = king_of(team_of(me))

func evaluate(for_team: Team) -> int:
	var score := 0
	for y in 8:
		for x in 8:
			var grid: Tile = grid[y][x]
			var team := team_of(grid)
			if team == Team.NONE:
				continue
			var value := 160 if is_king(grid) else 100
			if not is_king(grid):
				var home := 7 if grid == Team.BURGER else 0      # start row (opposite of crown_row)
				value += 5 * abs(y - home)
			score += value if team == for_team else -value
	return score

const WIN := 100000

# Score of the current grid for ai_team, looking depth moves ahead.
# to_move = whose turn it is in this imagined position.
func minimax(depth: int, to_move: Team, ai_team: Team, alpha: int, beta: int) -> int:
	var moves := all_moves(to_move)
	if moves.is_empty():                             # to_move can't move: they lose
		return -WIN - depth if to_move == ai_team else WIN + depth
	if depth == 0:
		return evaluate(ai_team)
	var other := Team.HOTDOG if to_move == Team.BURGER else Team.BURGER
	var saved := grid
	if to_move == ai_team:                           # computer's turn: maximize
		var best := -WIN * 2
		for path in moves:
			grid = saved.duplicate(true)
			apply_path(path)
			best = max(best, minimax(depth - 1, other, ai_team, alpha, beta))
			alpha = max(alpha, best)
			if alpha >= beta:
				break                                    # alpha-beta cut
		grid = saved
		return best
	else:                                            # opponent's turn: minimize
		var best := WIN * 2
		for path in moves:
			grid = saved.duplicate(true)
			apply_path(path)
			best = min(best, minimax(depth - 1, other, ai_team, alpha, beta))
			beta = min(beta, best)
			if alpha >= beta:
				break
		grid = saved
		return best
		

func best_path(team: Team) -> Array:
	var other := Team.HOTDOG if team == Team.BURGER else Team.BURGER
	var saved := grid
	var best_score := -WIN * 2
	var best := []
	var moves := all_moves(team)
	moves.shuffle()                                # equal moves: vary the choice
	for path in moves:
		grid = saved.duplicate(true)
		apply_path(path)
		var score := minimax(ai_depth - 1, other, team, -WIN * 2, WIN * 2)
		if score > best_score:
			best_score = score
			best = path
	grid = saved
	return best
		
