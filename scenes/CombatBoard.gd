extends Node2D

func _ready() -> void:
	pass

func set_player(new_node: Node2D) -> void:
	get_parent().get_node('CombatBoard').add_child(new_node)

func set_player_action(new_action: Node2D) -> void:
	get_parent().get_node('CombatBoard').add_child(new_action)
