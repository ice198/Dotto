extends ColorRect

@onready var title_label = $TitleLabel
@onready var width_label = $WidthLabel
@onready var width_box = $WidthBox
@onready var height_label = $HeightLabel
@onready var height_box = $HeightBox
@onready var create_button = $CreateButton

# Color
var base_color = Color(0.1, 0.1, 0.1)

# layout
var title_label_position_y = 30
var width_box_position_x = 70
var width_box_position_y = 130
var width_height_items_space = 40
var label_between_box_space = 80
var create_button_x_space = 80
var create_button_y_space = 90


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.color = base_color
	self.position = Vector2(0, 0)
	title_label.size = Vector2(0 , 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_layout()

func _update_layout():
	var window_size = get_viewport().size
	var window_width = window_size.x
	var window_height = window_size.y
	
	self.size = (Vector2(window_width, window_height))
	
	var title_font = title_label.get_theme_font("font")
	var text_size = title_font.get_string_size(title_label.text)
	var title_width = text_size.x
	title_label.position = Vector2(window_width / 2 - title_width / 2, title_label_position_y)
	
	var width_font = width_label.get_theme_font("font")
	var width_text_size = width_font.get_string_size(width_label.text)
	var width_label_width = width_text_size.x
	width_label.position = Vector2(window_width / 2 - width_label_width - width_box_position_x, width_box_position_y)
	height_label.position = Vector2(window_width / 2 - width_label_width - width_box_position_x, width_box_position_y + width_height_items_space)
	
	width_box.position = Vector2(window_width / 2 - width_label_width - width_box_position_x + label_between_box_space, width_box_position_y)
	height_box.position = Vector2(window_width / 2 - width_label_width - width_box_position_x + label_between_box_space, width_box_position_y + width_height_items_space)
	
	create_button.position = Vector2(window_width / 2 - create_button_x_space, window_height - create_button_y_space)
