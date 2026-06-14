## Test de la sauvegarde/chargement (round-trip). Lancer :
##   godot --headless --script res://tests/smoke_save.gd
extends SceneTree


func _initialize() -> void:
	# Repart propre.
	SaveSystem.delete_save()
	assert(not SaveSystem.has_save())
	assert(SaveSystem.load_state().is_empty())

	# Construit une équipe avec de la progression et une spé.
	var party: Array[CharacterData] = []
	var pal := ContentLibrary.make_member("Jeanne", ContentLibrary.paladin_class())
	pal.level = 6
	pal.xp = 40
	pal.chosen_specialization = pal.character_class.specializations[1]   # Protecteur de la Foi
	party.append(pal)
	party.append(ContentLibrary.make_member("Liss", ContentLibrary.elementalist_class()))  # niv.1, sans spé

	# Inventaire (butin non équipé) + or à sauvegarder aussi.
	var inv: Array[WeaponData] = [ContentLibrary.loot_weapons()[0]]
	SaveSystem.save(party, GameEnums.Difficulty.HARD, inv, 137)
	assert(SaveSystem.has_save())

	# Recharge et vérifie le round-trip.
	var st := SaveSystem.load_state()
	assert(not st.is_empty())
	assert(int(st.difficulty) == int(GameEnums.Difficulty.HARD))
	var loaded: Array = st.party
	assert(loaded.size() == 2)

	# Inventaire rechargé (nom + bonus de crit préservés).
	var inv_loaded: Array = st.get("inventory", [])
	assert(inv_loaded.size() == 1)
	var iw := inv_loaded[0] as WeaponData
	assert(iw.display_name == inv[0].display_name and abs(iw.crit_bonus - inv[0].crit_bonus) < 0.001)
	# Or rechargé.
	assert(int(st.get("gold", 0)) == 137)

	var a := loaded[0] as CharacterData
	print("Rechargé : %s (%s) niv.%d xp.%d spé=%s arme=%s" % [
		a.display_name, a.character_class.display_name, a.level, a.xp,
		a.chosen_specialization.display_name if a.chosen_specialization else "—",
		a.weapon.display_name if a.weapon else "—"])
	assert(a.display_name == "Jeanne")
	assert(a.character_class.display_name == "Paladin")
	assert(a.level == 6 and a.xp == 40)
	assert(a.chosen_specialization != null and a.chosen_specialization.display_name == "Protecteur de la Foi")
	assert(a.weapon != null and a.weapon.base_damage > 0)

	var b := loaded[1] as CharacterData
	assert(b.character_class.display_name == "Élémentaliste")
	assert(b.level == 1 and b.chosen_specialization == null)

	# Le combattant fabriqué depuis le perso rechargé est jouable + a la spé.
	var cb := Combatant.from_character(a)
	assert(cb.is_alive() and not cb.skills.is_empty())
	assert(cb.heal_power_mult > 1.0)   # spé Protecteur de la Foi (soins renforcés)

	# Nettoyage : on ne laisse pas de sauvegarde traîner pour les autres tests.
	SaveSystem.delete_save()
	assert(not SaveSystem.has_save())

	print("OK : sauvegarde/chargement (équipe + niveaux + XP + spé + arme + difficulté) validés.")
	quit()
