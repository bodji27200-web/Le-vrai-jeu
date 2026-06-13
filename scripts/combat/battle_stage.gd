## Décor de combat : fond en dégradé + sol ISOMÉTRIQUE (grand losange + grille).
## Donne la profondeur et la "vue" type Sword of Convallaria, sans grille de jeu
## (les positions des combattants restent libres). Purement visuel, dessiné par
## code (cohérent avec la direction pixel art "maison").
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
	# Fond : dégradé vertical en bandes.
	var bands := 36
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(0, screen.y * float(i) / bands, screen.x, screen.y / bands + 1.0),
			SKY_TOP.lerp(SKY_BOT, t))

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

	# Grille isométrique : deux familles de droites parallèles aux bords.
	var n := 9
	for i in range(1, n):
		var f := float(i) / n
		draw_line(left.lerp(bot, f), top.lerp(right, f), GRID, 1.0)   # // bord haut-gauche
		draw_line(left.lerp(top, f), bot.lerp(right, f), GRID, 1.0)   # // bord bas-gauche

	# Bord du losange.
	draw_polyline(PackedVector2Array([top, right, bot, left, top]), EDGE, 3.0)
