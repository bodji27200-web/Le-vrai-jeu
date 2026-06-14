## Village-hub habité. Reprend la mécanique d'exploration des zones (décor vaste,
## caméra qui suit), mais peuplé de PNJ avec qui INTERAGIR :
##  - dialogues (le PNJ "vit" : léger balancement idle, une activité),
##  - le forgeron ouvre l'écran d'équipement,
##  - une sortie ramène à l'overworld.
## Pas de combat ici : c'est le refuge.
extends Node2D

const ZONE_BOUNDS := Rect2(-1100, -700, 2200, 1400)
const EXIT_POS := Vector2(-950, 0)
const INTERACT_RADIUS := 130.0

var _zone: ZoneData
var _player: PlayerAvatar
var _camera: Camera2D
var _prompt: Label
var _dialogue: Label

## PNJ du village. action ∈ "dialogue" | "forge".
var _npcs := [
	{
		"name": "Maugrim, l'aubergiste",
		"pos": Vector2(-250, -120), "color": Color(0.80, 0.55, 0.35), "action": "dialogue",
		"lines": [
			"Bienvenue à l'auberge, voyageur. Pose tes armes un instant.",
			"On raconte que les morts s'agitent dans le Marais d'Ombre…",
			"Une chope ? Ah, tu as du pain sur la planche d'abord.",
		], "i": 0,
	},
	{
		"name": "Brontë, la forgeronne",
		"pos": Vector2(150, -90), "color": Color(0.7, 0.4, 0.3), "action": "forge",
		"lines": ["Besoin d'équiper ton groupe ? Montre-moi ce que tu as ramassé."],
		"i": 0,
	},
	{
		"name": "Selene, la marchande",
		"pos": Vector2(60, 160), "color": Color(0.45, 0.6, 0.8), "action": "shop",
		"lines": ["Or en poche ? J'ai justement quelques lames de qualité…"],
		"i": 0,
	},
	{
		"name": "Un ivrogne avachi",
		"pos": Vector2(-180, 120), "color": Color(0.6, 0.5, 0.45), "action": "dialogue",
		"lines": [
			"*hips* … le dragon… il était GRAND comme ça… *ronfle*",
			"Laisse-moi… encore cinq minutes…",
		], "i": 0,
	},
	{
		"name": "Vieux Cadoc",
		"pos": Vector2(350, 60), "color": Color(0.55, 0.55, 0.6), "action": "dialogue",
		"lines": [
			"Plus tu combats, plus tu apprends. La force vient avec le temps.",
			"Au niveau 5, un héros trouve sa voie — sa spécialisation.",
		], "i": 0,
	},
]
var _near_npc: Dictionary = {}
var _near_exit := false


func _ready() -> void:
	_zone = Game.current_zone
	_build_village()
	_build_ui()
	_fade_in()


func _process(_delta: float) -> void:
	if _camera != null:
		_camera.position = _player.position
	_update_nearest()


func _update_nearest() -> void:
	_near_exit = _player.position.distance_to(EXIT_POS) < INTERACT_RADIUS
	_near_npc = {}
	if not _near_exit:
		var best := INTERACT_RADIUS
		for npc in _npcs:
			var d := _player.position.distance_to(npc.pos)
			if d < best:
				best = d
				_near_npc = npc
	if _near_exit:
		_prompt.text = "▶ Entrée : revenir à la carte du monde"
	elif not _near_npc.is_empty():
		var verb := "parler"
		if _near_npc.action == "forge":
			verb = "ouvrir l'équipement (forge)"
		elif _near_npc.action == "shop":
			verb = "ouvrir la boutique"
		_prompt.text = "▶ Entrée : %s — %s" % [verb, _near_npc.name]
	else:
		_prompt.text = ""
		_dialogue.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode not in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
		return
	if _near_exit:
		Game.goto_overworld()
	elif not _near_npc.is_empty():
		match _near_npc.action:
			"forge":
				Game.goto_party_select()
			"shop":
				Game.goto_shop()
			_:
				var lines: Array = _near_npc.lines
				_dialogue.text = "%s : « %s »" % [_near_npc.name, lines[_near_npc.i % lines.size()]]
				_near_npc.i += 1


# =============================================================================
# Construction
# =============================================================================

func _build_village() -> void:
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([
		ZONE_BOUNDS.position,
		ZONE_BOUNDS.position + Vector2(ZONE_BOUNDS.size.x, 0),
		ZONE_BOUNDS.position + ZONE_BOUNDS.size,
		ZONE_BOUNDS.position + Vector2(0, ZONE_BOUNDS.size.y),
	])
	var base_col: Color = _zone.theme_color if _zone != null else Color(0.5, 0.45, 0.35)
	ground.color = base_col.darkened(0.4)
	add_child(ground)

	# Sentier central + quelques maisons (placeholders évocateurs).
	var path := Polygon2D.new()
	path.polygon = PackedVector2Array([Vector2(-950, 40), Vector2(450, 10), Vector2(450, 70), Vector2(-950, 100)])
	path.color = base_col.lightened(0.1)
	add_child(path)
	for h in [Vector2(-300, -220), Vector2(120, -200), Vector2(360, -40), Vector2(-120, 230), Vector2(260, 200)]:
		_add_house(h, base_col)

	# Sortie.
	_add_marker(EXIT_POS, Color(0.5, 0.8, 1.0), "Sortie")

	# PNJ (avec balancement idle = ils "vivent").
	for npc in _npcs:
		_add_npc(npc)

	# Joueur (sprite du meneur).
	_player = PlayerAvatar.new()
	_player.speed = 380.0
	_player.bounds = ZONE_BOUNDS
	add_child(_player)
	_player.setup(Game.lead_sprite_kind(), Vector2(44, 60))
	_player.position = Vector2(-820, 40)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.3, 1.3)
	add_child(_camera)
	_camera.make_current()


func _add_house(pos: Vector2, col: Color) -> void:
	var node := Node2D.new()
	node.position = pos
	add_child(node)
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([Vector2(-70, -50), Vector2(70, -50), Vector2(70, 60), Vector2(-70, 60)])
	wall.color = col.lightened(0.05)
	node.add_child(wall)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-85, -50), Vector2(0, -110), Vector2(85, -50)])
	roof.color = col.darkened(0.45)
	node.add_child(roof)


func _add_npc(npc: Dictionary) -> void:
	var node := Node2D.new()
	node.position = npc.pos
	add_child(node)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-12, -34), Vector2(12, -34), Vector2(14, 6), Vector2(-14, 6)])
	body.color = npc.color
	node.add_child(body)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(-9, -52), Vector2(9, -52), Vector2(9, -34), Vector2(-9, -34)])
	head.color = Color(0.95, 0.82, 0.68)
	node.add_child(head)
	var lbl := Label.new()
	lbl.text = npc.name
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-70, -84)
	lbl.size = Vector2(140, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(lbl)
	# Balancement idle : le PNJ respire/oscille (pas une statue).
	var t := create_tween().set_loops()
	var dur := 1.2 + randf() * 0.8
	t.tween_property(body, "position:y", -3.0, dur).set_trans(Tween.TRANS_SINE)
	t.tween_property(body, "position:y", 0.0, dur).set_trans(Tween.TRANS_SINE)


func _add_marker(pos: Vector2, color: Color, label: String) -> void:
	var node := Node2D.new()
	node.position = pos
	add_child(node)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([Vector2(0, -45), Vector2(40, 0), Vector2(0, 45), Vector2(-40, 0)])
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
	title.text = _zone.display_name if _zone != null else "Village"
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(30, 24)
	layer.add_child(title)

	var help := Label.new()
	help.text = "Flèches / ZQSD : se déplacer · Entrée : interagir"
	help.add_theme_font_size_override("font_size", 16)
	help.position = Vector2(30, 64)
	layer.add_child(help)

	_dialogue = Label.new()
	_dialogue.add_theme_font_size_override("font_size", 20)
	_dialogue.add_theme_color_override("font_outline_color", Color.BLACK)
	_dialogue.add_theme_constant_override("outline_size", 5)
	_dialogue.position = Vector2(60, 520)
	_dialogue.size = Vector2(1030, 60)
	_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_dialogue)

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
