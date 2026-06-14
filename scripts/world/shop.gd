## Boutique de la marchande : on dépense l'or gagné en combat pour acheter des
## armes d'identité (ajoutées à l'inventaire, à équiper ensuite dans l'écran
## d'équipe). Achat persistant (sauvegarde).
extends Control

var _gold_label: Label
var _list: VBoxContainer


func _ready() -> void:
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Game.leave_menu()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := _label("Boutique de Selene", 30)
	title.add_theme_color_override("font_color", Color(0.86, 0.74, 0.42))
	title.position = Vector2(28, 18)
	add_child(title)

	var help := _label("Dépense ton or pour des armes (à équiper ensuite via le menu Équipe). Échap : sortir.", 15)
	help.modulate = Color(1, 1, 1, 0.7)
	help.position = Vector2(30, 58)
	add_child(help)

	_gold_label = _label("", 22)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_gold_label.position = Vector2(30, 92)
	add_child(_gold_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 132)
	scroll.custom_minimum_size = Vector2(1090, 420)
	scroll.size = Vector2(1090, 420)
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(1070, 0)
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	var back := Button.new()
	back.text = "Sortir"
	back.custom_minimum_size = Vector2(160, 44)
	back.position = Vector2(30, 588)
	back.pressed.connect(Game.leave_menu)
	add_child(back)


func _refresh() -> void:
	_gold_label.text = "Or : %d" % Game.gold
	for c in _list.get_children():
		c.queue_free()
	for w in ContentLibrary.shop_weapons():
		var price := ContentLibrary.weapon_price(w)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := _label("%s  [%s]  —  dmg %d%s%s%s%s" % [
			w.display_name, ContentLibrary.rarity_name(w.rarity), w.base_damage,
			"  agi+%d" % w.agility_bonus if w.agility_bonus != 0 else "",
			"  déf+%d" % w.defense_bonus if w.defense_bonus != 0 else "",
			"  PV+%d" % w.max_health_bonus if w.max_health_bonus != 0 else "",
			"  crit+%d%%" % int(w.crit_bonus * 100) if w.crit_bonus != 0.0 else "",
		], 15)
		info.custom_minimum_size = Vector2(760, 0)
		row.add_child(info)

		var buy := Button.new()
		buy.text = "Acheter (%d or)" % price
		buy.custom_minimum_size = Vector2(200, 34)
		buy.disabled = Game.gold < price
		buy.pressed.connect(_buy.bind(w, price))
		row.add_child(buy)
		_list.add_child(row)

		var lore := _label("    %s" % w.lore, 12)
		lore.modulate = Color(1, 1, 1, 0.5)
		_list.add_child(lore)


func _buy(w: WeaponData, price: int) -> void:
	if Game.gold < price:
		return
	Game.gold -= price
	Game.inventory.append(w.duplicate())
	Game.save_game()
	_refresh()


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
