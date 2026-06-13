## Définition d'une classe : stats de base, croissance, compétences.
## Les spécialisations/arbres viendront dans un milestone dédié.
class_name ClassData
extends Resource

@export var display_name: String = ""
@export var base_stats: StatBlock
@export var growth_per_level: StatBlock
@export var skills: Array[SkillData] = []
@export var specializations: Array[SpecializationData] = []
@export var sprite_kind: String = ""   ## Clé du sprite pixel art (cf. PixelArt).
@export_multiline var identity: String = ""
