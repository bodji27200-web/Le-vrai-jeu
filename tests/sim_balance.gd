## Simulateur d'équilibrage : rejoue des combats COMPLETS (sans UI) pour mesurer
## le taux de victoire et régler la difficulté. Modèle de défense du joueur
## PROBABILISTE (le combat réel dépend du timing de parade) : on simule un niveau
## de skill via une probabilité de parade/esquive. Fidèle à battle._enemy_turn.
##   godot --headless --script res://tests/sim_balance.gd
extends SceneTree

const ROUNDS_CAP := 60
const N := 1500

# Profils de skill du joueur : (parade, esquive) avant ajustement par difficulté.
const PROFILES := {
	"novice":  Vector2(0.25, 0.15),
	"correct": Vector2(0.45, 0.22),
	"expert":  Vector2(0.78, 0.12),
}


func _initialize() -> void:
	print("=== Simulateur d'équilibrage (%d combats / cellule) ===" % N)
	var diffs := [
		GameEnums.Difficulty.EASY, GameEnums.Difficulty.NORMAL,
		GameEnums.Difficulty.HARD, GameEnums.Difficulty.HARDCORE,
	]
	print("%-10s | %-8s %-8s %-8s | dmg×/pv×" % ["profil", "Facile", "Normal", "Diff."])
	for prof in PROFILES:
		var p: Vector2 = PROFILES[prof]
		var cells: Array[String] = []
		for d in diffs:
			GameSettings.difficulty = d
			var wins := 0
			for _i in N:
				if _simulate_battle(p.x, p.y):
					wins += 1
			cells.append("%5.1f%%" % (100.0 * wins / N))
		print("%-10s | %s %s %s %s" % [prof, cells[0], cells[1], cells[2], cells[3]])
	print("(colonnes : Facile / Normal / Difficile / Hardcore)")
	quit()


## Un combat complet. Retourne true si les héros gagnent.
func _simulate_battle(p_parry: float, p_dodge: float) -> bool:
	var heroes: Array[Combatant] = []
	for c in ContentDB.party():
		heroes.append(Combatant.from_character(c))
	var enemies: Array[Combatant] = []
	for e in ContentDB.demo_encounter():
		enemies.append(Combatant.from_enemy(e))

	# La difficulté resserre la fenêtre -> baisse la parade EFFECTIVE.
	var eff_parry: float = clampf(p_parry * GameSettings.parry_window_scale(), 0.0, 0.95)

	var last_target: Combatant = null
	var rounds := 0
	while not _team_dead(heroes) and not _team_dead(enemies) and rounds < ROUNDS_CAP:
		rounds += 1
		var all: Array = []
		all.append_array(heroes)
		all.append_array(enemies)
		for actor in CombatResolver.turn_order(all):
			if not actor.is_alive():
				continue
			# Début de tour : on lève les effets temporaires.
			actor.damage_taken_mult = 1.0
			actor.guarding = null
			if actor.is_player:
				_hero_turn(actor, heroes, enemies)
			else:
				last_target = _enemy_turn(actor, enemies, heroes, rounds, last_target, eff_parry, p_dodge)
			actor.damage_dealt_mult = 1.0
			if _team_dead(heroes) or _team_dead(enemies):
				break
	return _team_dead(enemies) and not _team_dead(heroes)


## Tour d'un héros (IA simple : frappe l'ennemi vivant le plus bas en PV).
func _hero_turn(hero: Combatant, heroes: Array, enemies: Array) -> void:
	var target := _lowest_alive(enemies)
	if target == null:
		return
	var guardian := _guardian_of(target, enemies)
	if guardian != null:
		target = guardian
	var dmg: Dictionary = CombatResolver.attack_damage(hero, target)
	target.take_damage(dmg.damage)


## Tour d'un ennemi : reproduit battle._enemy_turn (archétypes + défense + contre).
func _enemy_turn(enemy: Combatant, enemies: Array, heroes: Array, round_index: int,
		last_target: Combatant, eff_parry: float, p_dodge: float) -> Combatant:
	var intent: Dictionary = EnemyBrain.decide(enemy, enemies, heroes, round_index)
	match intent.action:
		"defend":
			enemy.damage_taken_mult = EnemyBrain.DEFEND_MULT
			return last_target
		"protect":
			enemy.guarding = intent.ally
			return last_target
		"empower":
			intent.ally.damage_dealt_mult = EnemyBrain.EMPOWER_MULT
			return last_target
		"weaken":
			intent.target.damage_dealt_mult = EnemyBrain.WEAKEN_MULT
			return last_target

	var target: Combatant = intent.target
	if target == null:
		target = CombatResolver.choose_target(enemy, heroes, last_target)
	if target == null:
		return last_target
	last_target = target

	var seq: int = maxi(1, int(round(intent.hits * GameSettings.enemy_aggression_scale())))
	var parried_all := true
	for _i in seq:
		if not target.is_alive():
			parried_all = false
			break
		var roll := randf()
		if roll < eff_parry:
			target.gain_mana(1)                       # parade : 0 dégât, +1 mana
		elif roll < eff_parry + p_dodge:
			parried_all = false                       # esquive : 0 dégât
		else:
			parried_all = false                       # touché
			var dmg: Dictionary = CombatResolver.attack_damage(enemy, target)
			target.take_damage(dmg.damage)
		if not target.is_alive():
			break

	# Contre Parfait : toute la séquence parée -> riposte gratuite (×1.5).
	if parried_all and seq > 0 and target.is_alive():
		var rip: Dictionary = CombatResolver.attack_damage(target, enemy, 1.5)
		enemy.take_damage(rip.damage)
	return last_target


# --- Utilitaires -------------------------------------------------------------

func _team_dead(team: Array) -> bool:
	for c in team:
		if c.is_alive():
			return false
	return true


func _lowest_alive(team: Array) -> Combatant:
	var best: Combatant = null
	for c in team:
		if c.is_alive() and (best == null or c.health < best.health):
			best = c
	return best


func _guardian_of(target: Combatant, enemies: Array) -> Combatant:
	for e in enemies:
		if e.is_alive() and e.guarding == target and e != target:
			return e
	return null
