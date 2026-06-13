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
	_zones = WorldLibrary.zones()
	_build_world()
	_build_ui()
	_fade_in()


func _process(_delta: float) -> void:
	_update_nearest_zone()


func _unhandled_input(event: InputEvent) -> void:
	if _near == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			Game.enter_zone(_near)


func _build_world() -> void:
	# Fond de carte.
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		MAP_BOUNDS.position,
		MAP_BOUNDS.position + Vector2(MAP_BOUNDS.size.x, 0),
		MAP_BOUNDS.position + MAP_BOUNDS.size,
		MAP_BOUNDS.position + Vector2(0, MAP_BOUNDS.size.y),
	])
	bg.color = Color(0.16, 0.18, 0.24)
	add_child(bg)

	# Zones en miniature.
	for z in _zones:
		var node := Node2D.new()
		node.position = z.overworld_position
		add_child(node)

		var island := Polygon2D.new()
		island.polygon = PackedVector2Array([
			Vector2(-70, -50), Vector2(70, -50), Vector2(85, 0),
			Vector2(70, 55), Vector2(-70, 55), Vector2(-85, 0),
		])
		island.color = z.theme_color
		node.add_child(island)

		var name_lbl := Label.new()
		name_lbl.text = z.display_name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		name_lbl.add_theme_constant_override("outline_size", 5)
		name_lbl.position = Vector2(-80, 58)
		node.add_child(name_lbl)

		_zone_nodes[z] = node

	# Joueur minuscule.
	_player = PlayerAvatar.new()
	_player.speed = 300.0
	_player.bounds = MAP_BOUNDS
	add_child(_player)
	_player.setup("gardien", Vector2(20, 28))
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
	help.text = "Flèches / ZQSD : se déplacer"
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
