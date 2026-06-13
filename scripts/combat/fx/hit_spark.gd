## Étincelle d'impact : éclat radial bref au point de contact.
class_name HitSpark
extends Node2D


## À appeler APRÈS l'ajout à l'arbre.
func burst(color: Color = Color(1, 1, 1)) -> void:
	var star := Polygon2D.new()
	star.polygon = PackedVector2Array([
		Vector2(0, -34), Vector2(9, -9), Vector2(34, 0), Vector2(9, 9),
		Vector2(0, 34), Vector2(-9, 9), Vector2(-34, 0), Vector2(-9, -9),
	])
	star.color = color
	add_child(star)

	rotation = randf_range(-0.4, 0.4)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.5, 1.5), 0.12).from(Vector2(0.2, 0.2)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(star, "modulate:a", 0.0, 0.18)
	t.tween_callback(queue_free)
