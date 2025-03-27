extends Node2D
class_name SlotTile
var _size : Vector2
var _speed : float

signal finished

func _ready() -> void:
	pass
	
func set_texture(tex):
	$Sprite.texture = tex
	set_size(_size)

func set_size(new_size: Vector2):
	_size = new_size
	$Sprite.scale = _size / $Sprite.texture.get_size()
	
func set_text(new_text: String):
	$Sprite/Label.text = new_text

func set_speed(new_speed: float):
	_speed = new_speed

func move_to(to: Vector2):
	var tween : Tween = create_tween()
	tween.set_speed_scale(_speed)
	tween.tween_interval(0.6)
	tween.tween_property(self, "position", to, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _on_finished())
	
func move_by(by: Vector2):
	move_to(position + by)
	
func spin_up():
	$Animations.play('SPIN_UP')
  
func spin_down():
	$Animations.play('SPIN_DOWN')
	
func _on_finished():
	get_parent()._on_tile_moved(self, self)
