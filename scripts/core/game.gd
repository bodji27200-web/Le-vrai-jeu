## Autoload "Game" : routeur de scènes + état persistant entre les scènes.
## Gère les transitions overworld <-> zone <-> combat.
extends Node

var current_zone: ZoneData = null
## Équipe composée par le joueur (UI de sélection). Vide = trio de démo.
var active_party: Array[CharacterData] = []


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
