@tool
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		init_grid()
		spawn_pieces()
		print_grid()

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton): 
		return  # if it isn't a click, then exit function
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed: 
		return # reject right button clicks
	var local_pos := get_local_mouse_position()
	var cell := screen_to_grid(local_pos)
	if cell == NO_CELL: return
	var tapped_team := team_of(grid[cell.y][cell.x])
	if tapped_team == current_turn:
		if cell == selected_cell:
			selected_cell = NO_CELL
		else:
			selected_cell = cell
		queue_redraw()
	elif selected_cell != NO_CELL and is_simple_move(selected_cell, cell) :
		move_piece(selected_cell, cell)
		queue_redraw()
		end_turn()
		print_grid()
	
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

# check for legal simple move
func is_simple_move(from: Vector2i, to: Vector2i) -> bool:
	if not is_on_board(to):
		return false
	if grid[to.y][to.x] != Tile.EMPTY :
		return false
	var step := to - from
	var team := team_of(grid[from.y][from.x])
	return abs(step.x) == 1 and step.y == forward_of(team)

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
	
	
func end_turn() -> void:
	current_turn = Team.HOTDOG if current_turn == Team.BURGER else Team.BURGER
	print("Turn: ", Team.keys()[current_turn])



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
