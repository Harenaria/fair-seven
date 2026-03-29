extends Node2D
@onready var board:Board = self.get_parent()
const CardScene = preload("res://card.tscn")

var player_id:int
var current_column: int = 3
var held_card: Dictionary = {}
var card_node: Node2D
var score_tracker: ScoreTracker

var capture_combinations: Array = []
var capture_index: int = 0

const tween_speed = 0.05
var _pulsing_nodes: Array[Node2D] = []
var is_animating: bool = false

var input_left:   String   # L
var input_right:  String   # R
var input_pick:   String   # A
var input_launch: String   # B
var input_rotate: String   # C

signal no_captures_available(player_id: int)

func _ready() -> void:
	if board:
		player_id = board.player_id
		score_tracker = board.score_tracker
	input_left   = "P%dL"   % player_id
	input_right  = "P%dR"  % player_id
	input_pick   = "P%dA"   % player_id
	input_launch = "P%dB" % player_id
	input_rotate = "P%dC" % player_id
	_snap_to_column()

func _snap_to_column() -> void:
	if board:
		position.x = board.get_column_x(current_column)
	if held_card != {}:
		capture_combinations = CaptureResolver.resolve(held_card["value"], current_column, board)
		capture_index = 0
		_highlight_current_combo()

func _process(_delta: float) -> void:
	_handle_movement()
	_handle_actions()

func _handle_movement() -> void:
	if Input.is_action_just_pressed(input_left):
		current_column = max(0, current_column - 1)
		_snap_to_column()
	elif Input.is_action_just_pressed(input_right):
		current_column = min(board.COLUMNS - 1, current_column + 1)
		_snap_to_column()

func _handle_actions() -> void:
	if Input.is_action_just_pressed(input_pick):
		_try_pick()
	elif Input.is_action_just_pressed(input_launch):
		_try_launch()
	elif Input.is_action_just_pressed(input_rotate):
		_try_rotate()
		
func _try_pick() -> void:
	if not board.get_top_card(current_column):
		return
	if held_card != {} or is_animating:
		return
	var card = board.get_top_card(current_column)
	if card == {}:
		return
	var card_world_pos = board.get_top_card_world_pos(current_column)
	held_card = board.pop_card(current_column)
	card_node = CardScene.instantiate()
	add_child(card_node)
	card_node.initialize_card(held_card)
	card_node.position = to_local(card_world_pos)
	
	if held_card != {}:
		capture_combinations = CaptureResolver.resolve(held_card["value"], current_column, board)
	capture_index = 0
	_highlight_current_combo()
	
	var tween = create_tween()
	tween.tween_property(card_node, "position", Vector2.ZERO, tween_speed) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
func _try_launch() -> void:
	if held_card == {} or is_animating:
		return
	var dest_world_pos = board.get_next_card_world_pos(current_column)
	var dest_local = to_local(dest_world_pos)
	var combo = get_current_combo()
	is_animating = true
	var tween = create_tween()
	tween.tween_property(card_node, "position", dest_local, tween_speed) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		if combo != null:
			_apply_capture(combo)
		else:
			board.push_card(current_column, held_card)

		if card_node != null:
			card_node.queue_free()
			card_node = null
		held_card = {}
		capture_combinations = []
		capture_index = 0
		is_animating = false
		
		if not CaptureResolver.has_any_capture(board):
			no_captures_available.emit(player_id)
	)
	
func _try_rotate() -> void:
	if capture_combinations.size() <= 1:
		return
	capture_index = (capture_index + 1) % capture_combinations.size()
	_highlight_current_combo() 
	
func _highlight_current_combo() -> void:
	for node in _pulsing_nodes:
		if is_instance_valid(node):
			node.stop_pulse()
	_pulsing_nodes.clear()

	var combo = get_current_combo()
	if combo == null:
		return

	for pos in combo.positions:
		var node = board.get_card_node_at(pos.x, pos.y)
		if node != null:
			node.start_pulse()
			_pulsing_nodes.append(node)

func get_current_combo() -> CaptureResolver.CaptureCombo:
	if capture_combinations.is_empty():
		return null
	return capture_combinations[capture_index]
	
func _apply_capture(combo: CaptureResolver.CaptureCombo) -> void:
	for pos in combo.positions:
		board.remove_card_at(pos.x, pos.y)

	var all_captured: Array[Dictionary] = combo.cards.duplicate()
	all_captured.append(held_card)

	if score_tracker:
		score_tracker.register_capture(player_id, all_captured)
		score_tracker.request_garbage_to_opponent(player_id, all_captured.size())

	board.remove_garbage(all_captured.size())

	if board.is_empty() and score_tracker:
		score_tracker.register_sweep(player_id)
		

func reset() -> void:
	if card_node:
		card_node.queue_free()
		card_node = null
	for node in _pulsing_nodes:
		if is_instance_valid(node):
			node.stop_pulse()
	_pulsing_nodes.clear()
	held_card = {}
	capture_combinations = []
	capture_index = 0
	is_animating = false
	current_column = 3
	_snap_to_column()
	
