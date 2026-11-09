extends Node2D
@onready var board = $Board
@onready var hud = $Hud
@onready var sfx = $SFX

# --------------------------------------------------------
# SOUND AND MUSIC ATTRIBUTION
# Tiny Hand Bell Ding by tosha73 -- https://freesound.org/s/862762/ -- License: Attribution 4.0
# Classic Glass Hit-C5 by CAT-FOX_ALEX -- https://freesound.org/s/865788/ -- License: Creative Commons 0
# win.wav by OtisJames -- https://freesound.org/s/215773/ -- License: Creative Commons 0
# Plates 2 by Aiwha -- https://freesound.org/s/417449/ -- License: Attribution 4.0
# Clean Record Scratch by kwahmah_02 -- https://freesound.org/s/269476/ -- License: Attribution 3.0
# Music by <a href="https://pixabay.com/users/nickpanek-38266323/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=253093">Nicholas Panek</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=253093">Pixabay</a>
# Music by <a href="https://pixabay.com/users/alanajordan-25247407/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=234847">Alana Jordan</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=234847">Pixabay</a>
# Music by <a href="https://pixabay.com/users/jumpingbunny-47869633/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=371806">jumpingbunny</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=371806">Pixabay</a>
# Music by <a href="https://pixabay.com/users/jumpingbunny-47869633/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=371806">jumpingbunny</a> from <a href="https://pixabay.com/music//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=371806">Pixabay</a>
# ---------------------------------------------------------

func _ready() -> void:
	board.turn_changed.connect(on_turn_changed)
	board.piece_captured.connect(hud.on_piece_captured)
	board.game_ended.connect(hud.on_game_ended)
	board.message.connect(hud.on_message)
	board.message_sound.connect(on_message_sound)
	board.piece_selected.connect(on_selected_sound)
	board.piece_captured.connect(on_captured_sound)
	board.piece_moved.connect(on_moved_sound)
	board.piece_crowned.connect(on_crowned_sound)
	board.game_ended.connect(on_game_ended_sound)
	board.multi_jump.connect(on_multi_jump)

func on_turn_changed(team) -> void:
	hud.show_turn(team == board.Team.BURGER)

func on_selected_sound(_cell) -> void:
	$SFX/Select.play()
	
func on_moved_sound() -> void:
	$SFX/Move.play()
	
func on_crowned_sound(_team) -> void:
	$SFX/Crown.play()
	
func on_captured_sound(_by_team, _cell) -> void:
	$SFX/Capture.play()
	
func on_message_sound(_msg) -> void:
	$SFX/Denied.play()

func on_game_ended_sound(_winner) -> void:
	$SFX/Music.stop()
	$SFX/Win.play()

func on_multi_jump(active: bool) -> void:
	hud.on_message("Keep Jumping!" if active else "")

func fade_music() -> void:
	var t := create_tween()
	t.tween_property($SFX/Music, "volume_db", -40.0, 0.35)
