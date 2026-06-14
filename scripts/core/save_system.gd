## Sauvegarde / chargement de la progression (équipe + difficulté).
## Format JSON dans user://save.json. Sur le web (export HTML5), user:// est
## stocké dans le navigateur (IndexedDB) et PERSISTE entre les sessions —
## donc la progression tient aussi sur la Xbox/Edge.
class_name SaveSystem

const SAVE_PATH := "user://save.json"
const VERSION := 1


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


## Écrit l'état complet (équipe + difficulté + inventaire).
static func save(party: Array[CharacterData], difficulty: int, inventory: Array[WeaponData] = []) -> void:
	var entries: Array = []
	for cd in party:
		if cd == null or cd.character_class == null:
			continue
		var e := {
			"name": cd.display_name,
			"class": cd.character_class.display_name,
			"level": cd.level,
			"xp": cd.xp,
			"spec": cd.chosen_specialization.display_name if cd.chosen_specialization != null else "",
		}
		if cd.weapon != null:
			e["weapon"] = _weapon_to_dict(cd.weapon)
		entries.append(e)
	var inv: Array = []
	for w in inventory:
		if w != null:
			inv.append(_weapon_to_dict(w))
	var data := {"version": VERSION, "difficulty": difficulty, "party": entries, "inventory": inv}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem : écriture impossible (%s)" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


## Lit l'état. Retourne {} si pas de sauvegarde / illisible, sinon
## { "party": Array[CharacterData], "difficulty": int }.
static func load_state() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("party"):
		push_warning("SaveSystem : sauvegarde illisible, ignorée.")
		return {}
	var by_name := _classes_by_name()
	var party: Array[CharacterData] = []
	for entry in (parsed as Dictionary).get("party", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var cls: ClassData = by_name.get(entry.get("class", ""), null)
		if cls == null:
			continue   # classe inconnue (contenu modifié) : on ignore ce héros
		var cd := CharacterData.new()
		cd.character_class = cls
		cd.display_name = entry.get("name", cls.display_name)
		cd.level = int(entry.get("level", 1))
		cd.xp = int(entry.get("xp", 0))
		var spec_name: String = entry.get("spec", "")
		if spec_name != "":
			for sp in cls.specializations:
				if sp.display_name == spec_name:
					cd.chosen_specialization = sp
					break
		var w: Variant = entry.get("weapon", null)
		if typeof(w) == TYPE_DICTIONARY:
			cd.weapon = _weapon_from_dict(w)
		party.append(cd)

	var inventory: Array[WeaponData] = []
	for wd in (parsed as Dictionary).get("inventory", []):
		if typeof(wd) == TYPE_DICTIONARY:
			inventory.append(_weapon_from_dict(wd))

	return {
		"party": party,
		"difficulty": int((parsed as Dictionary).get("difficulty", 1)),
		"inventory": inventory,
	}


static func _weapon_to_dict(w: WeaponData) -> Dictionary:
	return {
		"name": w.display_name,
		"damage": w.base_damage,
		"element": int(w.element),
		"rarity": int(w.rarity),
		"agi": w.agility_bonus,
		"def": w.defense_bonus,
		"hp": w.max_health_bonus,
		"crit": w.crit_bonus,
		"lore": w.lore,
	}


static func _weapon_from_dict(d: Dictionary) -> WeaponData:
	var w := WeaponData.new()
	w.display_name = d.get("name", "Arme")
	w.base_damage = int(d.get("damage", 9))
	w.element = int(d.get("element", 0)) as GameEnums.Element
	w.rarity = int(d.get("rarity", 0)) as GameEnums.Rarity
	w.agility_bonus = int(d.get("agi", 0))
	w.defense_bonus = int(d.get("def", 0))
	w.max_health_bonus = int(d.get("hp", 0))
	w.crit_bonus = float(d.get("crit", 0.0))
	w.lore = d.get("lore", "")
	return w


static func _classes_by_name() -> Dictionary:
	var d := {}
	for c in ContentLibrary.all_classes():
		d[c.display_name] = c
	return d
