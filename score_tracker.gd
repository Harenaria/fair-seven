class_name ScoreTracker
extends Node

enum PointType {
	FAIR_SEVEN,    # Settebello: 7 di Denari
	ALL_SEVEN,     # Primiera: tutti e 4 i sette
	GOLDS,         # Denari: 5+ carte oro
	QUOTA,         # Carte Lunghe: 20+ carte
	SWEEP,         # Board svuotata
	REVERSE_SWEEP, # Avversario in overflow
	EXACT_CAPTURE  # Prendo una carta con una carta
}

signal point_scored(player_id: int, point_type: PointType)
signal match_ended(winner_id: int)
signal send_garbage_to(player_id: int, count: int)

func request_garbage_to_opponent(sender_id: int, count: int) -> void:
	send_garbage_to.emit(3 - sender_id, count)

const MATCH_WIN_THRESHOLD := 11
const GOLD_THRESHOLD      := 5   # 5/10 carte Denari
const QUOTA_THRESHOLD     := 20  # 20/40 carte totali
const SEVENS_TOTAL        := 4

# Punti accumulati nel match (sopravvivono tra round)
var match_points: Dictionary = { 1: 0, 2: 0 }

# Punti già reclamati in questo round (esclusivi)
var _round_claimed: Dictionary = {}

# Statistiche catture per round, per giocatore
var _round_stats: Dictionary = {}

func _ready() -> void:
	reset_round()

# Chiamato a inizio di ogni nuovo round
func reset_round() -> void:
	_round_claimed.clear()
	_round_stats = { 1: _empty_stats(), 2: _empty_stats() }

func _empty_stats() -> Dictionary:
	return { "total": 0, "golds": 0, "sevens": [] }

# Chiamato da cursor.gd dopo ogni cattura riuscita.
# cards = combo.cards (carte sul board) + [held_card] (carta lanciata)
func register_capture(player_id: int, cards: Array[Dictionary]) -> void:
	var s: Dictionary = _round_stats[player_id]
	for card in cards:
		if CardUtils.is_neutral(card):
			continue
		s["total"] += 1
		if card["suit"] == CardUtils.Suit.GOLD:
			s["golds"] += 1
			if card["value"] == 7:
				_try_claim(player_id, PointType.FAIR_SEVEN)
		if card["value"] == 7 and card["suit"] != CardUtils.Suit.NEUTRAL:
			if not s["sevens"].has(card["suit"]):
				s["sevens"].append(card["suit"])
			if s["sevens"].size() >= SEVENS_TOTAL:
				_try_claim(player_id, PointType.ALL_SEVEN)
	if s["golds"] >= GOLD_THRESHOLD:
		_try_claim(player_id, PointType.GOLDS)
	if s["total"] >= QUOTA_THRESHOLD:
		_try_claim(player_id, PointType.QUOTA)

func register_exact_capture(player_id: int) -> void:
	_try_claim(player_id, PointType.EXACT_CAPTURE)

# Chiamato da board.gd quando la board è completamente svuotata
func register_sweep(player_id: int) -> void:
	_try_claim(player_id, PointType.SWEEP)

# Chiamato da board.gd quando la board del loser va in overflow
func register_reverse_sweep(loser_id: int) -> void:
	var player_id = 3 - loser_id
	_try_claim(player_id, PointType.REVERSE_SWEEP)

func get_points(player_id: int) -> int:
	return match_points.get(player_id, 0)

func _try_claim(player_id: int, point_type: PointType) -> void:
	#if _round_claimed.has(point_type):
		#if point_type == PointType.GOLDS or point_type == PointType.QUOTA:
			#var current_holder: int = _round_claimed[point_type]
			#if current_holder == player_id:
				#return
			#match_points[current_holder] -= 1
		#else:
			#return
	if _round_claimed.has(point_type) and not point_type == PointType.EXACT_CAPTURE:
		return
	_round_claimed[point_type] = player_id
	match_points[player_id] += 1
	point_scored.emit(player_id, point_type)
	$Score.text = str(get_points(1))
	$Score2.text = str(get_points(2))
	if match_points[player_id] >= MATCH_WIN_THRESHOLD:
		match_ended.emit(player_id)
