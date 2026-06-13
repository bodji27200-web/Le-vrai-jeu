## Écran de composition d'équipe + arbre de compétences.
## Le joueur parcourt le catalogue de classes, consulte l'arbre de compétences
## (débloquées par niveau), choisit une spécialisation et un niveau, puis
## assemble jusqu'à 3 héros. L'équipe validée est stockée dans Game.active_party
## et utilisée par le combat.
extends Control

const MAX_PARTY := 3
const MAX_LEVEL := 10

var _classes: Array[ClassData] = []
var _selected_class: ClassData = null
var _selected_spec: SpecializationData = null
var _selected_level := 3
## Entrées : { "name": String, "cls": ClassData, "spec": SpecializationData, "level": int }
var _party: Array = []

# --- Références UI -----------------------------------------------------------
var _detail_box: VBoxContainer
var _party_box: HBoxContainer
var _sprite_rect: TextureRect
var _start_btn: Button
var _hint: Label


func _ready() -> void:
	_classes = ContentLibrary.all_classes()
	# Recharge l'équipe déjà composée (pour la modifier).
	for c in Game.active_party:
		_party.append({
			"name": c.display_name,
			"cls": c.character_class,
			"spec": c.chosen_specialization,
			"level": c.level,
		})
	_build_ui()
	_select_class(_classes[0])
	_refresh_party()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Game.goto_overworld()


# =============================================================================
# Construction de l'interface
# =============================================================================

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.11, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := _label("Composer l'équipe", 30)
	title.position = Vector2(28, 18)
	add_child(title)

	var help := _label("Choisis tes héros, leur spécialisation et leur niveau. Échap : retour.", 15)
	help.modulate = Color(1, 1, 1, 0.7)
	help.position = Vector2(30, 58)
	add_child(help)

	# Colonne gauche : liste des classes.
	var list_title := _label("Classes", 18)
	list_title.position = Vector2(28, 92)
	add_child(list_title)
	var list := VBoxContainer.new()
	list.position = Vector2(24, 122)
	list.add_theme_constant_override("separation", 4)
	add_child(list)
	for cls in _classes:
		var b := Button.new()
		b.text = cls.display_name
		b.custom_minimum_size = Vector2(230, 34)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_select_class.bind(cls))
		list.add_child(b)

	# Aperçu sprite (haut droite).
	_sprite_rect = TextureRect.new()
	_sprite_rect.position = Vector2(870, 110)
	_sprite_rect.custom_minimum_size = Vector2(120, 160)
	_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite_rect)

	# Colonne centrale : détail de la classe + arbre de compétences.
	var detail_title := _label("Détail & arbre de compétences", 18)
	detail_title.position = Vector2(300, 92)
	add_child(detail_title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(300, 122)
	scroll.custom_minimum_size = Vector2(540, 320)
	scroll.size = Vector2(540, 320)
	add_child(scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.custom_minimum_size = Vector2(520, 0)
	_detail_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_detail_box)

	# Bas : équipe en cours + actions.
	var party_title := _label("Ton équipe (max %d)" % MAX_PARTY, 18)
	party_title.position = Vector2(28, 462)
	add_child(party_title)
	_party_box = HBoxContainer.new()
	_party_box.position = Vector2(24, 492)
	_party_box.add_theme_constant_override("separation", 12)
	add_child(_party_box)

	_hint = _label("", 15)
	_hint.modulate = Color(1, 0.85, 0.5)
	_hint.position = Vector2(28, 596)
	add_child(_hint)

	_start_btn = Button.new()
	_start_btn.text = "Valider l'équipe ▶"
	_start_btn.custom_minimum_size = Vector2(220, 44)
	_start_btn.position = Vector2(620, 588)
	_start_btn.pressed.connect(_confirm)
	add_child(_start_btn)

	var back := Button.new()
	back.text = "Retour"
	back.custom_minimum_size = Vector2(120, 44)
	back.position = Vector2(880, 588)
	back.pressed.connect(Game.goto_overworld)
	add_child(back)


# =============================================================================
# Sélection & détail
# =============================================================================

func _select_class(cls: ClassData) -> void:
	_selected_class = cls
	_selected_spec = cls.specializations[0] if not cls.specializations.is_empty() else null
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

	# Sélecteur de niveau (affecte les compétences débloquées).
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 10)
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(40, 32)
	minus.pressed.connect(_change_level.bind(-1))
	lvl_row.add_child(minus)
	lvl_row.add_child(_label("Niveau %d" % _selected_level, 16))
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(40, 32)
	plus.pressed.connect(_change_level.bind(1))
	lvl_row.add_child(plus)
	_detail_box.add_child(lvl_row)

	# Arbre de compétences : trié par niveau de déblocage, verrouillées grisées.
	_detail_box.add_child(_label("— Arbre de compétences —", 16))
	var skills := cls.skills.duplicate()
	skills.sort_custom(func(a: SkillData, b: SkillData) -> bool: return a.unlock_level < b.unlock_level)
	for sk in skills:
		var unlocked: bool = sk.unlock_level <= _selected_level
		var tags := _skill_tags(sk)
		var lock := "" if unlocked else "  🔒"
		var line := _label("[niv.%d] %s — %s%s" % [sk.unlock_level, sk.display_name, tags, lock], 14)
		line.modulate = Color(0.85, 1.0, 0.85) if unlocked else Color(0.6, 0.6, 0.6)
		_detail_box.add_child(line)
		var desc := _label("        %s" % sk.description, 12)
		desc.modulate = Color(1, 1, 1, 0.55) if unlocked else Color(0.5, 0.5, 0.5, 0.6)
		_detail_box.add_child(desc)

	# Choix de spécialisation.
	_detail_box.add_child(_label("— Spécialisation —", 16))
	for spec in cls.specializations:
		var chosen := spec == _selected_spec
		var b := Button.new()
		b.text = ("✔ " if chosen else "") + spec.display_name
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(500, 30)
		b.pressed.connect(_select_spec.bind(spec))
		_detail_box.add_child(b)
		var sdesc := _label("        %s" % spec.description, 12)
		sdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sdesc.custom_minimum_size = Vector2(500, 0)
		sdesc.modulate = Color(1, 1, 1, 0.6)
		_detail_box.add_child(sdesc)

	var add := Button.new()
	add.text = "+ Ajouter à l'équipe"
	add.custom_minimum_size = Vector2(240, 40)
	add.disabled = _party.size() >= MAX_PARTY
	add.pressed.connect(_add_to_party)
	_detail_box.add_child(add)


## Résumé compact des effets d'une compétence (coût, multi-frappes, soin, élément).
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


func _change_level(delta: int) -> void:
	_selected_level = clampi(_selected_level + delta, 1, MAX_LEVEL)
	_refresh_detail()


func _select_spec(spec: SpecializationData) -> void:
	_selected_spec = spec
	_refresh_detail()


# =============================================================================
# Gestion de l'équipe
# =============================================================================

func _add_to_party() -> void:
	if _party.size() >= MAX_PARTY or _selected_class == null:
		return
	_party.append({
		"name": _unique_name(_selected_class.display_name),
		"cls": _selected_class,
		"spec": _selected_spec,
		"level": _selected_level,
	})
	_refresh_detail()   # met à jour l'état du bouton "Ajouter"
	_refresh_party()


func _unique_name(base: String) -> String:
	var count := 0
	for e in _party:
		if (e.cls as ClassData).display_name == base:
			count += 1
	return base if count == 0 else "%s %d" % [base, count + 1]


func _refresh_party() -> void:
	for c in _party_box.get_children():
		c.queue_free()
	for i in _party.size():
		var e: Dictionary = _party[i]
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(250, 96)
		var vb := VBoxContainer.new()
		vb.position = Vector2(8, 6)
		vb.add_theme_constant_override("separation", 1)
		panel.add_child(vb)
		vb.add_child(_label(e.name, 16))
		var spec_name: String = (e.spec as SpecializationData).display_name if e.spec != null else "—"
		vb.add_child(_label("%s · niv.%d" % [(e.cls as ClassData).display_name, e.level], 13))
		var spec_lbl := _label(spec_name, 12)
		spec_lbl.modulate = Color(0.7, 0.9, 1.0)
		vb.add_child(spec_lbl)
		var rm := Button.new()
		rm.text = "Retirer"
		rm.custom_minimum_size = Vector2(90, 28)
		rm.pressed.connect(_remove_member.bind(i))
		vb.add_child(rm)
		_party_box.add_child(panel)

	if _party.is_empty():
		_hint.text = "Ajoute au moins un héros pour partir à l'aventure."
		_start_btn.disabled = true
	else:
		_hint.text = "%d/%d héros — prêt à valider." % [_party.size(), MAX_PARTY]
		_start_btn.disabled = false


func _remove_member(index: int) -> void:
	if index >= 0 and index < _party.size():
		_party.remove_at(index)
	_refresh_detail()
	_refresh_party()


func _confirm() -> void:
	if _party.is_empty():
		return
	var members: Array[CharacterData] = []
	for e in _party:
		members.append(ContentLibrary.make_member(e.name, e.cls, e.spec, e.level))
	Game.active_party = members
	Game.goto_overworld()


# --- Utilitaires -------------------------------------------------------------

func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l
