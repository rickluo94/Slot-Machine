extends Node2D

const SlotTile := preload("res://scenes/SlotTile.tscn")
const Player := preload("res://scenes/Player.tscn")
const ActionEffect := preload("res://scenes/ActionEffect.tscn")

var player:Node2D
var actionEffect:Node2D
# Stores the SlotTile's SPIN_UP animation distance
const SPIN_UP_DISTANCE = 100.0
signal stopped

@export var pictures :Array[Texture2D] = [
	# Spades (0-11)
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
	# Hearts (12-23)
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
	# Diamonds (24-35)
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
	# Clubs (36-47)
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

@export_range(1,20) var reels :int = 5
@export_range(1,20) var tiles_per_reel :int = 4
# Defines how long the reels are spinning
@export_range(0,10) var runtime :float = 2.0
# Defines how fast the reels are spinning
@export_range(0.1,10) var speed :float = 5.0
# Defines the start delay between each reel
@export_range(0,2) var reel_delay :float = 0.3

# Adjusts tile size to viewport
@onready var size := get_viewport_rect().size
@onready var tile_size := size / Vector2(reels, tiles_per_reel)
# Normalizes the speed for consistancy independent of the number of tiles
@onready var speed_norm := speed * tiles_per_reel
# 在每個捲軸中增加瓦片在鏡頭外增加動畫流暢度
# Grid 增加兩個瓦片在前後的 TODO 當前也會因為增加的瓦片在停止時未依照預期結果
@onready var extra_tiles := 0#int(ceil(SPIN_UP_DISTANCE / tile_size.y)*2)

# Stores the actual number of tiles
@onready var rows := tiles_per_reel + extra_tiles

enum State {OFF, ON, STOPPED}
var state = State.OFF
var result := {}

# Stores SlotTile instances
var tiles := []
# Stores the top left corner of each grid cell
var grid_pos := []

# 1/speed*runtime*reels times
# Stores the desured number of movements per reel
@onready var expected_runs :int = int(runtime * speed_norm)
# Stores the current number of movements per reel
var tiles_moved_per_reel := []
# When force stopped, stores the current number of movements 
var runs_stopped := 0
# Store the runs independent of how they are achieved
var total_runs : int

func _ready():
	# Initializes Player
	player = Player.instantiate()
	actionEffect = ActionEffect.instantiate()
	$"../../../CombatViewportContainer".get_node('Viewport/CombatBoard').set_player(player)
	$"../../../CombatViewportContainer".get_node('Viewport/CombatBoard').set_player_action(actionEffect)
	await player.set_profession(player.Profession.MAGE)  # 初始化時設置職業
	print("Name:", player.player_name)
	# 當運作停止時觸發玩家動作效果動畫
	self.connect("stopped", Callable(actionEffect, "attack_right"))
	
	# Initializes grid of tiles
	for col in reels:
		grid_pos.append([])
		tiles_moved_per_reel.append(0)
		for row in range(rows):
		# Position extra tiles above and below the viewport
			grid_pos[col].append(Vector2(col, row-0.5*extra_tiles) * tile_size)
			_add_tile(col, row)
  
# Stores and initializes a new tile at the given grid cell
func _add_tile(col :int, row :int) -> void:
	tiles.append(SlotTile.instantiate())
	var tile := get_tile(col, row)
	tile.set_speed(speed_norm)
	tile.set_texture(_randomTexture())
	#tile.set_text("col:%d row:%d" % [col, row])
	tile.set_text("")
	tile.set_size(tile_size)
	tile.position = grid_pos[col][row]
	add_child(tile)

# Returns the tile at the given grid cell
func get_tile(col :int, row :int) -> SlotTile:
	return tiles[(col * rows) + row]

func start() -> void:
  # Only start if it is not running yet
	if state == State.OFF:
		state = State.ON
		total_runs = expected_runs
		# Ask server for result
		_get_result()
		print(result)
		# Spins all reels
		for reel in reels:
			_spin_reel(reel)
			# Spins the next reel a little bit later
			if reel_delay > 0:
				await get_tree().create_timer(reel_delay).timeout
  
# Force the machine to stop before runtime ends
func stop():
	# Tells the machine to stop at the next possible moment
	state = State.STOPPED
	# Store the current runs of the first reel
	# Add runs to update the tiles to the result images
	runs_stopped = current_runs()
	total_runs = runs_stopped + tiles_per_reel - 1

# 問題動畫尚未結束就將陣列歸零重置
# Is called when the animation stops
func _stop() -> void:
	for reel in reels:
		tiles_moved_per_reel[reel] = 0
	state = State.OFF
	emit_signal("stopped")

# Starts moving all tiles of the given reel
func _spin_reel(reel :int) -> void:
	# Moves each tile of the reel
	for row in rows:
		_move_tile(get_tile(reel, row))

func _move_tile(tile :SlotTile) -> void:
	# Plays a spin up animation
	tile.spin_up()
	await tile.get_node("Animations").animation_finished
	# Moves reel by one tile at a time to avoid artifacts when going too fast
	tile.move_by(Vector2(0, tile_size.y))
	# The reel will move further through the _on_tile_moved function
  
func _on_tile_moved(tile: SlotTile, _nodePath) -> void:    
	# Calculates the reel that the tile is on
	var reel := int(tile.position.x / tile_size.x)
	# Count how many tiles moved per reel
	tiles_moved_per_reel[reel] += 1
	var reel_runs := current_runs(reel)
	var current_idx = total_runs - reel_runs
	# If tile moved out of the viewport, move it to the invisible row at the top
	if (tile.position.y > grid_pos[0][-1].y):
		tile.position.y = grid_pos[0][0].y
			# Set a new random texture
		if (current_idx < tiles_per_reel):
			tile.set_texture(pictures[result.tiles[reel][current_idx]])
		else:
			tile.set_texture(_randomTexture())

  # Stop moving after the reel ran expected_runs times
  # Or if the player stopped it
	if (state != State.OFF && reel_runs != total_runs):
		tile.move_by(Vector2(0, tile_size.y))
	else: # stop moving this reel
		tile.spin_down()
		await tile.get_node("Animations").animation_finished
		# When last reel stopped, machine is stopped
		if reel == reels - 1:
			_stop()

# Divide it by the number of tiles to know how often the whole reel moved
# Since this function is called by each tile, the number changes (e.g. for 6 tiles: 1/6, 2/6, ...)
# We use ceil, so that both 1/7, as well as 7/7 return that the reel ran 1 time
func current_runs(reel_idex := 0) -> int:
	return int(ceil(float(tiles_moved_per_reel[reel_idex]) / rows))

func _randomTexture() -> Texture2D:
	return pictures[randi() % pictures.size()]

# 取得結果
func _get_result() -> void:
	result = {
		"tiles": [
			[ 1,player.get_random_texture_idx(),5,1 ],
			[ 2,player.get_random_texture_idx(),4,2 ],
			[ 3,player.get_random_texture_idx(),3,3 ],
			[ 4,player.get_random_texture_idx(),2,4 ],
			[ 5,player.get_random_texture_idx(),1,5 ],
		]
	}
