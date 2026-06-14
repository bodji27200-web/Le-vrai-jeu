## Sol de combat en PERSPECTIVE (fausse 3D) : un plan qui FUIT vers le fond —
## étroit et sombre au loin (en haut), large et clair au premier plan (en bas) —
## avec une grille qui converge vers un point de fuite. Donne la profondeur d'une
## vue de combat cinématique (héros au 1er plan, ennemis au fond). Le ciel et les
## collines sont gérés à part (BattleBackdrop, en parallaxe). Dessiné par code.
class_name BattleStage
extends Node2D

var screen := Vector2(1152, 648)

const FLOOR_NEAR := Color8(88, 80, 108)   ## Premier plan (bas) : clair.
const FLOOR_FAR := Color8(44, 38, 60)     ## Lointain (haut) : sombre.
const GRID := Color(1, 1, 1, 0.07)
const EDGE := Color8(20, 18, 30)


func _draw() -> void:
	var cx := screen.x * 0.5
	var far_y := 258.0
	var near_y := 708.0
	var far_h := 250.0      # demi-largeur au loin (étroit)
	var near_h := 880.0     # demi-largeur au 1er plan (large, déborde)

	# Sol en bandes de profondeur (perspective : les rangées se resserrent au loin).
	var rows := 22
	var prev_y := far_y
	var prev_h := far_h
	for i in range(1, rows + 1):
		var t := float(i) / float(rows)
		var e := t * t                      # easing : densité au loin
		var y := lerpf(far_y, near_y, e)
		var hh := lerpf(far_h, near_h, e)
		var shade := FLOOR_FAR.lerp(FLOOR_NEAR, t)
		if i % 2 == 0:
			shade = shade.darkened(0.06)    # damier discret pour lire le sol
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - prev_h, prev_y), Vector2(cx + prev_h, prev_y),
			Vector2(cx + hh, y), Vector2(cx - hh, y)]), shade)
		draw_line(Vector2(cx - hh, y), Vector2(cx + hh, y), GRID, 1.0)   # ligne de profondeur
		prev_y = y
		prev_h = hh

	# Lignes de fuite (lanes) qui convergent du 1er plan vers le fond.
	var lanes := 8
	for k in range(lanes + 1):
		var f := float(k) / float(lanes)
		var xn := lerpf(cx - near_h, cx + near_h, f)
		var xf := lerpf(cx - far_h, cx + far_h, f)
		draw_line(Vector2(xn, near_y), Vector2(xf, far_y), GRID, 1.0)

	# Liseré sombre sur l'arête lointaine (assoit le fond).
	draw_line(Vector2(cx - far_h, far_y), Vector2(cx + far_h, far_y), EDGE, 3.0)
