## Zone explorable "en grand", vue ISOMÉTRIQUE (sol en dalles + décor en
## profondeur). La caméra suit le personnage. La zone peut définir des rencontres
## (combats variés + boss) et des événements à choix (recrutement, secret).
extends Node2D

const ZONE_BOUNDS := Rect2(-1400, -900, 2800, 1800)
const EXIT_POS := Vector2(-1180, 0)
const INTERACT_RADIUS := 120.0
const ENCOUNTER_RADIUS := 90.0
const ENCOUNTER_SPOTS := [Vector2(250, -300), Vector2(700, 160), Vector2(-120, 380), Vector2(1000, -200)]

var _zone: ZoneData
var _player: PlayerAvatar
var _camera: Camera2D
var _world: Node2D                  ## Décor + marqueurs + joueur, triés en profondeur.
var _near_exit := false
var _prompt: Label
var _battle_started := false
var _encounters: Array[EncounterData] = []
var _enc_points: Array = []          ## [{ pos, enc }]
var _event_points: Array = []        ## [{ pos, ev }]


func _ready() -> void:
	_zone = Game.current_zone
	if _zone == null:
		_zone = ContentDB.zones()[0]
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
			_battle_started = true
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
	var theme: Color = _zone.theme_color

	# Sol isométrique + fond (derrière tout).
	var stage := WorldStage.new()
	stage.bounds = ZONE_BOUNDS
	stage.ground = theme
	stage.sky_top = theme.darkened(0.72)
	stage.sun = Color(0.85, 0.95, 0.7)            # lumière filtrée par la canopée
	stage.sun_at = Vector2(0.32, 0.14)
	add_child(stage)

	# Teinte ambiante : sous-bois frais et vert.
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.82, 0.92, 0.86)
	add_child(ambient)

	# Conteneur trié en profondeur.
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)

	var spawn := Vector2(-1000, 0)
	var clear: Array[Vector2] = [EXIT_POS, spawn]

	# Sortie.
	_add_marker(EXIT_POS, Color(0.5, 0.8, 1.0), "Sortie")

	# Rencontres (un marqueur chacune).
	if not _encounters.is_empty():
		for i in _encounters.size():
			var enc := _encounters[i]
			var pos: Vector2 = ENCOUNTER_SPOTS[i] if i < ENCOUNTER_SPOTS.size() else Vector2(0, 0)
			clear.append(pos)
			var is_boss := not enc.enemies.is_empty() and enc.enemies[0].is_boss
			var col := Color(0.9, 0.4, 0.95) if is_boss else Color(0.92, 0.32, 0.32)
			_add_marker(pos, col, ("☠ " + enc.display_name) if is_boss else enc.display_name)
			_enc_points.append({"pos": pos, "enc": enc})
	elif _zone.has_encounter:
		var pos := Vector2(650, -250)
		clear.append(pos)
		_add_marker(pos, Color(0.9, 0.25, 0.3), "Ennemi !")
		_enc_points.append({"pos": pos, "enc": null})

	# Événements de la forêt (une fois chacun).
	if _zone.id == "clairiere":
		if not Game.has_event("foret_recrue"):
			var pp := Vector2(-380, -260)
			clear.append(pp)
			_add_marker(pp, Color(0.45, 0.85, 0.6), "Voyageur ?")
			_event_points.append({"pos": pp, "ev": ContentLibrary.forest_recruit_event()})
		if not Game.has_event("foret_secret"):
			var sp := Vector2(1150, 660)
			clear.append(sp)
			_add_marker(sp, Color(0.95, 0.88, 0.45), "✦")
			_event_points.append({"pos": sp, "ev": ContentLibrary.forest_secret_event()})

	# Décor forestier dense, en évitant les marqueurs et le spawn.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_zone.id)
	var count := 80
	for i in count:
		var p := Vector2(
			rng.randf_range(ZONE_BOUNDS.position.x + 90, ZONE_BOUNDS.end.x - 90),
			rng.randf_range(ZONE_BOUNDS.position.y + 90, ZONE_BOUNDS.end.y - 90))
		var ok := true
		for cp in clear:
			if p.distance_to(cp) < 180.0:
				ok = false
				break
		if not ok:
			continue
		var sc := rng.randf_range(0.8, 1.35)
		var roll := rng.randf()
		var deco: Node2D
		if roll < 0.42:
			deco = WorldStage.tree(sc, theme.lightened(0.12))
		elif roll < 0.66:
			deco = WorldStage.pine(sc)
		elif roll < 0.80:
			deco = WorldStage.bush(sc, theme.lightened(0.16))
		elif roll < 0.90:
			deco = WorldStage.grass(rng.randf_range(0.9, 1.6), theme.lightened(0.22))
		elif roll < 0.96:
			deco = WorldStage.flower(rng.randf_range(0.8, 1.3),
				[Color(0.95, 0.85, 0.4), Color(0.85, 0.5, 0.8), Color(0.9, 0.95, 0.95)][rng.randi() % 3])
		else:
			deco = WorldStage.rock(sc)
		deco.position = p
		_world.add_child(deco)

	# Lucioles / spores flottantes (ambiance forestière), au-dessus du décor.
	var motes := WorldStage.ambiance(60, Color(0.85, 1.0, 0.7, 0.9),
		Vector2(ZONE_BOUNDS.size.x * 0.5, ZONE_BOUNDS.size.y * 0.5), -10.0, 6.0)
	motes.position = ZONE_BOUNDS.position + ZONE_BOUNDS.size * 0.5
	add_child(motes)

	# Joueur (au-dessus du sol, trié avec le décor).
	_player = PlayerAvatar.new()
	_player.speed = 430.0
	_player.bounds = ZONE_BOUNDS
	_world.add_child(_player)
	_player.setup(Game.lead_sprite_kind(), Vector2(48, 66))
	_player.position = spawn

	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.15, 1.15)
	add_child(_camera)
	_camera.make_current()


func _add_marker(pos: Vector2, color: Color, label: String) -> void:
	var node := Node2D.new()
	node.position = pos
	_world.add_child(node)
	# Halo lumineux au sol (additif) pour un repère qui "rayonne".
	var halo := WorldStage.glow(Color(color.r, color.g, color.b, 0.7), 90.0)
	halo.position = Vector2(0, -8)
	node.add_child(halo)
	# Halo au sol + pilier lumineux (lisible en iso).
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([Vector2(0, -16), Vector2(34, 0), Vector2(0, 16), Vector2(-34, 0)])
	ring.color = Color(color.r, color.g, color.b, 0.85)
	node.add_child(ring)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(6, -60), Vector2(-6, -60)])
	beam.color = Color(color.r, color.g, color.b, 0.35)
	node.add_child(beam)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-90, -90)
	lbl.size = Vector2(180, 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(lbl)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# Vignette (assombrit les bords) — posée en premier pour rester sous le texte.
	layer.add_child(WorldStage.vignette(0.5))
	var title := Label.new()
	title.text = _zone.display_name
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	title.position = Vector2(30, 24)
	layer.add_child(title)
	var desc := Label.new()
	desc.text = _zone.description
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_outline_color", Color.BLACK)
	desc.add_theme_constant_override("outline_size", 4)
	desc.position = Vector2(30, 64)
	layer.add_child(desc)
	if not _encounters.is_empty():
		var hint := Label.new()
		hint.text = "Approche un groupe d'ennemis pour combattre. ☠ = boss · ✦ = secret."
		hint.add_theme_font_size_override("font_size", 15)
		hint.modulate = Color(1, 1, 1, 0.8)
		hint.position = Vector2(30, 92)
		layer.add_child(hint)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 5)
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
