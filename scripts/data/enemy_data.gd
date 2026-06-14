## Définition d'un ennemi ou boss.
## attack_sequences : chaque entrée = nombre d'attaques enchaînées d'une séquence.
## Parer TOUTE une séquence déclenche le Contre Parfait (cf. vision).
class_name EnemyData
extends Resource

@export var display_name: String = ""
@export var stats: StatBlock
@export var archetype: GameEnums.Archetype = GameEnums.Archetype.AGGRESSIVE
@export var is_boss: bool = false
@export var base_damage: int = 12
@export var element: GameEnums.Element = GameEnums.Element.NONE
@export var sprite_kind: String = ""   ## Clé du sprite pixel art (cf. PixelArt).
## Options de séquences (ex : [1, 3, 5] = le boss choisit 1, 3 ou 5 coups).
@export var attack_sequences: Array[int] = [1]
@export var xp_reward: int = 0          ## XP donnée à l'équipe quand il est vaincu.
