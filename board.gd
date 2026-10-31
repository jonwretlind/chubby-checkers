@tool
extends Node2D
# Globals
@export var square_h = 80
@export var square_v = 80
@export var square_color: Color = Color("#9b0a22")
@export var square_alt_color: Color = Color("#d9e1cc")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass
	
# Painting
func _draw() -> void:
	for y in 8:
		var color1 = square_color if (y % 2 == 0) else square_alt_color
		var color2 = square_alt_color if (y % 2 == 0) else square_color
		for x in 4:
			draw_rect(Rect2((x * square_h * 2) + square_h, y * square_v, square_h, square_v), color1)
			draw_rect(Rect2((x * square_h * 2) + square_h * 2, y * square_v, square_h, square_v), color2)
