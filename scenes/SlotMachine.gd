extends Node2D

const SlotTile := preload("res://scenes/SlotTile.tscn")
const Player := preload("res://scenes/Player.tscn")
const ActionEffect := preload("res://scenes/ActionEffect.tscn")

var player:Node2D
var actionEffect:Node2D
# 儲存 SlotTile 的 SPIN_UP 動畫移動距離
const SPIN_UP_DISTANCE = 100.0
signal stopped

# 材質陣列
@export var pictures :Array[Texture2D] = [
	# 黑桃 (0-11)
	preload("res://sprites/CardIcons/ace_of_spades2.png"),
	preload("res://sprites/CardIcons/2_of_spades.png"),
	preload("res://sprites/CardIcons/3_of_spades.png"),
	preload("res://sprites/CardIcons/4_of_spades.png"),
	preload("res://sprites/CardIcons/5_of_spades.png"),
	preload("res://sprites/CardIcons/6_of_spades.png"),
	preload("res://sprites/CardIcons/7_of_spades.png"),
	preload("res://sprites/CardIcons/8_of_spades.png"),
	preload("res://sprites/CardIcons/9_of_spades.png"),
	preload("res://sprites/CardIcons/10_of_spades.png"),
	preload("res://sprites/CardIcons/queen_of_spades.png"),
	preload("res://sprites/CardIcons/king_of_spades.png"),
	# 紅心 (12-23)
	preload("res://sprites/CardIcons/ace_of_hearts.png"),
	preload("res://sprites/CardIcons/2_of_hearts.png"),
	preload("res://sprites/CardIcons/3_of_hearts.png"),
	preload("res://sprites/CardIcons/4_of_hearts.png"),
	preload("res://sprites/CardIcons/5_of_hearts.png"),
	preload("res://sprites/CardIcons/6_of_hearts.png"),
	preload("res://sprites/CardIcons/7_of_hearts.png"),
	preload("res://sprites/CardIcons/8_of_hearts.png"),
	preload("res://sprites/CardIcons/9_of_hearts.png"),
	preload("res://sprites/CardIcons/10_of_hearts.png"),
	preload("res://sprites/CardIcons/queen_of_hearts.png"),
	preload("res://sprites/CardIcons/king_of_hearts.png"),
	# 方塊 (24-35)
	preload("res://sprites/CardIcons/ace_of_diamonds.png"),
	preload("res://sprites/CardIcons/2_of_diamonds.png"),
	preload("res://sprites/CardIcons/3_of_diamonds.png"),
	preload("res://sprites/CardIcons/4_of_diamonds.png"),
	preload("res://sprites/CardIcons/5_of_diamonds.png"),
	preload("res://sprites/CardIcons/6_of_diamonds.png"),
	preload("res://sprites/CardIcons/7_of_diamonds.png"),
	preload("res://sprites/CardIcons/8_of_diamonds.png"),
	preload("res://sprites/CardIcons/9_of_diamonds.png"),
	preload("res://sprites/CardIcons/10_of_diamonds.png"),
	preload("res://sprites/CardIcons/queen_of_diamonds.png"),
	preload("res://sprites/CardIcons/king_of_diamonds.png"),
	# 梅花 (36-47)
	preload("res://sprites/CardIcons/ace_of_clubs.png"),
	preload("res://sprites/CardIcons/2_of_clubs.png"),
	preload("res://sprites/CardIcons/3_of_clubs.png"),
	preload("res://sprites/CardIcons/4_of_clubs.png"),
	preload("res://sprites/CardIcons/5_of_clubs.png"),
	preload("res://sprites/CardIcons/6_of_clubs.png"),
	preload("res://sprites/CardIcons/7_of_clubs.png"),
	preload("res://sprites/CardIcons/8_of_clubs.png"),
	preload("res://sprites/CardIcons/9_of_clubs.png"),
	preload("res://sprites/CardIcons/10_of_clubs.png"),
	preload("res://sprites/CardIcons/queen_of_clubs.png"),
	preload("res://sprites/CardIcons/king_of_clubs.png"),
]

# 定義有幾個轉軸
@export_range(1,20) var reels :int = 5
# 定義轉軸有幾個瓦片數字
@export_range(1,20) var tiles_per_reel :int = 4
# 定義轉軸旋轉的持續時間
@export_range(0,10) var runtime :float = 2.0
# 定義轉軸旋轉的速度
@export_range(0.1,10) var speed :float = 5.0
# 定義每個轉軸之間的啟動延遲時間
@export_range(0,2) var reel_delay :float = 0.3

# 依照視窗大小調整瓦片尺寸
@onready var size := get_viewport_rect().size
@onready var tile_size := size / Vector2(reels, tiles_per_reel)
# 將速度正規化，使其不受瓦片數量影響而保持一致
@onready var speed_norm := speed * tiles_per_reel
# 在每個捲軸中增加瓦片在鏡頭外增加動畫流暢度
# Grid 增加兩個瓦片在前後的 TODO 當前也會因為增加的瓦片在停止時未依照預期結果
@onready var extra_tiles := 0#int(ceil(SPIN_UP_DISTANCE / tile_size.y)*2)

# 儲存實際的瓦片列數
@onready var rows := tiles_per_reel + extra_tiles

enum State {OFF, ON, STOPPED}
var state = State.OFF
var result := {}

# 儲存 SlotTile 實例
var tiles := []
# 儲存每個格子左上角的位置
var grid_pos := []

# 1/speed*runtime*reels 次
# 儲存每個轉軸期望的移動次數
@onready var expected_runs :int = int(runtime * speed_norm)
# 儲存每個轉軸目前已移動的次數
var tiles_moved_per_reel := []
# 當被強制停止時，儲存目前的移動次數
var runs_stopped := 0
# 儲存與實際執行方式無關的總移動次數
var total_runs : int

# 聲音
@onready var spin_sound = $"../../../SpinSound"
@onready var stop_sound = $"../../../StopSound"
@onready var bgm_sound = $"../../../BGMSound"
@onready var big_win_sound = $"../../../BigWinSound"
@onready var big_win_coin_sound = $"../../../BigWinCoinSound"
@onready var Jackpot_sound = $"../../../JackpotSound"
@onready var MegaWin_Sound = $"../../../MegaWinSound"

# 得獎大圖
@onready var big_win_coin_img = $"../../../big_win_coin"
@onready var coin_treasure_img = $"../../../coin_treasure"

# 動畫
@onready var bigWin_Ani = $"../../../turmp_point"

	
func _on_anim_finished():
	big_win_coin_img.visible = false
	coin_treasure_img.visible = false
	bigWin_Ani.visible = false
	bigWin_Ani.pause()
	big_win_sound.stop()
	big_win_coin_sound.stop()
	
func bigWin_Ani_ini():
	big_win_coin_img.visible = false
	coin_treasure_img.visible = false
	bigWin_Ani.visible = false
	bigWin_Ani.animation_finished.connect(_on_anim_finished)
	
func play_once_bigWin_Ani():
	big_win_coin_img.pop_big()
	big_win_coin_img.visible = true
	coin_treasure_img.visible = true
	bigWin_Ani.visible = true
	bigWin_Ani.frame = 0
	bigWin_Ani.play()
	big_win_sound.play()
	big_win_coin_sound.play()
	
func play_segment(start_sec: float, duration: float):
	spin_sound.play(start_sec)

	await get_tree().create_timer(duration).timeout
	spin_sound.stop()

func _ready():
	# BGM
	bgm_sound.play()
	# WIN ANI
	bigWin_Ani_ini()
	# 初始化玩家
	player = Player.instantiate()
	actionEffect = ActionEffect.instantiate()
	$"../../../CombatViewportContainer".get_node('Viewport/CombatBoard').set_player(player)
	$"../../../CombatViewportContainer".get_node('Viewport/CombatBoard').set_player_action(actionEffect)
	await player.set_profession(player.Profession.MAGE)  # 初始化時設置職業
	print("Name:", player.player_name)
	# 當運作停止時觸發玩家動作效果動畫
	self.connect("stopped", Callable(actionEffect, "attack_right"))
	
	# 初始化瓦片格子
	for col in reels:
		grid_pos.append([])
		tiles_moved_per_reel.append(0)
		for row in range(rows):
		# 將額外瓦片放置在視窗上方與下方
			grid_pos[col].append(Vector2(col, row-0.5*extra_tiles) * tile_size)
			_add_tile(col, row)
  
# 在指定的格子位置儲存並初始化一個新的瓦片
func _add_tile(col :int, row :int) -> void:
	tiles.append(SlotTile.instantiate())
	var tile := get_tile(col, row)
	tile.set_speed(speed_norm)
	tile.set_texture(_randomTexture())
	tile.set_text("col:%d row:%d" % [col, row])
	#tile.set_text("")
	tile.set_size(tile_size)
	tile.position = grid_pos[col][row]
	add_child(tile)

# 回傳指定格子位置的瓦片
func get_tile(col :int, row :int) -> SlotTile:
	return tiles[(col * rows) + row]

func start() -> void:
	_on_anim_finished()
  # 僅在尚未運作時才開始
	if state == State.OFF:
		state = State.ON
		total_runs = expected_runs
		# 向伺服器請求結果
		_get_result()
		print(result)
		# 旋轉所有轉軸
		for reel in reels:
			_spin_reel(reel)
			play_segment(0.1,6)
			# 稍後再旋轉下一個轉軸
			if reel_delay > 0:
				await get_tree().create_timer(reel_delay).timeout
	
# 在運行時間結束前強制停止機器
func stop():
	# 告知機器在下一個可行時機停止
	state = State.STOPPED
	# 儲存第一個轉軸目前的移動次數
	# 增加移動次數以更新瓦片為結果圖片
	runs_stopped = current_runs()
	total_runs = runs_stopped + tiles_per_reel

# 問題動畫尚未結束就將陣列歸零重置
# 當動畫停止時呼叫
func _stop() -> void:
	for reel in reels:
		spin_sound.stop()
		tiles_moved_per_reel[reel] = 0
	state = State.OFF
	emit_signal("stopped")
	play_once_bigWin_Ani()

# 開始移動指定轉軸上的所有瓦片
func _spin_reel(reel :int) -> void:
	# 移動該轉軸上的每一個瓦片
	spin_sound.stop()
	for row in rows:
		_move_tile(get_tile(reel, row))

func _move_tile(tile :SlotTile) -> void:
	# 播放啟動旋轉動畫
	tile.spin_up()
	await tile.get_node("Animations").animation_finished
	# 每次只移動一個瓦片高度，以避免速度過快產生的畫面瑕疵
	tile.move_by(Vector2(0, tile_size.y))
	# 轉軸會在 _on_tile_moved 函式中繼續移動
  
func _on_tile_moved(tile: SlotTile, _nodePath) -> void:
	# 計算該瓦片所屬的轉軸
	var reel := int(tile.position.x / tile_size.x)
	# 計算每個轉軸已移動的瓦片數量
	tiles_moved_per_reel[reel] += 1
	var reel_runs := current_runs(reel)
	var current_idx = total_runs - reel_runs
	
	# 若瓦片移出視窗，則將其移到最上方的不可見列
	if (tile.position.y > grid_pos[0][-1].y):
		tile.position.y = grid_pos[0][0].y
		
		# 設定新的隨機貼圖
		if (tiles_per_reel > current_idx):
			tile.set_texture(pictures[result.tiles[reel][current_idx]])
		else:
			tile.set_texture(_randomTexture())
				
	# 當轉軸達到期望的移動次數後停止
	# 或者玩家已強制停止
	if (state != State.OFF && reel_runs < total_runs):
		tile.move_by(Vector2(0, tile_size.y))
	else: # 停止該轉軸的移動
		tile.spin_down()
		stop_sound.stop()
		stop_sound.play()
		await tile.get_node("Animations").animation_finished
		# 當最後一個轉軸停止時，整台機器停止
		print(reel_runs)
		print(reel)
		if reel == reels - 1:
			_stop()

# 將移動次數除以瓦片數量，以得知整個轉軸移動了幾次
# 由於此函式會被每個瓦片呼叫，數值會逐步變化（例如 6 個瓦片時：1/6、2/6...）
# 使用 ceil，確保 1/7 與 7/7 都會回傳轉軸已運行 1 次
func current_runs(reel_idex := 0) -> int:
	return int(ceil(float(tiles_moved_per_reel[reel_idex]) / rows))

func _randomTexture() -> Texture2D:
	return pictures[randi() % pictures.size()]
	
# 取得結果
func _get_result() -> void:
	result = {
		"tiles": [
			[ 1,1,1,1 ],
			[ 1,1,1,1 ],
			[ 2,2,2,2 ],
			[ 3,3,3,3 ],
			[ 4,4,4,4 ],
		]
	}
