extends Node2D
@onready var player1_label: Label = $Control/Scores/Player1 
@onready var player2_label: Label = $Control/Scores/Player2 
@onready var message: Label = $Control/Message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_turn(burgers_turn: bool) -> void:
	$Control/BurgerTurnSprite.visible = burgers_turn
	$Control/HotdogTurnSprite.visible = not burgers_turn

func on_piece_captured(by_team: Board.Team, total: int) -> void:
	if by_team == Board.Team.BURGER:
		player1_label.text = "Burgers: %d" % total
	else:
		player2_label.text = "Hotdogs: %d" % total
		
func on_game_ended(winner) -> void:
	if winner != 0: 
		$Control/WinSprite.visible = true
	else:
		$Control/DrawSprite.visible = true

func on_message(msg) -> void:
	message.text = msg
