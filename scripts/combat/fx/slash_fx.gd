## Tranche lumineuse à l'impact : un arc en croissant orienté selon la direction
## du coup (gauche/droite/dessus/estoc). C'est LE repère visuel qui fait qu'on
## "voit" le coup connecter. À ajouter à l'arbre puis appeler `slash(...)`.
class_name SlashFX
extends Node2D


## angle_deg : orientation de la tranche (0 = horizontale, 90 = verticale).
## reach : longueur de l'arc. flip : inverse le sens (ennemis face à gauche).
func slash(angle_deg: float, color: Color = Color(1, 1, 1), reach: float = 70.0, flip: bool = false) -> void:
	rotation = deg_to_rad(angle_deg)
	scale.x = -1.0 if flip else 1.0

	# Arc en croissant, tranchant fin aux extrémités, épais au centre.
	var pts := PackedVector2Array()
	var span := 1.7              # ~100° d'arc
	var steps := 14
	for i in steps + 1:
		var a: float = lerp(-span * 0.5, span * 0.5, float(i) / steps)
		pts.append(Vector2(cos(a), sin(a)) * reach)

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.05))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.05))

	var line := Line2D.new()
	line.points = pts
	line.width = 11.0
	line.width_curve = curve
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(line)

	# Cœur blanc plus fin par-dessus, pour le côté "lame".
	var core := Line2D.new()
	core.points = pts
	core.width = 4.0
	core.width_curve = curve
	core.default_color = Color(1, 1, 1, 0.9)
	add_child(core)

	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.25 * scale.x, 1.25), 0.16).from(Vector2(0.6 * scale.x, 0.6)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(line, "modulate:a", 0.0, 0.18)
	t.parallel().tween_property(core, "modulate:a", 0.0, 0.14)
	t.tween_callback(queue_free)
