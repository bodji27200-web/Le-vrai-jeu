## Outil de migration : génère les ressources .tres ÉDITABLES à partir des
## builders en code (ContentLibrary / WorldLibrary). Les .tres produits par
## ResourceSaver sont garantis valides (c'est Godot lui-même qui les écrit).
##
## À lancer UNE FOIS (puis éditer les .tres dans l'inspecteur) :
##   godot --headless --path . --script res://tools/generate_content.gd
##
## Après génération, ContentDB charge automatiquement ces .tres au lieu du code.
extends SceneTree


func _initialize() -> void:
	_ensure_dir("res://content")

	var party := PartyData.new()
	party.members = ContentLibrary.starting_party()
	_save(party, ContentDB.PARTY_PATH)

	var enc := EncounterData.new()
	enc.display_name = "Rencontre de démonstration"
	enc.enemies = ContentLibrary.demo_encounter()
	_save(enc, ContentDB.ENCOUNTER_PATH)

	var world := WorldData.new()
	world.zones = WorldLibrary.zones()
	_save(world, ContentDB.WORLD_PATH)

	print("Génération du contenu terminée. ContentDB chargera désormais les .tres.")
	quit()


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		var err := DirAccess.make_dir_recursive_absolute(path)
		if err != OK:
			push_error("Impossible de créer le dossier %s (err %d)" % [path, err])


func _save(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err == OK:
		print("  écrit : ", path)
	else:
		push_error("Échec d'écriture de %s (err %d)" % [path, err])
