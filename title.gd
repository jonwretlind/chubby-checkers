extends Control

const DEPTHS := { "Easy": 1, "Medium": 3, "Hard": 5 }

@onready var side_row: HBoxContainer = $BtnContainer/SideRow
@onready var difficulty_row: HBoxContainer = $BtnContainer/DifficultyRow

func _ready() -> void:
	$BtnContainer/Players/OnePlayer.pressed.connect(_on_players.bind(true))
	$BtnContainer/Players/TwoPlayers.pressed.connect(_on_players.bind(false))
	$BtnContainer/SideRow/BurgerButton.pressed.connect(_on_side.bind(Board.Team.BURGER))
	$BtnContainer/SideRow/HotdogButton.pressed.connect(_on_side.bind(Board.Team.HOTDOG))
	$BtnContainer/DifficultyRow/Difficulty.item_selected.connect(func(i): GameSettings.ai_depth = $BtnContainer/DifficultyRow/Difficulty.get_item_id(i))
	$StartButton.pressed.connect(_on_start)
	_on_players(GameSettings.vs_computer)      # show/hide rows to match

func _on_players(one_player: bool) -> void:
	GameSettings.vs_computer = one_player
	side_row.visible = one_player             # side and difficulty only matter vs the computer
	difficulty_row.visible = one_player
	if one_player:
		$BtnContainer/Players/OnePlayer.button_pressed = true
		$BtnContainer/Players/TwoPlayers.button_pressed = false
	else:
		$BtnContainer/Players/OnePlayer.button_pressed = false
		$BtnContainer/Players/TwoPlayers.button_pressed = true
		
func _on_side(team: int) -> void:
	GameSettings.human_team = team

func _on_difficulty(depth: int) -> void:
	GameSettings.ai_depth = depth

func _on_start() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
