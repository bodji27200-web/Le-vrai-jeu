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
var sun: Color = Color(1.0, 0.92, 0.7)         ## Couleur du halo solaire/lunaire.
var sun_at: Vector2 = Vector2(0.30, 0.16)      ## Position du soleil (fraction du fond).


func _draw() -> void:
	# Fond : dégradé vertical riche (ciel -> horizon -> sol lointain).
	var r := bounds.grow(700)
	var bands := 64
	var horizon := ground.lightened(0.10).lerp(sun, 0.18)
	var bot := ground.darkened(0.30)
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col: Color
		if t < 0.55:
			col = sky_top.lerp(horizon, smoothstep(0.0, 0.55, t))
		else:
			col = horizon.lerp(bot, smoothstep(0.55, 1.0, t))
		draw_rect(Rect2(r.position.x, r.position.y + r.size.y * float(i) / bands,
			r.size.x, r.size.y / bands + 1.0), col)

	# Halo solaire (dégradé radial peint, additif léger) haut dans le ciel.
	var sc := r.position + Vector2(r.size.x * sun_at.x, r.size.y * sun_at.y)
	for k in 7:
		var rad := 90.0 + k * 70.0
		var a := 0.16 * (1.0 - float(k) / 7.0)
		draw_circle(sc, rad, Color(sun.r, sun.g, sun.b, a))

	# Sol isométrique : dalles en losange + variation de teinte (texture organique).
	var hx := tile.x * 0.5
	var hy := tile.y * 0.5
	var cols := int(bounds.size.x / tile.x) + 4
	var rows := int(bounds.size.y / hy) + 4
	var border := ground.darkened(0.16)
	border.a = 0.10
	for row in range(rows):
		for col in range(cols):
			var cx := bounds.position.x + col * tile.x + (hx if row % 2 == 1 else 0.0)
			var cy := bounds.position.y + row * hy
			# Bruit de valeur déterministe pour casser la régularité.
			var n := _value_noise(col, row)
			var shade := ground.lightened(0.10 * n) if n > 0.0 else ground.darkened(-0.10 * n)
			# Léger éclaircissement vers le soleil (haut de la zone).
			var depth := clampf((cy - bounds.position.y) / bounds.size.y, 0.0, 1.0)
			shade = shade.lerp(sun, 0.05 * (1.0 - depth))
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - hy), Vector2(cx + hx, cy),
				Vector2(cx, cy + hy), Vector2(cx - hx, cy)]), shade)
			# Liseré très discret pour garder la lecture iso.
			draw_polyline(PackedVector2Array([
				Vector2(cx, cy - hy), Vector2(cx + hx, cy),
				Vector2(cx, cy + hy), Vector2(cx - hx, cy), Vector2(cx, cy - hy)]),
				border, 1.0)
			# Touffes d'herbe / cailloux semés (déterministe, peu coûteux).
			if absf(n) > 0.62:
				var gx := cx + n * 22.0
				var gy := cy + _value_noise(col + 7, row + 3) * 10.0
				var blade := ground.lightened(0.18) if n > 0.0 else ground.darkened(0.22)
				draw_line(Vector2(gx, gy), Vector2(gx - 2, gy - 7), blade, 1.0)
				draw_line(Vector2(gx, gy), Vector2(gx + 2, gy - 6), blade, 1.0)


## Bruit de valeur lissé déterministe dans [-1, 1] (pas de RNG : stable au redraw).
func _value_noise(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) ^ 0x5DEECE66
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return (float(h & 0xFFFF) / 32768.0) - 1.0


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


## Touffe d'herbe (décor léger, posé sur le sol).
static func grass(s: float = 1.0, col := Color(0.30, 0.5, 0.30)) -> Node2D:
	var n := Node2D.new()
	for k in 5:
		var bx := (k - 2) * 4.0 * s
		var bh := (12.0 + (k % 2) * 6.0) * s
		n.add_child(_poly(PackedVector2Array([
			Vector2(bx - 2 * s, 0), Vector2(bx + 2 * s, 0),
			Vector2(bx + 1 * s, -bh)]), col.darkened(0.05 * (k % 2))))
	return n


## Petite fleur (touche de couleur).
static func flower(s: float = 1.0, col := Color(0.9, 0.8, 0.3)) -> Node2D:
	var n := Node2D.new()
	n.add_child(_poly(PackedVector2Array([
		Vector2(-1 * s, 0), Vector2(1 * s, 0), Vector2(0, -10 * s)]), Color(0.3, 0.5, 0.3)))
	n.add_child(_disc(Vector2(0, -11 * s), 4 * s, 4 * s, col))
	n.add_child(_disc(Vector2(0, -11 * s), 1.6 * s, 1.6 * s, col.lightened(0.4)))
	return n


# =============================================================================
# LUMIÈRE & AMBIANCE
# =============================================================================

static var _radial: Texture2D

## Texture radiale blanche (opaque au centre -> transparente au bord). Mise en cache.
static func radial_texture() -> Texture2D:
	if _radial != null:
		return _radial
	var res := 128
	var img := Image.create(res, res, false, Image.FORMAT_RGBA8)
	var c := res * 0.5
	for y in res:
		for x in res:
			var d := Vector2(x - c, y - c).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a                       # falloff doux
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_radial = ImageTexture.create_from_image(img)
	return _radial


## Halo lumineux additif (lampes, fenêtres, marqueurs). `radius` = rayon en pixels.
static func glow(color: Color, radius: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = radial_texture()
	s.modulate = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.scale = Vector2.ONE * (radius / 64.0)
	return s


## Vignette plein écran (assombrit les bords) à poser sur un CanvasLayer.
static func vignette(strength: float = 0.55) -> TextureRect:
	var res := 160
	var img := Image.create(res, res, false, Image.FORMAT_RGBA8)
	var c := res * 0.5
	for y in res:
		for x in res:
			var d := Vector2(x - c, y - c).length() / (c * 1.18)
			var a := clampf(smoothstep(0.45, 1.0, d), 0.0, 1.0) * strength
			img.set_pixel(x, y, Color(0, 0, 0, a))
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## Particules d'ambiance (lucioles, poussière, braises) dérivant lentement.
static func ambiance(count: int, color: Color, area: Vector2, up := -12.0, life := 5.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = radial_texture()
	p.amount = count
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = absf(up) * 0.4
	p.initial_velocity_max = absf(up)
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.16
	p.color = color
	# Fondu d'opacité sur la durée de vie.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.r, color.g, color.b, 0.0))
	ramp.add_point(0.5, color)
	ramp.set_color(ramp.get_point_count() - 1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	return p


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
