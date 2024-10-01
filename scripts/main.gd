extends Control

@onready var inspector_rect = $InspectorRect
@onready var color_picker = $InspectorRect/ColorPicker
@onready var export_dialog = $ExportDialog
@onready var canvas_sprite = $CanvasSprite
@onready var layer_zone = $LayerZone
@onready var preview_frame = $PreviewFrame
@onready var preview_sprite = $PreviewSprite
@onready var guide_line = $GuideLine
@onready var cache_canvas = $CacheCanvas
@onready var start_screen = $StartScreen

# キャンバスの横幅と縦幅(後で開始時に設定できるようにする)
var canvas_width = 1000
var canvas_height = 1000

# キャンバスをズームした縦幅と横幅
var dot_size = 1  # 1ドットのサイズ（ピクセル単位）
var zoom_width = canvas_width * dot_size
var zoom_height = canvas_height * dot_size

# プレビュー画面の拡大率
var preview_zoom_X = 1

# 色の変数
var color_red = 0
var color_green = 0
var color_blue = 0
var color_alpha = 1
var canvas_color = Color(1, 1, 1, 1) # キャンバスの下地の色
var color_on = Color(color_red, color_green, color_blue, color_alpha)
var color_off = Color(1, 1, 1, 1)

# グリッドデータを保持
var grid = []
var cache_grid = []

# オフセットを設定 (最初はキャンバスが中心に来るようにする)
var offset_x = (1600 - (350 + canvas_width)) / 2
var offset_y = (950 - canvas_height) / 2

# キャンバス上でのマウスカーソルの座標
var mouse_x_point = 0
var mouse_y_point = 0

# GUI上でのマウスカーソルの座標
var global_mouse_x_point = 0
var global_mouse_y_point = 0

# ドラッグ用のマウスが掴まれた座標(キャンバス上じゃなくてもいい)
var last_drag_mouse_x = 0
var last_drag_mouse_y = 0

# 最後に取得したマウスカーソルの座標
var last_mouse_x_point = 0
var last_mouse_y_point = 0

# 2点間を線で補完するための開始地点の座標(等倍サイズ)
var one_before_pixel_x = -1
var one_before_pixel_y = -1

# マウスの状態
var is_mouse_left_held = false
var is_mouse_right_held = false
var is_mouse_wheel_held = false
var is_mouse_wheel_move = false
var is_mouse_on_preview = false

# グリッドがonかoffか判定
var is_grid_on = false

# マウスカーソルを設定
var drag_cursor = preload("res://icon/drag.png")

# レイヤーを保持する配列
var current_layer_index = 1 #0は下地
var layers_num = 2

# プレビュー画面のガイド線の座標
var guide_line_x = 0
var guide_line_y = 0

# プレビュー画面の外枠の太さ
var preview_frame_width = 2

# ガイド線の太さ
var guide_line_width = 2

# ウィンドウサイズ
var window_size = 0
#var window_width = window_size.x
#var window_height = window_size.y

# ゾーンの数値
var inspector_zone_width = 350
var layer_zone_width = 200

# 小さすぎるキャンバスを補正
var zoom_correction = 1

# レイヤー関連
var layer_top_space = 60

# 色設定
var accent_color = Color.LIGHT_SKY_BLUE

### 開始時に実行 ###
func _ready() -> void:
	# グリッドの初期化
	for layer in range(layers_num):
		var layer_grid = []  # 新しいレイヤーを初期化
		for x in range(canvas_width):
			layer_grid.append([])  # 新しい行を追加
			for y in range(canvas_height):
				layer_grid[x].append(color_off)  # 色データを追加
		grid.append(layer_grid)  # レイヤーをグリッドに追加
	
	# プレビュー画面の初期の拡大率を計算(縦横ともに200px以下か400px以上だった場合)
	if canvas_width <= 200 and canvas_height <= 300:
		if canvas_width > canvas_height:
			preview_zoom_X = 200.0 / canvas_width
			zoom_correction = preview_zoom_X
		else:
			preview_zoom_X = 200.0 / canvas_height
			zoom_correction = preview_zoom_X
			
	if canvas_width >= 400 and canvas_height >= 400:
		if canvas_width > canvas_height:
			preview_zoom_X = 1.0 / (canvas_width / layer_zone_width)
		else:
			preview_zoom_X = 1.0 / (canvas_width / layer_zone_width)
	
	# レイヤーゾーンを初期化
	layer_zone.size = Vector2(layer_zone_width, 10000) # 縦幅はとても長くした
	layer_zone.position = Vector2(0 , canvas_height * preview_zoom_X + preview_frame_width * 2)
	
	_draw_canvas_sprite(0) # 下地を描画
	_move_canvas_sprite()
	_draw_preview_sprite()
	_move_preview_sprite()
	
	queue_redraw()

### 常に実行 ###
func _process(delta: float) -> void:
	# DEBUG--------------
	var fps = str(Engine.get_frames_per_second())
	#print("", fps)
	#print("",is_mouse_wheel_move)

	_draw_preview_frame()
	#--------------------
	
	_update_color_picker_position()
	_update_layer_position()
	_draw_guide_line()
	
	window_size = get_viewport().size
	global_mouse_x_point = get_global_mouse_position().x
	global_mouse_y_point = get_global_mouse_position().y

	# キャンバス上でのマウスカーソルの座標を取得
	mouse_x_point = global_mouse_x_point - offset_x
	mouse_y_point = global_mouse_y_point - offset_y
	
	# マウスが左クリックされたらドットを描画
	if is_mouse_left_held:
		if not is_mouse_right_held: # ドラッグ中は無効
			if mouse_x_point >= 0 and mouse_x_point < zoom_width and mouse_y_point >= 0 and mouse_y_point < zoom_height:
				# 書き始めた場合
				if one_before_pixel_x < 0:
					var grid_x = int(mouse_x_point / dot_size)
					var grid_y = int(mouse_y_point / dot_size)
						
					# グリッドに色を設定
					grid[current_layer_index][grid_x][grid_y] = color_on
						
					one_before_pixel_x = grid_x
					one_before_pixel_y = grid_y
				else:
					var grid_x = int(mouse_x_point / dot_size)
					var grid_y = int(mouse_y_point / dot_size)
						
					grid[current_layer_index][grid_x][grid_y] = color_on
				
					# 点と点の間を線で補完
					var start_point = Vector2(one_before_pixel_x,one_before_pixel_y)
					var end_point = Vector2(grid_x,grid_y)
					var between_pixels = _get_line_pixels(start_point,end_point) # 2点間を結ぶ線に触れているドットの座標を配列で取得
					for i in range(between_pixels.size()):
						var between_pixel_x = int(between_pixels[i][0])
						var between_pixel_y = int(between_pixels[i][1])
							
						grid[current_layer_index][between_pixel_x][between_pixel_y] = color_on
						
					one_before_pixel_x = grid_x
					one_before_pixel_y = grid_y
	
	# マウスの右クリックでドラッグ
	if is_mouse_right_held:
		# ホールド時の移動量
		var delta_move_x = mouse_x_point - last_drag_mouse_x
		var delta_move_y = mouse_y_point - last_drag_mouse_y
		
		offset_x += delta_move_x
		offset_y += delta_move_y
		
		Input.set_custom_mouse_cursor(drag_cursor) #ドラッグカーソルに設定
		
		_move_canvas_sprite()
	else:
		Input.set_custom_mouse_cursor(null)  # ドラッグカーソルを解除
		_move_canvas_sprite()
	
	# プレビュー画面にマウスがあった場合の処理
	if is_mouse_on_preview:
		_move_preview_sprite()
	
	# マウスカーソルがプレビュー画面上にあるか判定
	if global_mouse_x_point <= canvas_width * preview_zoom_X + preview_frame_width * 2 and global_mouse_y_point <= canvas_height * preview_zoom_X + preview_frame_width * 2:
		is_mouse_on_preview = true
	else:
		is_mouse_on_preview = false
	
	queue_redraw()

### 入力を検知して判定を更新 ###
func _input(event):
	var zoom_increment = 1 # 拡大は整数倍
	
	# マウスからの入力
	if event is InputEventMouseButton:
		# プレビュー画面にマウスがあった場合はプレビューを拡大縮小
		if is_mouse_on_preview: 
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				is_mouse_wheel_move = true
				preview_zoom_X += 0.01 * zoom_correction
				var a = canvas_width * preview_zoom_X
				var b = (canvas_width * preview_zoom_X) + (preview_frame_width * 2)
				var preview_frame_scale_x =  preview_zoom_X * (b / a)
				#print("",a)
				#preview_zone.scale = Vector2(preview_frame_scale_x ,preview_zoom_X)
				#_move_canvas_sprite(current_layer_index)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				is_mouse_wheel_move = false
				#dot_size = max(1, dot_size - increment)  # 下に回した場合は減少（最小1）
				preview_zoom_X -= 0.01 * zoom_correction
				#preview_zone.scale = Vector2(preview_zoom_X,preview_zoom_X)
				#_move_canvas_sprite(current_layer_index)
			
		# マウスホイールを回して拡大縮小
		if not is_mouse_right_held: # ドラッグしているときは拡大縮小とペイントを無効にする
			if not is_mouse_on_preview: # マウスがプレビュー上にあった場合は無効
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					is_mouse_wheel_move = true
					dot_size += zoom_increment
					_update_grid_size()
					_move_canvas_sprite()
				
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					is_mouse_wheel_move = false
					dot_size = max(1, dot_size - zoom_increment)  # 下に回した場合は減少（最小1）
					_update_grid_size()  # グリッドのサイズを更新
					_move_canvas_sprite()
			
		# マウスホイールが押された場合の処理（後で追加）
		if Input.is_action_pressed("MOUSE_BUTTON_WHEEL"):
			is_mouse_wheel_held = true
			_add_layer()
		elif Input.is_action_just_released("MOUSE_BUTTON_WHEEL"):
			is_mouse_wheel_held = false
		
		# マウスの左クリックがホールドされているか判定
		if event.is_action_pressed("MOUSE_L"):
			is_mouse_left_held = true
			one_before_pixel_x = -1 # 初めて書くと設定
			one_before_pixel_y = -1
			_draw_canvas_sprite(0)
		elif event.is_action_released("MOUSE_L"):
			is_mouse_left_held = false
			one_before_pixel_x = -1 # マウスを話したと設定
			one_before_pixel_y = -1
		
		# マウスの右クリックがホールドされているか判定
		if event.is_action_pressed("MOUSE_R"):
			is_mouse_right_held = true
			last_drag_mouse_x = get_global_mouse_position().x - offset_x # delta_move_x,yが最初から0になるようにする
			last_drag_mouse_y = get_global_mouse_position().y - offset_y
			
		elif event.is_action_released("MOUSE_R"):
			is_mouse_right_held = false
			
		# 左クリックが離された瞬間に描画を更新
		const BUTTON_RIGHT = 1
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_RIGHT and not event.pressed:
				_draw_canvas_sprite(current_layer_index)
				_draw_preview_sprite()
			
	# キーボードからの入力
	if event is InputEventKey:
		# オフセットを変更してキャンバスを移動
		var move_speed = 30 # 感度
		if Input.is_action_pressed("KEY_LEFT"):
			offset_x += move_speed
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_RIGHT"):
			offset_x -= move_speed
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_UP"):
			offset_y += move_speed
			_move_canvas_sprite()
		if Input.is_action_pressed("KEY_DOWN"):
			offset_y -= move_speed
			_move_canvas_sprite()

# グリッドのサイズを更新
func _update_grid_size():
	zoom_width = canvas_width * dot_size
	zoom_height = canvas_height * dot_size

# PNGとして保存
func _save_as_png(path: String):
	var img = Image.new()
	img = img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			img.set_pixel(x, y, grid[1][x][y])
			
	img.save_png(path)

# ウィンドウのサイズに合わせてカラーピッカーの位置を変更
func _update_color_picker_position():
	# ウィンドウサイズを取得
	var window_size = get_viewport().size
	var window_width = window_size.x
	var window_height = window_size.y
	
	inspector_rect.position = Vector2(window_width - inspector_zone_width, 0)

# 2点間を結ぶ線を計算
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
		cells.append(Vector2(x1, y1))  # 現在のマス目を追加
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

# キャンバスを描画
func _draw_canvas_sprite(current_layer_index):
	var canvas_img = Image.new()
	canvas_img = canvas_img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			canvas_img.set_pixel(x, y, grid[1][x][y])
	
	var canvas_image_texture = ImageTexture.create_from_image(canvas_img)
	canvas_sprite.texture = canvas_image_texture

# キャンバスを移動
func _move_canvas_sprite():
	canvas_sprite.scale = (Vector2(dot_size, dot_size))
	canvas_sprite.position.x = offset_x + (canvas_width / 2) * dot_size
	canvas_sprite.position.y = offset_y + (canvas_height / 2) * dot_size

# プレビューを描画
func _draw_preview_sprite():
	var preview_img = Image.new()
	preview_img = preview_img.create(canvas_width, canvas_height, false, Image.FORMAT_RGBA8)
	
	for x in range(canvas_width):
		for y in range(canvas_height):
			preview_img.set_pixel(x, y, grid[current_layer_index][x][y])
	
	var preview_image_texture = ImageTexture.create_from_image(preview_img)
	preview_sprite.texture = preview_image_texture

# プレビューを移動
func _move_preview_sprite():
	preview_sprite.scale = (Vector2(preview_zoom_X, preview_zoom_X))
	preview_sprite.position.x = (canvas_width / 2) * preview_zoom_X + preview_frame_width
	preview_sprite.position.y = (canvas_height / 2) * preview_zoom_X + preview_frame_width

# プレビューの外枠を表示
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
		Vector2(top_left_x, top_left_y),  # 左上
		Vector2(top_right_x, top_right_y), # 右上
		Vector2(bottom_right_x, bottom_right_y),# 右下
		Vector2(bottom_left_x, bottom_left_y), # 左下
		Vector2(top_left_x, top_left_y - preview_frame_width / 2)   # 左上に戻る なぜかy座標は幅の半分の値を引く
	]
	
	preview_frame.points = points
	preview_frame.width = preview_frame_width
	
	var preview_frame_color = Color(0.3, 0.3, 0.3)
	
	if is_mouse_on_preview:
		preview_frame_color = accent_color
		
	preview_frame.default_color = preview_frame_color

# プレビューのガイド線を表示
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
	
	if offset_x >= layer_zone_width and offset_y + canvas_height * dot_size <= window_height and offset_x + canvas_width * dot_size <= window_width - inspector_zone_width and offset_y > 0:
		guide_line.default_color = Color(0, 1, 0 ,0) # 全体が表示されていた場合は透明にする
	
	var points = [
		Vector2(top_left_x, top_left_y),  # 左上
		Vector2(top_right_x, top_right_y), # 右上
		Vector2(bottom_right_x, bottom_right_y),# 右下
		Vector2(bottom_left_x, bottom_left_y), # 左下
		Vector2(top_left_x, top_left_y - guide_line_width / 2 ) # 左上に戻る なぜかy座標は幅の半分の値を引く
	]
	
	guide_line.points = points
	guide_line.width = guide_line_width

# レイヤーの位置を更新
func _update_layer_position():
	layer_zone.position = Vector2(0, canvas_height * preview_zoom_X + preview_frame_width * 2)

# レイヤーを作成する関数
func _add_layer():
	layers_num += 1

	# グリッドの初期化
	#for layer in range(layers_num):
	var layer_grid = []  # 新しいレイヤーを初期化
	for x in range(canvas_width):
		layer_grid.append([])  # 新しい行を追加
		for y in range(canvas_height):
			layer_grid[x].append(color_off)  # 色データを追加
	grid.append(layer_grid)  # レイヤーをグリッドに追加

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

# レイヤーを切り替える関数
func _switch_layer():
	#if index >= 0 and index < layers.size():
	current_layer_index = current_layer_index + 1#index

# レイヤーが追加されたときにレイヤー画面を更新
func _update_layer_zone():
	pass

# カラーピッカーから色を取得
func _on_color_picker_color_changed(color: Color) -> void:
	color_red = color.r
	color_green = color.g
	color_blue = color.b
	color_alpha = color.a
	color_on = Color(color_red, color_green ,color_blue ,color_alpha)

# エクスポートボタンが押された場合
func _on_export_button_pressed() -> void:	
	export_dialog.show()

# エクスポートダイアログからパスを取得
func _on_file_dialog_file_selected(path: String) -> void:
	path = path + ".png"
	_save_as_png(path)

# グリッドモードのonとoffを切り替える
func _on_grid_button_pressed() -> void:
	if is_grid_on:
		is_grid_on = false
	else:
		is_grid_on = true

# 作成ボタンが押された場合
func _on_create_button_pressed() -> void:
	start_screen.hide()

func _on_width_box_value_changed(value: float) -> void:
	canvas_width = value

func _on_height_box_value_changed(value: float) -> void:
	canvas_height = value
