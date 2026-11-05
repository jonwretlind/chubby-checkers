extends Node2D
@onready var board = $Board
@onready var hud = $Hud

func _ready() -> void:
	board.turn_changed.connect(on_turn_changed)
	board.piece_captured.connect(hud.on_piece_captured)
	board.game_ended.connect(hud.on_game_ended)
	board.message.connect(hud.on_message)

func on_turn_changed(team) -> void:
	hud.show_turn(team == board.Team.BURGER)
	
