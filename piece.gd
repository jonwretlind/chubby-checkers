extends Node2D
var side: String = "burger"
@onready var sprite: AnimatedSprite2D = $PieceSprite
enum Piece {IS_KING, IS_TAKEN}
enum PieceSide {PLAYER, OPPONENT}
@export var piece_state: Piece
@export var piece_side: PieceSide
const LIFT := 24.0
const HOP_TIME := 0.8

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(side + "_idle") 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hop() -> void:
	var arc := create_tween()
	arc.tween_property(sprite ,"position:y", -LIFT, HOP_TIME/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(sprite ,"position:y", 0.0, HOP_TIME/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sprite.play(side + "_jump")
	await sprite.animation_finished
	sprite.play(side + "_idle")
			
			
