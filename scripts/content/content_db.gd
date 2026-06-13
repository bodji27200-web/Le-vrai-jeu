## Accès central au contenu du jeu.
##
## Charge les ressources .tres ÉDITABLES si elles existent (source de vérité),
## sinon retombe sur les builders en code (ContentLibrary / WorldLibrary) en
## émettant un avertissement. Objectif : la migration vers .tres peut se faire
## progressivement SANS jamais casser un build qui tourne.
##
## Pour générer les .tres (une fois, sous Godot) :
##   godot --headless --path . --script res://tools/generate_content.gd
class_name ContentDB

const PARTY_PATH := "res://content/party.tres"
const ENCOUNTER_PATH := "res://content/encounter_demo.tres"
const WORLD_PATH := "res://content/world.tres"


## Équipe de héros de départ.
static func party() -> Array[CharacterData]:
	var r := _load_or_null(PARTY_PATH)
	if r is PartyData and not (r as PartyData).members.is_empty():
		return (r as PartyData).members
	_warn(PARTY_PATH)
	return ContentLibrary.starting_party()


## Rencontre ennemie de démonstration.
static func demo_encounter() -> Array[EnemyData]:
	var r := _load_or_null(ENCOUNTER_PATH)
	if r is EncounterData and not (r as EncounterData).enemies.is_empty():
		return (r as EncounterData).enemies
	_warn(ENCOUNTER_PATH)
	return ContentLibrary.demo_encounter()


## Zones de l'overworld.
static func zones() -> Array[ZoneData]:
	var r := _load_or_null(WORLD_PATH)
	if r is WorldData and not (r as WorldData).zones.is_empty():
		return (r as WorldData).zones
	_warn(WORLD_PATH)
	return WorldLibrary.zones()


# --- Interne -----------------------------------------------------------------

static func _load_or_null(path: String) -> Resource:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	return null


static func _warn(path: String) -> void:
	push_warning("ContentDB : %s introuvable — contenu code utilisé. Lance tools/generate_content.gd pour générer les .tres éditables." % path)
