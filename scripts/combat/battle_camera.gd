## Caméra de combat avec juice : secousse (trauma) + zoom "punch".
## Affecte uniquement le champ de bataille (le HUD est sur un CanvasLayer, donc
## il reste stable pendant les secousses).
class_name BattleCamera
extends Camera2D

var trauma := 0.0          ## 0..1, décroît avec le temps. Secousse = trauma².
var _base_zoom := Vector2.ONE
var _shaking := false


func _ready() -> void:
	_base_zoom = zoom
	make_current()


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 1.8)
		var amount := trauma * trauma
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount * 20.0
	elif offset != Vector2.ZERO:
		offset = offset.lerp(Vector2.ZERO, delta * 8.0)


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Bref zoom avant puis retour (focus sur l'action).
func punch_zoom(amount: float = 0.12, duration: float = 0.22) -> void:
	var t := create_tween()
	t.tween_property(self, "zoom", _base_zoom * (1.0 + amount), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "zoom", _base_zoom, duration * 0.65).set_trans(Tween.TRANS_SINE)
