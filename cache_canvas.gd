extends TextureRect

var window_size = 0
var global_mouse_x_point = 0
var global_mouse_y_point = 0

# キャンバスの横幅と縦幅(後で開始時に設定できるようにする)
var canvas_width = 1000
var canvas_height = 1000

# キャンバスをズームした縦幅と横幅
var dot_size = 1  # 1ドットのサイズ（ピクセル単位）
var zoom_width = canvas_width * dot_size
var zoom_height = canvas_height * dot_size

# オフセットを設定 (最初はキャンバスが中心に来るようにする)
var offset_x = (1600 - (350 + canvas_width)) / 2
var offset_y = (950 - canvas_height) / 2

# キャンバス上でのマウスカーソルの座標
var mouse_x_point = 0
var mouse_y_point = 0

# マウスの状態
var is_mouse_left_held = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	window_size = get_viewport().size
	global_mouse_x_point = get_global_mouse_position().x
	global_mouse_y_point = get_global_mouse_position().y

func _draw():
	""" 
	# キャンバスを描画
	for x in range(canvas_width):
		for y in range(canvas_height):
			var rect = Rect2(offset_x + x * dot_size, offset_y + y * dot_size, dot_size, dot_size)
			var color = grid[current_layer_index][x][y]  # 現在のレイヤーから色を取得
			draw_rect(rect, color)  # セルを描画

			# グリッドモードがonになっていた場合はグレーのグリッドを描画
			if is_grid_on:
				draw_rect(Rect2(rect.position, rect.size), Color(0.5, 0.5, 0.5), false)
	
	# キャンバスを描画
	for x in range(canvas_width):
		for y in range(canvas_height):
			var rect = Rect2(offset_x + mouse_x_point * dot_size, offset_y + mouse_y_point * dot_size, dot_size, dot_size)
			var color = grid[current_layer_index][x][y]  # 現在のレイヤーから色を取得
			draw_rect(rect, color)  # セルを描画

			# グリッドモードがonになっていた場合はグレーのグリッドを描画
			#if is_grid_on:
				#draw_rect(Rect2(rect.position, rect.size), Color(0.5, 0.5, 0.5), false)

	# クリックされた位置にドットを描画
	var dot_x = int((mouse_x_point - offset_x) / dot_size)
	var dot_y = int((mouse_y_point - offset_y) / dot_size)
	if dot_x >= 0 and dot_x < canvas_width and dot_y >= 0 and dot_y < canvas_height:
		var dot_rect = Rect2(offset_x + dot_x * dot_size, offset_y + dot_y * dot_size, dot_size, dot_size)
		draw_rect(dot_rect, Color(1, 0, 0))  # 例えば赤色のドットを描画
		"""
	#draw_rect(Rect2(500, 500, 100, 500), Color.BLUE, true)
	#var outer_rect = Rect2(0, 0, canvas_width * preview_zoom_X + 5, canvas_height * preview_zoom_X + 5)
	#draw_rect(outer_rect, Color(0, 0, 0))  # 内側の枠（黒）
	
	var outer_rect = Rect2(mouse_x_point, mouse_y_point, 10, 10) #(オフセットx,y,横,縦)
	draw_rect(outer_rect, Color(0, 0, 1))
