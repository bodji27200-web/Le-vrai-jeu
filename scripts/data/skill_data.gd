## Définition d'une compétence. Consomme du mana, applique un multiplicateur.
class_name SkillData
extends Resource

@export var display_name: String = ""
@export var mana_cost: int = 0
@export_range(0.0, 5.0, 0.05) var power: float = 1.0   ## Multiplicateur de dégâts.
@export var target_type: GameEnums.TargetType = GameEnums.TargetType.SINGLE_ENEMY
@export var element: GameEnums.Element = GameEnums.Element.NONE
@export_multiline var description: String = ""
## Si défini, la compétence invoque cette créature au lieu d'infliger des dégâts.
@export var summon: SummonData
