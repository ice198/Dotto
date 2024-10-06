extends Control

@onready var inspector_zone = $InspectorZone
@onready var color_picker = $InspectorZone/ColorPicker
@onready var export_dialog = $ExportDialog
@onready var canvas_sprite = $CanvasSprite
@onready var layer_zone = $LayerZone
@onready var preview_frame = $PreviewFrame
@onready var preview_sprite = $PreviewSprite
@onready var guide_line = $GuideLine
@onready var cache_canvas = $CacheCanvas
@onready var start_screen = $StartScreen
@onready var pencil_tool = $InspectorZone/PencilTool
@onready var line_tool = $InspectorZone/LineTool
@onready var color_palette = $InspectorZone/ColorPalette
@onready var color_palette_tool = $InspectorZone/ColorPaletteTool
@onready var color_focus_line = $InspectorZone/ColorPalette/ColorFocusLine

# Layout
var canvas_width = 1000
var canvas_height = 1000
var offset_x = 0
var offset_y = 0
var preview_frame_width = 2
var guide_line_width = 2
var tool_panel_width = 40
var inspector_zone_width = 350
var inspector_zone_height = 550
var layer_zone_width = 200
var layer_top_space = 60
var color_piece_scale = 22
var color_piece_space = 4
var color_focus_frame_width = 2
var color_palette_outer_space = 8

# Canvas
var dot_size = 1
var zoom_width = canvas_width * dot_size
var zoom_height = canvas_height * dot_size

# Preview
var preview_zoom_X = 1
var preview_zoom_sensitivity = 2
var zoom_correction = 1
var guide_line_x = 0
var guide_line_y = 0

# Color
var color_red = 0
var color_green = 0
var color_blue = 0
var color_alpha = 1
var canvas_color = Color(1, 1, 1, 1)
var color_on = Color(color_red, color_green, color_blue, color_alpha)
var color_off = Color(1, 1, 1, 1)
var base_color = Color(0.1, 0.1, 0.1)
var focus_color = Color(0.2, 0.2, 0.2)
var accent_color = Color(0, 0, 1)

# Grid data
var grid = []
var cache_grid = []

# Mouse data
var drag_cursor = preload("res://icon/drag.png")
var canvas_mouse_x = 0
var canvas_mouse_y = 0
var global_mouse_x_point = 0
var global_mouse_y_point = 0
var last_drag_mouse_x = 0
var last_drag_mouse_y = 0
var last_mouse_x_point = 0
var last_mouse_y_point = 0

# Coordinates of the starting point for interpolating a line between two points (same size)
var one_before_pixel_x = -1
var one_before_pixel_y = -1

# State
var is_mouse_left_held = false
var is_mouse_right_held = false
var is_mouse_wheel_held = false
var is_mouse_wheel_move = false
var is_mouse_on_preview = false
var is_space_key_pressed = false
var is_mode_draw = false
var is_pencil_mode = false
var is_line_mode = false
var is_grid_on = false
var on_main_screen = false
var on_tool_panel = false
var on_color_palette = false

# Layer
var current_layer_index = 1 # 0 is base 
var layers_num = 2

# window data
var window_size = 0

func _on_create_button_pressed() -> void:
	start_screen.hide()
	on_main_screen = true
	
	# Calculate defolt preview scale
	preview_zoom_X = (layer_zone_width - guide_line_width * 2) / canvas_width
	zoom_correction = preview_zoom_X * preview_zoom_sensitivity
	
	_draw_canvas_sprite(0)
	_move_canvas_sprite()
	_draw_preview_sprite()
	_move_preview_sprite()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize grid
	for layer in range(layers_num):
		var layer_grid = []
		for x in range(canvas_width):
			layer_grid.append([])
			for y in range(canvas_height):
				layer_grid[x].append(color_off)
		grid.append(layer_grid)
	
	inspector_zone.color = focus_color
	
	layer_zone.size = Vector2(layer_zone_width, 10000)
	layer_zone.position = Vector2(0 , canvas_height * preview_zoom_X + preview_frame_width * 2)
	layer_zone.color = base_color 
	
	pencil_tool.size = Vector2(tool_panel_width, tool_panel_width)
	pencil_tool.position = Vector2(-tool_panel_width, 0)
	pencil_tool.color = focus_color
	
	line_tool.size = Vector2(tool_panel_width, tool_panel_width)
	line_tool.position = Vector2(-tool_panel_width, tool_panel_width)
	line_tool.color = base_color
	
	color_palette_tool.size = Vector2(tool_panel_width, tool_panel_width)
	color_palette_tool.position = Vector2(-tool_panel_width, inspector_zone_height)
	color_palette_tool.color = base_color
	
	color_palette.size = Vector2(inspector_zone_width, 1000)
	color_palette.position = Vector2(0, inspector_zone_height)
	color_palette.color = base_color
	
	for i in range(22):
		var color = get_node("InspectorZone/ColorPalette/Color" + str(i))
		color.size = Vector2(color_piece_scale, color_piece_scale)
		color.position = Vector2(color_palette_outer_space + (color_piece_scale + color_piece_space) * (i % 13), color_palette_outer_space + (color_piece_scale + color_piece_space) * (i / 13))
		color.color = Color.WHITE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# DEBUG--------------
	var fps = str(Engine.get_frames_per_second())
	#print("", fps)
	#print("",on_color_palette)
	#--------------------
	window_size = get_viewport().size
	
	global_mouse_x_point = get_global_mouse_position().x
	global_mouse_y_point = get_global_mouse_position().y
	
	canvas_mouse_x = global_mouse_x_point - offset_x
	canvas_mouse_y = global_mouse_y_point - offset_y
	
	# When mouse is left clicked
	if is_mouse_left_held:
		if is_mode_draw:
			if not is_mouse_right_held:
				if canvas_mouse_x >= 0 and canvas_mouse_x < zoom_width and canvas_mouse_y >= 0 and canvas_mouse_y < zoom_height:
					# When writing for the first time
					if one_before_pixel_x < 0:
						var grid_x = int(canvas_mouse_x / dot_size)
						var grid_y = int(canvas_mouse_y / dot_size)
						
						grid[current_layer_index][grid_x][grid_y] = color_on
						
						one_before_pixel_x = grid_x
						one_before_pixel_y = grid_y
					else:
						var grid_x = int(canvas_mouse_x / dot_size)
						var grid_y = int(canvas_mouse_y / dot_size)
						
						grid[current_layer_index][grid_x][grid_y] = color_on
				
						# Fill in lines between points
						var start_point = Vector2(one_before_pixel_x,one_before_pixel_y)
						var end_point = Vector2(grid_x,grid_y)
						var between_pixels = _get_line_pixels(start_point,end_point)
						for i in range(between_pixels.size()):
							var between_pixel_x = int(between_pixels[i][0])
							var between_pixel_y = int(between_pixels[i][1])
							
							grid[current_layer_index][between_pixel_x][between_pixel_y] = color_on
						
						one_before_pixel_x = grid_x
						one_before_pixel_y = grid_y
		
		if on_color_palette:
			var color_palette_mouse_x = global_mouse_x_point - (window_size.x - inspector_zone_width) - 6
			var color_palette_mouse_y = global_mouse_y_point - inspector_zone_height - 6
			var x_th_color_piece = int(color_palette_mouse_x / (color_piece_scale + color_piece_space)) + 1
			var y_th_color_piece = int(color_palette_mouse_y / (color_piece_scale + color_piece_space)) + 1
			
			_draw_color_palette_focus_frame(x_th_color_piece, y_th_color_piece)
	
	# Drag when mouse is right clicked
	if is_mouse_right_held:
		var delta_move_x = canvas_mouse_x - last_drag_mouse_x
		var delta_move_y = canvas_mouse_y - last_drag_mouse_y
		
		offset_x += delta_move_x
		offset_y += delta_move_y
		
		Input.set_custom_mouse_cursor(drag_cursor)
		_move_canvas_sprite()
	else:
		Input.set_custom_mouse_cursor(null)
		_move_canvas_sprite()
	
	if is_mouse_on_preview:
		_move_preview_sprite()
	
	# Determine whether the mouse cursor is on the preview screen
	if global_mouse_x_point <= canvas_width * preview_zoom_X + preview_frame_width * 2 and global_mouse_y_point <= canvas_height * preview_zoom_X + preview_frame_width * 2:
		is_mouse_on_preview = true
	else:
		is_mouse_on_preview = false
	
	# Determine whether the mouse cursor is on the canvas
	if on_main_screen and layer_zone_width < global_mouse_x_point and global_mouse_x_point < window_size.x - (inspector_zone_width + tool_panel_width):
		is_mode_draw = true
	else:
		is_mode_draw = false
	
	# Determine whether the mouse cursor is on the preview screen
	if window_size.x - (inspector_zone_width + tool_panel_width) < global_mouse_x_point and global_mouse_x_point < window_size.x - inspector_zone_width:
		on_tool_panel = true
	else:
		on_tool_panel = false
	
	# Determine whether the mouse cursor is on the color palette
	if window_size.x - inspector_zone_width < global_mouse_x_point and global_mouse_x_point < window_size.x - 6 and inspector_zone_height < global_mouse_y_point:
		on_color_palette = true
	else:
		on_color_palette = false
	
	_update_inspector_position()
	_update_layer_position()
	_draw_guide_line()
	_draw_preview_frame()

func _input(event):
	var zoom_increment = 1
	var canvas_move_speed_sensitivity = 30
	
	if event is InputEventMouseButton:
		# Change preview scale
		if is_mouse_on_preview:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				is_mouse_wheel_move = true
				preview_zoom_X += 0.01 * zoom_correction
				var a = canvas_width * preview_zoom_X
				var b = (canvas_width * preview_zoom_X) + (preview_frame_width * 2)
				var preview_frame_scale_x =  preview_zoom_X * (b / a)
				
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				is_mouse_wheel_move = true
				dot_size = max(1, dot_size - zoom_increment)
				preview_zoom_X -= 0.01 * zoom_correction
			
		# Change canvas scale
		if is_mode_draw and not is_mouse_right_held:
			if not is_mouse_on_preview:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					is_mouse_wheel_move = true
					
					offset_x -= int(canvas_mouse_x) / dot_size - 1
					offset_y -= canvas_mouse_y / dot_size - 1
					
					dot_size += zoom_increment
					
					_update_grid_size()
					_move_canvas_sprite()
				
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					is_mouse_wheel_move = true
					
					offset_x += int(canvas_mouse_x) / dot_size
					offset_y += canvas_mouse_y / dot_size
					
					dot_size = max(1, dot_size - zoom_increment)
					
					_update_grid_size()
					_move_canvas_sprite()
			
		# When the mouse wheel is scrolled
		if Input.is_action_pressed("MOUSE_BUTTON_WHEEL"):
			is_mouse_wheel_held = true
		elif Input.is_action_just_released("MOUSE_BUTTON_WHEEL"):
			is_mouse_wheel_held = false
		
		# When mouse is left clicked
		if event.is_action_pressed("MOUSE_L"):
			is_mouse_left_held = true
			one_before_pixel_x = -1
			one_before_pixel_y = -1
			_draw_canvas_sprite(0)
			
			if on_tool_panel:
				if global_mouse_y_point < tool_panel_width:
					pencil_tool.color = focus_color
					line_tool.color = base_color
					is_pencil_mode = true
					is_line_mode = false
				elif tool_panel_width < global_mouse_y_point and global_mouse_y_point < tool_panel_width * 2:
					pencil_tool.color = base_color
					line_tool.color = focus_color
					is_pencil_mode = false
					is_line_mode = true

		elif event.is_action_released("MOUSE_L"):
			is_mouse_left_held = false
			one_before_pixel_x = -1
			one_before_pixel_y = -1
		
		# When mouse is right clicked
		if event.is_action_pressed("MOUSE_R"):
			is_mouse_right_held = true
			last_drag_mouse_x = get_global_mouse_position().x - offset_x
			last_drag_mouse_y = get_global_mouse_position().y - offset_y
		elif event.is_action_released("MOUSE_R"):
			is_mouse_right_held = false
			
		# Update drawing when left click is released
		const BUTTON_RIGHT = 1
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_RIGHT and not event.pressed:
				_draw_canvas_sprite(current_layer_index)
				_draw_preview_sprite()
	
	if event is InputEventKey:
		if Input.is_action_pressed("KEY_LEFT"):
			offset_x += canvas_move_speed_sensitivity
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_RIGHT"):
			offset_x -= canvas_move_speed_sensitivity
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_UP"):
			offset_y += canvas_move_speed_sensitivity
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_DOWN"):
			offset_y -= canvas_move_speed_sensitivity
			_move_canvas_sprite()
		
		if Input.is_action_pressed("SPACE_KEY"):
			is_space_key_pressed = true
		else:
			is_space_key_pressed = false

func _update_grid_size():
	zoom_width = canvas_width * dot_size
	zoom_height = canvas_height * dot_size

func _update_inspector_position():
	inspector_zone.position = Vector2(window_size.x - inspector_zone_width, 0)

func _update_layer_position():
	layer_zone.position = Vector2(0, canvas_height * preview_zoom_X + preview_frame_width * 2)

func _save_as_png(path: String):
	var img = Image.new()
	img = img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			img.set_pixel(x, y, grid[1][x][y])
			
	img.save_png(path)

# Calculate the coordinates of the dots touching the line connecting two points in an array
func _get_line_pixels(start: Vector2, end: Vector2) -> Array:
	var cells = []
	var x1 = int(start.x)
	var y1 = int(start.y)
	var x2 = int(end.x)
	var y2 = int(end.y)
	var dx = abs(x2 - x1)
	var dy = abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx - dy
	
	while true:
		cells.append(Vector2(x1, y1))
		if x1 == x2 and y1 == y2:
			break
		var err2 = err * 2
		if err2 > -dy:
			err -= dy
			x1 += sx
		if err2 < dx:
			err += dx
			y1 += sy
	return cells

func _draw_canvas_sprite(current_layer_index):
	var canvas_img = Image.new()
	canvas_img = canvas_img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			canvas_img.set_pixel(x, y, grid[1][x][y])
	
	var canvas_image_texture = ImageTexture.create_from_image(canvas_img)
	canvas_sprite.texture = canvas_image_texture

func _move_canvas_sprite():
	canvas_sprite.scale = (Vector2(dot_size, dot_size))
	canvas_sprite.position.x = offset_x + (canvas_width / 2) * dot_size
	canvas_sprite.position.y = offset_y + (canvas_height / 2) * dot_size

func _draw_preview_sprite():
	var preview_img = Image.new()
	preview_img = preview_img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			preview_img.set_pixel(x, y, grid[current_layer_index][x][y])
	
	var preview_image_texture = ImageTexture.create_from_image(preview_img)
	preview_sprite.texture = preview_image_texture

func _move_preview_sprite():
	preview_sprite.scale = (Vector2(preview_zoom_X, preview_zoom_X))
	preview_sprite.position.x = (canvas_width / 2) * preview_zoom_X + preview_frame_width
	preview_sprite.position.y = (canvas_height / 2) * preview_zoom_X + preview_frame_width

func _draw_preview_frame():
	var top_left_x = preview_frame_width / 2
	var top_left_y = preview_frame_width / 2
	var top_right_x = canvas_width * preview_zoom_X + preview_frame_width * 1.5
	var top_right_y = preview_frame_width / 2
	var bottom_right_x = canvas_width * preview_zoom_X + preview_frame_width * 1.5
	var bottom_right_y = canvas_height * preview_zoom_X + preview_frame_width * 1.5
	var bottom_left_x = preview_frame_width / 2
	var bottom_left_y = canvas_height * preview_zoom_X + preview_frame_width * 1.5
	
	var points = [
		Vector2(top_left_x, top_left_y),
		Vector2(top_right_x, top_right_y),
		Vector2(bottom_right_x, bottom_right_y),
		Vector2(bottom_left_x, bottom_left_y),
		Vector2(top_left_x, top_left_y - preview_frame_width / 2)
	]
	
	preview_frame.points = points
	preview_frame.width = preview_frame_width
	
	var preview_frame_color = Color(0.3, 0.3, 0.3)
	
	if is_mouse_on_preview:
		preview_frame_color = accent_color
		
	preview_frame.default_color = preview_frame_color

func _draw_guide_line():
	var top_left_x = guide_line_width / 2
	var top_left_y = guide_line_width / 2
	var top_right_x = canvas_width * preview_zoom_X + guide_line_width * 1.5
	var top_right_y = guide_line_width / 2
	var bottom_right_x = canvas_width * preview_zoom_X + guide_line_width * 1.5
	var bottom_right_y = canvas_height * preview_zoom_X + guide_line_width * 1.5
	var bottom_left_x = guide_line_width / 2
	var bottom_left_y = canvas_height * preview_zoom_X + guide_line_width * 1.5
	var window_size = get_viewport().size
	var window_width = window_size.x
	var window_height = window_size.y
	var guide_line_color = Color(0.5, 0.5, 0.5 ,1)
	
	if offset_x < layer_zone_width:
		top_left_x = ( - (offset_x - layer_zone_width) / dot_size) * preview_zoom_X
		bottom_left_x = ( - (offset_x - layer_zone_width) / dot_size) * preview_zoom_X
		guide_line.default_color = guide_line_color
	
	if offset_x + canvas_width * dot_size > window_width - inspector_zone_width:
		top_right_x = (canvas_width - (((offset_x + canvas_width * dot_size) - (window_width - inspector_zone_width)) / dot_size)) * preview_zoom_X
		bottom_right_x = (canvas_width - (((offset_x + canvas_width * dot_size) - (window_width - inspector_zone_width)) / dot_size)) * preview_zoom_X
		guide_line.default_color = guide_line_color
	
	if offset_y < 0:
		top_left_y = ( - offset_y / dot_size ) * preview_zoom_X
		top_right_y = ( - offset_y / dot_size ) * preview_zoom_X
		guide_line.default_color = guide_line_color
	
	if offset_y + canvas_height * dot_size > window_height:
		bottom_left_y = (canvas_height - ((offset_y + canvas_height * dot_size) - window_height) / dot_size) * preview_zoom_X
		bottom_right_y = (canvas_height - ((offset_y + canvas_height * dot_size) - window_height) / dot_size) * preview_zoom_X
		guide_line.default_color = guide_line_color
	
	# Make it transparent if the whole thing is visible
	if offset_x >= layer_zone_width and offset_y + canvas_height * dot_size <= window_height and offset_x + canvas_width * dot_size <= window_width - inspector_zone_width and offset_y > 0:
		guide_line.default_color = Color(0, 1, 0 ,0)
	
	var points = [
		Vector2(top_left_x, top_left_y),
		Vector2(top_right_x, top_right_y),
		Vector2(bottom_right_x, bottom_right_y),
		Vector2(bottom_left_x, bottom_left_y),
		Vector2(top_left_x, top_left_y - guide_line_width / 2 )
	]
	
	guide_line.points = points
	guide_line.width = guide_line_width

# Unfinished
func _draw_color_palette_focus_frame(x_th_color_piece, y_th_color_piece):
	var top_left_x = 0#window_size.x - inspector_zone_width + 6 + (color_piece_scale + color_focus_frame_width) * (x_th_color_piece - 1)#guide_line_width / 2
	var top_left_y = guide_line_width / 2
	var top_right_x = canvas_width * preview_zoom_X + guide_line_width * 1.5
	var top_right_y = guide_line_width / 2
	var bottom_right_x = canvas_width * preview_zoom_X + guide_line_width * 1.5
	var bottom_right_y = canvas_height * preview_zoom_X + guide_line_width * 1.5
	var bottom_left_x = guide_line_width / 2
	var bottom_left_y = canvas_height * preview_zoom_X + guide_line_width * 1.5
	var window_size = get_viewport().size
	var window_width = window_size.x
	var window_height = window_size.y
	var guide_line_color = Color.RED
	
	var points = [
		Vector2(top_left_x, top_left_y),
		Vector2(top_right_x, top_right_y),
		Vector2(bottom_right_x, bottom_right_y),
		Vector2(bottom_left_x, bottom_left_y),
		Vector2(top_left_x, top_left_y - color_focus_frame_width / 2 )
	]
	
	color_focus_line.points = points
	color_focus_line.width = color_focus_frame_width

func _add_layer():
	layers_num += 1
	#for layer in range(layers_num):
	var layer_grid = []
	for x in range(canvas_width):
		layer_grid.append([])
		for y in range(canvas_height):
			layer_grid[x].append(color_off)
	grid.append(layer_grid)

	var layer_splite = Sprite2D.new()
	var layer_img = Image.new()
	var layer_preview_scale = 1
	if canvas_width > 90 or canvas_height > 90:
		if canvas_width > canvas_height:
			layer_preview_scale = 90.0 / canvas_height
		else:
			layer_preview_scale = 90.0 / canvas_width
			
	layer_img = layer_img.create(canvas_width * layer_preview_scale, canvas_height * layer_preview_scale, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			layer_img.set_pixel(x, y, grid[layers_num - 1][x][y])
	
	var layer_image_texture = ImageTexture.create_from_image(layer_img)
	layer_splite.texture = layer_image_texture
	layer_splite.position.x = (canvas_width * layer_preview_scale) / 2
	layer_splite.position.y = (canvas_height * layer_preview_scale) / 2 + layer_top_space
	
	layer_zone.add_child(layer_splite)

func _switch_layer():
	#if index >= 0 and index < layers.size():
	current_layer_index = current_layer_index + 1#index

func _update_layer_zone():
	pass

func _on_color_picker_color_changed(color: Color) -> void:
	color_red = color.r
	color_green = color.g
	color_blue = color.b
	color_alpha = color.a
	color_on = Color(color_red, color_green ,color_blue ,color_alpha)

func _on_export_button_pressed() -> void:	
	export_dialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
	path = path + ".png"
	_save_as_png(path)

func _on_grid_button_pressed() -> void:
	if is_grid_on:
		is_grid_on = false
	else:
		is_grid_on = true

func _on_width_box_value_changed(value: float) -> void:
	canvas_width = value

func _on_height_box_value_changed(value: float) -> void:
	canvas_height = value
