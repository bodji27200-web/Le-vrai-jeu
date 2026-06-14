## Caméra de combat avec juice + mise en scène cinématique.
## Effets : secousse (trauma), zoom "punch", et surtout un RÉALISATEUR — focus
## (déplacement + zoom) sur un point du champ de bataille puis retour au plan
## large. Le HUD étant sur un CanvasLayer, il reste stable pendant tout ça.
class_name BattleCamera
extends Camera2D

var trauma := 0.0          ## 0..1, décroît avec le temps. Secousse = trauma².
var base_position := Vector2.ZERO   ## Plan large (centre). Défini par la scène de combat.
var _base_zoom := Vector2.ONE
var _cam_tween: Tween       ## Un seul tween de cadrage à la fois (évite les conflits).


func _ready() -> void:
	_base_zoom = zoom
	if base_position == Vector2.ZERO:
		base_position = position
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


## Un nouveau tween de cadrage, en tuant le précédent (pas de bagarre sur zoom/position).
func _frame_tween() -> Tween:
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()
	_cam_tween = create_tween().set_parallel()
	return _cam_tween


## Cadre un point du champ (déplacement + zoom). `zoom_mult` > 1 = plan rapproché.
func focus_on(point: Vector2, zoom_mult: float, duration: float) -> void:
	var t := _frame_tween()
	t.tween_property(self, "position", point, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "zoom", _base_zoom * zoom_mult, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Retour au plan large (centre + zoom de base).
func reset_view(duration: float = 0.4) -> void:
	var t := _frame_tween()
	t.tween_property(self, "position", base_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "zoom", _base_zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Bref zoom avant puis retour (accent d'impact). Repart du zoom courant.
func punch_zoom(amount: float = 0.12, duration: float = 0.22) -> void:
	var from := zoom
	var t := _frame_tween()
	t.set_parallel(false)
	t.tween_property(self, "zoom", from * (1.0 + amount), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "zoom", _base_zoom, duration * 0.65).set_trans(Tween.TRANS_SINE)
