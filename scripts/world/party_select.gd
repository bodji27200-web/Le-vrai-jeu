## Écran d'équipe + arbre de compétences + réserve de compagnons.
## On gère l'équipe PERSISTANTE (3 max, qui gagne de l'XP) : ajouter une classe,
## intégrer/mettre en réserve un compagnon recruté, équiper le butin, et — au
## niveau 5 — choisir la spécialisation. Retirer un membre le met EN RÉSERVE
## (aucune perte de progression).
extends Control

const MAX_PARTY := 3

var _classes: Array[ClassData] = []
var _selected_class: ClassData = null
var _party: Array[CharacterData] = []     ## Équipe active (mêmes objets que Game).
var _bench: Array[CharacterData] = []      ## Compagnons/héros en réserve.

# --- Références UI -----------------------------------------------------------
var _roster_box: VBoxContainer
var _detail_box: VBoxContainer
var _party_box: HBoxContainer
var _sprite_rect: TextureRect
var _start_btn: Button
var _hint: Label


func _ready() -> void:
	_classes = ContentLibrary.all_classes()
	for cd in Game.get_party():
		_party.append(cd)
	for cd in Game.bench:
		_bench.append(cd)
	_build_ui()
	_select_class(_classes[0])
	_refresh_roster()
	_refresh_party()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_confirm()


# =============================================================================
# Interface
# =============================================================================

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	add_child(_titled(_label("Équipe & compétences", 30), Vector2(28, 18)))
	var help := _label("Ajoute des classes, intègre tes compagnons (réserve), équipe ton butin. Spé au niveau %d. Échap : valider." % Progression.SPEC_UNLOCK_LEVEL, 15)
	help.modulate = Color(1, 1, 1, 0.7)
	help.position = Vector2(30, 56)
	add_child(help)

	# Colonne gauche : classes + réserve (défilable).
	add_child(_titled(_label("Classes & réserve", 18), Vector2(28, 90)))
	var scroll_l := ScrollContainer.new()
	scroll_l.position = Vector2(24, 120)
	scroll_l.custom_minimum_size = Vector2(250, 320)
	scroll_l.size = Vector2(250, 320)
	add_child(scroll_l)
	_roster_box = VBoxContainer.new()
	_roster_box.custom_minimum_size = Vector2(232, 0)
	_roster_box.add_theme_constant_override("separation", 4)
	scroll_l.add_child(_roster_box)

	# Aperçu sprite.
	_sprite_rect = TextureRect.new()
	_sprite_rect.position = Vector2(870, 110)
	_sprite_rect.custom_minimum_size = Vector2(120, 160)
	_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite_rect)

	# Colonne centrale : détail + arbre.
	add_child(_titled(_label("Détail & arbre de compétences", 18), Vector2(300, 90)))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(300, 120)
	scroll.custom_minimum_size = Vector2(540, 320)
	scroll.size = Vector2(540, 320)
	add_child(scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.custom_minimum_size = Vector2(520, 0)
	_detail_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_detail_box)

	# Bas : équipe + actions.
	add_child(_titled(_label("Ton équipe (max %d)" % MAX_PARTY, 18), Vector2(28, 448)))
	_party_box = HBoxContainer.new()
	_party_box.position = Vector2(24, 470)
	_party_box.add_theme_constant_override("separation", 10)
	add_child(_party_box)

	_hint = _label("", 15)
	_hint.modulate = Color(1, 0.85, 0.5)
	_hint.position = Vector2(28, 600)
	add_child(_hint)

	_start_btn = Button.new()
	_start_btn.text = "Valider ▶"
	_start_btn.custom_minimum_size = Vector2(190, 42)
	_start_btn.position = Vector2(560, 592)
	_start_btn.pressed.connect(_confirm)
	add_child(_start_btn)

	var newgame := Button.new()
	newgame.text = "Nouvelle partie ⟳"
	newgame.custom_minimum_size = Vector2(180, 42)
	newgame.position = Vector2(770, 592)
	newgame.tooltip_text = "Efface la sauvegarde et repart d'une équipe niveau 1."
	newgame.pressed.connect(_new_game)
	add_child(newgame)


## Liste de gauche : un bouton par classe (pour en ajouter), puis la réserve.
func _refresh_roster() -> void:
	for c in _roster_box.get_children():
		c.queue_free()
	for cls in _classes:
		var b := Button.new()
		b.text = cls.display_name
		b.custom_minimum_size = Vector2(224, 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_select_class.bind(cls))
		_roster_box.add_child(b)

	if not _bench.is_empty():
		var sep := _label("— Réserve (compagnons) —", 13)
		sep.modulate = Color(0.7, 0.9, 1.0)
		_roster_box.add_child(sep)
		for cd in _bench:
			var b := Button.new()
			var tag := "  ♥%d" % cd.loyalty if cd.is_companion else ""
			b.text = "★ %s (niv.%d)%s" % [cd.display_name, cd.level, tag]
			b.custom_minimum_size = Vector2(224, 30)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = _party.size() >= MAX_PARTY
			b.tooltip_text = cd.bio
			b.pressed.connect(_add_from_bench.bind(cd))
			_roster_box.add_child(b)


func _select_class(cls: ClassData) -> void:
	_selected_class = cls
	_refresh_detail()


func _refresh_detail() -> void:
	for c in _detail_box.get_children():
		c.queue_free()
	if _selected_class == null:
		return
	var cls := _selected_class
	_sprite_rect.texture = PixelArt.for_unit(cls.sprite_kind)

	_detail_box.add_child(_label(cls.display_name, 24))
	var ident := _label(cls.identity, 15)
	ident.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ident.custom_minimum_size = Vector2(510, 0)
	ident.modulate = Color(1, 1, 1, 0.85)
	_detail_box.add_child(ident)

	var s := cls.base_stats
	_detail_box.add_child(_label("PV %d · Force %d · Défense %d · Agilité %d · Crit %d%%" % [
		s.max_health, s.strength, s.defense, s.agility, int(s.crit_chance * 100)], 14))

	_detail_box.add_child(_label("— Arbre de compétences —", 16))
	var skills := cls.skills.duplicate()
	skills.sort_custom(func(a: SkillData, b: SkillData) -> bool: return a.unlock_level < b.unlock_level)
	for sk in skills:
		var at_start: bool = sk.unlock_level <= 1
		var line := _label("[niv.%d] %s — %s" % [sk.unlock_level, sk.display_name, _skill_tags(sk)], 14)
		line.modulate = Color(0.85, 1.0, 0.85) if at_start else Color(0.65, 0.65, 0.7)
		_detail_box.add_child(line)
		var desc := _label("        %s" % sk.description, 12)
		desc.modulate = Color(1, 1, 1, 0.5)
		_detail_box.add_child(desc)

	_detail_box.add_child(_label("— Spécialisations (niv.%d) —" % Progression.SPEC_UNLOCK_LEVEL, 16))
	for spec in cls.specializations:
		var sl := _label("• %s" % spec.display_name, 14)
		sl.modulate = Color(0.7, 0.9, 1.0)
		_detail_box.add_child(sl)
		var sd := _label("        %s" % spec.description, 12)
		sd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sd.custom_minimum_size = Vector2(500, 0)
		sd.modulate = Color(1, 1, 1, 0.55)
		_detail_box.add_child(sd)

	var add := Button.new()
	add.text = "+ Ajouter à l'équipe (niv.1)"
	add.custom_minimum_size = Vector2(260, 40)
	add.disabled = _party.size() >= MAX_PARTY
	add.pressed.connect(_add_to_party)
	_detail_box.add_child(add)


func _skill_tags(sk: SkillData) -> String:
	if sk.summon != null:
		return "invoque %s (%d mana)" % [sk.summon.display_name, sk.mana_cost]
	var parts: Array[String] = []
	parts.append("%d mana" % sk.mana_cost)
	if sk.heal_power > 0.0:
		parts.append("soin ×%.2f" % sk.heal_power)
	else:
		parts.append("dégâts ×%.2f" % sk.power)
		if sk.hits > 1:
			parts.append("%d coups" % sk.hits)
	return ", ".join(parts)


# =============================================================================
# Gestion équipe / réserve
# =============================================================================

func _add_to_party() -> void:
	if _party.size() >= MAX_PARTY or _selected_class == null:
		return
	_party.append(ContentLibrary.make_member(_unique_name(_selected_class.display_name), _selected_class))
	_after_change()


func _add_from_bench(cd: CharacterData) -> void:
	if _party.size() >= MAX_PARTY:
		return
	_bench.erase(cd)
	_party.append(cd)
	_after_change()


func _remove_member(index: int) -> void:
	if index >= 0 and index < _party.size():
		var cd: CharacterData = _party[index]
		_party.remove_at(index)
		_bench.append(cd)   # mis en réserve : aucune perte de progression
	_after_change()


func _choose_spec(cd: CharacterData, spec: SpecializationData) -> void:
	cd.chosen_specialization = spec
	_commit()
	_refresh_party()


func _cycle_weapon(cd: CharacterData) -> void:
	if Game.inventory.is_empty():
		return
	var next: WeaponData = Game.inventory.pop_front()
	var old := cd.weapon
	cd.weapon = next
	if old != null:
		Game.inventory.append(old)
	_commit()
	_refresh_party()


func _unique_name(base: String) -> String:
	var count := 0
	for cd in _party:
		if cd.character_class != null and cd.character_class.display_name == base:
			count += 1
	for cd in _bench:
		if cd.character_class != null and cd.character_class.display_name == base:
			count += 1
	return base if count == 0 else "%s %d" % [base, count + 1]


func _refresh_party() -> void:
	for c in _party_box.get_children():
		c.queue_free()
	for i in _party.size():
		var cd: CharacterData = _party[i]
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(268, 116)
		var vb := VBoxContainer.new()
		vb.position = Vector2(8, 5)
		vb.add_theme_constant_override("separation", 1)
		panel.add_child(vb)

		var name_line := cd.display_name + ("  ★" if cd.is_companion else "")
		vb.add_child(_label(name_line, 15))
		var cls_name: String = cd.character_class.display_name if cd.character_class != null else "?"
		var next_xp := Progression.xp_for_next(cd.level)
		var xp_txt := "niv.%d (%d/%d XP)" % [cd.level, cd.xp, next_xp] if next_xp > 0 else "niv.%d (max)" % cd.level
		vb.add_child(_label("%s · %s" % [cls_name, xp_txt], 13))

		if cd.is_companion:
			var loy := _label("Loyauté : %d%s" % [cd.loyalty, "  (motivé)" if cd.loyalty >= 50 else ""], 12)
			loy.modulate = Color(1.0, 0.6, 0.7) if cd.loyalty < 50 else Color(0.6, 1.0, 0.7)
			vb.add_child(loy)
		elif cd.chosen_specialization != null:
			var sp := _label("Spé : %s" % cd.chosen_specialization.display_name, 12)
			sp.modulate = Color(0.7, 0.9, 1.0)
			vb.add_child(sp)
		elif Progression.can_choose_spec(cd):
			var pick := _label("★ Spé :", 12)
			pick.modulate = Color(1, 0.85, 0.4)
			vb.add_child(pick)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			for spec in cd.character_class.specializations:
				var sb := Button.new()
				sb.text = spec.display_name
				sb.tooltip_text = spec.description
				sb.add_theme_font_size_override("font_size", 11)
				sb.pressed.connect(_choose_spec.bind(cd, spec))
				row.add_child(sb)
			vb.add_child(row)
		else:
			var locked := _label("Spé au niv.%d" % Progression.SPEC_UNLOCK_LEVEL, 12)
			locked.modulate = Color(0.6, 0.6, 0.65)
			vb.add_child(locked)

		var wname: String = cd.weapon.display_name if cd.weapon != null else "—"
		var wl := _label("Arme : %s" % wname, 12)
		wl.modulate = Color(1.0, 0.85, 0.5)
		vb.add_child(wl)

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		var info := Button.new()
		info.text = "Fiche"
		info.tooltip_text = "Voir les stats, attributs (points à dépenser), arme et compétences."
		info.add_theme_font_size_override("font_size", 11)
		info.pressed.connect(Game.goto_character.bind(cd))
		btn_row.add_child(info)
		var eq := Button.new()
		eq.text = "Changer (%d)" % Game.inventory.size()
		eq.disabled = Game.inventory.is_empty()
		eq.add_theme_font_size_override("font_size", 11)
		eq.pressed.connect(_cycle_weapon.bind(cd))
		btn_row.add_child(eq)
		var rm := Button.new()
		rm.text = "Réserve"
		rm.tooltip_text = "Met en réserve (conserve la progression)."
		rm.add_theme_font_size_override("font_size", 11)
		rm.pressed.connect(_remove_member.bind(i))
		btn_row.add_child(rm)
		vb.add_child(btn_row)
		_party_box.add_child(panel)

	if _party.is_empty():
		_hint.text = "Ajoute au moins un héros pour partir à l'aventure."
		_start_btn.disabled = true
	else:
		_hint.text = "%d/%d héros · %d en réserve" % [_party.size(), MAX_PARTY, _bench.size()]
		_start_btn.disabled = false


## Applique au modèle (Game) après un changement de composition + sauvegarde.
func _commit() -> void:
	Game.active_party = _party
	Game.bench = _bench
	if not _party.is_empty():
		Game.save_game()


func _after_change() -> void:
	_commit()
	_refresh_roster()
	_refresh_detail()
	_refresh_party()


func _new_game() -> void:
	Game.reset_progress()
	_party.clear()
	for cd in Game.get_party():
		_party.append(cd)
	_bench.clear()
	_after_change()


func _confirm() -> void:
	_commit()
	Game.goto_overworld()


# --- Utilitaires -------------------------------------------------------------

func _titled(lbl: Label, pos: Vector2) -> Label:
	lbl.position = pos
	return lbl


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
