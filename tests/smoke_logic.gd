## Test de fumée de la logique (sans UI). Lancer :
##   godot --headless --script res://tests/smoke_logic.gd
extends SceneTree


func _initialize() -> void:
	var party := ContentLibrary.starting_party()
	print("Équipe : ", party.size(), " héros")
	assert(party.size() == 3)

	# Le 3e héros est le Nécromancien avec sa spécialisation.
	var necro := Combatant.from_character(party[2])
	print("Necro: ", necro.display_name, " | spé summon_hp x", necro.summon_hp_mult, " summon_dmg x", necro.summon_damage_mult)
	assert(necro.summon_hp_mult > 1.0)  # Seigneur de la Charogne

	# Fabrique chaque invocation via une compétence d'invocation.
	for sk in necro.skills:
		if sk.summon != null:
			var s := Combatant.from_summon(sk.summon, necro)
			print("  Invocation: %s | PV %d | dmg %d | taunt %s | atk/tour %d" % [
				s.display_name, s.max_health, s.base_damage, s.taunt, s.attacks_per_turn])
			# Les mults de spé sont appliqués.
			assert(s.max_health == int(round(sk.summon.stats.max_health * necro.summon_hp_mult)))

	# Aggro : un tank (taunt) doit attirer la majorité des attaques.
	var allies: Array = []
	for c in party:
		allies.append(Combatant.from_character(c))
	var tank := Combatant.from_summon(necro.skills[0].summon, necro)
	assert(tank.taunt)
	allies.append(tank)
	var boss := Combatant.from_enemy(ContentLibrary.demo_boss())

	var counts := {}
	for i in range(400):
		var t: Combatant = CombatResolver.choose_target(boss, allies, null)
		counts[t.display_name] = counts.get(t.display_name, 0) + 1
	print("Répartition des cibles (400 tirages) : ", counts)
	assert(counts.get(tank.display_name, 0) > 150)  # le tank prend le plus gros de l'aggro

	# --- IA des ennemis par archétype ---
	var edata := ContentLibrary.demo_encounter()
	assert(edata.size() == 3)
	var ens: Array = []
	for e in edata:
		ens.append(Combatant.from_enemy(e))
	var main_boss := ens[0] as Combatant      # AGGRESSIVE
	var garde := ens[1] as Combatant     # PROTECTOR
	var acolyte := ens[2] as Combatant   # MANIPULATOR
	var heroez: Array = []
	for c in party:
		heroez.append(Combatant.from_character(c))

	# Le boss agressif attaque.
	assert(EnemyBrain.decide(main_boss, ens, heroez, 1).action == "attack")

	# Quand le boss est bas, le protecteur le protège.
	main_boss.health = int(main_boss.max_health * 0.3)
	var prot := EnemyBrain.decide(garde, ens, heroez, 1)
	print("Protecteur (boss à 30%%) → ", prot.action, " ", prot.get("ally").display_name if prot.has("ally") else "")
	assert(prot.action == "protect" and prot.ally == main_boss)

	# Le manipulateur renforce son allié le plus dangereux (le boss).
	var manip := EnemyBrain.decide(acolyte, ens, heroez, 0)
	print("Manipulateur → ", manip.action, " ", manip.get("ally").display_name if manip.has("ally") else "")
	assert(manip.action == "empower" and manip.ally == main_boss)

	# Effets appliqués au calcul de dégâts.
	var h := heroez[0] as Combatant
	h.crit_chance = 0.0
	garde.crit_chance = 0.0
	var normal := int(CombatResolver.attack_damage(h, garde, 1.0).damage)
	garde.damage_taken_mult = 0.5
	var reduced := int(CombatResolver.attack_damage(h, garde, 1.0).damage)
	print("Dégâts sur garde : normal %d / en défense %d" % [normal, reduced])
	assert(reduced < normal)

	main_boss.crit_chance = 0.0
	var base_dmg := int(CombatResolver.attack_damage(main_boss, h, 1.0).damage)
	main_boss.damage_dealt_mult = EnemyBrain.EMPOWER_MULT
	var empowered := int(CombatResolver.attack_damage(main_boss, h, 1.0).damage)
	print("Dégâts du boss : normal %d / renforcé %d" % [base_dmg, empowered])
	assert(empowered > base_dmg)

	print("OK : invocations + spécialisation + aggro + IA archétypes validés.")
	quit()
