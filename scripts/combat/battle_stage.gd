## Décor de combat : fond en dégradé + sol ISOMÉTRIQUE (grand losange + grille).
## Donne la profondeur et une vue isométrique, SANS grille de jeu (les positions
## des combattants restent libres). Purement visuel, dessiné par code (cohérent
## avec la direction pixel art "maison").
class_name BattleStage
extends Node2D

var screen := Vector2(1152, 648)
var floor_center := Vector2(576, 430)
var floor_half := Vector2(680, 250)        ## Demi-extents du losange (x, y).

const SKY_TOP := Color8(26, 24, 38)
const SKY_BOT := Color8(58, 46, 70)
const FLOOR := Color8(72, 64, 90)
const GRID := Color8(98, 90, 120)
const EDGE := Color8(38, 34, 52)
const GLOW := Color8(120, 100, 150)


func _draw() -> void:
	# Fond : dégradé vertical à 3 teintes (ciel sombre -> brume -> horizon chaud).
	var bands := 48
	var horizon := SKY_BOT.lerp(Color8(96, 70, 96), 0.5)
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := SKY_TOP.lerp(SKY_BOT, smoothstep(0.0, 0.7, t)) if t < 0.7 \
			else SKY_BOT.lerp(horizon, smoothstep(0.7, 1.0, t))
		draw_rect(Rect2(0, screen.y * float(i) / bands, screen.x, screen.y / bands + 1.0), col)

	# Halo d'arène lointain (rayon de lumière qui plante le décor).
	for k in 6:
		var rad := 120.0 + k * 80.0
		draw_circle(Vector2(screen.x * 0.5, screen.y * 0.30), rad,
			Color(0.55, 0.42, 0.6, 0.06 * (1.0 - float(k) / 6.0)))

	# Sommets du losange (haut, droite, bas, gauche).
	var top := floor_center + Vector2(0, -floor_half.y)
	var right := floor_center + Vector2(floor_half.x, 0)
	var bot := floor_center + Vector2(0, floor_half.y)
	var left := floor_center + Vector2(-floor_half.x, 0)

	# Halo doux sous le sol + dalle.
	draw_colored_polygon(PackedVector2Array([
		top + Vector2(0, 18), right + Vector2(26, 0), bot + Vector2(0, 26), left + Vector2(-26, 0)]),
		Color(GLOW.r, GLOW.g, GLOW.b, 0.25))
	draw_colored_polygon(PackedVector2Array([top, right, bot, left]), FLOOR)

	# Halo central clair (la lumière tombe au centre de l'arène) -> profondeur.
	for k in 4:
		var f := 1.0 - float(k) / 4.0
		draw_colored_polygon(PackedVector2Array([
			floor_center.lerp(top, f), floor_center.lerp(right, f),
			floor_center.lerp(bot, f), floor_center.lerp(left, f)]),
			Color(FLOOR.lightened(0.10).r, FLOOR.lightened(0.10).g, FLOOR.lightened(0.10).b, 0.16))

	# Grille isométrique : deux familles de droites parallèles aux bords.
	var n := 9
	for i in range(1, n):
		var f := float(i) / n
		draw_line(left.lerp(bot, f), top.lerp(right, f), GRID, 1.0)   # // bord haut-gauche
		draw_line(left.lerp(top, f), bot.lerp(right, f), GRID, 1.0)   # // bord bas-gauche

	# Rebord intérieur assombri (vignette du sol) + bord net.
	draw_polyline(PackedVector2Array([
		top.lerp(floor_center, 0.06), right.lerp(floor_center, 0.06),
		bot.lerp(floor_center, 0.06), left.lerp(floor_center, 0.06),
		top.lerp(floor_center, 0.06)]), Color(EDGE.r, EDGE.g, EDGE.b, 0.5), 10.0)
	draw_polyline(PackedVector2Array([top, right, bot, left, top]), EDGE, 3.0)
