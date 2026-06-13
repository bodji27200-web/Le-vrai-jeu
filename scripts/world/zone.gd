## Zone explorable "en grand". On y entre depuis l'overworld : le décor est
## vaste, la caméra rapprochée suit le personnage à taille normale.
## Contient une sortie (retour overworld) et, éventuellement, un combat.
extends Node2D

const ZONE_BOUNDS := Rect2(-1400, -900, 2800, 1800)
const EXIT_POS := Vector2(-1250, 0)
const ENCOUNTER_POS := Vector2(650, -250)
const INTERACT_RADIUS := 110.0
const ENCOUNTER_RADIUS := 80.0

var _zone: ZoneData
var _player: PlayerAvatar
var _camera: Camera2D
var _near_exit := false
var _prompt: Label
var _battle_started := false


func _ready() -> void:
	_zone = Game.current_zone
	if _zone == null:
		_zone = ContentDB.zones()[0]   # zone par défaut si lancée seule
	_build_zone()
	_build_ui()
	_fade_in()


func _process(_delta: float) -> void:
	if _camera != null:
		_camera.position = _player.position
	_near_exit = _player.position.distance_to(EXIT_POS) < INTERACT_RADIUS
	_prompt.text = "▶ Entrée : revenir à la carte du monde" if _near_exit else ""

	if _zone.has_encounter and not _battle_started:
		if _player.position.distance_to(ENCOUNTER_POS) < ENCOUNTER_RADIUS:
			_battle_started = true
			Game.start_battle()


func _unhandled_input(event: InputEvent) -> void:
	if not _near_exit:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			Game.goto_overworld()


func _build_zone() -> void:
	# Sol vaste, teinté selon l'identité de la zone.
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([
		ZONE_BOUNDS.position,
		ZONE_BOUNDS.position + Vector2(ZONE_BOUNDS.size.x, 0),
		ZONE_BOUNDS.position + ZONE_BOUNDS.size,
		ZONE_BOUNDS.position + Vector2(0, ZONE_BOUNDS.size.y),
	])
	ground.color = _zone.theme_color.darkened(0.35)
	add_child(ground)

	# Décor dispersé (placeholders) pour donner du relief.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_zone.id)
	for i in 40:
		var deco := Polygon2D.new()
		var s := rng.randf_range(30.0, 80.0)
		deco.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s),
		])
		deco.color = _zone.theme_color.lightened(0.1) if i % 2 == 0 else _zone.theme_color.darkened(0.5)
		deco.position = Vector2(
			rng.randf_range(ZONE_BOUNDS.position.x + 100, ZONE_BOUNDS.end.x - 100),
			rng.randf_range(ZONE_BOUNDS.position.y + 100, ZONE_BOUNDS.end.y - 100))
		deco.rotation = rng.randf_range(0.0, TAU)
		add_child(deco)

	# Portail de sortie.
	_add_marker(EXIT_POS, Color(0.5, 0.8, 1.0), "Sortie")

	# Marqueur de combat.
	if _zone.has_encounter:
		_add_marker(ENCOUNTER_POS, Color(0.9, 0.25, 0.3), "Ennemi !")

	# Joueur à taille normale.
	_player = PlayerAvatar.new()
	_player.speed = 420.0
	_player.bounds = ZONE_BOUNDS
	add_child(_player)
	_player.setup("gardien", Vector2(48, 66))
	_player.position = Vector2(-900, 0)

	# Caméra rapprochée qui suit : le décor paraît immense.
	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.35, 1.35)
	add_child(_camera)
	_camera.make_current()


func _add_marker(pos: Vector2, color: Color, label: String) -> void:
	var node := Node2D.new()
	node.position = pos
	add_child(node)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([
		Vector2(0, -45), Vector2(40, 0), Vector2(0, 45), Vector2(-40, 0),
	])
	ring.color = color
	node.add_child(ring)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-40, 48)
	node.add_child(lbl)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.text = _zone.display_name
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(30, 24)
	layer.add_child(title)

	var desc := Label.new()
	desc.text = _zone.description
	desc.add_theme_font_size_override("font_size", 16)
	desc.position = Vector2(30, 64)
	layer.add_child(desc)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.position = Vector2(330, 590)
	layer.add_child(_prompt)


func _fade_in() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.size = get_viewport_rect().size
	layer.add_child(rect)
	var t := create_tween()
	t.tween_property(rect, "color:a", 0.0, 0.4)
	t.tween_callback(layer.queue_free)
