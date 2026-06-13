## Représentation visuelle d'un combattant sur le champ de bataille (Node2D).
## Affiche un sprite pixel art (PixelArt) + une ARME tenue en main, une OMBRE
## portée, et porte les animations qui rendent le combat lisible :
##  - élan d'attaque AVEC balayage d'arme directionnel (repère pour parer),
##  - coups variés en séquence (gauche / droite / dessus / estoc), data-driven
##    via CombatStyle (clé = sprite_kind),
##  - esquive, parade, coup encaissé.
## Seul `_body` bouge (lunge/squash) : l'ombre et les labels restent stables.
class_name CombatantView
extends Node2D

# L'impact d'une attaque a lieu à WINDUP + STRIKE après le début de l'élan.
# (Ne PAS changer sans ajuster la fenêtre de parade dans battle.gd.)
const WINDUP := 0.5
const STRIKE := 0.22
const RECOVER := 0.35

const WEAPON_REST := 150.0          ## Angle de repos de l'arme (deg, repère héros).

var home: Vector2
var face_dir := Vector2.RIGHT
var _is_enemy := false
var _style: Dictionary
var _half: Vector2

var _shadow: Polygon2D
var _body: Node2D                   ## Conteneur animé (lunge + squash).
var _visual: Node2D                 ## Sprite2D (pixel art) ou Polygon2D (repli).
var _base_scale := Vector2.ONE
var _weapon_pivot: Node2D           ## Pivot au pommeau : on tourne ça pour balayer.
var _hp_label: Label


func setup(disp_name: String, sprite_kind: String, body_size: Vector2, is_enemy: bool, fallback_color: Color = Color(0.6, 0.6, 0.65)) -> void:
	_half = body_size * 0.5
	_is_enemy = is_enemy
	face_dir = Vector2.LEFT if is_enemy else Vector2.RIGHT
	_style = CombatStyle.for_kind(sprite_kind)

	# Ombre portée (ellipse douce sous les pieds) -> profondeur.
	_shadow = _make_shadow(_half.x * 1.5, _half.x * 0.5)
	_shadow.position = Vector2(0, _half.y - 2)
	add_child(_shadow)

	# Conteneur animé.
	_body = Node2D.new()
	add_child(_body)

	if sprite_kind != "":
		var spr := Sprite2D.new()
		spr.texture = PixelArt.for_unit(sprite_kind)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixels nets
		var s := body_size.y / float(spr.texture.get_height())
		spr.scale = Vector2(s, s)
		_base_scale = spr.scale
		_visual = spr
	else:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(-_half.x, -_half.y), Vector2(_half.x, -_half.y),
			Vector2(_half.x, _half.y), Vector2(-_half.x, _half.y),
		])
		poly.color = fallback_color
		_visual = poly
	_body.add_child(_visual)

	# Arme tenue en main (sauf mains nues : weapon "").
	var weapon_kind: String = _style.weapon
	var wtex := PixelArt.for_weapon(weapon_kind)
	if wtex != null:
		var hand_x: float = _half.x * 0.5
		var hand_y: float = _half.y * 0.12
		_weapon_pivot = Node2D.new()
		_weapon_pivot.position = Vector2(-hand_x if is_enemy else hand_x, hand_y)
		_weapon_pivot.scale.x = -1.0 if is_enemy else 1.0
		_weapon_pivot.rotation = deg_to_rad(WEAPON_REST)
		var wspr := Sprite2D.new()
		wspr.texture = wtex
		wspr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wspr.offset = Vector2(0, -wtex.get_height() / 2.0)   # pommeau au pivot
		var ws: float = (body_size.y * 0.8) / float(wtex.get_height())
		wspr.scale = Vector2(ws, ws)
		_weapon_pivot.add_child(wspr)
		_body.add_child(_weapon_pivot)

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
	_hp_label.position = Vector2(-_half.x - 30, _half.y + 6)
	_hp_label.size = Vector2((_half.x + 30) * 2, 40)
	add_child(_hp_label)


func set_home(pos: Vector2) -> void:
	position = pos
	home = pos


func set_info(text: String) -> void:
	_hp_label.text = text


## Géométrie du coup `move_index` : orientation de la tranche + miroir + caster.
## Utilisé par battle.gd pour faire jaillir le SlashFX au bon angle à l'impact.
func attack_geometry(move_index: int) -> Dictionary:
	var moves: Array = _style.moves
	var key: String = moves[move_index % moves.size()] if not moves.is_empty() else "right"
	var mp := CombatStyle.move(key)
	return {"slash": mp.slash, "flip": _is_enemy, "caster": bool(_style.caster)}


## Joue l'attaque. `move_index` choisit le coup dans l'enchaînement du style :
## coups successifs = animations DIFFÉRENTES (gauche, droite, dessus, estoc...).
func play_attack(target_pos: Vector2, move_index: int = 0) -> void:
	var dir := (target_pos - home).normalized()
	var moves: Array = _style.moves
	var key: String = moves[move_index % moves.size()] if not moves.is_empty() else "right"
	var mp := CombatStyle.move(key)

	if bool(_style.caster):
		_play_cast(dir)
		return

	var lunge: float = mp.lunge
	var t := create_tween()
	# Armement (tell) : léger recul + arme levée.
	t.tween_property(_body, "position", -dir * 18.0, WINDUP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(mp.raise), WINDUP).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_visual, "modulate", Color(1.25, 1.25, 1.3), WINDUP)
	# Frappe : élan vers la cible + balayage rapide de l'arme.
	t.tween_property(_body, "position", dir * lunge, STRIKE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(mp.swing), STRIKE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_visual, "scale", _base_scale * Vector2(1.15, 0.88), STRIKE * 0.6)
	# Récupération : retour à la maison.
	t.tween_property(_body, "position", Vector2.ZERO, RECOVER).set_trans(Tween.TRANS_SINE)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(WEAPON_REST), RECOVER).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "scale", _base_scale, RECOVER).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "modulate", Color.WHITE, RECOVER)


## Incantation : pas de charge ni d'élan, on lève l'arme/bâton et le corps pulse.
func _play_cast(dir: Vector2) -> void:
	var t := create_tween()
	t.tween_property(_body, "position", -dir * 8.0, WINDUP).set_trans(Tween.TRANS_SINE)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(-15.0), WINDUP).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "modulate", Color(1.4, 1.4, 1.6), WINDUP)
	t.tween_property(_body, "position", dir * 10.0, STRIKE).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_visual, "scale", _base_scale * Vector2(0.92, 1.1), STRIKE)
	t.tween_property(_body, "position", Vector2.ZERO, RECOVER).set_trans(Tween.TRANS_SINE)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(WEAPON_REST), RECOVER).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "scale", _base_scale, RECOVER).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_visual, "modulate", Color.WHITE, RECOVER)


func play_dodge() -> void:
	var away := -face_dir * 95.0
	var t := create_tween()
	t.tween_property(_body, "position", away, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_body, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_SINE)


func play_parry() -> void:
	var t := create_tween()
	t.tween_property(_body, "position", face_dir * 22.0, 0.07).set_trans(Tween.TRANS_QUAD)
	if _weapon_pivot != null:
		# Lève l'arme en garde, bref.
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(60.0), 0.07)
	t.tween_property(_body, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_SINE)
	if _weapon_pivot != null:
		t.parallel().tween_property(_weapon_pivot, "rotation", deg_to_rad(WEAPON_REST), 0.2)
	t.parallel().tween_property(_visual, "modulate", Color(0.65, 0.95, 1.4), 0.07)
	t.parallel().tween_property(_visual, "modulate", Color.WHITE, 0.25)


func play_hit() -> void:
	var t := create_tween()
	t.tween_property(_visual, "modulate", Color(1.6, 0.4, 0.4), 0.06)
	t.tween_property(_visual, "modulate", Color.WHITE, 0.25)
	t.parallel().tween_property(_body, "position", -face_dir * 12.0, 0.05)
	t.parallel().tween_property(_body, "position", Vector2.ZERO, 0.2).set_delay(0.05)


func set_dead() -> void:
	_body.modulate = Color(0.4, 0.4, 0.4, 0.55)
	if _shadow != null:
		_shadow.modulate.a = 0.3


# --- Outils ------------------------------------------------------------------

static func _make_shadow(rx: float, ry: float) -> Polygon2D:
	var pts := PackedVector2Array()
	var n := 16
	for i in n:
		var a := TAU * float(i) / n
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = Color(0, 0, 0, 0.33)
	return p
