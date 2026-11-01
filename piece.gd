extends Node2D
var side: String = "burger"
@onready var sprite: AnimatedSprite2D = $PieceSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.play(side + "_idle") 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


			
			
