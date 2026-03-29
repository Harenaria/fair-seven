class_name CaptureResolver

class CaptureCombo:
	var cards: Array[Dictionary]
	var positions: Array[Vector2i]
	var priority: int

	func _init(c: Array[Dictionary], p: Array[Vector2i], pr: int) -> void:
		cards = c
		positions = p
		priority = pr

const PRIORITY = { "touched": 8, "up": 4, "left": 2, "right": 1 }

static func resolve(launched_value: int, col: int, board: Board) -> Array[CaptureCombo]:
	var candidates = _get_candidates(col, board)
	if candidates["touched"] == null:
		return []
	if launched_value == 11:
		return [CaptureCombo.new(
			[candidates["touched"]["card"]],
			[candidates["touched"]["pos"]],
			PRIORITY["touched"]
		)]
	var combos: Array[CaptureCombo] = []
	var optional_keys = ["up", "left", "right"]

	for mask in range(8):
		var combo_cards: Array[Dictionary] = [candidates["touched"]["card"]]
		var combo_positions: Array[Vector2i] = [candidates["touched"]["pos"]]
		var priority_score = PRIORITY["touched"]

		for i in range(3):
			if mask & (1 << i):
				var key = optional_keys[i]
				if candidates[key] == null:
					combo_cards = []  # sottoinsieme non valido
					break
				combo_cards.append(candidates[key]["card"])
				combo_positions.append(candidates[key]["pos"])
				priority_score += PRIORITY[key]

		if combo_cards.is_empty():
			continue

		var sum = combo_cards.reduce(func(acc, c): return acc + c["value"], 0)
		if sum == launched_value:
			combos.append(CaptureCombo.new(combo_cards, combo_positions, priority_score))
	combos.sort_custom(func(a, b): return a.priority > b.priority)
	return combos

static func _get_candidates(col: int, board: Board) -> Dictionary:
	var result = { "touched": null, "up": null, "left": null, "right": null }

	var top_row = board.get_column_height(col) - 1
	if top_row < 0:
		return result

	result["touched"] = {
		"card": board.board[col][top_row],
		"pos": Vector2i(col, top_row)
	}

	# Up: la carta sotto la touched nella stessa colonna
	if top_row >= 1:
		result["up"] = {
			"card": board.board[col][top_row - 1],
			"pos": Vector2i(col, top_row - 1)
		}

	# Left: esiste una carta nella colonna sinistra ALLA STESSA RIGA di touched
	if col > 0 and board.get_column_height(col - 1) > top_row:
		result["left"] = {
			"card": board.board[col - 1][top_row],
			"pos": Vector2i(col - 1, top_row)
		}

	# Right: esiste una carta nella colonna destra ALLA STESSA RIGA di touched
	if col < board.COLUMNS - 1 and board.get_column_height(col + 1) > top_row:
		result["right"] = {
			"card": board.board[col + 1][top_row],
			"pos": Vector2i(col + 1, top_row)
		}
	return result
	

static func has_any_capture(board: Board) -> bool:
	for pick_col in range(board.COLUMNS):
		if board.board[pick_col].is_empty():
			continue
		var picked: Dictionary = board.board[pick_col].pop_back()
		for target_col in range(board.COLUMNS):
			var combos = resolve(picked["value"], target_col, board)
			if combos.size() > 0:
				board.board[pick_col].append(picked)  # ripristina
				return true
		board.board[pick_col].append(picked)
	return false
