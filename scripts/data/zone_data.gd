## Définition d'une zone explorable. Affichée en miniature sur l'overworld,
## puis chargée "en grand" quand on y entre.
class_name ZoneData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var overworld_position: Vector2 = Vector2.ZERO   ## Place sur la carte du monde.
@export var theme_color: Color = Color(0.35, 0.55, 0.4)
@export_multiline var description: String = ""
@export var has_encounter: bool = true                   ## Contient un combat ?
