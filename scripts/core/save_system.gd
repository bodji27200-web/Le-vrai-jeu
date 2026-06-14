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


## Écrit l'état complet (équipe + difficulté + inventaire + or + réserve + flags).
static func save(party: Array[CharacterData], difficulty: int, inventory: Array[WeaponData] = [], gold: int = 0, bench: Array[CharacterData] = [], flags: Array[String] = []) -> void:
	var entries: Array = []
	for cd in party:
		var e := _char_to_dict(cd)
		if not e.is_empty():
			entries.append(e)
	var bench_entries: Array = []
	for cd in bench:
		var e := _char_to_dict(cd)
		if not e.is_empty():
			bench_entries.append(e)
	var inv: Array = []
	for w in inventory:
		if w != null:
			inv.append(_weapon_to_dict(w))
	var data := {
		"version": VERSION, "difficulty": difficulty, "party": entries,
		"inventory": inv, "gold": gold, "bench": bench_entries, "flags": flags,
	}
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
		var cd := _char_from_dict(entry, by_name)
		if cd != null:
			party.append(cd)

	var bench: Array[CharacterData] = []
	for entry in (parsed as Dictionary).get("bench", []):
		var cd := _char_from_dict(entry, by_name)
		if cd != null:
			bench.append(cd)

	var inventory: Array[WeaponData] = []
	for wd in (parsed as Dictionary).get("inventory", []):
		if typeof(wd) == TYPE_DICTIONARY:
			inventory.append(_weapon_from_dict(wd))

	var flags: Array[String] = []
	for fl in (parsed as Dictionary).get("flags", []):
		flags.append(str(fl))

	return {
		"party": party,
		"difficulty": int((parsed as Dictionary).get("difficulty", 1)),
		"inventory": inventory,
		"gold": int((parsed as Dictionary).get("gold", 0)),
		"bench": bench,
		"flags": flags,
	}


static func _char_to_dict(cd: CharacterData) -> Dictionary:
	if cd == null or cd.character_class == null:
		return {}
	var e := {
		"name": cd.display_name,
		"class": cd.character_class.display_name,
		"level": cd.level,
		"xp": cd.xp,
		"spec": cd.chosen_specialization.display_name if cd.chosen_specialization != null else "",
		"companion": cd.is_companion,
		"loyalty": cd.loyalty,
		"bio": cd.bio,
		"att": [cd.att_vitalite, cd.att_force, cd.att_agilite, cd.att_defense, cd.att_chance],
	}
	if cd.weapon != null:
		e["weapon"] = _weapon_to_dict(cd.weapon)
	return e


static func _char_from_dict(entry: Variant, by_name: Dictionary) -> CharacterData:
	if typeof(entry) != TYPE_DICTIONARY:
		return null
	var cls: ClassData = by_name.get(entry.get("class", ""), null)
	if cls == null:
		return null   # classe inconnue (contenu modifié) : on ignore ce personnage
	var cd := CharacterData.new()
	cd.character_class = cls
	cd.display_name = entry.get("name", cls.display_name)
	cd.level = int(entry.get("level", 1))
	cd.xp = int(entry.get("xp", 0))
	cd.is_companion = bool(entry.get("companion", false))
	cd.loyalty = int(entry.get("loyalty", 0))
	cd.bio = entry.get("bio", "")
	var att: Variant = entry.get("att", [])
	if typeof(att) == TYPE_ARRAY and (att as Array).size() == 5:
		cd.att_vitalite = int(att[0])
		cd.att_force = int(att[1])
		cd.att_agilite = int(att[2])
		cd.att_defense = int(att[3])
		cd.att_chance = int(att[4])
	var spec_name: String = entry.get("spec", "")
	if spec_name != "":
		for sp in cls.specializations:
			if sp.display_name == spec_name:
				cd.chosen_specialization = sp
				break
	var w: Variant = entry.get("weapon", null)
	if typeof(w) == TYPE_DICTIONARY:
		cd.weapon = _weapon_from_dict(w)
	return cd


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
