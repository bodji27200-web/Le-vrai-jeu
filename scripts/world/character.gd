## Fiche de personnage / écran de BUILD (inspiré des références : attributs,
## statistiques de combat dérivées, arme-identité, compétences).
## On y dépense les points d'attribut gagnés en montant de niveau, et on peut
## réinitialiser (respec). Les stats affichées sont calculées via le vrai
## Combatant, donc ce qu'on voit = ce qu'on aura en combat.
extends Control

const ATTRS := [
	["Vitalité", "att_vitalite", "+%d PV / point" % Progression.VITALITE_HP],
	["Force", "att_force", "+%d puissance / point" % Progression.FORCE_ATK],
	["Agilité", "att_agilite", "+%d agilité (ordre des tours) / point" % Progression.AGILITE],
	["Défense", "att_defense", "+%d défense / point" % Progression.DEFENSE],
	["Chance", "att_chance", "+%d%% critique / point" % int(Progression.CHANCE_CRIT * 100)],
]

var _cd: CharacterData
var _box: VBoxContainer


func _ready() -> void:
	_cd = Game.viewing_character
	if _cd == null:
		Game.goto_party_select()
		return
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Game.goto_party_select()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.10, 0.15)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 24)
	scroll.custom_minimum_size = Vector2(1070, 560)
	scroll.size = Vector2(1070, 560)
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(1040, 0)
	_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_box)

	var back := Button.new()
	back.text = "◀ Retour (équipe)"
	back.custom_minimum_size = Vector2(220, 42)
	back.position = Vector2(40, 592)
	back.pressed.connect(Game.goto_party_select)
	add_child(back)


func _refresh() -> void:
	for c in _box.get_children():
		c.queue_free()

	var cb := Combatant.from_character(_cd)
	var cls_name: String = _cd.character_class.display_name if _cd.character_class != null else "?"
	var spec_name: String = _cd.chosen_specialization.display_name if _cd.chosen_specialization != null else "—"

	# En-tête.
	_box.add_child(_label("%s — %s" % [_cd.display_name, cls_name], 28))
	var next_xp := Progression.xp_for_next(_cd.level)
	var xp_txt := "%d / %d" % [_cd.xp, next_xp] if next_xp > 0 else "MAX"
	_box.add_child(_label("Niveau %d   ·   XP %s   ·   Spécialisation : %s" % [_cd.level, xp_txt, spec_name], 16))
	if _cd.is_companion:
		var loy := _label("Compagnon — Loyauté %d%s" % [_cd.loyalty, "  (motivé)" if _cd.loyalty >= 50 else ""], 14)
		loy.modulate = Color(0.7, 0.9, 1.0)
		_box.add_child(loy)

	# Statistiques de combat (dérivées = ce qu'on aura vraiment).
	_box.add_child(_section("Statistiques de combat"))
	_box.add_child(_label("  Santé %d    ·    Puissance d'attaque %d    ·    Agilité %d    ·    Défense %d    ·    Crit %d%%" % [
		cb.max_health, cb.base_damage + cb.strength, cb.agility, cb.defense, int(round(cb.crit_chance * 100))], 16))

	# Attributs (dépense de points).
	var avail := Progression.attr_available(_cd)
	var head := _label("Attributs — Points disponibles : %d" % avail, 20)
	head.modulate = Color(1, 0.88, 0.45) if avail > 0 else Color(1, 1, 1, 0.9)
	_box.add_child(head)
	for a in ATTRS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var val: int = _cd.get(a[1])
		var lbl := _label("%s : %d" % [a[0], val], 16)
		lbl.custom_minimum_size = Vector2(180, 0)
		row.add_child(lbl)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(40, 30)
		plus.disabled = avail <= 0
		plus.pressed.connect(_spend.bind(a[1]))
		row.add_child(plus)
		var eff := _label(a[2], 13)
		eff.modulate = Color(1, 1, 1, 0.55)
		row.add_child(eff)
		_box.add_child(row)
	var respec := Button.new()
	respec.text = "Réinitialiser les attributs"
	respec.custom_minimum_size = Vector2(260, 34)
	respec.pressed.connect(_respec)
	_box.add_child(respec)

	# Arme (identité).
	_box.add_child(_section("Arme"))
	if _cd.weapon != null:
		var w := _cd.weapon
		_box.add_child(_label("  %s  [%s]" % [w.display_name, ContentLibrary.rarity_name(w.rarity)], 17))
		_box.add_child(_label("  Puissance %d · Élément %s%s" % [w.base_damage, _element_name(w.element), _weapon_bonuses(w)], 14))
		if w.lore != "":
			var lore := _label("  « %s »" % w.lore, 13)
			lore.modulate = Color(1, 1, 1, 0.6)
			lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lore.custom_minimum_size = Vector2(1000, 0)
			_box.add_child(lore)
	else:
		_box.add_child(_label("  (aucune arme)", 14))

	# Compétences (débloquées par niveau).
	_box.add_child(_section("Compétences"))
	if _cd.character_class != null:
		var skills := _cd.character_class.skills.duplicate()
		skills.sort_custom(func(x: SkillData, y: SkillData) -> bool: return x.unlock_level < y.unlock_level)
		for sk in skills:
			var unlocked: bool = sk.unlock_level <= _cd.level
			var line := _label("  [niv.%d] %s%s" % [sk.unlock_level, sk.display_name, "" if unlocked else "  🔒"], 14)
			line.modulate = Color(0.85, 1.0, 0.85) if unlocked else Color(0.6, 0.6, 0.65)
			_box.add_child(line)


func _spend(field: String) -> void:
	if Progression.attr_available(_cd) <= 0:
		return
	_cd.set(field, int(_cd.get(field)) + 1)
	Game.save_game()
	_refresh()


func _respec() -> void:
	Progression.reset_attributes(_cd)
	Game.save_game()
	_refresh()


# --- Utilitaires -------------------------------------------------------------

func _weapon_bonuses(w: WeaponData) -> String:
	var parts: Array[String] = []
	if w.agility_bonus != 0:
		parts.append("agi+%d" % w.agility_bonus)
	if w.defense_bonus != 0:
		parts.append("déf+%d" % w.defense_bonus)
	if w.max_health_bonus != 0:
		parts.append("PV+%d" % w.max_health_bonus)
	if w.crit_bonus != 0.0:
		parts.append("crit+%d%%" % int(w.crit_bonus * 100))
	return "  ·  " + ", ".join(parts) if not parts.is_empty() else ""


func _element_name(e: GameEnums.Element) -> String:
	match e:
		GameEnums.Element.FIRE: return "Feu"
		GameEnums.Element.ICE: return "Glace"
		GameEnums.Element.LIGHTNING: return "Foudre"
		GameEnums.Element.EARTH: return "Terre"
		GameEnums.Element.HOLY: return "Sacré"
		GameEnums.Element.SHADOW: return "Ombre"
	return "Neutre"


func _section(title: String) -> Label:
	var l := _label("— %s —" % title, 19)
	l.modulate = Color(0.85, 0.9, 1.0)
	return l


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
