extends Node

signal tick(on: bool)

var state: bool = false
var _timer: float = 0.0
const INTERVAL = 0.1

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= INTERVAL:
		_timer = 0.0
		state = !state
		tick.emit(state)
