## Spécialisation d'une classe. Doit changer RÉELLEMENT la façon de jouer
## (cf. vision), pas juste donner des bonus passifs cosmétiques.
## Pour le Nécromancien : "Seigneur de la Charogne" (invocations puissantes) vs
## "Faucheur d'Âmes" (sorts directs puissants, invocations sacrifiables).
class_name SpecializationData
extends Resource

@export var display_name: String = ""
@export_multiline var description: String = ""
@export var summon_hp_mult: float = 1.0
@export var summon_damage_mult: float = 1.0
@export var skill_power_mult: float = 1.0      ## Multiplie les dégâts des sorts du lanceur.
@export var mana_on_summon_death: int = 0      ## Mana gagné quand une invocation meurt.
