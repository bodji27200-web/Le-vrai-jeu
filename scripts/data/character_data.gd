## Un personnage jouable concret : sa classe, son arme, son niveau.
class_name CharacterData
extends Resource

@export var display_name: String = ""
@export var character_class: ClassData
@export var weapon: WeaponData
@export var level: int = 1
@export var xp: int = 0                              ## Points d'expérience vers le niveau suivant.
@export var chosen_specialization: SpecializationData
@export var portrait: Texture2D
