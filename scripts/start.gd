extends ColorRect

@onready var title_label = $TitleLabel

var title_label_x = 0
var title_label_y = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.size = Vector2(1600, 950)
	self.position = Vector2(0 , 0)
	title_label.size = Vector2(1600 , 950)
	title_label.position = Vector2(0, 50) # yが上からの高さ


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
