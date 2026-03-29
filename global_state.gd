extends Node
func _on_match_scene_tree_entered() -> void:
	self.set_meta("match_seed", randi())
