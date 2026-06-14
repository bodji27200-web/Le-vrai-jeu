## Écran d'ÉVÉNEMENT : un moment de narration à CHOIX (façon BG3), affiché
## par-dessus l'aventure. Les choix sont nuancés (ni "bon" ni "mauvais") et ont
## des conséquences (recrutement d'un compagnon, loyauté de départ…).
## Les données viennent de Game.pending_event :
##   { id, title, text, choices: [ { text, recruit, loyalty, reply } ] }
extends Control

var _ev: Dictionary
var _box: VBoxContainer


func _ready() -> void:
	_ev = Game.pending_event
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var panel := Panel.new()
	panel.position = Vector2(160, 120)
	panel.custom_minimum_size = Vector2(832, 400)
	panel.size = Vector2(832, 400)
	add_child(panel)

	_box = VBoxContainer.new()
	_box.position = Vector2(36, 30)
	_box.custom_minimum_size = Vector2(760, 0)
	_box.add_theme_constant_override("separation", 14)
	panel.add_child(_box)

	_box.add_child(_label(_ev.get("title", "Événement"), 28))
	var txt := _label(_ev.get("text", ""), 18)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.custom_minimum_size = Vector2(760, 0)
	txt.modulate = Color(1, 1, 1, 0.9)
	_box.add_child(txt)

	for choice in _ev.get("choices", []):
		var b := Button.new()
		b.text = choice.get("text", "…")
		b.custom_minimum_size = Vector2(760, 44)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_choice.bind(choice))
		_box.add_child(b)


func _on_choice(choice: Dictionary) -> void:
	# Conséquences du choix (data-driven : compagnon et/ou objet).
	var comp: Variant = choice.get("companion", null)
	if comp != null:
		(comp as CharacterData).loyalty = int(choice.get("loyalty", 30))
		Game.recruit(comp)
	var item: Variant = choice.get("item_weapon", null)
	if item != null:
		Game.inventory.append(item)
		Game.save_game()
	Game.mark_event(_ev.get("id", ""))   # one-shot quel que soit le choix

	# Affiche la réponse + un bouton pour continuer.
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(_label(_ev.get("title", "Événement"), 28))
	var reply := _label(choice.get("reply", ""), 19)
	reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reply.custom_minimum_size = Vector2(760, 0)
	reply.add_theme_color_override("font_color", Color(0.8, 0.95, 0.8))
	_box.add_child(reply)
	var cont := Button.new()
	cont.text = "Continuer"
	cont.custom_minimum_size = Vector2(220, 48)
	cont.pressed.connect(Game.return_to_zone)
	_box.add_child(cont)


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
