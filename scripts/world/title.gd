## Écran-titre (inspiré des références : menu sobre et élégant sur fond sombre).
## Continuer (reprend la sauvegarde chargée au lancement), Nouvelle partie
## (réinitialise), et choix de la difficulté. Scène principale du jeu.
extends Control

const DIFFS := [
	[GameEnums.Difficulty.EASY, "Facile"],
	[GameEnums.Difficulty.NORMAL, "Normal"],
	[GameEnums.Difficulty.HARD, "Difficile"],
	[GameEnums.Difficulty.HARDCORE, "Hardcore"],
]

const GOLD := Color(0.86, 0.74, 0.42)

var _diff_row: HBoxContainer


func _ready() -> void:
	_build_ui()
	_fade_in()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fond sombre dégradé (bandes).
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color(0.14, 0.13, 0.20)
	glow.position = Vector2(0, 120)
	glow.size = Vector2(1152, 320)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Titre.
	var title := _label("L E   V R A I   J E U", 60, GOLD)
	title.position = Vector2(0, 150)
	title.size = Vector2(1152, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := _label("Un RPG tour par tour — aventure, attachement, maîtrise", 20, Color(0.8, 0.8, 0.85))
	sub.position = Vector2(0, 232)
	sub.size = Vector2(1152, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	# Boutons principaux.
	var menu := VBoxContainer.new()
	menu.position = Vector2(476, 320)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)

	if SaveSystem.has_save():
		menu.add_child(_menu_button("Continuer", _on_continue))
	menu.add_child(_menu_button("Nouvelle partie", _on_new_game))

	# Difficulté.
	var dlabel := _label("Difficulté", 18, Color(0.8, 0.8, 0.85))
	dlabel.position = Vector2(0, 470)
	dlabel.size = Vector2(1152, 24)
	dlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(dlabel)
	_diff_row = HBoxContainer.new()
	_diff_row.position = Vector2(346, 500)
	_diff_row.add_theme_constant_override("separation", 8)
	add_child(_diff_row)
	_refresh_diff()

	var hint := _label("Hardcore : une vraie épreuve. La parade et la lecture du combat priment.", 14, Color(1, 1, 1, 0.5))
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1152, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _refresh_diff() -> void:
	for c in _diff_row.get_children():
		c.queue_free()
	for d in DIFFS:
		var b := Button.new()
		b.text = d[1]
		b.custom_minimum_size = Vector2(110, 38)
		if GameSettings.difficulty == d[0]:
			b.add_theme_color_override("font_color", GOLD)
			b.text = "▸ %s ◂" % d[1]
		b.pressed.connect(_set_diff.bind(d[0]))
		_diff_row.add_child(b)


func _set_diff(d: GameEnums.Difficulty) -> void:
	GameSettings.difficulty = d
	Game.save_game()   # persiste si une équipe existe déjà
	_refresh_diff()


func _on_continue() -> void:
	Game.goto_overworld()


func _on_new_game() -> void:
	Game.reset_progress()
	Game.goto_overworld()


func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 48)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(cb)
	return b


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _fade_in() -> void:
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	var t := create_tween()
	t.tween_property(rect, "color:a", 0.0, 0.5)
	t.tween_callback(rect.queue_free)
