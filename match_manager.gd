extends Node2D
@export var score_tracker:ScoreTracker
var _round_number: int = 0

func _ready() -> void:
	$Board.board_overflowed.connect(_on_board_overflowed)
	$Board2.board_overflowed.connect(_on_board_overflowed)
	$Board.board_cleared.connect(_on_board_cleared)
	$Board2.board_cleared.connect(_on_board_cleared)
	score_tracker.point_scored.connect(_on_point_scored)
	score_tracker.match_ended.connect(_on_match_ended)
	score_tracker.send_garbage_to.connect(func(pid, count): _board_of(pid).add_garbage(count))
	$Board/Cursor.no_captures_available.connect(_on_dead_board)
	$Board2/Cursor.no_captures_available.connect(_on_dead_board)

func _on_board_overflowed(loser_id: int) -> void:
	score_tracker.register_reverse_sweep(loser_id)
	await _show_round_end(3 - loser_id, "REVERSE SWEEP!")
	_start_new_round()

func _on_board_cleared(player_id: int) -> void:
	score_tracker.register_sweep(player_id)
	await _show_round_end(player_id, "SWEEP!")
	_start_new_round()

func _board_of(player_id: int) -> Board:
	return $Board if player_id == 1 else $Board2
	
func _on_point_scored(player_id: int, point_type: ScoreTracker.PointType) -> void:
	pass
	
func _on_match_ended(winner: int) -> void:
	_freeze_all()
	_board_of(winner).show_message("WIN")
	_board_of(3 - winner).show_message("LOSE")

func _on_dead_board(player_id: int) -> void:
	_freeze_all()
	if player_id == 1:
		$Board.show_message("NO CAPTURE AVAILABLE")
		$Board2.show_message("PLEASE WAIT...")
	else:
		$Board2.show_message("NO CAPTURE AVAILABLE")
		$Board.show_message("PLEASE WAIT...")
	await get_tree().create_timer(2.0).timeout
	_unfreeze_all()
	_start_new_round()

func _start_new_round() -> void:
	_round_number += 1
	var match_seed: int = $MatchState.get_meta("match_seed", 0)
	# Seed derivato deterministicamente: stesso match seed + numero round
	var round_seed: int = hash(match_seed + _round_number)
	$Board.reset(hash(round_seed + 1))
	$Board2.reset(hash(round_seed + 2))
	score_tracker.reset_round()

func _freeze_all() -> void:
	$Board/Cursor.frozen = true
	$Board2/Cursor.frozen = true

func _unfreeze_all() -> void:
	$Board/Cursor.frozen = false
	$Board2/Cursor.frozen = false
	$Board.hide_message()
	$Board2.hide_message()
	
func _start_countdown() -> void:
	_freeze_all()
	for n in [3, 2, 1]:
		$Board.show_message(str(n))
		$Board2.show_message(str(n))
		await get_tree().create_timer(1.0).timeout
	_unfreeze_all()
func _show_round_end(winner_id: int, reason: String) -> void:
	_freeze_all()
	_board_of(winner_id).show_message(reason)
	_board_of(3 - winner_id).show_message("...")
	await get_tree().create_timer(2.0).timeout
	_unfreeze_all()
