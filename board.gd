@tool
extends Node2D
# Globals
@export var square_h = 80
@export var square_v = 80
@export var square_color: Color = Color("#9b0a22")
@export var square_alt_color: Color = Color("#d9e1cc")
const PIECE_SCENE = preload("res://piece.tscn")
enum Tile {EMPTY, BURGER, BURGER_KING, HOTDOG, HOTDOG_KING}
var grid: Array[Array] = []

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
	
# Painting
func _draw() -> void:
	for y in 8:
		var color1 = square_alt_color if (y % 2 == 0) else square_color
		var color2 = square_color if (y % 2 == 0) else square_alt_color
		for x in 4:
			draw_rect(Rect2((x * square_h * 2) + square_h, y * square_v, square_h, square_v), color1)
			draw_rect(Rect2((x * square_h * 2) + square_h * 2, y * square_v, square_h, square_v), color2)
			
func init_grid():
	grid.clear()
	for y in range(8):
		grid.append([])
		for x in range(8):
			grid[y].append(Tile.EMPTY) 					# Place empty square first

			
func spawn_pieces():
	for y in 8:
		for x in 8:
			var pos_X = (x * square_h) + square_h 
			var pos_Y = y * square_v
			var is_alt_x = false if (x % 2 != 0) else true      # is this an alternating column?
			var is_alt_y = false if (y % 2 == 0) else true      # is this an alternating row?
			var skip_rows = true if (y < 3 or y > 4) else false # rows to skip
			var piece_side = "hotdog" if (y < 3) else "burger"
			match [is_alt_x, is_alt_y, skip_rows]:
				[false, false, true]: spawn(pos_X ,pos_Y, x, y, piece_side)
				[true, true, true]: spawn(pos_X ,pos_Y, x, y, piece_side)
			
func spawn(pos_X, pos_Y, x, y, piece_side):
	var p = PIECE_SCENE.instantiate()
	p.position = Vector2(pos_X, pos_Y)
	p.side = piece_side
	var the_piece = Tile.HOTDOG if (piece_side == "hotdog") else Tile.BURGER
	grid[y][x] = the_piece
	add_child(p)

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
