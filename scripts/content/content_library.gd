## Bibliothèque de contenu (builders en code).
## Sert de SOURCE des builders : `tools/generate_content.gd` s'en sert pour
## produire les .tres éditables, et `ContentDB` y retombe tant que les .tres
## n'existent pas. La structure reste entièrement data-driven.
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

## Compétence d'attaque, avec coups multiples (combo) et niveau de déblocage.
static func _atk(name: String, cost: int, power: float, element: GameEnums.Element, desc: String, hits: int = 1, unlock: int = 1) -> SkillData:
	var s := _skill(name, cost, power, element, desc)
	s.hits = hits
	s.unlock_level = unlock
	return s

## Compétence de soin. La cible suit `target` (SELF / SINGLE_ALLY / ALL_ALLIES).
static func _heal(name: String, cost: int, heal_power: float, target: GameEnums.TargetType, desc: String, unlock: int = 1) -> SkillData:
	var s := SkillData.new()
	s.display_name = name
	s.mana_cost = cost
	s.heal_power = heal_power
	s.target_type = target
	s.element = GameEnums.Element.HOLY
	s.description = desc
	s.unlock_level = unlock
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

# --- Spécialisations ---------------------------------------------------------

## Spé orientée invocations (Nécromancien).
static func _spec(name: String, hp_mult: float, dmg_mult: float, skill_mult: float, mana_on_death: int, desc: String) -> SpecializationData:
	var sp := SpecializationData.new()
	sp.display_name = name
	sp.summon_hp_mult = hp_mult
	sp.summon_damage_mult = dmg_mult
	sp.skill_power_mult = skill_mult
	sp.mana_on_summon_death = mana_on_death
	sp.description = desc
	return sp

## Spé orientée combat direct (puissance de sort, critique, soin, robustesse).
static func _combat_spec(name: String, skill_mult: float, crit_bonus: float, heal_mult: float, hp_mult: float, desc: String) -> SpecializationData:
	var sp := SpecializationData.new()
	sp.display_name = name
	sp.skill_power_mult = skill_mult
	sp.crit_bonus = crit_bonus
	sp.heal_power_mult = heal_mult
	sp.max_health_mult = hp_mult
	sp.description = desc
	return sp

# --- Invocations -------------------------------------------------------------

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

# =============================================================================
# CLASSES
# =============================================================================

## Gardien — mur du groupe. Récompense la parade par sa survie. Peut se soigner.
static func guardian_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Frappe du Gardien", 3, 1.4, GameEnums.Element.NONE, "Coup lourd et fiable.", 1, 1),
		_heal("Second Souffle", 4, 1.0, GameEnums.TargetType.SELF, "Le gardien puise dans sa volonté et se soigne.", 1),
		_atk("Riposte Sacrée", 5, 1.9, GameEnums.Element.HOLY, "Punition divine coûteuse.", 1, 3),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Rempart", 1.0, 0.0, 1.2, 1.25,
			"PV très supérieurs : un véritable mur qui encaisse pour l'équipe."),
		_combat_spec("Templier", 1.35, 0.05, 1.0, 1.0,
			"Foi offensive : ses sorts sacrés frappent bien plus fort."),
	]
	var c := _class("Gardien",
		_stats(160, 14, 18, 8, 0.05),
		_stats(18, 2, 3, 1, 0.0),
		skills,
		"Mur du groupe. Récompense la parade par sa survie.",
		specs)
	c.sprite_kind = "gardien"
	return c


## Pyromancien — dégâts massifs mais fragile : doit gérer son mana et parer.
static func pyromancer_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Trait de Feu", 2, 1.3, GameEnums.Element.FIRE, "Sort rapide et économe.", 1, 1),
		_atk("Salve de Flammes", 4, 0.7, GameEnums.Element.FIRE, "Trois jets de feu en rafale.", 3, 1),
		_atk("Embrasement", 6, 2.4, GameEnums.Element.FIRE, "Explosion dévastatrice.", 1, 3),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Brasier", 1.35, 0.0, 1.0, 1.0,
			"Maîtrise du feu pur : tous les sorts gagnent en puissance brute."),
		_combat_spec("Pyrokinésie", 1.1, 0.12, 1.0, 1.0,
			"Combustion instable : forte chance de critique sur chaque sort."),
	]
	var c := _class("Pyromancien",
		_stats(95, 20, 7, 11, 0.08),
		_stats(9, 4, 1, 2, 0.005),
		skills,
		"Dégâts massifs, mais fragile : doit gérer son mana et parer.",
		specs)
	c.sprite_kind = "pyromancien"
	return c


## Nécromancien — max 2 invocations aux rôles distincts (tank / rapide / offensif).
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
		_atk("Éclat d'Ossements", 2, 1.4, GameEnums.Element.SHADOW, "Projection osseuse : dégâts directs.", 1, 1),
	]

	var specs: Array[SpecializationData] = [
		_spec("Seigneur de la Charogne", 1.4, 1.25, 1.0, 0,
			"Invocations bien plus robustes et puissantes. On gagne par l'armée."),
		_spec("Faucheur d'Âmes", 0.85, 0.9, 1.5, 2,
			"Invocations sacrifiables ; sorts directs surpuissants et mana au sacrifice."),
	]

	var necro := _class("Nécromancien",
		_stats(100, 16, 9, 10, 0.06),
		_stats(10, 3, 1, 2, 0.0),
		skills,
		"Maître des morts : max 2 invocations aux rôles distincts.",
		specs)
	necro.sprite_kind = "necromancien"
	return necro


## Duelliste — très agile (joue souvent en premier), combos multi-frappes et critiques.
static func duelist_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Estoc", 2, 1.2, GameEnums.Element.NONE, "Frappe vive et précise.", 1, 1),
		_atk("Danse des Lames", 4, 0.6, GameEnums.Element.NONE, "Une volée de quatre coups fulgurants.", 4, 1),
		_atk("Coup Fatal", 5, 2.6, GameEnums.Element.NONE, "Une seule estocade, droit au cœur.", 1, 4),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Lames Jumelles", 1.15, 0.05, 1.0, 1.0,
			"Combat à deux lames : chaque coup compte un peu plus."),
		_combat_spec("Assassin", 1.1, 0.20, 1.0, 1.0,
			"Cible les points vitaux : chance de critique très élevée."),
	]
	var c := _class("Duelliste",
		_stats(105, 17, 9, 19, 0.12),
		_stats(11, 3, 1, 3, 0.01),
		skills,
		"Vitesse et combos : transforme l'initiative en pluie de coups.",
		specs)
	c.sprite_kind = "duelliste"
	return c


## Clerc — soutien : soigne les alliés et châtie de lumière sacrée.
static func cleric_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Châtiment", 2, 1.3, GameEnums.Element.HOLY, "Trait de lumière sur un ennemi.", 1, 1),
		_heal("Soin", 3, 1.1, GameEnums.TargetType.SINGLE_ALLY, "Restaure les PV d'un allié.", 1),
		_heal("Lumière Réparatrice", 6, 0.9, GameEnums.TargetType.ALL_ALLIES, "Soigne toute l'équipe d'un halo sacré.", 4),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Gardien de la Lumière", 1.0, 0.0, 1.5, 1.1,
			"Soins nettement renforcés : maintient l'équipe debout envers et contre tout."),
		_combat_spec("Inquisiteur", 1.4, 0.05, 1.0, 1.0,
			"La foi devient une arme : lumière offensive dévastatrice."),
	]
	var c := _class("Clerc",
		_stats(120, 15, 12, 10, 0.05),
		_stats(13, 3, 2, 2, 0.0),
		skills,
		"Pilier du groupe : soigne, protège et punit de lumière.",
		specs)
	c.sprite_kind = "clerc"
	return c


## Berserker — frappe fort, défense faible : tout ou rien.
static func berserker_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Taillade", 2, 1.5, GameEnums.Element.NONE, "Coup sauvage et puissant.", 1, 1),
		_atk("Déchaînement", 5, 0.8, GameEnums.Element.NONE, "Trois assauts enragés.", 3, 1),
		_atk("Carnage", 7, 3.0, GameEnums.Element.NONE, "Frappe titanesque, tout dans un coup.", 1, 5),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Furie Sanglante", 1.4, 0.10, 1.0, 1.0,
			"Rage offensive pure : dégâts et critiques décuplés."),
		_combat_spec("Indomptable", 1.0, 0.0, 1.0, 1.3,
			"Résistance brute : encaisse là où d'autres tomberaient."),
	]
	var c := _class("Berserker",
		_stats(135, 22, 8, 13, 0.10),
		_stats(15, 4, 1, 2, 0.01),
		skills,
		"Tout ou rien : des dégâts énormes au prix de la prudence.",
		specs)
	c.sprite_kind = "berserker"
	return c


## Rôdeur — archer agile : tirs de glace en rafale, à distance.
static func ranger_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Tir Précis", 2, 1.4, GameEnums.Element.ICE, "Une flèche bien placée.", 1, 1),
		_atk("Pluie de Flèches", 4, 0.65, GameEnums.Element.ICE, "Trois flèches en rafale.", 3, 1),
		_atk("Flèche Perforante", 5, 2.5, GameEnums.Element.ICE, "Une flèche qui transperce l'armure.", 1, 4),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Œil de Lynx", 1.1, 0.15, 1.0, 1.0,
			"Précision mortelle : critiques fréquents sur chaque tir."),
		_combat_spec("Pluie Mortelle", 1.3, 0.0, 1.0, 1.0,
			"Volées plus denses et bien plus douloureuses."),
	]
	var c := _class("Rôdeur",
		_stats(110, 18, 10, 18, 0.11),
		_stats(12, 3, 2, 3, 0.01),
		skills,
		"Maîtrise de la distance : harcèle de rafales glacées.",
		specs)
	c.sprite_kind = "rodeur"
	return c


## Paladin — hybride : châtie de lumière, soigne un allié, encaisse.
static func paladin_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Marteau de Justice", 2, 1.4, GameEnums.Element.HOLY, "Frappe sacrée fiable.", 1, 1),
		_heal("Imposition des Mains", 4, 1.0, GameEnums.TargetType.SINGLE_ALLY, "Pose les mains sur un allié et le soigne.", 1),
		_atk("Jugement", 6, 2.5, GameEnums.Element.HOLY, "Condamnation divine dévastatrice.", 1, 4),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Croisé", 1.3, 0.05, 1.0, 1.0,
			"Foi guerrière : châtiments sacrés bien plus puissants."),
		_combat_spec("Protecteur de la Foi", 1.0, 0.0, 1.4, 1.2,
			"Bouclier vivant : soins renforcés et grande robustesse."),
	]
	var c := _class("Paladin",
		_stats(145, 16, 16, 9, 0.05),
		_stats(16, 3, 3, 1, 0.0),
		skills,
		"Chevalier sacré : punit, soigne et tient la ligne.",
		specs)
	c.sprite_kind = "paladin"
	return c


## Élémentaliste — mage polyvalent : foudre et glace, dont une rafale.
static func elementalist_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Éclair", 2, 1.4, GameEnums.Element.LIGHTNING, "Décharge rapide et précise.", 1, 1),
		_atk("Stalactites", 4, 0.7, GameEnums.Element.ICE, "Trois pics de glace en rafale.", 3, 1),
		_atk("Tempête", 6, 2.5, GameEnums.Element.LIGHTNING, "Orage dévastateur sur l'ennemi.", 1, 4),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Foudroyeur", 1.35, 0.0, 1.0, 1.0,
			"Maîtrise de la foudre : puissance de sort accrue."),
		_combat_spec("Cryomancien", 1.1, 0.12, 1.0, 1.0,
			"Froid mordant : critiques glacials fréquents."),
	]
	var c := _class("Élémentaliste",
		_stats(92, 21, 7, 12, 0.08),
		_stats(9, 4, 1, 2, 0.005),
		skills,
		"Polyvalence des éléments : foudre vive ou glace en rafale.",
		specs)
	c.sprite_kind = "elementaliste"
	return c


## Moine — arts martiaux : combos de coups rapides et méditation (auto-soin).
static func monk_class() -> ClassData:
	var skills: Array[SkillData] = [
		_atk("Paume de Fer", 2, 1.3, GameEnums.Element.NONE, "Frappe nette et disciplinée.", 1, 1),
		_atk("Rafale de Coups", 4, 0.55, GameEnums.Element.NONE, "Quatre frappes en un souffle.", 4, 1),
		_heal("Méditation", 3, 1.0, GameEnums.TargetType.SELF, "Recentre son souffle et se soigne.", 1),
		_atk("Frappe du Dragon", 5, 2.4, GameEnums.Element.NONE, "Un coup unique d'une force colossale.", 1, 5),
	]
	var specs: Array[SpecializationData] = [
		_combat_spec("Voie du Poing", 1.25, 0.08, 1.0, 1.0,
			"Discipline offensive : coups plus durs et critiques."),
		_combat_spec("Voie de l'Esprit", 1.0, 0.0, 1.4, 1.15,
			"Équilibre intérieur : méditation renforcée et endurance."),
	]
	var c := _class("Moine",
		_stats(118, 18, 11, 17, 0.10),
		_stats(12, 3, 2, 3, 0.01),
		skills,
		"Corps et esprit : enchaîne les coups, se régénère seul.",
		specs)
	c.sprite_kind = "moine"
	return c


## Catalogue de toutes les classes jouables (UI de sélection d'équipe).
static func all_classes() -> Array[ClassData]:
	return [
		guardian_class(),
		pyromancer_class(),
		necromancer_class(),
		duelist_class(),
		cleric_class(),
		berserker_class(),
		ranger_class(),
		paladin_class(),
		elementalist_class(),
		monk_class(),
	]


## Construit un héros jouable à partir d'une classe (niveau 1, sans spé par
## défaut : tout se gagne en jouant). Donne une arme correcte.
static func make_member(name: String, cls: ClassData, spec: SpecializationData = null, level: int = 1) -> CharacterData:
	var w := _weapon("Arme de %s" % cls.display_name, 9, GameEnums.Element.NONE, GameEnums.Rarity.COMMON)
	return _character(name, cls, w, level, spec)

# =============================================================================
# ARMES D'IDENTITÉ & BUTIN
# =============================================================================

## Une arme n'est pas "plus forte", elle est DIFFÉRENTE (cf. vision : l'arme est
## une identité). Chacune pousse un style : vitesse/crit, défense, robustesse…
static func _wpn(name: String, dmg: int, element: GameEnums.Element, rarity: GameEnums.Rarity, agi: int = 0, defe: int = 0, hp: int = 0, crit: float = 0.0, lore: String = "", vkind: String = "sword") -> WeaponData:
	var w := WeaponData.new()
	w.display_name = name
	w.base_damage = dmg
	w.element = element
	w.rarity = rarity
	w.agility_bonus = agi
	w.defense_bonus = defe
	w.max_health_bonus = hp
	w.crit_bonus = crit
	w.lore = lore
	w.visual_kind = vkind
	return w

## Catalogue des armes qui peuvent tomber en butin. Chaque arme a une SILHOUETTE
## distincte (visual_kind) : l'équiper change l'arme tenue à l'écran.
static func loot_weapons() -> Array[WeaponData]:
	return [
		_wpn("Lame Véloce", 8, GameEnums.Element.NONE, GameEnums.Rarity.RARE, 6, 0, 0, 0.08, "Si légère qu'elle semble danser.", "rapier"),
		_wpn("Dague Sanguine", 7, GameEnums.Element.SHADOW, GameEnums.Rarity.RARE, 2, 0, 0, 0.15, "Elle a soif.", "dagger"),
		_wpn("Couperet Brutal", 16, GameEnums.Element.NONE, GameEnums.Rarity.RARE, 0, 0, 0, 0.04, "Un coup, une fin.", "axe"),
		_wpn("Égide du Gardien", 9, GameEnums.Element.HOLY, GameEnums.Rarity.EPIC, 0, 8, 30, 0.0, "Un rempart fait arme.", "sword"),
		_wpn("Marteau de Granit", 14, GameEnums.Element.EARTH, GameEnums.Rarity.RARE, 0, 6, 40, 0.0, "Lourd comme la montagne.", "mace"),
		_wpn("Bâton de Givre", 8, GameEnums.Element.ICE, GameEnums.Rarity.RARE, 3, 0, 10, 0.02, "Le froid obéit.", "staff"),
		_wpn("Faux des Ombres", 12, GameEnums.Element.SHADOW, GameEnums.Rarity.EPIC, 2, 0, 0, 0.10, "La moisson des âmes.", "greatsword"),
		_wpn("Arc du Rôdeur", 10, GameEnums.Element.NONE, GameEnums.Rarity.RARE, 8, 0, 0, 0.05, "Le vent guide la flèche.", "bow"),
	]

## Tire une arme de butin au hasard (communes plus fréquentes que les épiques).
static func random_loot() -> WeaponData:
	var pool := loot_weapons()
	# Pondération simple : les épiques sont 2x plus rares.
	var weights: Array[float] = []
	for w in pool:
		weights.append(0.5 if w.rarity >= GameEnums.Rarity.EPIC else 1.0)
	var total := 0.0
	for x in weights:
		total += x
	var roll := randf() * total
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[0]

## Prix d'achat d'une arme en boutique (selon la rareté).
static func weapon_price(w: WeaponData) -> int:
	match w.rarity:
		GameEnums.Rarity.COMMON: return 20
		GameEnums.Rarity.RARE: return 60
		GameEnums.Rarity.EPIC: return 140
		GameEnums.Rarity.LEGENDARY: return 300
		GameEnums.Rarity.UNIQUE: return 500
	return 80

## Stock de la boutique de la marchande (mêmes armes d'identité que le butin).
static func shop_weapons() -> Array[WeaponData]:
	return loot_weapons()

# =============================================================================
# COMPAGNONS & ÉVÉNEMENTS (première zone)
# =============================================================================

## Kael, un déserteur croisé dans la forêt. Rencontré, jamais imposé.
static func companion_kael() -> CharacterData:
	var c := _character("Kael", duelist_class(),
		_wpn("Lame du Déserteur", 11, GameEnums.Element.NONE, GameEnums.Rarity.EPIC, 5, 0, 0, 0.10,
			"L'épée d'un homme qui a fui une guerre injuste — et le regrette.", "rapier"),
		2)
	c.is_companion = true
	c.bio = "Ancien soldat en fuite. Rapide, méfiant, mais d'une loyauté farouche envers qui lui rend sa dignité."
	return c

## Événement de recrutement dans la forêt. Choix NUANCÉS (ni "bon" ni "mauvais") :
## la décision façonne la loyauté de départ, pas une morale binaire.
## Chaque choix peut embarquer un "companion" (CharacterData) et/ou un
## "item_weapon" (WeaponData) appliqués par l'écran d'événement.
static func forest_recruit_event() -> Dictionary:
	var k1 := companion_kael()
	var k2 := companion_kael()
	return {
		"id": "foret_recrue",
		"title": "Un déserteur sur le chemin",
		"text": "Un homme blessé, l'épée encore au poing, te barre à demi la route. « Je ne cherche pas les ennuis… mais si tu m'aides, ma lame est à toi. »",
		"choices": [
			{"text": "L'aider sans rien exiger", "companion": k1, "loyalty": 65,
				"reply": "Il te dévisage, surpris par ta franchise. « …Alors je me battrai pour toi. Vraiment. » Kael rejoint le groupe."},
			{"text": "Le recruter, mais qu'il prouve sa valeur", "companion": k2, "loyalty": 25,
				"reply": "Il serre les dents. « Marché conclu. » Kael te suit — sans illusions, pour l'instant."},
			{"text": "Le laisser à son sort",
				"reply": "Tu poursuis ta route. L'homme te suit du regard, puis disparaît entre les arbres."},
		],
	}

## Arme unique cachée dans un recoin de la forêt (récompense d'exploration).
static func forest_secret_weapon() -> WeaponData:
	return _wpn("Rosée d'Émeraude", 13, GameEnums.Element.EARTH, GameEnums.Rarity.LEGENDARY,
		4, 4, 20, 0.06, "Une lame oubliée sous la mousse, où perle une sève qui ne sèche jamais.", "sword")

## Événement secret de la forêt : récompense l'exploration d'un recoin caché.
static func forest_secret_event() -> Dictionary:
	return {
		"id": "foret_secret",
		"title": "Une lueur sous la mousse",
		"text": "Dans un creux oublié, à l'écart du sentier, quelque chose scintille faiblement sous les fougères…",
		"choices": [
			{"text": "Dégager la mousse et prendre la lame", "item_weapon": forest_secret_weapon(),
				"reply": "Tu exhumes la Rosée d'Émeraude, une lame légendaire où perle une sève vivante. (Ajoutée à l'inventaire.)"},
		],
	}

## Nom lisible d'une rareté (pour l'UI).
static func rarity_name(r: GameEnums.Rarity) -> String:
	match r:
		GameEnums.Rarity.COMMON: return "Commune"
		GameEnums.Rarity.RARE: return "Rare"
		GameEnums.Rarity.EPIC: return "Épique"
		GameEnums.Rarity.LEGENDARY: return "Légendaire"
		GameEnums.Rarity.UNIQUE: return "Unique"
	return "?"

# =============================================================================
# ÉQUIPE DE DÉPART
# =============================================================================

## Trio de démonstration. Chaque membre illustre un style et une mécanique :
## - Gardien : tanky, met en valeur la parade et le soin de soi.
## - Pyromancien : burst + multi-frappes (Salve de Flammes), fragile.
## - Nécromancien : invocations.
## Tous commencent NIVEAU 1 sans spécialisation : niveaux, compétences et spé
## (au niv.5) se gagnent en jouant (cf. Progression).
static func starting_party() -> Array[CharacterData]:
	var party: Array[CharacterData] = []

	party.append(_character("Aldric", guardian_class(),
		_weapon("Égide de Fer", 10, GameEnums.Element.NONE, GameEnums.Rarity.RARE)))

	party.append(_character("Lyse", pyromancer_class(),
		_weapon("Bâton de Braise", 7, GameEnums.Element.FIRE, GameEnums.Rarity.EPIC)))

	party.append(_character("Mortis", necromancer_class(),
		_weapon("Grimoire d'Os", 6, GameEnums.Element.SHADOW, GameEnums.Rarity.EPIC)))

	return party

static func _character(name: String, cls: ClassData, weapon: WeaponData, level: int = 1, spec: SpecializationData = null) -> CharacterData:
	var c := CharacterData.new()
	c.display_name = name
	c.character_class = cls
	c.weapon = weapon
	c.level = level
	c.chosen_specialization = spec
	return c

# =============================================================================
# ENNEMIS
# =============================================================================

static func _enemy(name: String, boss: bool, arch: GameEnums.Archetype, dmg: int, stats: StatBlock, seqs: Array[int], sprite: String, element: GameEnums.Element = GameEnums.Element.NONE, xp: int = 0, gold: int = 0, enrage: float = 0.0) -> EnemyData:
	var e := EnemyData.new()
	e.display_name = name
	e.is_boss = boss
	e.archetype = arch
	e.base_damage = dmg
	e.stats = stats
	e.attack_sequences = seqs
	e.sprite_kind = sprite
	e.element = element
	e.xp_reward = xp
	e.gold_reward = gold
	e.enrage_threshold = enrage
	return e

## Le Chevalier Déchu : boss agressif aux séquences variables (1/3/5 coups).
static func demo_boss() -> EnemyData:
	return _enemy("Chevalier Déchu", true, GameEnums.Archetype.AGGRESSIVE, 22,
		_stats(420, 24, 14, 12, 0.07), [1, 3, 5], "boss_chevalier", GameEnums.Element.SHADOW, 60)

## Rencontre de démo : montre les archétypes d'IA.
## - Chevalier Déchu : AGRESSIF (va pour le kill).
## - Garde Squelette : PROTECTEUR (intercepte les coups quand le boss est bas).
## - Acolyte Profane : MANIPULATEUR (renforce le boss / affaiblit les héros).
static func demo_encounter() -> Array[EnemyData]:
	return [
		demo_boss(),
		_enemy("Garde Squelette", false, GameEnums.Archetype.PROTECTOR, 12,
			_stats(120, 12, 18, 9, 0.0), [1, 2], "garde_squelette", GameEnums.Element.NONE, 22, 12),
		_enemy("Acolyte Profane", false, GameEnums.Archetype.MANIPULATOR, 8,
			_stats(90, 8, 8, 13, 0.0), [1], "acolyte", GameEnums.Element.SHADOW, 18, 10),
	]

# =============================================================================
# PREMIÈRE ZONE : Clairière d'Émeraude (forêt) — démo dense
# =============================================================================

static func _encounter(id: String, name: String, foes: Array[EnemyData]) -> EncounterData:
	var e := EncounterData.new()
	e.id = id
	e.display_name = name
	e.enemies = foes
	return e

## Les rencontres de la forêt : 3 combats variés (répétables) + un boss à phases.
## Chacune met en avant des archétypes/styles différents (pas juste des sacs à PV).
static func forest_encounters() -> Array[EncounterData]:
	var list: Array[EncounterData] = []

	# 1) Meute de loups : rapides et agressifs, l'alpha pousse à l'attaque.
	list.append(_encounter("foret_loups", "Meute de Loups", [
		_enemy("Loup Alpha", false, GameEnums.Archetype.AGGRESSIVE, 13,
			_stats(95, 16, 8, 18, 0.10), [1, 2], "loup", GameEnums.Element.NONE, 16, 12),
		_enemy("Loup Affamé", false, GameEnums.Archetype.AGGRESSIVE, 10,
			_stats(60, 12, 5, 16, 0.06), [1], "loup", GameEnums.Element.NONE, 9, 6),
		_enemy("Loup Affamé", false, GameEnums.Archetype.OPPORTUNIST, 10,
			_stats(60, 12, 5, 15, 0.06), [1], "loup", GameEnums.Element.NONE, 9, 6),
	]))

	# 2) Embuscade de bandits : un costaud défensif + harceleurs opportunistes.
	list.append(_encounter("foret_bandits", "Embuscade de Bandits", [
		_enemy("Brigand Costaud", false, GameEnums.Archetype.DEFENSIVE, 14,
			_stats(140, 15, 16, 8, 0.04), [1, 2], "bandit", GameEnums.Element.NONE, 18, 16),
		_enemy("Bandit", false, GameEnums.Archetype.OPPORTUNIST, 11,
			_stats(85, 13, 8, 13, 0.07), [1, 2], "bandit", GameEnums.Element.NONE, 12, 10),
		_enemy("Coupe-Jarret", false, GameEnums.Archetype.AGGRESSIVE, 12,
			_stats(80, 14, 7, 15, 0.10), [1, 2], "bandit", GameEnums.Element.NONE, 12, 10),
	]))

	# 3) Morts-vivants : protecteur + manipulateur (combat tactique).
	list.append(_encounter("foret_mortsvivants", "Mort-vivants de la Clairière", [
		_enemy("Garde Squelette", false, GameEnums.Archetype.PROTECTOR, 12,
			_stats(130, 12, 18, 9, 0.0), [1, 2], "garde_squelette", GameEnums.Element.NONE, 16, 12),
		_enemy("Zombie Putride", false, GameEnums.Archetype.AGGRESSIVE, 13,
			_stats(120, 14, 10, 6, 0.0), [1], "zombie", GameEnums.Element.SHADOW, 14, 10),
		_enemy("Acolyte Profane", false, GameEnums.Archetype.MANIPULATOR, 9,
			_stats(90, 9, 8, 13, 0.0), [1], "acolyte", GameEnums.Element.SHADOW, 16, 12),
	]))

	# 4) BOSS : Gorth, le Chef Bandit. Phase 1 défensif (il temporise), puis à 50%
	# de PV il ENRAGE → devient agressif, frappe plus fort et enchaîne. Escorté.
	list.append(_encounter("foret_boss", "Gorth, le Chef Bandit", [
		_enemy("Gorth, le Chef Bandit", true, GameEnums.Archetype.DEFENSIVE, 20,
			_stats(360, 22, 16, 11, 0.06), [2, 3], "bandit_chef", GameEnums.Element.NONE, 90, 70, 0.5),
		_enemy("Bandit", false, GameEnums.Archetype.PROTECTOR, 11,
			_stats(95, 12, 12, 11, 0.05), [1, 2], "bandit", GameEnums.Element.NONE, 14, 12),
		_enemy("Coupe-Jarret", false, GameEnums.Archetype.OPPORTUNIST, 12,
			_stats(85, 14, 7, 14, 0.10), [1, 2], "bandit", GameEnums.Element.NONE, 14, 12),
	]))

	return list

## Rencontres disponibles dans une zone donnée (vide = zone non détaillée).
static func encounters_for_zone(zone_id: String) -> Array[EncounterData]:
	if zone_id == "clairiere":
		return forest_encounters()
	return []
