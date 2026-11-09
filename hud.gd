extends Node2D
@onready var player1_label: Label = $Control/Scores/Player1 
@onready var player2_label: Label = $Control/Scores/Player2 
@onready var message: Label = $Control/Message

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Control/MenuButton.pressed.connect(_set_paused.bind(true))
	$Control/PauseMenu/VBoxContainer/Resume.pressed.connect(_set_paused.bind(false))
	$Control/PauseMenu/VBoxContainer/Restart.pressed.connect(func(): _set_paused(false); Transition.reload())
	$Control/PauseMenu/VBoxContainer/MainMenu.pressed.connect(func(): _set_paused(false); Transition.change_scene("res://title.tscn"))
	$Control/PauseMenu/VBoxContainer/Sound.toggled.connect(_on_sound_toggled)

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
		$Control/Message.visible = false
		$Control/WinSprite.visible = true
	else:
		$Control/Message.visible = false
		$Control/DrawSprite.visible = true
	$Control/PauseMenu.visible = true
	$Control/PauseMenu/VBoxContainer/Restart.text = "Play Again"
func on_message(msg) -> void:
	message.text = msg

func _set_paused(on: bool) -> void:
	get_tree().paused = on
	$Control/PauseMenu.visible = on
	$Control/MenuOverlay.visible = on

func _on_sound_toggled(on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not on)
