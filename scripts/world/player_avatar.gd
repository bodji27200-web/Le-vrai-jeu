## Avatar du joueur hors combat (déplacement libre 2D, flèches ou ZQSD/WASD).
## Réutilisé sur l'overworld (petit) et dans les zones (taille normale).
class_name PlayerAvatar
extends Node2D

var speed := 340.0
var bounds := Rect2()           ## Si size != 0, la position est bornée.
var _body: Polygon2D
var facing := Vector2.DOWN


func setup(sprite_kind: String, size: Vector2, fallback_color: Color = Color(0.95, 0.9, 0.4)) -> void:
	if sprite_kind != "":
		var spr := Sprite2D.new()
		spr.texture = PixelArt.for_unit(sprite_kind)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var s := size.y / float(spr.texture.get_height())
		spr.scale = Vector2(s, s)
		add_child(spr)
	else:
		var hw := size.x * 0.5
		var hh := size.y * 0.5
		_body = Polygon2D.new()
		_body.polygon = PackedVector2Array([
			Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh),
		])
		_body.color = fallback_color
		add_child(_body)


func _process(delta: float) -> void:
	var dir := _read_input()
	if dir != Vector2.ZERO:
		facing = dir
		position += dir * speed * delta
		if bounds.size != Vector2.ZERO:
			position.x = clampf(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
			position.y = clampf(position.y, bounds.position.y, bounds.position.y + bounds.size.y)


func _read_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	return dir.normalized()
