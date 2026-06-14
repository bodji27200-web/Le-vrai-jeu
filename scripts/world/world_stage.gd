## Rendu du monde en exploration : un sol ISOMÉTRIQUE (dalles en losange) + un
## fond dégradé, dessinés par code. Fournit aussi des constructeurs de DÉCOR
## (arbres, maisons, rochers…) en Node2D — origine aux PIEDS pour le tri en
## profondeur (y-sort). But : remplacer le "terrain vert plat" par une vraie
## scène isométrique lisible.
class_name WorldStage
extends Node2D

var bounds: Rect2 = Rect2(-1400, -900, 2800, 1800)
var ground: Color = Color(0.30, 0.45, 0.30)
var sky_top: Color = Color(0.10, 0.12, 0.18)
var tile: Vector2 = Vector2(128, 64)


func _draw() -> void:
	# Fond : dégradé vertical (ambiance) couvrant largement la zone.
	var r := bounds.grow(600)
	var bands := 40
	var bot := ground.darkened(0.35)
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * float(i) / bands, r.size.x, r.size.y / bands + 1.0),
			sky_top.lerp(bot, t))

	# Sol isométrique : dalles en losange sur une grille décalée (effet iso).
	var hx := tile.x * 0.5
	var hy := tile.y * 0.5
	var cols := int(bounds.size.x / tile.x) + 4
	var rows := int(bounds.size.y / hy) + 4
	for row in range(rows):
		for col in range(cols):
			var cx := bounds.position.x + col * tile.x + (hx if row % 2 == 1 else 0.0)
			var cy := bounds.position.y + row * hy
			var c := cx + cy
			var shade := ground.lightened(0.06) if int(c / tile.x) % 2 == 0 else ground.darkened(0.06)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - hy), Vector2(cx + hx, cy),
				Vector2(cx, cy + hy), Vector2(cx - hx, cy)]), shade)
			# Liseré discret pour lire la grille iso.
			draw_polyline(PackedVector2Array([
				Vector2(cx, cy - hy), Vector2(cx + hx, cy),
				Vector2(cx, cy + hy), Vector2(cx - hx, cy), Vector2(cx, cy - hy)]),
				ground.darkened(0.18), 1.0)


# =============================================================================
# DÉCOR (Node2D, origine aux pieds → tri en profondeur)
# =============================================================================

static func _shadow(rx: float, ry: float) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = Color(0, 0, 0, 0.28)
	return p


static func _poly(points: PackedVector2Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = col
	return p


## Arbre feuillu (forêt) : tronc + houppier en 3 couches + ombre.
static func tree(s: float = 1.0, leaf := Color(0.22, 0.45, 0.26)) -> Node2D:
	var n := Node2D.new()
	n.add_child(_shadow(40 * s, 14 * s))
	var trunk := _poly(PackedVector2Array([
		Vector2(-7 * s, 0), Vector2(7 * s, 0), Vector2(5 * s, -46 * s), Vector2(-5 * s, -46 * s)]),
		Color(0.34, 0.24, 0.16))
	n.add_child(trunk)
	# Houppier : 3 disques décalés, du plus sombre (bas) au plus clair (haut).
	for layer in 3:
		var cy := -50.0 * s - layer * 26.0 * s
		var rad := (52.0 - layer * 10.0) * s
		var col := leaf.darkened(0.12 - layer * 0.06)
		n.add_child(_disc(Vector2(0, cy), rad, rad * 0.82, col))
	# Reflet de lumière.
	n.add_child(_disc(Vector2(-12 * s, -96 * s), 16 * s, 13 * s, leaf.lightened(0.22)))
	return n


## Pin sombre (variété) : étages triangulaires.
static func pine(s: float = 1.0) -> Node2D:
	var n := Node2D.new()
	n.add_child(_shadow(30 * s, 12 * s))
	n.add_child(_poly(PackedVector2Array([Vector2(-5 * s, 0), Vector2(5 * s, 0), Vector2(0, -30 * s)]), Color(0.30, 0.22, 0.15)))
	var col := Color(0.16, 0.34, 0.22)
	for k in 3:
		var base_y := -20.0 * s - k * 26.0 * s
		var w := (40.0 - k * 9.0) * s
		var h := 38.0 * s
		n.add_child(_poly(PackedVector2Array([
			Vector2(-w, base_y), Vector2(w, base_y), Vector2(0, base_y - h)]), col.darkened(0.05 * (2 - k))))
	return n


## Rocher.
static func rock(s: float = 1.0) -> Node2D:
	var n := Node2D.new()
	n.add_child(_shadow(28 * s, 10 * s))
	n.add_child(_poly(PackedVector2Array([
		Vector2(-26 * s, 0), Vector2(-16 * s, -22 * s), Vector2(6 * s, -28 * s),
		Vector2(24 * s, -16 * s), Vector2(28 * s, 0)]), Color(0.45, 0.45, 0.5)))
	n.add_child(_poly(PackedVector2Array([
		Vector2(-16 * s, -22 * s), Vector2(6 * s, -28 * s), Vector2(2 * s, -14 * s), Vector2(-10 * s, -12 * s)]),
		Color(0.55, 0.55, 0.6)))
	return n


## Buisson.
static func bush(s: float = 1.0, col := Color(0.22, 0.42, 0.25)) -> Node2D:
	var n := Node2D.new()
	n.add_child(_shadow(24 * s, 9 * s))
	n.add_child(_disc(Vector2(0, -14 * s), 22 * s, 16 * s, col))
	n.add_child(_disc(Vector2(-12 * s, -10 * s), 14 * s, 11 * s, col.darkened(0.08)))
	n.add_child(_disc(Vector2(11 * s, -11 * s), 14 * s, 11 * s, col.lightened(0.08)))
	return n


## Maison en bois (village). `warm` allume les fenêtres (taverne/soir).
static func house(s: float = 1.0, wall := Color(0.55, 0.40, 0.26), warm := false) -> Node2D:
	var n := Node2D.new()
	n.add_child(_shadow(70 * s, 22 * s))
	# Murs.
	var w := 64.0 * s
	var h := 70.0 * s
	n.add_child(_poly(PackedVector2Array([
		Vector2(-w, 0), Vector2(w, 0), Vector2(w, -h), Vector2(-w, -h)]), wall))
	# Planches verticales (bois).
	var planks := wall.darkened(0.14)
	for i in range(-3, 4):
		n.add_child(_poly(PackedVector2Array([
			Vector2(i * w / 3.5, 0), Vector2(i * w / 3.5 + 2, 0),
			Vector2(i * w / 3.5 + 2, -h), Vector2(i * w / 3.5, -h)]), planks))
	# Toit.
	n.add_child(_poly(PackedVector2Array([
		Vector2(-w - 12 * s, -h), Vector2(w + 12 * s, -h), Vector2(0, -h - 46 * s)]),
		Color(0.42, 0.26, 0.18)))
	# Porte.
	n.add_child(_poly(PackedVector2Array([
		Vector2(-13 * s, 0), Vector2(13 * s, 0), Vector2(13 * s, -38 * s), Vector2(-13 * s, -38 * s)]),
		Color(0.30, 0.20, 0.13)))
	# Fenêtres.
	var glass := Color(1.0, 0.85, 0.45) if warm else Color(0.55, 0.7, 0.8)
	n.add_child(_poly(_rect_pts(Vector2(-44 * s, -52 * s), Vector2(20 * s, 18 * s)), glass))
	n.add_child(_poly(_rect_pts(Vector2(26 * s, -52 * s), Vector2(20 * s, 18 * s)), glass))
	return n


# --- Outils ------------------------------------------------------------------

static func _disc(center: Vector2, rx: float, ry: float, col: Color) -> Polygon2D:
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return _poly(pts, col)


static func _rect_pts(top_left: Vector2, size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		top_left, top_left + Vector2(size.x, 0),
		top_left + size, top_left + Vector2(0, size.y)])
