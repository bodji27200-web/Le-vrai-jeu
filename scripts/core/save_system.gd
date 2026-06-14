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


## Écrit l'état complet (équipe + difficulté).
static func save(party: Array[CharacterData], difficulty: int) -> void:
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
			e["weapon"] = {
				"name": cd.weapon.display_name,
				"damage": cd.weapon.base_damage,
				"element": int(cd.weapon.element),
				"rarity": int(cd.weapon.rarity),
			}
		entries.append(e)
	var data := {"version": VERSION, "difficulty": difficulty, "party": entries}
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
			var weapon := WeaponData.new()
			weapon.display_name = (w as Dictionary).get("name", "Arme")
			weapon.base_damage = int((w as Dictionary).get("damage", 9))
			weapon.element = int((w as Dictionary).get("element", 0)) as GameEnums.Element
			weapon.rarity = int((w as Dictionary).get("rarity", 0)) as GameEnums.Rarity
			cd.weapon = weapon
		party.append(cd)
	return {"party": party, "difficulty": int((parsed as Dictionary).get("difficulty", 1))}


static func _classes_by_name() -> Dictionary:
	var d := {}
	for c in ContentLibrary.all_classes():
		d[c.display_name] = c
	return d
