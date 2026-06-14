## Test de fumée de la logique (sans UI). Lancer :
##   godot --headless --script res://tests/smoke_logic.gd
extends SceneTree


func _initialize() -> void:
	# ContentDB doit retomber sur le code tant qu'aucun .tres n'existe.
	var party := ContentDB.party()
	print("Équipe (via ContentDB) : ", party.size(), " héros")
	assert(party.size() == 3)
	assert(ContentDB.demo_encounter().size() == 3)
	assert(not ContentDB.zones().is_empty())

	# Tous les héros démarrent NIVEAU 1 sans spécialisation (progression en jeu).
	for c in party:
		assert(c.level == 1 and c.chosen_specialization == null)

	# Le 3e héros est le Nécromancien : ses invocations sont dispo dès le niv.1.
	var necro := Combatant.from_character(party[2])
	assert(necro.summon_hp_mult == 1.0)   # pas encore de spé
	for sk in necro.skills:
		if sk.summon != null:
			var s := Combatant.from_summon(sk.summon, necro)
			print("  Invocation: %s | PV %d | taunt %s | atk/tour %d" % [
				s.display_name, s.max_health, s.taunt, s.attacks_per_turn])
			assert(s.max_health == int(round(sk.summon.stats.max_health * necro.summon_hp_mult)))

	# Avec la spé "Seigneur de la Charogne", les invocations deviennent costaudes.
	var necro_cd := ContentLibrary.make_member("N", ContentLibrary.necromancer_class())
	necro_cd.level = 5
	necro_cd.chosen_specialization = necro_cd.character_class.specializations[0]
	assert(Combatant.from_character(necro_cd).summon_hp_mult > 1.0)

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

	# --- Classes profondes : catalogue, compétences, soins, specs ---
	var classes := ContentLibrary.all_classes()
	print("Classes au catalogue : ", classes.size())
	assert(classes.size() == 10)

	# Chaque classe a au moins une compétence et deux spécialisations.
	for cls in classes:
		assert(not cls.skills.is_empty())
		assert(cls.specializations.size() >= 2)

	# Le Pyromancien a une compétence multi-frappes (Salve de Flammes).
	var pyro := ContentLibrary.pyromancer_class()
	var has_multi := false
	for sk in pyro.skills:
		if sk.hits > 1:
			has_multi = true
	assert(has_multi)

	# Le Clerc soigne réellement.
	var cleric_char := CharacterData.new()
	cleric_char.display_name = "Test"
	cleric_char.character_class = ContentLibrary.cleric_class()
	cleric_char.level = 5
	cleric_char.chosen_specialization = cleric_char.character_class.specializations[0]  # +soins
	var cleric := Combatant.from_character(cleric_char)
	var heal_skill: SkillData = null
	for sk in cleric.skills:
		if sk.heal_power > 0.0:
			heal_skill = sk
	assert(heal_skill != null)
	var heal := CombatResolver.heal_amount(cleric, heal_skill.heal_power)
	print("Soin du Clerc (Gardien de la Lumière) : +%d PV" % heal)
	assert(heal > 0)

	# La spé "Gardien de la Lumière" augmente bien le soin par rapport au code de base.
	assert(cleric.heal_power_mult > 1.0)

	# Spé défensive : max_health_mult gonfle les PV (Gardien "Rempart").
	var guard_char := CharacterData.new()
	guard_char.character_class = ContentLibrary.guardian_class()
	guard_char.display_name = "G"
	guard_char.level = 3
	var guard_plain := Combatant.from_character(guard_char)
	guard_char.chosen_specialization = guard_char.character_class.specializations[0]  # Rempart
	var guard_tank := Combatant.from_character(guard_char)
	print("Gardien PV : base %d / Rempart %d" % [guard_plain.max_health, guard_tank.max_health])
	assert(guard_tank.max_health > guard_plain.max_health)

	# Déblocage par niveau : un héros bas niveau a moins de compétences.
	guard_char.chosen_specialization = null
	guard_char.level = 1
	var guard_lv1 := Combatant.from_character(guard_char)
	guard_char.level = 5
	var guard_lv5 := Combatant.from_character(guard_char)
	print("Compétences Gardien : niv.1 = %d / niv.5 = %d" % [guard_lv1.skills.size(), guard_lv5.skills.size()])
	assert(guard_lv5.skills.size() >= guard_lv1.skills.size())

	# make_member (utilisé par l'UI de composition d'équipe) produit un héros jouable.
	var monk_cls := ContentLibrary.monk_class()
	var member := ContentLibrary.make_member("Test", monk_cls, monk_cls.specializations[0], 5)
	assert(member.weapon != null and member.weapon.base_damage > 5)
	var monk := Combatant.from_character(member)
	assert(monk.is_alive() and not monk.skills.is_empty())
	print("make_member : %s niv.%d, %d compétences débloquées" % [member.display_name, member.level, monk.skills.size()])

	# --- Progression : XP, montée de niveau, déblocage de spé au niv.5 ---
	assert(Progression.xp_for_next(1) < Progression.xp_for_next(2))   # coût croissant
	assert(Progression.xp_for_next(2) < Progression.xp_for_next(5))
	var hero := ContentLibrary.make_member("Hero", ContentLibrary.guardian_class())
	assert(hero.level == 1 and hero.chosen_specialization == null)
	assert(not Progression.can_choose_spec(hero))   # pas avant le niv.5
	var res := Progression.gain_xp(hero, 2000)
	print("Progression : 2000 XP → niveau %d (a gagné des niveaux : %s)" % [hero.level, str(res.leveled)])
	assert(res.leveled and hero.level >= Progression.SPEC_UNLOCK_LEVEL)
	assert(Progression.can_choose_spec(hero))       # spé débloquée à >= niv.5
	# Un combat de démo rapporte de l'XP.
	var battle_xp := 0
	for e in ContentLibrary.demo_encounter():
		battle_xp += e.xp_reward
	print("XP d'un combat de démo : ", battle_xp)
	assert(battle_xp > 0)
	# La récompense est bien transmise au combattant.
	assert(Combatant.from_enemy(ContentLibrary.demo_boss()).xp_reward > 0)

	# --- Équipement : bonus d'arme appliqués + butin ---
	var loot := ContentLibrary.loot_weapons()
	assert(loot.size() >= 6)
	var swift_wpn: WeaponData = null
	for w in loot:
		if w.agility_bonus > 0:
			swift_wpn = w
			break
	assert(swift_wpn != null)
	var eq_char := ContentLibrary.make_member("Eq", ContentLibrary.duelist_class())
	var base_agi := Combatant.from_character(eq_char).agility
	eq_char.weapon = swift_wpn
	var armed := Combatant.from_character(eq_char)
	print("Arme %s : agilité %d → %d (crit +%.2f)" % [swift_wpn.display_name, base_agi, armed.agility, swift_wpn.crit_bonus])
	assert(armed.agility == base_agi + swift_wpn.agility_bonus)
	assert(armed.crit_chance >= swift_wpn.crit_bonus)
	var drop := ContentLibrary.random_loot()
	assert(drop != null and drop.base_damage > 0)

	# --- Village : un hub habité existe dans le monde ---
	var has_village := false
	for z in WorldLibrary.zones():
		if z.is_village:
			has_village = true
	assert(has_village)

	print("OK : invocations + spé + aggro + IA + classes + progression + équipement + village validés.")
	quit()
