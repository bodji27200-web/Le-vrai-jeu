## Bloc de statistiques réutilisable (stats de base OU croissance par niveau).
class_name StatBlock
extends Resource

@export var max_health: int = 100
@export var strength: int = 10
@export var defense: int = 10
@export var agility: int = 10          ## Influence l'ordre des tours.
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05
