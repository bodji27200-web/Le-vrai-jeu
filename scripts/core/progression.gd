## Système de progression : courbe d'XP, montée de niveau, déblocages.
## Rythme "rapide au début puis ralentit" : la 1re montée est bon marché, puis le
## coût croît régulièrement. Pur (sans état), facile à rééquilibrer et à tester.
class_name Progression

const MAX_LEVEL := 30
const SPEC_UNLOCK_LEVEL := 5      ## Niveau où l'on choisit sa spécialisation.


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
