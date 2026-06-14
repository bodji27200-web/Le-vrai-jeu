## Système de progression : courbe d'XP, montée de niveau, déblocages.
## Rythme "rapide au début puis ralentit" : la 1re montée est bon marché, puis le
## coût croît régulièrement. Pur (sans état), facile à rééquilibrer et à tester.
class_name Progression

const MAX_LEVEL := 30
const SPEC_UNLOCK_LEVEL := 5      ## Niveau où l'on choisit sa spécialisation.
const ATTR_POINTS_PER_LEVEL := 3  ## Points d'attribut gagnés à chaque niveau.

# Bonus par point d'attribut (build du personnage).
const VITALITE_HP := 12
const FORCE_ATK := 2
const AGILITE := 2
const DEFENSE := 2
const CHANCE_CRIT := 0.01


## Total de points d'attribut gagnés au niveau actuel (3 par niveau au-delà du 1).
static func attr_total(cd: CharacterData) -> int:
	return (maxi(1, cd.level) - 1) * ATTR_POINTS_PER_LEVEL


static func attr_spent(cd: CharacterData) -> int:
	return cd.att_vitalite + cd.att_force + cd.att_agilite + cd.att_defense + cd.att_chance


## Points encore à dépenser.
static func attr_available(cd: CharacterData) -> int:
	return maxi(0, attr_total(cd) - attr_spent(cd))


## Réinitialise les attributs (respec) : tout revient en réserve.
static func reset_attributes(cd: CharacterData) -> void:
	cd.att_vitalite = 0
	cd.att_force = 0
	cd.att_agilite = 0
	cd.att_defense = 0
	cd.att_chance = 0


## XP nécessaire pour passer de `level` à `level+1`.
static func xp_for_next(level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return int(round(25.0 * pow(float(maxi(1, level)), 1.5)))


## Ajoute de l'XP à un personnage et applique les montées de niveau.
## Mute `cd.level` et `cd.xp`. Retourne { gained, from, to, leveled }.
static func gain_xp(cd: CharacterData, amount: int) -> Dictionary:
	var from_level := cd.level
	cd.xp += maxi(0, amount)
	while cd.level < MAX_LEVEL and cd.xp >= xp_for_next(cd.level):
		cd.xp -= xp_for_next(cd.level)
		cd.level += 1
	if cd.level >= MAX_LEVEL:
		cd.xp = 0
	return {
		"gained": amount,
		"from": from_level,
		"to": cd.level,
		"leveled": cd.level > from_level,
	}


## Le personnage peut-il choisir une spécialisation maintenant ?
static func can_choose_spec(cd: CharacterData) -> bool:
	return cd.level >= SPEC_UNLOCK_LEVEL and cd.chosen_specialization == null \
		and cd.character_class != null and not cd.character_class.specializations.is_empty()


## Compétences débloquées en passant de from_level (exclu) à to_level (inclus).
static func newly_unlocked_skills(cls: ClassData, from_level: int, to_level: int) -> Array[SkillData]:
	var out: Array[SkillData] = []
	if cls == null:
		return out
	for sk in cls.skills:
		if sk != null and sk.unlock_level > from_level and sk.unlock_level <= to_level:
			out.append(sk)
	return out
