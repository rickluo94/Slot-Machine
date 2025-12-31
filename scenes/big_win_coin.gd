extends Sprite2D

class_name big_win_coin

func pop_big():
	scale = Vector2(0.177, 0.176)

	var tween := create_tween()

	tween.tween_property(self, "scale", Vector2(0.177*5, 0.177*5), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "scale", Vector2(0.177*1.2, 0.176*1.2), 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
