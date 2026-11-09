extends CanvasLayer

const FADE_TIME := 0.35
@onready var fade: ColorRect = $Fade
var busy := false

func _ready() -> void:
	fade.modulate.a = 1.0
	await _fade_to(0.0)

func change_scene(path: String) -> void:
	if busy:
		return                                   # ignore double clicks during a fade
	busy = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP   # block taps while covered
	await _fade_to(1.0)                          # 1. cover the screen
	get_tree().paused = false                    # never arrive in a paused scene
	get_tree().change_scene_to_file(path)        # 2. swap
	await get_tree().process_frame               # 3. let the new scene appear
	await _fade_to(0.0)                          # 4. reveal it
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false

func reload() -> void:
	change_scene(get_tree().current_scene.scene_file_path)

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
