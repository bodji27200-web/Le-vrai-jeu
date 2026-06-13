## Représentation visuelle d'un combattant sur le champ de bataille (Node2D).
## Affiche un sprite pixel art (généré par PixelArt) et porte les animations
## qui rendent le combat lisible : élan d'attaque (repère pour parer), esquive,
## parade, coup encaissé. Les flashs passent par `modulate` (marche sprite OU
## rectangle de repli).
class_name CombatantView
extends Node2D

# L'impact d'une attaque a lieu à WINDUP + STRIKE après le début de l'élan.
const WINDUP := 0.5
const STRIKE := 0.22
const RECOVER := 0.35

var home: Vector2
var face_dir := Vector2.RIGHT
var _visual: Node2D            ## Sprite2D (pixel art) ou Polygon2D (repli).
var _half: Vector2
var _hp_label: Label


func setup(disp_name: String, sprite_kind: String, body_size: Vector2, is_enemy: bool, fallback_color: Color = Color(0.6, 0.6, 0.65)) -> void:
	_half = body_size * 0.5
	face_dir = Vector2.LEFT if is_enemy else Vector2.RIGHT

	if sprite_kind != "":
		var spr := Sprite2D.new()
		spr.texture = PixelArt.for_unit(sprite_kind)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixels nets
		var s := body_size.y / float(spr.texture.get_height())
		spr.scale = Vector2(s, s)
		_visual = spr
	else:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-_half.x, -_half.y), Vector2(_half.x, -_half.y),
			Vector2(_half.x, _half.y), Vector2(-_half.x, _half.y),
		])
		poly.color = fallback_color
		_visual = poly
	add_child(_visual)

	var name_lbl := Label.new()
	name_lbl.text = disp_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 5)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-_half.x - 30, -_half.y - 26)
	name_lbl.size = Vector2((_half.x + 30) * 2, 20)
	add_child(name_lbl)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hp_label.add_theme_constant_override("outline_size", 5)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.position = Vector2(-_half.x - 30, _half.y + 4)
	_hp_label.size = Vector2((_half.x + 30) * 2, 40)
	add_child(_hp_label)


func set_home(pos: Vector2) -> void:
	position = pos
	home = pos


func set_info(text: String) -> void:
	_hp_label.text = text


func play_attack(target_pos: Vector2) -> void:
	var dir := (target_pos - home).normalized()
	var windup_pos := home - dir * 40.0
	var strike_pos := target_pos - dir * 100.0
	var t := create_tween()
	t.tween_property(self, "position", windup_pos, WINDUP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_visual, "modulate", Color(1.3, 1.3, 1.3), WINDUP)
	t.tween_property(self, "position", strike_pos, STRIKE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "position", home, RECOVER).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "modulate", Color.WHITE, RECOVER)


func play_dodge() -> void:
	var away := home - face_dir * 95.0
	var t := create_tween()
	t.tween_property(self, "position", away, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position", home, 0.18).set_trans(Tween.TRANS_SINE)


func play_parry() -> void:
	var t := create_tween()
	t.tween_property(self, "position", home + face_dir * 22.0, 0.07).set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "position", home, 0.18).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "modulate", Color(0.65, 0.95, 1.4), 0.07)
	t.parallel().tween_property(_visual, "modulate", Color.WHITE, 0.25)


func play_hit() -> void:
	var t := create_tween()
	t.tween_property(_visual, "modulate", Color(1.6, 0.4, 0.4), 0.06)
	t.tween_property(_visual, "modulate", Color.WHITE, 0.25)
	t.parallel().tween_property(self, "position", home + Vector2(8, 0), 0.05)
	t.parallel().tween_property(self, "position", home, 0.2).set_delay(0.05)


func set_dead() -> void:
	_visual.modulate = Color(0.4, 0.4, 0.4, 0.55)
