## Conteneur éditable du monde : la liste des zones de l'overworld.
## Stocke une Array[ZoneData] dans un .tres unique éditable dans l'inspecteur.
class_name WorldData
extends Resource

@export var zones: Array[ZoneData] = []
