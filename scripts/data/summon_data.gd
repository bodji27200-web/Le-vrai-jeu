## Définition d'une invocation (créature convoquée par une compétence).
## Chaque rôle joue différemment (cf. vision Nécromancien).
class_name SummonData
extends Resource

@export var display_name: String = ""
@export var role: GameEnums.SummonRole = GameEnums.SummonRole.OFFENSIVE
@export var stats: StatBlock
@export var base_damage: int = 10
@export var attacks_per_turn: int = 1   ## La goule rapide en a 2, par ex.
@export var taunt: bool = false         ## Le tank attire les attaques ennemies.
@export var body_color: Color = Color(0.6, 0.6, 0.6)
@export var sprite_kind: String = ""    ## Clé du sprite pixel art (cf. PixelArt).
