## Autoload "Game" : routeur de scènes + état persistant entre les scènes.
## Gère les transitions overworld <-> zone <-> combat.
extends Node

var current_zone: ZoneData = null
## Équipe persistante (progression conservée entre les combats ET les sessions
## via la sauvegarde). Vide au démarrage : chargée depuis la sauvegarde si elle
## existe, sinon initialisée depuis le contenu (trio de démo) à la demande.
var active_party: Array[CharacterData] = []
## Armes non équipées récupérées en butin (persistant).
var inventory: Array[WeaponData] = []
## Or accumulé (persistant) — gagné en combat, dépensé à la boutique.
var gold: int = 0
## Rencontre à lancer au prochain combat (définie par la zone). Vide = démo.
var pending_encounter: EncounterData = null
## Compagnons recrutés mais hors équipe active (réserve). L'équipe = 3 max.
var bench: Array[CharacterData] = []
## Événements déjà vécus (one-shot : recrutements, secrets…). Persistant.
var event_flags: Array[String] = []
## Événement à afficher (rempli par la zone avant d'ouvrir l'écran d'événement).
var pending_event: Dictionary = {}


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
		var inv: Array[WeaponData] = []
		for w in st.get("inventory", []):
			inv.append(w)
		inventory = inv
		gold = int(st.get("gold", 0))
		var bn: Array[CharacterData] = []
		for cd in st.get("bench", []):
			bn.append(cd)
		bench = bn
		var fl: Array[String] = []
		for f in st.get("flags", []):
			fl.append(str(f))
		event_flags = fl


## Renvoie l'équipe persistante, en l'initialisant depuis le contenu si besoin.
## C'est CE tableau qui gagne de l'XP et monte en niveau au fil des combats.
func get_party() -> Array[CharacterData]:
	if active_party.is_empty():
		active_party = ContentDB.party()
	return active_party


## Sauvegarde la progression actuelle (équipe + difficulté + inventaire + or +
## compagnons en réserve + drapeaux d'événements).
func save_game() -> void:
	if not active_party.is_empty():
		SaveSystem.save(active_party, int(GameSettings.difficulty), inventory, gold, bench, event_flags)


## Efface la sauvegarde et repart d'une équipe de démo niveau 1.
func reset_progress() -> void:
	SaveSystem.delete_save()
	active_party = []
	inventory = []
	gold = 0
	bench = []
	event_flags = []
	get_party()


## Ouvre la boutique de la marchande.
func goto_shop() -> void:
	_change("res://scenes/shop.tscn")


## Personnage dont on consulte la fiche détaillée (attributs, arme, compétences).
var viewing_character: CharacterData = null

func goto_character(cd: CharacterData) -> void:
	viewing_character = cd
	_change("res://scenes/character.tscn")


# --- Compagnons & événements -------------------------------------------------

## Recrute un compagnon : dans l'équipe s'il reste de la place (3 max), sinon en
## réserve (à intégrer depuis l'écran d'équipe).
func recruit(companion: CharacterData) -> void:
	if companion == null:
		return
	if get_party().size() < 3:
		active_party.append(companion)
	else:
		bench.append(companion)
	save_game()


func has_event(id: String) -> bool:
	return event_flags.has(id)


func mark_event(id: String) -> void:
	if not event_flags.has(id):
		event_flags.append(id)
		save_game()


## Ouvre l'écran d'événement (dialogue à choix) avec les données fournies.
func start_event(ev: Dictionary) -> void:
	pending_event = ev
	_change("res://scenes/event.tscn")


## Revient dans la zone courante (après un événement).
func return_to_zone() -> void:
	if current_zone != null and current_zone.is_village:
		_change("res://scenes/village.tscn")
	else:
		_change("res://scenes/zone.tscn")


func goto_overworld() -> void:
	current_zone = null
	_change("res://scenes/overworld.tscn")


## Retour à l'écran-titre / menu.
func goto_title() -> void:
	current_zone = null
	_change("res://scenes/title.tscn")


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
	if zone != null and zone.is_village:
		_change("res://scenes/village.tscn")
	else:
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
