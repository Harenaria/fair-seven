extends Node2D
func get_suit_color(suit: int) -> Color:
	match suit:
		0:  return Color(1, 1, 0.0)   # giallo oro
		1:   return Color(1, 0, 0)    # rosso
		2: return Color(0, 0, 1)    # blu
		3:  return Color(0, 1, 0)    # verde
		-1:   return Color(1, 1, 1)    # grigio
	return Color.WHITE

# card.gd
var _pulsing: bool = false

func initialize_card(dict: Dictionary) -> void:
	if dict == {}:
		return
	var atlas: AtlasTexture = $Sprite2D.texture.duplicate()
	var suit = dict["suit"]
	atlas.region = Rect2(0, 16 * (suit + 1), 16, 16)
	$Sprite2D.texture = atlas
	$Sprite2D.modulate = get_suit_color(suit)
	$Highlight.texture = atlas
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://highlight.gdshader")
	mat.set_shader_parameter("highlight_color", Color.AQUA)
	$Highlight.material = mat
	$Highlight.visible = false
	$Label.text = str(dict["value"])

func start_pulse() -> void:
	if _pulsing:
		return
	_pulsing = true
	$Highlight.visible = PulseTimer.state
	PulseTimer.tick.connect(_on_tick)

func stop_pulse() -> void:
	if not _pulsing:
		return
	_pulsing = false
	PulseTimer.tick.disconnect(_on_tick)
	$Highlight.visible = false

func _on_tick(on: bool) -> void:
	$Highlight.visible = on

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
