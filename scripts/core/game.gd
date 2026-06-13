## Autoload "Game" : routeur de scènes + état persistant entre les scènes.
## Gère les transitions overworld <-> zone <-> combat.
extends Node

var current_zone: ZoneData = null


func goto_overworld() -> void:
	current_zone = null
	_change("res://scenes/overworld.tscn")


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
