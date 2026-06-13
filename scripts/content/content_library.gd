## Bibliothèque de contenu de démonstration (Milestone 1).
## Construit les Resources en code pour garantir un projet qui tourne sans
## dépendre de fichiers .tres/.uid. À terme, migrer vers des .tres édités
## dans l'inspecteur (la structure est déjà data-driven).
class_name ContentLibrary

# --- Armes -------------------------------------------------------------------

static func _weapon(name: String, dmg: int, element: GameEnums.Element, rarity: GameEnums.Rarity) -> WeaponData:
	var w := WeaponData.new()
	w.display_name = name
	w.base_damage = dmg
	w.element = element
	w.rarity = rarity
	return w

# --- Compétences -------------------------------------------------------------

static func _skill(name: String, cost: int, power: float, element: GameEnums.Element, desc: String) -> SkillData:
	var s := SkillData.new()
	s.display_name = name
	s.mana_cost = cost
	s.power = power
	s.element = element
	s.description = desc
	return s

# --- Stats -------------------------------------------------------------------

static func _stats(hp: int, str_: int, def: int, agi: int, crit: float) -> StatBlock:
	var sb := StatBlock.new()
	sb.max_health = hp
	sb.strength = str_
	sb.defense = def
	sb.agility = agi
	sb.crit_chance = crit
	return sb

# --- Classes -----------------------------------------------------------------

static func _class(name: String, base: StatBlock, growth: StatBlock, skills: Array[SkillData], identity: String, specs: Array[SpecializationData] = []) -> ClassData:
	var c := ClassData.new()
	c.display_name = name
	c.base_stats = base
	c.growth_per_level = growth
	c.skills = skills
	c.specializations = specs
	c.identity = identity
	return c

# --- Invocations & spécialisations -------------------------------------------

static func _summon(name: String, role: GameEnums.SummonRole, stats: StatBlock, dmg: int, attacks: int, taunt: bool, color: Color) -> SummonData:
	var s := SummonData.new()
	s.display_name = name
	s.role = role
	s.stats = stats
	s.base_damage = dmg
	s.attacks_per_turn = attacks
	s.taunt = taunt
	s.body_color = color
	return s

static func _summon_skill(name: String, cost: int, summon: SummonData, desc: String) -> SkillData:
	var sk := SkillData.new()
	sk.display_name = name
	sk.mana_cost = cost
	sk.element = GameEnums.Element.SHADOW
	sk.summon = summon
	sk.description = desc
	return sk

static func _spec(name: String, hp_mult: float, dmg_mult: float, skill_mult: float, mana_on_death: int, desc: String) -> SpecializationData:
	var sp := SpecializationData.new()
	sp.display_name = name
	sp.summon_hp_mult = hp_mult
	sp.summon_damage_mult = dmg_mult
	sp.skill_power_mult = skill_mult
	sp.mana_on_summon_death = mana_on_death
	sp.description = desc
	return sp

## Le Nécromancien : classe centrée sur les invocations (max 2 actives),
## aux rôles distincts (tank / rapide / offensif), et NON un simple debuffer.
static func necromancer_class() -> ClassData:
	var zombie := _summon(
		"Zombie Cuirassé", GameEnums.SummonRole.TANK,
		_stats(140, 8, 22, 6, 0.0), 8, 1, true, Color(0.45, 0.55, 0.4)
	)
	zombie.sprite_kind = "zombie"
	var ghoul := _summon(
		"Goule Rapide", GameEnums.SummonRole.FAST,
		_stats(70, 14, 6, 20, 0.10), 11, 2, false, Color(0.6, 0.4, 0.7)
	)
	ghoul.sprite_kind = "goule"
	var aberration := _summon(
		"Aberration", GameEnums.SummonRole.OFFENSIVE,
		_stats(90, 20, 8, 11, 0.12), 18, 1, false, Color(0.85, 0.45, 0.3)
	)
	aberration.sprite_kind = "aberration"

	var skills: Array[SkillData] = [
		_summon_skill("Lever un Zombie", 4, zombie, "Invoque un tank qui encaisse les coups (provocation)."),
		_summon_skill("Invoquer une Goule", 3, ghoul, "Invoque une goule rapide qui frappe deux fois."),
		_summon_skill("Convoquer une Aberration", 5, aberration, "Invoque une créature offensive dévastatrice."),
		_skill("Éclat d'Ossements", 2, 1.4, GameEnums.Element.SHADOW, "Projection osseuse : dégâts directs."),
	]

	var specs: Array[SpecializationData] = [
		_spec("Seigneur de la Charogne", 1.4, 1.25, 1.0, 0,
			"Invocations bien plus robustes et puissantes. On gagne par l'armée."),
		_spec("Faucheur d'Âmes", 0.85, 0.9, 1.5, 2,
			"Invocations sacrifiables ; sorts directs surpuissants et mana au sacrifice."),
	]

	var necro := _class(
		"Nécromancien",
		_stats(100, 16, 9, 10, 0.06),
		_stats(10, 3, 1, 2, 0.0),
		skills,
		"Maître des morts : max 2 invocations aux rôles distincts.",
		specs
	)
	necro.sprite_kind = "necromancien"
	return necro

# --- Équipe de départ --------------------------------------------------------

## Trio de démonstration. Chaque membre illustre un style :
## - Gardien : tanky, met en valeur la parade.
## - Pyromancien : burst de mana, fragile.
## - Duelliste : agilité élevée (joue souvent en premier), critiques.
static func starting_party() -> Array[CharacterData]:
	var party: Array[CharacterData] = []

	# Gardien
	var guardian_skills: Array[SkillData] = [
		_skill("Frappe du Gardien", 3, 1.4, GameEnums.Element.NONE, "Coup lourd et fiable."),
		_skill("Riposte Sacrée", 5, 1.9, GameEnums.Element.HOLY, "Punition divine coûteuse."),
	]
	var guardian := _class(
		"Gardien",
		_stats(160, 14, 18, 8, 0.05),
		_stats(18, 2, 3, 1, 0.0),
		guardian_skills,
		"Mur du groupe. Récompense la parade par sa survie."
	)
	guardian.sprite_kind = "gardien"
	party.append(_character("Aldric", guardian, _weapon("Égide de Fer", 10, GameEnums.Element.NONE, GameEnums.Rarity.RARE)))

	# Pyromancien
	var pyro_skills: Array[SkillData] = [
		_skill("Trait de Feu", 2, 1.3, GameEnums.Element.FIRE, "Sort rapide et économe."),
		_skill("Embrasement", 6, 2.4, GameEnums.Element.FIRE, "Explosion dévastatrice."),
	]
	var pyro := _class(
		"Pyromancien",
		_stats(95, 20, 7, 11, 0.08),
		_stats(9, 4, 1, 2, 0.005),
		pyro_skills,
		"Dégâts massifs, mais fragile : doit gérer son mana et parer."
	)
	pyro.sprite_kind = "pyromancien"
	party.append(_character("Lyse", pyro, _weapon("Bâton de Braise", 7, GameEnums.Element.FIRE, GameEnums.Rarity.EPIC)))

	# Nécromancien (démontre les invocations + la spécialisation).
	var necro := necromancer_class()
	# Spécialisation par défaut : Seigneur de la Charogne (invocations puissantes).
	party.append(_character("Mortis", necro, _weapon("Grimoire d'Os", 6, GameEnums.Element.SHADOW, GameEnums.Rarity.EPIC), 3, necro.specializations[0]))

	return party

static func _character(name: String, cls: ClassData, weapon: WeaponData, level: int = 3, spec: SpecializationData = null) -> CharacterData:
	var c := CharacterData.new()
	c.display_name = name
	c.character_class = cls
	c.weapon = weapon
	c.level = level
	c.chosen_specialization = spec
	return c

# --- Boss de démonstration ---------------------------------------------------

static func _enemy(name: String, boss: bool, arch: GameEnums.Archetype, dmg: int, stats: StatBlock, seqs: Array[int], sprite: String, element: GameEnums.Element = GameEnums.Element.NONE) -> EnemyData:
	var e := EnemyData.new()
	e.display_name = name
	e.is_boss = boss
	e.archetype = arch
	e.base_damage = dmg
	e.stats = stats
	e.attack_sequences = seqs
	e.sprite_kind = sprite
	e.element = element
	return e

## Le Chevalier Déchu : boss agressif aux séquences variables (1/3/5 coups).
static func demo_boss() -> EnemyData:
	return _enemy("Chevalier Déchu", true, GameEnums.Archetype.AGGRESSIVE, 22,
		_stats(420, 24, 14, 12, 0.07), [1, 3, 5], "boss_chevalier", GameEnums.Element.SHADOW)

## Rencontre de démo : montre les archétypes d'IA.
## - Chevalier Déchu : AGRESSIF (va pour le kill).
## - Garde Squelette : PROTECTEUR (intercepte les coups quand le boss est bas).
## - Acolyte Profane : MANIPULATEUR (renforce le boss / affaiblit les héros).
static func demo_encounter() -> Array[EnemyData]:
	return [
		demo_boss(),
		_enemy("Garde Squelette", false, GameEnums.Archetype.PROTECTOR, 12,
			_stats(120, 12, 18, 9, 0.0), [1, 2], "garde_squelette"),
		_enemy("Acolyte Profane", false, GameEnums.Archetype.MANIPULATOR, 8,
			_stats(90, 8, 8, 13, 0.0), [1], "acolyte", GameEnums.Element.SHADOW),
	]
