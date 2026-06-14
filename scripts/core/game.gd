## Autoload "Game" : routeur de scènes + état persistant entre les scènes.
## Gère les transitions overworld <-> zone <-> combat.
extends Node

var current_zone: ZoneData = null
## Équipe persistante (progression conservée entre les combats ET les sessions
## via la sauvegarde). Vide au démarrage : chargée depuis la sauvegarde si elle
## existe, sinon initialisée depuis le contenu (trio de démo) à la demande.
var active_party: Array[CharacterData] = []


## Au lancement : charge la progression sauvegardée si elle existe.
func _ready() -> void:
	var st := SaveSystem.load_state()
	if not st.is_empty():
		var loaded: Array[CharacterData] = []
		for cd in st.get("party", []):
			loaded.append(cd)
		if not loaded.is_empty():
			active_party = loaded
			GameSettings.difficulty = int(st.get("difficulty", GameSettings.difficulty)) as GameEnums.Difficulty


## Renvoie l'équipe persistante, en l'initialisant depuis le contenu si besoin.
## C'est CE tableau qui gagne de l'XP et monte en niveau au fil des combats.
func get_party() -> Array[CharacterData]:
	if active_party.is_empty():
		active_party = ContentDB.party()
	return active_party


## Sauvegarde la progression actuelle (équipe + difficulté).
func save_game() -> void:
	if not active_party.is_empty():
		SaveSystem.save(active_party, int(GameSettings.difficulty))


## Efface la sauvegarde et repart d'une équipe de démo niveau 1.
func reset_progress() -> void:
	SaveSystem.delete_save()
	active_party = []
	get_party()


func goto_overworld() -> void:
	current_zone = null
	_change("res://scenes/overworld.tscn")


## Ouvre l'écran de composition d'équipe (classes + spécialisation + niveau).
func goto_party_select() -> void:
	_change("res://scenes/party_select.tscn")


## Sprite du meneur d'équipe (pour l'avatar d'exploration), sinon le gardien.
func lead_sprite_kind() -> String:
	if not active_party.is_empty() and active_party[0].character_class != null:
		return active_party[0].character_class.sprite_kind
	return "gardien"


func enter_zone(zone: ZoneData) -> void:
	current_zone = zone
	_change("res://scenes/zone.tscn")


func start_battle() -> void:
	_change("res://scenes/battle.tscn")


## Après un combat : retour dans la zone courante, ou sur l'overworld par défaut.
func return_from_battle() -> void:
	if current_zone != null:
		_change("res://scenes/zone.tscn")
	else:
		_change("res://scenes/overworld.tscn")


func _change(path: String) -> void:
	get_tree().change_scene_to_file(path)
