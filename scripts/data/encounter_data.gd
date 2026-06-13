## Conteneur éditable d'une rencontre (groupe d'ennemis).
## Stocke une Array[EnemyData] dans un .tres unique éditable dans l'inspecteur.
class_name EncounterData
extends Resource

@export var display_name: String = ""
@export var enemies: Array[EnemyData] = []
