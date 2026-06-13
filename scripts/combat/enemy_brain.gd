## IA de décision des ennemis. Chaque archétype choisit une action qui RÉAGIT à
## la situation (cf. vision), pas un simple script fixe.
## Retourne une "intention" : { action, hits?, target?, ally? }.
##   action ∈ "attack" | "defend" | "protect" | "empower" | "weaken"
class_name EnemyBrain

const EMPOWER_MULT := 1.5
const WEAKEN_MULT := 0.6
const DEFEND_MULT := 0.5


static func decide(enemy: Combatant, enemies: Array, heroes: Array, round_index: int) -> Dictionary:
	match enemy.archetype:
		GameEnums.Archetype.DEFENSIVE:
			# Réagit aux blessures : se met en garde quand il est bas.
			if _hp_ratio(enemy) < 0.4 and enemy.damage_taken_mult >= 1.0:
				return {"action": "defend"}
			return _attack(enemy, false)

		GameEnums.Archetype.PROTECTOR:
			# Protège un allié en danger plutôt que d'attaquer.
			var weak := _weakest_other(enemy, enemies)
			if weak != null and _hp_ratio(weak) < 0.5 and enemy.guarding == null:
				return {"action": "protect", "ally": weak}
			return _attack(enemy, false)

		GameEnums.Archetype.MANIPULATOR:
			# Alterne : renforce un allié, sinon affaiblit le plus dangereux héros.
			var ally := _strongest_other(enemy, enemies)
			if round_index % 2 == 0 and ally != null and ally.damage_dealt_mult <= 1.0:
				return {"action": "empower", "ally": ally}
			var hero := _strongest_hero(heroes)
			if hero != null and hero.damage_dealt_mult >= 1.0:
				return {"action": "weaken", "target": hero}
			return _attack(enemy, false)

		GameEnums.Archetype.OPPORTUNIST:
			# Frappe fort quand une proie est vulnérable (PV bas ou plus de mana).
			return _attack(enemy, _has_vulnerable(heroes))

		_:  # AGGRESSIVE
			# Va pour le kill (séquence longue) si un héros est bas.
			return _attack(enemy, _has_low(heroes))


static func _attack(enemy: Combatant, go_big: bool) -> Dictionary:
	return {"action": "attack", "hits": _base_hits(enemy, go_big), "target": null}


static func _base_hits(enemy: Combatant, go_big: bool) -> int:
	var seqs := enemy.attack_sequences
	if seqs.is_empty():
		return 1
	if go_big:
		return seqs.max()
	return seqs[randi() % seqs.size()]


# --- Utilitaires -------------------------------------------------------------

static func _hp_ratio(c: Combatant) -> float:
	return float(c.health) / float(c.max_health)


static func _weakest_other(self_c: Combatant, group: Array) -> Combatant:
	var best: Combatant = null
	for c in group:
		if c == self_c or not c.is_alive():
			continue
		if best == null or _hp_ratio(c) < _hp_ratio(best):
			best = c
	return best


static func _strongest_other(self_c: Combatant, group: Array) -> Combatant:
	var best: Combatant = null
	for c in group:
		if c == self_c or not c.is_alive():
			continue
		if best == null or c.base_damage > best.base_damage:
			best = c
	return best


static func _strongest_hero(heroes: Array) -> Combatant:
	var best: Combatant = null
	for h in heroes:
		if not h.is_alive():
			continue
		if best == null or h.strength > best.strength:
			best = h
	return best


static func _has_vulnerable(heroes: Array) -> bool:
	for h in heroes:
		if h.is_alive() and (h.mana < 2 or _hp_ratio(h) < 0.4):
			return true
	return false


static func _has_low(heroes: Array) -> bool:
	for h in heroes:
		if h.is_alive() and _hp_ratio(h) < 0.35:
			return true
	return false
