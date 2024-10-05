extends TextureRect

var window_size = 0
var global_mouse_x_point = 0
var global_mouse_y_point = 0

var canvas_width = 1000
var canvas_height = 1000

var dot_size = 1
var zoom_width = canvas_width * dot_size
var zoom_height = canvas_height * dot_size

var offset_x = (1600 - (350 + canvas_width)) / 2
var offset_y = (950 - canvas_height) / 2

var mouse_x_point = 0
var mouse_y_point = 0

var is_mouse_left_held = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_size = get_viewport().size
	global_mouse_x_point = get_global_mouse_position().x
	global_mouse_y_point = get_global_mouse_position().y

func _draw():
	pass
