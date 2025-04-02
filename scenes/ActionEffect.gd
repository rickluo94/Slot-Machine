extends Node2D
class_name ActionEffect

func _ready() -> void:
	# 確保節點存在
	if not $Sprite or not $Animations:
		push_error("Sprite or Animations node missing in ActionEffect!")
		return
	
	# 初始隱藏 Sprite
	$Sprite.hide()
	
	# 連接信號，避免重複連接
	if not $Animations.is_connected("animation_started", Callable(self, "_on_animation_started")):
		$Animations.connect("animation_started", Callable(self, "_on_animation_started"))
	if not $Animations.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		$Animations.connect("animation_finished", Callable(self, "_on_animation_finished"))

# 播放攻擊動畫
func attack_right() -> void:
	$Animations.play("ATTACK_RIGHT")

# 動畫開始時的回調
func _on_animation_started(anim_name: String) -> void:
	$Sprite.show()  # 顯示 Sprite
	# 可選：根據 anim_name 添加條件邏輯
	# print("Animation started: ", anim_name)

# 動畫結束時的回調
func _on_animation_finished(anim_name: String) -> void:
	$Sprite.hide()  # 隱藏 Sprite
	# 可選：根據 anim_name 添加條件邏輯
	# print("Animation finished: ", anim_name)
