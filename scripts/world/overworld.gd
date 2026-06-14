## Carte du monde (overworld) façon Expédition 33 : le personnage est minuscule,
## toutes les zones sont visibles en miniature. Entrer dans une zone la charge
## "en grand" (scene zone.tscn via le routeur Game).
extends Node2D

const ENTER_RADIUS := 95.0
const MAP_BOUNDS := Rect2(-880, -480, 1760, 960)

var _player: PlayerAvatar
var _zones: Array[ZoneData] = []
var _zone_nodes := {}            ## ZoneData -> Node2D
var _near: ZoneData = null
var _prompt: Label


func _ready() -> void:
	_zones = ContentDB.zones()
	_build_world()
	_build_ui()
	_fade_in()


func _process(_delta: float) -> void:
	_update_nearest_zone()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Menu / écran-titre.
		if event.keycode == KEY_ESCAPE:
			Game.goto_title()
			return
		# Composition d'équipe : accessible depuis n'importe où sur la carte.
		if event.keycode == KEY_P:
			Game.menu_origin = "overworld"
			Game.goto_party_select()
			return
		if _near != null and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			Game.enter_zone(_near)


func _build_world() -> void:
	# Fond de carte : dégradé vertical (atmosphère, plutôt qu'un aplat).
	var top := Color(0.09, 0.11, 0.18)
	var bot := Color(0.17, 0.21, 0.25)
	var bands := 28
	for i in bands:
		var band := Polygon2D.new()
		var y0 := MAP_BOUNDS.position.y + MAP_BOUNDS.size.y * float(i) / bands
		var h := MAP_BOUNDS.size.y / bands + 1.0
		band.polygon = PackedVector2Array([
			Vector2(MAP_BOUNDS.position.x, y0), Vector2(MAP_BOUNDS.end.x, y0),
			Vector2(MAP_BOUNDS.end.x, y0 + h), Vector2(MAP_BOUNDS.position.x, y0 + h)])
		band.color = top.lerp(bot, float(i) / float(bands - 1))
		add_child(band)

	# Chemin reliant les lieux de la région (le hameau et la forêt).
	if _zones.size() >= 2:
		var path := Line2D.new()
		for z in _zones:
			path.add_point(z.overworld_position)
		path.width = 7.0
		path.default_color = Color(0.55, 0.5, 0.38, 0.45)
		add_child(path)

	# Zones en miniature, avec halo lumineux.
	for z in _zones:
		var node := Node2D.new()
		node.position = z.overworld_position
		add_child(node)

		var halo := WorldStage.glow(Color(z.theme_color.r, z.theme_color.g, z.theme_color.b, 0.55), 130.0)
		node.add_child(halo)

		var island := Polygon2D.new()
		island.polygon = PackedVector2Array([
			Vector2(-72, -52), Vector2(72, -52), Vector2(88, 0),
			Vector2(72, 56), Vector2(-72, 56), Vector2(-88, 0),
		])
		island.color = z.theme_color.darkened(0.1)
		node.add_child(island)
		# Reflet supérieur (volume).
		var topface := Polygon2D.new()
		topface.polygon = PackedVector2Array([
			Vector2(-72, -52), Vector2(72, -52), Vector2(60, -20), Vector2(-60, -20)])
		topface.color = z.theme_color.lightened(0.12)
		node.add_child(topface)
		var edge := Line2D.new()
		edge.points = PackedVector2Array([
			Vector2(-72, -52), Vector2(72, -52), Vector2(88, 0),
			Vector2(72, 56), Vector2(-72, 56), Vector2(-88, 0), Vector2(-72, -52)])
		edge.width = 2.0
		edge.default_color = z.theme_color.darkened(0.4)
		node.add_child(edge)

		var name_lbl := Label.new()
		name_lbl.text = z.display_name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		name_lbl.add_theme_constant_override("outline_size", 5)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(-90, 60)
		name_lbl.size = Vector2(180, 22)
		node.add_child(name_lbl)

		_zone_nodes[z] = node

	# Joueur minuscule.
	_player = PlayerAvatar.new()
	_player.speed = 300.0
	_player.bounds = MAP_BOUNDS
	add_child(_player)
	_player.setup(Game.lead_sprite_kind(), Vector2(20, 28))
	_player.position = Vector2(0, 60)

	# Caméra fixe dézoomée : on voit tout le monde.
	var cam := Camera2D.new()
	cam.zoom = Vector2(0.7, 0.7)
	add_child(cam)
	cam.make_current()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var title := Label.new()
	title.text = "Carte du Monde"
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(30, 24)
	layer.add_child(title)

	var help := Label.new()
	help.text = "Flèches / ZQSD : se déplacer    ·    P : équipe    ·    Échap : menu"
	help.add_theme_font_size_override("font_size", 16)
	help.position = Vector2(30, 64)
	layer.add_child(help)

	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", 22)
	_prompt.position = Vector2(360, 590)
	layer.add_child(_prompt)


func _update_nearest_zone() -> void:
	var best: ZoneData = null
	var best_d := ENTER_RADIUS
	for z in _zones:
		var d := _player.position.distance_to(z.overworld_position)
		if d < best_d:
			best_d = d
			best = z
	_near = best
	if _near != null:
		_prompt.text = "▶ Entrée : explorer « %s »" % _near.display_name
	else:
		_prompt.text = ""


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
