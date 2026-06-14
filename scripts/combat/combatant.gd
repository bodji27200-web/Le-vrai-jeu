## Instance runtime d'un combattant (PV/mana courants, etc.).
## Construite à partir d'une CharacterData ou d'une EnemyData : les données
## restent immuables, l'état de combat vit ici.
class_name Combatant
extends RefCounted

const MAX_MANA := 10

var display_name: String
var is_player: bool = false
var is_boss: bool = false
var archetype: GameEnums.Archetype = GameEnums.Archetype.AGGRESSIVE

var max_health: int
var health: int
var mana: int = 0

var strength: int
var defense: int
var agility: int
var crit_chance: float

var base_damage: int = 5
var skills: Array[SkillData] = []
var attack_sequences: Array[int] = [1]
var xp_reward: int = 0                   ## XP donnée quand cet ennemi est vaincu.
var sprite_kind := ""                   ## Clé du sprite pixel art.

# --- Invocations -------------------------------------------------------------
var is_summon := false
var auto_act := false                  ## Agit en IA (invocations + ennemis).
var taunt := false                     ## Attire les attaques ennemies (tank).
var attacks_per_turn := 1
var role: GameEnums.SummonRole = GameEnums.SummonRole.OFFENSIVE
var owner: Combatant = null            ## Invocateur (pour le retour de mana, etc.).
var body_color := Color.WHITE

# --- Modificateurs de spécialisation ----------------------------------------
var summon_hp_mult := 1.0
var summon_damage_mult := 1.0
var skill_power_mult := 1.0
var mana_on_summon_death := 0
var heal_power_mult := 1.0              ## Renforce les soins lancés (spé de prêtre).

# --- Effets de combat temporaires (IA ennemie) -------------------------------
## Nettoyés au DÉBUT du tour de l'unité : protègent pendant les tours adverses.
var damage_taken_mult := 1.0           ## < 1.0 = en défense.
var guarding: Combatant = null         ## Allié protégé (protecteur intercepte).
## Nettoyé à la FIN du tour de l'unité : consommé par sa propre action.
var damage_dealt_mult := 1.0           ## > 1.0 renforcé, < 1.0 affaibli.


func is_alive() -> bool:
	return health > 0


func take_damage(amount: int) -> int:
	var dmg: int = maxi(1, amount)
	health = maxi(0, health - dmg)
	return dmg


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)


func gain_mana(amount: int) -> void:
	mana = clampi(mana + amount, 0, MAX_MANA)


func spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true


## Fabrique un combattant jouable depuis ses données.
static func from_character(c: CharacterData) -> Combatant:
	var cb := Combatant.new()
	var cls := c.character_class
	var base := cls.base_stats
	var growth := cls.growth_per_level
	var lvl := maxi(1, c.level)
	var steps := lvl - 1

	cb.display_name = c.display_name
	cb.is_player = true
	cb.max_health = base.max_health + growth.max_health * steps
	cb.health = cb.max_health
	cb.strength = base.strength + growth.strength * steps
	cb.defense = base.defense + growth.defense * steps
	cb.agility = base.agility + growth.agility * steps
	cb.crit_chance = base.crit_chance
	# Seules les compétences débloquées au niveau actuel sont disponibles
	# (socle d'arbre de progression : on apprend en montant de niveau).
	var available: Array[SkillData] = []
	for s in cls.skills:
		if s != null and s.unlock_level <= lvl:
			available.append(s)
	cb.skills = available
	cb.sprite_kind = cls.sprite_kind
	# Arme équipée : dégâts de base + bonus d'identité (agilité/défense/PV/crit).
	if c.weapon != null:
		cb.base_damage = c.weapon.base_damage
		cb.agility += c.weapon.agility_bonus
		cb.defense += c.weapon.defense_bonus
		cb.max_health += c.weapon.max_health_bonus
		cb.crit_chance += c.weapon.crit_bonus
		cb.health = cb.max_health
	else:
		cb.base_damage = 5

	# Application de la spécialisation choisie.
	var spec := c.chosen_specialization
	if spec != null:
		cb.summon_hp_mult = spec.summon_hp_mult
		cb.summon_damage_mult = spec.summon_damage_mult
		cb.skill_power_mult = spec.skill_power_mult
		cb.mana_on_summon_death = spec.mana_on_summon_death
		cb.crit_chance += spec.crit_bonus
		cb.heal_power_mult = spec.heal_power_mult
		if spec.max_health_mult != 1.0:
			cb.max_health = int(round(cb.max_health * spec.max_health_mult))
			cb.health = cb.max_health
	return cb


## Fabrique une invocation. Hérite des modificateurs de spécialisation du maître.
static func from_summon(s: SummonData, master: Combatant) -> Combatant:
	var cb := Combatant.new()
	var hp_mult := master.summon_hp_mult if master != null else 1.0
	var dmg_mult := master.summon_damage_mult if master != null else 1.0
	cb.display_name = s.display_name
	cb.is_player = true
	cb.is_summon = true
	cb.auto_act = true
	cb.role = s.role
	cb.taunt = s.taunt
	cb.attacks_per_turn = s.attacks_per_turn
	cb.body_color = s.body_color
	cb.sprite_kind = s.sprite_kind
	cb.owner = master
	var st := s.stats
	cb.max_health = int(round(st.max_health * hp_mult))
	cb.health = cb.max_health
	cb.strength = st.strength
	cb.defense = st.defense
	cb.agility = st.agility
	cb.crit_chance = st.crit_chance
	cb.base_damage = int(round(s.base_damage * dmg_mult))
	return cb


## Fabrique un ennemi/boss depuis ses données.
static func from_enemy(e: EnemyData) -> Combatant:
	var cb := Combatant.new()
	var s := e.stats
	cb.display_name = e.display_name
	cb.is_player = false
	cb.is_boss = e.is_boss
	cb.archetype = e.archetype
	cb.max_health = int(round(s.max_health * GameSettings.enemy_health_scale()))
	cb.health = cb.max_health
	cb.strength = s.strength
	cb.defense = s.defense
	cb.agility = s.agility
	cb.crit_chance = s.crit_chance
	cb.base_damage = int(round(e.base_damage * GameSettings.enemy_damage_scale()))
	cb.attack_sequences = e.attack_sequences.duplicate()
	cb.xp_reward = e.xp_reward
	cb.sprite_kind = e.sprite_kind
	return cb
