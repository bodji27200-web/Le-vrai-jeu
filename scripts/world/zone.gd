## Zone explorable "en grand". On y entre depuis l'overworld : le décor est
## vaste, la caméra rapprochée suit le personnage à taille normale.
## Si la zone définit des rencontres (ContentLibrary.encounters_for_zone), on
## place un marqueur par rencontre (combats variés + boss) ; sinon, repli sur un
## unique marqueur de combat (rencontre de démo).
extends Node2D

const ZONE_BOUNDS := Rect2(-1400, -900, 2800, 1800)
const EXIT_POS := Vector2(-1250, 0)
const INTERACT_RADIUS := 110.0
const ENCOUNTER_RADIUS := 85.0
## Emplacements des marqueurs de rencontre (jusqu'à 4 + repli).
const ENCOUNTER_SPOTS := [Vector2(250, -320), Vector2(720, 120), Vector2(-150, 360), Vector2(980, -220)]

var _zone: ZoneData
var _player: PlayerAvatar
var _camera: Camera2D
var _near_exit := false
var _prompt: Label
var _battle_started := false
var _encounters: Array[EncounterData] = []
## [{ "pos": Vector2, "enc": EncounterData (ou null = démo) }]
var _enc_points: Array = []
## [{ "pos": Vector2, "ev": Dictionary }] — événements à choix (recrutement, secret).
var _event_points: Array = []


func _ready() -> void:
	_zone = Game.current_zone
	if _zone == null:
		_zone = ContentDB.zones()[0]   # zone par défaut si lancée seule
	_encounters = ContentLibrary.encounters_for_zone(_zone.id)
	_build_zone()
	_build_ui()
	_fade_in()


func _process(_delta: float) -> void:
	if _camera != null:
		_camera.position = _player.position
	_near_exit = _player.position.distance_to(EXIT_POS) < INTERACT_RADIUS
	_prompt.text = "▶ Entrée : revenir à la carte du monde" if _near_exit else ""

	if _battle_started:
		return
	for ep in _event_points:
		if _player.position.distance_to(ep.pos) < ENCOUNTER_RADIUS:
			_battle_started = true   # garde anti-double-déclenchement
			Game.start_event(ep.ev)
			return
	for pt in _enc_points:
		if _player.position.distance_to(pt.pos) < ENCOUNTER_RADIUS:
			_battle_started = true
			Game.pending_encounter = pt.enc
			Game.start_battle()
			return


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

	# Rencontres : une par marqueur si la zone est détaillée, sinon une seule.
	if not _encounters.is_empty():
		for i in _encounters.size():
			var enc := _encounters[i]
			var pos: Vector2 = ENCOUNTER_SPOTS[i] if i < ENCOUNTER_SPOTS.size() else Vector2(rng.randf_range(-800, 1000), rng.randf_range(-600, 600))
			var is_boss := not enc.enemies.is_empty() and enc.enemies[0].is_boss
			var col := Color(0.85, 0.4, 0.95) if is_boss else Color(0.9, 0.3, 0.32)
			var label := ("☠ " + enc.display_name) if is_boss else enc.display_name
			_add_marker(pos, col, label)
			_enc_points.append({"pos": pos, "enc": enc})
	elif _zone.has_encounter:
		var pos := Vector2(650, -250)
		_add_marker(pos, Color(0.9, 0.25, 0.3), "Ennemi !")
		_enc_points.append({"pos": pos, "enc": null})

	# Événements de la première zone (recrutement + secret), une seule fois chacun.
	if _zone.id == "clairiere":
		if not Game.has_event("foret_recrue"):
			var ep := Vector2(-420, -260)
			_add_marker(ep, Color(0.45, 0.85, 0.6), "Voyageur ?")
			_event_points.append({"pos": ep, "ev": ContentLibrary.forest_recruit_event()})
		if not Game.has_event("foret_secret"):
			# Recoin écarté : récompense la curiosité.
			var sp := Vector2(1120, 640)
			_add_marker(sp, Color(0.95, 0.88, 0.45), "✦")
			_event_points.append({"pos": sp, "ev": ContentLibrary.forest_secret_event()})

	# Joueur à taille normale.
	_player = PlayerAvatar.new()
	_player.speed = 420.0
	_player.bounds = ZONE_BOUNDS
	add_child(_player)
	_player.setup(Game.lead_sprite_kind(), Vector2(48, 66))
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
	lbl.position = Vector2(-90, 48)
	lbl.size = Vector2(180, 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

	if not _encounters.is_empty():
		var hint := Label.new()
		hint.text = "Approche-toi d'un groupe d'ennemis pour combattre. ☠ = boss."
		hint.add_theme_font_size_override("font_size", 15)
		hint.modulate = Color(1, 1, 1, 0.7)
		hint.position = Vector2(30, 92)
		layer.add_child(hint)

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
