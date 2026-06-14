## Arrière-plan LOINTAIN du combat (ciel + collines), dessiné par code.
## Destiné à vivre dans un ParallaxLayer : il dérive plus lentement que le champ
## de bataille quand la caméra bouge → sensation de PROFONDEUR (1er plan / fond).
class_name BattleBackdrop
extends Node2D

var screen := Vector2(1152, 648)

const SKY_TOP := Color8(24, 22, 38)
const SKY_BOT := Color8(64, 46, 74)
const MOON := Color8(240, 230, 200)
const HILL_FAR := Color8(46, 40, 64)
const HILL_NEAR := Color8(32, 28, 48)


func _draw() -> void:
	var w := screen.x
	var h := screen.y
	var pad := 700.0
	# Ciel dégradé (large, pour couvrir les déplacements/zoom de caméra).
	var bands := 48
	for i in bands:
		var t := float(i) / float(bands - 1)
		draw_rect(Rect2(-pad, -pad + (h + 2.0 * pad) * float(i) / bands,
			w + 2.0 * pad, (h + 2.0 * pad) / bands + 1.0), SKY_TOP.lerp(SKY_BOT, t))
	# Lune + halo doux.
	var mc := Vector2(w * 0.74, h * 0.24)
	for k in 7:
		draw_circle(mc, 28.0 + k * 34.0, Color(MOON.r, MOON.g, MOON.b, 0.05 * (1.0 - float(k) / 7.0)))
	draw_circle(mc, 26.0, MOON)
	# Deux rangées de collines (silhouettes) -> profondeur du fond.
	_hills(h * 0.46, 64.0, 0.0040, HILL_FAR)
	_hills(h * 0.58, 46.0, 0.0062, HILL_NEAR)


## Collines en bandes verticales (robuste : pas de triangulation de polygone concave).
func _hills(base_y: float, amp: float, freq: float, col: Color) -> void:
	var x := -700.0
	var step := 18.0
	var bottom := screen.y + 400.0
	while x <= screen.x + 700.0:
		var y := base_y + sin(x * freq) * amp + sin(x * freq * 2.7) * amp * 0.4
		draw_rect(Rect2(x, y, step + 1.0, bottom - y), col)
		x += step
