## Un personnage jouable concret : sa classe, son arme, son niveau.
class_name CharacterData
extends Resource

@export var display_name: String = ""
@export var character_class: ClassData
@export var weapon: WeaponData
@export var level: int = 1
@export var xp: int = 0                              ## Points d'expérience vers le niveau suivant.
@export var chosen_specialization: SpecializationData
@export var portrait: Texture2D
# --- Compagnon (personnage rencontré, pas un héros de départ) -----------------
@export var is_companion: bool = false
@export var loyalty: int = 0                         ## 0..100. Influence le comportement/les bonus.
@export_multiline var bio: String = ""              ## Histoire courte du compagnon.
# --- Attributs alloués par le joueur (build), cf. montée de niveau -------------
## Points dépensés dans chaque attribut. Bonus additifs appliqués au combat.
@export var att_vitalite: int = 0   ## +PV
@export var att_force: int = 0      ## +puissance d'attaque
@export var att_agilite: int = 0    ## +agilité (ordre des tours)
@export var att_defense: int = 0    ## +défense
@export var att_chance: int = 0     ## +chance de critique
