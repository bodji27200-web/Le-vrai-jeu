## Définition d'une arme. L'arme est une identité du personnage (cf. vision).
class_name WeaponData
extends Resource

@export var display_name: String = "Lame rouillée"
## Sprite d'arme tenue en main (cf. PixelArt.for_weapon) : sword, greatsword,
## rapier, dagger, axe, mace, spear, bow, staff, staff_fire/dark/holy.
## Vide = on garde l'arme par défaut de la classe (CombatStyle).
@export var visual_kind: String = ""
@export var element: GameEnums.Element = GameEnums.Element.NONE
@export var rarity: GameEnums.Rarity = GameEnums.Rarity.COMMON
@export var level: int = 1
@export var base_damage: int = 8
@export_range(0.0, 3.0, 0.05) var strength_scaling: float = 1.0
## Bonus d'identité : une arme n'est pas forcément "plus forte", elle est
## DIFFÉRENTE (rapide/critique, défensive, robuste…). Appliqués au combattant.
@export var agility_bonus: int = 0
@export var defense_bonus: int = 0
@export var max_health_bonus: int = 0
@export_range(0.0, 1.0, 0.01) var crit_bonus: float = 0.0
@export_multiline var lore: String = ""
