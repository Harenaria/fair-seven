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
	_start_new_round()

func _on_board_cleared(player_id: int) -> void:
	score_tracker.register_sweep(player_id)
	_start_new_round()

func _board_of(player_id: int) -> Board:
	return $Board if player_id == 0 else $Board2
	
func _on_point_scored(player_id: int, point_type: ScoreTracker.PointType) -> void:
	pass
func _on_match_ended():
	pass

func _on_dead_board(_player_id: int) -> void:
	_start_new_round()

func _start_new_round() -> void:
	_round_number += 1
	var match_seed: int = $MatchState.get_meta("match_seed", 0)
	# Seed derivato deterministicamente: stesso match seed + numero round
	var round_seed: int = hash(match_seed + _round_number)
	$Board.reset(round_seed)
	$Board2.reset(round_seed)
	score_tracker.reset_round()
