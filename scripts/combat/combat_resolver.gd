## Fonctions pures de résolution de combat (ordre des tours, dégâts).
## Aucun état, aucune UI : facile à tester et à rééquilibrer.
class_name CombatResolver

## Ordre des tours : agilité décroissante (cf. vision).
static func turn_order(combatants: Array) -> Array:
	var alive := combatants.filter(func(c: Combatant) -> bool: return c.is_alive())
	alive.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.agility > b.agility)
	return alive


## Calcule les dégâts d'une attaque. Retourne {damage:int, crit:bool}.
static func attack_damage(attacker: Combatant, defender: Combatant, power: float = 1.0) -> Dictionary:
	var raw := (float(attacker.base_damage) + float(attacker.strength)) * power * attacker.damage_dealt_mult
	var mitigated := (raw - float(defender.defense) * 0.5) * defender.damage_taken_mult
	var dmg := int(maxf(1.0, mitigated))
	var crit := randf() < attacker.crit_chance
	if crit:
		dmg = int(round(dmg * 1.5))
	return {"damage": dmg, "crit": crit}


## Choisit la cible d'un ennemi via un score pondéré dépendant de l'archétype.
## Le tirage est pondéré (et non déterministe) pour que le combat reste vivant,
## et on évite de matraquer la même cible — sauf pour achever un blessé.
static func choose_target(attacker: Combatant, players: Array, last_target: Combatant = null) -> Combatant:
	var alive := players.filter(func(c: Combatant) -> bool: return c.is_alive())
	if alive.is_empty():
		return null
	if alive.size() == 1:
		return alive[0]

	var weights: Array[float] = []
	for p in alive:
		var hp_ratio := float(p.health) / float(p.max_health)
		var w := 1.0
		match attacker.archetype:
			GameEnums.Archetype.AGGRESSIVE:
				w += (1.0 - hp_ratio) * 3.0                          # finir les blessés
				w += clampf((20.0 - p.defense) / 20.0, 0.0, 1.0) * 1.5  # viser les fragiles
			GameEnums.Archetype.OPPORTUNIST:
				w += (1.0 - hp_ratio) * 5.0                          # sécuriser un kill
			GameEnums.Archetype.MANIPULATOR:
				w += clampf(p.strength / 30.0, 0.0, 1.0) * 3.0       # neutraliser les gros DPS
			GameEnums.Archetype.PROTECTOR, GameEnums.Archetype.DEFENSIVE:
				w += 0.5                                             # plus réparti
			_:
				pass
		# Invocations : le tank (taunt) attire l'aggro, les autres en attirent moins.
		if p.is_summon:
			if p.taunt:
				w += 5.0
			else:
				w *= 0.7
		# Éviter de répéter la même cible, sauf si elle est presque morte.
		if p == last_target and hp_ratio > 0.25:
			w *= 0.4
		weights.append(maxf(0.05, w))

	return _weighted_pick(alive, weights)


static func _weighted_pick(items: Array, weights: Array[float]) -> Combatant:
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in items.size():
		roll -= weights[i]
		if roll <= 0.0:
			return items[i]
	return items[items.size() - 1]
