extends Node2D
class_name SlotTile

var size :Vector2
var tween:Tween
signal finished

func _ready():
	pass

func set_tween():
	tween = create_tween()
	tween.stop()
	tween.bind_node(self)
	tween.connect("finished", Callable(self, "on_finished"))

func set_texture(tex):
	$Sprite.texture = tex
	set_size(size)

func set_size(new_size: Vector2):
	size = new_size
	$Sprite.scale = size / $Sprite.texture.get_size()
  
func set_speed(speed):
	tween.set_speed_scale(speed)
  
func move_to(to: Vector2):
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.bind_node(self)
	tween.set_speed_scale(15)
	tween.connect("finished", Callable(self, "on_finished"))
	tween.tween_property(self, "position", to, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
func move_by(by: Vector2):
	move_to(position + by)
	
func spin_up():
	$Animations.play('SPIN_UP')
  
func spin_down():
	$Animations.play('SPIN_DOWN')
	
func on_finished():
	get_parent()._on_tile_moved(self, null)
  
