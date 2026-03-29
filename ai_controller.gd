# ai_controller.gd
extends Node
class_name AIController

@onready var cursor:Cursor = get_parent().get_cursor()

@export_range(1, 11) var difficulty: float = 1



func _t_speed() -> float:
	if difficulty >= 11.0:
		return 1.0
	return pow((difficulty - 1.0) / 9.0, 0.5)  # sqrt = concava

var think_delay: float:
	get:
		if difficulty >= 11.0:
			return 0.3
		return lerpf(3.0, 0.8, _t_speed())

var step_delay: float:
	get:
		if difficulty >= 11.0:
			return 0.0
		return lerpf(0.6, 0.15, _t_speed())
var _skill: float:
	get: return 0 #Change here to implement move noise

enum State { THINKING, MOVING_TO_PICK, PICKING, MOVING_TO_LAUNCH, LAUNCHING }
var _state: State = State.THINKING

var _target_pick_col:   int = -1
var _target_launch_col: int = -1
var _target_combo_idx:  int =  0

var _step_timer:  float = 0.0
var _think_timer: float = 0.0

func _process(delta: float) -> void:
	if cursor == null or cursor.is_busy():
		return

	match _state:
		State.THINKING:
			_think_timer += delta
			if _think_timer >= think_delay:
				_think_timer = 0.0
				_decide()

		State.MOVING_TO_PICK:
			_step_timer += delta
			if _step_timer < step_delay:
				return
			_step_timer = 0.0
			var diff = sign(_target_pick_col - cursor.current_column)
			if diff != 0:
				cursor.command_move(diff)
			else:
				_state = State.PICKING

		State.PICKING:
			cursor.command_pick()
			_state = State.MOVING_TO_LAUNCH if cursor.is_holding() else State.THINKING

		State.MOVING_TO_LAUNCH:
			_step_timer += delta
			if _step_timer < step_delay:
				return
			_step_timer = 0.0
			var diff = sign(_target_launch_col - cursor.current_column)
			if diff != 0:
				cursor.command_move(diff)
			else:
				cursor.command_set_combo(_target_combo_idx)
				_state = State.LAUNCHING

		State.LAUNCHING:
			cursor.command_launch()
			_state = State.THINKING

# ── Planning ───────────────────────────────────────────────────────────

func _decide() -> void:
	var board: Board = cursor.board
	var best_score := -INF
	var best_pick  := -1
	var best_launch:= -1
	var best_combo := 0

	for pick_col in range(board.COLUMNS):
		if board.board[pick_col].is_empty():
			continue
		var picked: Dictionary = board.board[pick_col].pop_back()  # pop diretto, no segnali

		for launch_col in range(board.COLUMNS):
			var combos = CaptureResolver.resolve(picked["value"], launch_col, board)
			for ci in range(combos.size()):
				var s = _score_move(picked, combos[ci], board, launch_col)
				if s > best_score:
					best_score  = s
					best_pick   = pick_col
					best_launch = launch_col
					best_combo  = ci

		board.board[pick_col].append(picked)  # restore

	if best_pick == -1:
		cursor.no_captures_available.emit(cursor.player_id)
		return

	_target_pick_col   = best_pick
	_target_launch_col = best_launch
	_target_combo_idx  = best_combo
	_state = State.MOVING_TO_PICK

func _score_move(picked: Dictionary, combo: CaptureResolver.CaptureCombo,
				 board: Board, pick_col: int) -> float:
	var score := 0.0
	var all_cards: Array[Dictionary] = combo.cards.duplicate()
	all_cards.append(picked)

	for card in all_cards:
		if CardUtils.is_garbage(card):
			continue
		score += 1.0
		if card["suit"] == CardUtils.Suit.GOLD:
			score += 1.5
			if card["value"] == 7:
				score += 12.0                        # Settebello
		if card["value"] == 7:
			score += 4.0                             # verso Primiera

	score += board.get_column_height(pick_col) * 0.3  # bonus colonne alte

	var noise = randf_range(-8.0, 8.0) * (1.0 - _skill)
	return score + noise
