extends Node2D
class_name Board
const CardScene = preload("res://card.tscn")
@export var state:Node
@export var player_id:int
@export var score_tracker:ScoreTracker
@onready var grid = $Grid
@onready var garbage_bar = $GarbageBar

const COLUMNS = 7
const ROWS = 12
const TILE_SIZE = 16

var board = []

signal garbage_buffer_changed(size: int)
signal board_overflowed(player_id: int)
signal board_cleared(player_id: int)

const BUFFER_MAX    := 7
const DUMP_INTERVAL := 2.0

var _garbage_buffer: Array[Dictionary] = []
var _rng            := RandomNumberGenerator.new()
var _dump_timer     : float = 0.0

func get_top_card(col: int):
	if board[col].is_empty():
		return null
	return board[col].back()

func push_card(col: int, card: Dictionary):
	board[col].append(card)
	draw_board()

func pop_card(col: int) -> Dictionary:
	var res =  board[col].pop_back()
	draw_board()
	if is_empty():
		board_cleared.emit(player_id)
	return res if res != null else {}

func is_empty() -> bool:
	for col in range(COLUMNS):
		for row in range(board[col].size()):
			var card = board[col][row]
			if card != {}:
				if card["suit"] != -1:
					return false
	return true

func get_card_node_at(col: int, row: int) -> Node2D:
	for child in grid.get_children():
		var expected = Vector2(col * TILE_SIZE, row * TILE_SIZE)
		if child.position == expected:
			return child
	return null
func remove_card_at(col: int, row: int) -> Dictionary:
	var card = board[col][row]
	board[col].remove_at(row)
	draw_board()
	if is_empty():
		board_cleared.emit(player_id)
	return card

func get_column_height(col: int) -> int:
	return board[col].size()
func get_column_x(col_index: int) -> float:
	return (col_index-1) * TILE_SIZE + self.global_position.x
func get_top_card_world_pos(col: int) -> Vector2:
	var row = board[col].size() - 1
	var local_pos = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	return grid.global_position + local_pos
func get_next_card_world_pos(col: int) -> Vector2:
	var row = board[col].size()  # la carta verrà inserita a questo indice
	var local_pos = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	return grid.global_position + local_pos
	
func is_overflowing() -> bool:
	for col in range(COLUMNS):
		if get_column_height(col) >= (ROWS-1):
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_board()
	populate_board(state.get_meta("match_seed", 0))
	debug_board()
	draw_board()
func _process(delta: float) -> void:
	_dump_timer += delta
	if _dump_timer >= DUMP_INTERVAL and not $Cursor.is_animating:
		_dump_timer = 0.0
		add_garbage(1)
func add_garbage(count: int) -> void:
	for i in range(count):
		if _garbage_buffer.size() >= BUFFER_MAX:
			_dump_buffer_to_board()
			break
		_garbage_buffer.append(CardUtils.gen_garbage_card(_rng))
	garbage_buffer_changed.emit(_garbage_buffer.size())
	_draw_garbage_bar()

func remove_garbage(count: int) -> void:
	for i in range(count):
		if _garbage_buffer.is_empty():
			break
		_garbage_buffer.pop_back()
	garbage_buffer_changed.emit(_garbage_buffer.size())
	_draw_garbage_bar()
	
func flush_garbage_buffer() -> void:
	_garbage_buffer.clear()
	garbage_buffer_changed.emit(0)
	_draw_garbage_bar()

func clear_garbage_from_board() -> void:
	for col in range(COLUMNS):
		board[col] = board[col].filter(func(c): return not CardUtils.is_garbage(c))

func _dump_buffer_to_board() -> void:
	if _garbage_buffer.is_empty():
		return
	while not _garbage_buffer.is_empty():
		var card = _garbage_buffer.pop_front()
		var target_col = 0
		for col in range(1, COLUMNS):
			if board[col].size() < board[target_col].size():
				target_col = col
		push_card(target_col, card)
	if is_overflowing():
		board_overflowed.emit(player_id)
	garbage_buffer_changed.emit(0)
	_draw_garbage_bar()
	
	
func initialize_board() -> void:
	board = []
	for col in range(COLUMNS):
		board.append([])
func populate_board(shared_seed:int) -> void:
	var deck = []
	for i in range(40):
		deck.append(CardUtils.gen_card((i%10)+1, i/10))
	for i in range(2):
		deck.append(CardUtils.gen_card(11, -1))
	seed(shared_seed)
	deck.shuffle()
	
	var i = 0
	for col in range(COLUMNS):
		for j in range(6):
			if i < deck.size():
				push_card(col, deck[i])
				i += 1
func _draw_garbage_bar() -> void:
	for child in garbage_bar.get_children():
		child.queue_free()
	for i in range(_garbage_buffer.size()):
		var card_node = CardScene.instantiate()
		garbage_bar.add_child(card_node)
		card_node.initialize_card(_garbage_buffer[i])
		card_node.position = Vector2(i * TILE_SIZE, 0)
func draw_board() -> void:
	for child in grid.get_children():
		child.queue_free()
	for row in range(ROWS):
		for col in range(COLUMNS):
			if row < board[col].size():
				var card_data = board[col][row]
				var card_node = CardScene.instantiate()
				grid.add_child(card_node)
				card_node.initialize_card(card_data)
				var x = col * TILE_SIZE
				var y = (row) * TILE_SIZE
				card_node.position = Vector2(x, y)
			
func debug_board() -> void:
	if board.is_empty():
		print("Board is empty")
		return
		
	for row in range(ROWS):
		var res_row = ""
		for col in range(COLUMNS):
			var card
			if row < board[col].size():
				card = board[col][row] 
			else: 
				card = null
			if card == null:
				res_row += " , null , "
			else:
				res_row += " , "+str(card["value"])+" "+str(CardUtils.Suit.keys()[card["suit"]+1])+" , "
		print(res_row)
	
func reset(new_seed: int) -> void:
	$Cursor.reset()
	initialize_board()
	populate_board(new_seed)
	flush_garbage_buffer()
	draw_board()
