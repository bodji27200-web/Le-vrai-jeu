## Définition d'une compétence. Consomme du mana, applique un multiplicateur.
class_name SkillData
extends Resource

@export var display_name: String = ""
@export var mana_cost: int = 0
@export_range(0.0, 5.0, 0.05) var power: float = 1.0   ## Multiplicateur de dégâts.
@export var target_type: GameEnums.TargetType = GameEnums.TargetType.SINGLE_ENEMY
@export var element: GameEnums.Element = GameEnums.Element.NONE
@export_multiline var description: String = ""
## Nombre de coups portés (combo). > 1 = compétence multi-frappes (duelliste, salve…).
@export var hits: int = 1
## Si > 0, la compétence SOIGNE au lieu d'infliger des dégâts (multiplicateur).
## La cible suit `target_type` (SELF / SINGLE_ALLY / ALL_ALLIES).
@export_range(0.0, 5.0, 0.05) var heal_power: float = 0.0
## Niveau requis pour débloquer la compétence (socle d'arbre de progression).
@export var unlock_level: int = 1
## Si défini, la compétence invoque cette créature au lieu d'infliger des dégâts.
@export var summon: SummonData
