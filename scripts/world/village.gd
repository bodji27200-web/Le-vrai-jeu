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
var _world: Node2D                  ## Décor + PNJ + joueur, triés en profondeur.
var _prompt: Label
var _dialogue: Label

## PNJ du village. action ∈ "dialogue" | "forge".
var _npcs := [
	{
		"name": "Maugrim, l'aubergiste",
		"pos": Vector2(-250, -120), "color": Color(0.80, 0.55, 0.35), "action": "dialogue", "sprite": "pnj_aubergiste",
		"lines": [
			"Bienvenue à l'auberge, voyageur. Pose tes armes un instant.",
			"On raconte que des bandits rôdent dans la Clairière, à l'ouest…",
			"Une chope ? Ah, tu as du pain sur la planche d'abord.",
		], "i": 0,
	},
	{
		"name": "Brontë, la forgeronne",
		"pos": Vector2(150, -90), "color": Color(0.7, 0.4, 0.3), "action": "forge", "sprite": "pnj_forgeronne",
		"lines": ["Besoin d'équiper ton groupe ? Montre-moi ce que tu as ramassé."],
		"i": 0,
	},
	{
		"name": "Selene, la marchande",
		"pos": Vector2(60, 160), "color": Color(0.45, 0.6, 0.8), "action": "shop", "sprite": "pnj_marchande",
		"lines": ["Or en poche ? J'ai justement quelques lames de qualité…"],
		"i": 0,
	},
	{
		"name": "Un ivrogne avachi",
		"pos": Vector2(-180, 120), "color": Color(0.6, 0.5, 0.45), "action": "dialogue", "sprite": "pnj_ivrogne",
		"lines": [
			"*hips* … le dragon… il était GRAND comme ça… *ronfle*",
			"Laisse-moi… encore cinq minutes…",
		], "i": 0,
	},
	{
		"name": "Vieux Cadoc",
		"pos": Vector2(350, 60), "color": Color(0.55, 0.55, 0.6), "action": "dialogue", "sprite": "pnj_ancien",
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
	var base_col: Color = _zone.theme_color if _zone != null else Color(0.62, 0.5, 0.34)

	# Sol isométrique (terre/herbe du hameau) + fond, lumière chaude de fin de jour.
	var stage := WorldStage.new()
	stage.bounds = ZONE_BOUNDS
	stage.ground = base_col.darkened(0.05)
	stage.sky_top = Color(0.20, 0.15, 0.18)
	stage.sun = Color(1.0, 0.74, 0.42)            # soleil couchant
	stage.sun_at = Vector2(0.7, 0.18)
	add_child(stage)

	# Teinte ambiante : crépuscule doré et chaleureux.
	var ambient := CanvasModulate.new()
	ambient.color = Color(1.0, 0.88, 0.74)
	add_child(ambient)

	# Conteneur trié en profondeur.
	_world = Node2D.new()
	_world.y_sort_enabled = true
	add_child(_world)

	# Maisons en bois + la taverne (fenêtres chaudes), placées autour de la place.
	var homes := [Vector2(-330, -210), Vector2(140, -230), Vector2(380, -60), Vector2(-150, 250)]
	for h in homes:
		var house := WorldStage.house(1.0, base_col.lightened(0.04), false)
		house.position = h
		_world.add_child(house)
	# La taverne (plus grande, fenêtres allumées) près de l'aubergiste.
	var tavern := WorldStage.house(1.35, Color(0.5, 0.34, 0.22), true)
	tavern.position = Vector2(-250, -40)
	_world.add_child(tavern)
	# Halos chauds aux fenêtres de la taverne + braises montantes (cheminée).
	for off in [Vector2(-60, -110), Vector2(36, -110)]:
		var win := WorldStage.glow(Color(1.0, 0.7, 0.3, 0.9), 70.0)
		win.position = tavern.position + off
		add_child(win)
	var embers := WorldStage.ambiance(26, Color(1.0, 0.6, 0.25, 0.9), Vector2(60, 30), -28.0, 3.2)
	embers.position = tavern.position + Vector2(0, -150)
	add_child(embers)
	# Un peu de verdure pour habiller.
	for b in [Vector2(-520, 120), Vector2(470, 150), Vector2(60, 320), Vector2(-420, -300)]:
		var bush := WorldStage.bush(1.1, base_col.lightened(0.2))
		bush.position = b
		_world.add_child(bush)
	for g in [Vector2(-600, 40), Vector2(520, -40), Vector2(-80, 360), Vector2(300, 280), Vector2(-360, 320)]:
		var tuft := WorldStage.grass(1.2, base_col.lightened(0.28))
		tuft.position = g
		_world.add_child(tuft)

	# Sortie.
	_add_marker(EXIT_POS, Color(0.5, 0.8, 1.0), "Sortie")

	# PNJ (avec balancement idle = ils "vivent").
	for npc in _npcs:
		_add_npc(npc)

	# Joueur (sprite du meneur).
	_player = PlayerAvatar.new()
	_player.speed = 380.0
	_player.bounds = ZONE_BOUNDS
	_world.add_child(_player)
	_player.setup(Game.lead_sprite_kind(), Vector2(44, 60))
	_player.position = Vector2(-820, 40)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.2, 1.2)
	add_child(_camera)
	_camera.make_current()


func _add_npc(npc: Dictionary) -> void:
	var node := Node2D.new()
	node.position = npc.pos
	_world.add_child(node)
	node.add_child(WorldStage._shadow(24, 9))
	# Vrai sprite pixel art (pieds au sol). Conteneur animé pour le balancement idle.
	var body := Node2D.new()
	node.add_child(body)
	var spr := Sprite2D.new()
	spr.texture = PixelArt.for_unit(npc.get("sprite", ""))
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var size := Vector2(46, 62)
	var sc := size.y / float(spr.texture.get_height())
	spr.scale = Vector2(sc, sc)
	spr.position = Vector2(0, -size.y * 0.5)   # pieds à l'origine (tri en profondeur)
	body.add_child(spr)
	var lbl := Label.new()
	lbl.text = npc.name
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-70, -86)
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
	_world.add_child(node)
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
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.position = Vector2(-50, -86)
	lbl.size = Vector2(100, 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_child(lbl)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	# Vignette douce (sous le texte).
	layer.add_child(WorldStage.vignette(0.45))

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
