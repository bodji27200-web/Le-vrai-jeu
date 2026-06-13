## Définition d'une arme. L'arme est une identité du personnage (cf. vision).
class_name WeaponData
extends Resource

@export var display_name: String = "Lame rouillée"
@export var element: GameEnums.Element = GameEnums.Element.NONE
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export var level: int = 1
@export var base_damage: int = 8
@export_range(0.0, 3.0, 0.05) var strength_scaling: float = 1.0
@export_multiline var lore: String = ""
