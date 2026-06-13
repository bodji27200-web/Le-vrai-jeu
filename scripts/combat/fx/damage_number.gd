## Nombre/texte de dégâts flottant — retour visuel principal du combat
## (remplace le log texte pour le feedback instantané, façon JRPG moderne).
class_name DamageNumber
extends Node2D


## À appeler APRÈS avoir ajouté le noeud à l'arbre (create_tween le requiert).
func show_value(text: String, color: Color, big: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 40 if big else 26)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.position = Vector2(-24, -16)
	add_child(lbl)

	var rise := position + Vector2(randf_range(-18.0, 18.0), -70.0)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE, 0.14).from(Vector2(1.7, 1.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "position", rise, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.15)
	t.tween_property(lbl, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)
