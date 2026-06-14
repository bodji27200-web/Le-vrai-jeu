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
@export var gold_reward: int = 0        ## Or donné quand il est vaincu.
## Boss à phases : sous ce ratio de PV (0 = pas de phase), le boss "enrage" —
## il devient AGRESSIF (va pour le kill), frappe plus fort et enchaîne plus.
@export_range(0.0, 1.0, 0.05) var enrage_threshold: float = 0.0
@export var enrage_damage_mult: float = 1.35
