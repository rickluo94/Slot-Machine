extends Node2D
class_name Player

# 玩家名稱（可選，增加角色扮演感）
var player_name: String = "玩家一號"

# 當前金幣數量（老虎機的貨幣單位）
var gold: int = 1000

# 當前冒險層級（模擬地下城進度）
var dungeon_level: int = 1

# 定義職業枚舉
enum Profession { MAGE, WARRIOR, RANGER, ROGUE }
var current_profession: Profession #Profession.MAGE  # 當前職業，預設為法師

# 職業對應的花色
const PROFESSION_TO_SUIT = {
	Profession.MAGE: "Spades",    # 法師 - 黑桃
	Profession.WARRIOR: "Hearts", # 戰士 - 紅心
	Profession.RANGER: "Diamonds",# 遊俠 - 方塊
	Profession.ROGUE: "Clubs"     # 盜賊 - 梅花
}

# 職業對應圖片紋理
const PROFESSION_TO_PICTURE = {
	Profession.MAGE: preload("res://sprites/Profession/MAGE/mage_01.png"),    # 法師
	Profession.WARRIOR: preload("res://sprites/Profession/MAGE/mage_01.png"), # 戰士
	Profession.RANGER: preload("res://sprites/Profession/MAGE/mage_01.png"),  # 遊俠
	Profession.ROGUE: preload("res://sprites/Profession/MAGE/mage_01.png")    # 盜賊
}

# 基礎花色權重（未選擇職業時的默認值）
var base_symbol_weights: Dictionary = {
	"Spades": 0.25,    # 25%
	"Hearts": 0.25,
	"Diamonds": 0.25,
	"Clubs": 0.25
}

# 當前職業調整後的權重
var current_symbol_weights: Dictionary = base_symbol_weights.duplicate()

# 職業加成權重（選擇職業時增加的權重值）
@export var profession_weight_bonus: float = 0.15  # 例如，提升 15%

# 花色索引範圍
const SUIT_RANGES = {
	"Spades": [0, 11],
	"Hearts": [12, 23],
	"Diamonds": [24, 35],
	"Clubs": [36, 47]
}

func _ready() -> void:
	pass

func set_texture(prof: Profession):
	$Sprite.texture = PROFESSION_TO_PICTURE[prof]
	
	
# 設置當前職業並更新權重
func set_profession(prof: Profession) -> void:
	current_profession = prof
	set_texture(prof)
	update_symbol_weights()
	print("Profession set to: ", Profession.keys()[prof])
	
# 更新符號權重
func update_symbol_weights() -> void:
	current_symbol_weights = base_symbol_weights.duplicate()
	var favored_suit = PROFESSION_TO_SUIT[current_profession]
	# 增加職業對應花色的權重
	current_symbol_weights[favored_suit] += profession_weight_bonus
	# 減少其他花色的權重，保持總和為 1
	var reduction = profession_weight_bonus / 3.0
	for suit in current_symbol_weights:
		if suit != favored_suit:
			current_symbol_weights[suit] -= reduction
	print("Updated weights: ", current_symbol_weights)


# 根據當前權重隨機選擇一個花色並返回圖片索引
func get_random_texture_idx() -> int:
	var roll = randf()
	var cumulative = 0.0
	for suit in current_symbol_weights:
		cumulative += current_symbol_weights[suit]
		if roll <= cumulative:
			var range = SUIT_RANGES[suit]
			return randi_range(range[0], range[1])  # 返回花色範圍內的隨機索引
	return 0  # 預設返回黑桃 A 的索引

# 提供權重給老虎機
func get_symbol_weights() -> Dictionary:
	return current_symbol_weights
	
