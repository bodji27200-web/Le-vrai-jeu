## Style de combat par type d'unité : quelle arme, quel enchaînement de coups,
## et la géométrie de chaque coup (angles de l'arme, élan, orientation de la
## tranche). Data-driven : tout est piloté par `sprite_kind`, pas en dur dans la
## logique. CombatantView lit ces tables pour animer des coups VARIÉS et lisibles.
class_name CombatStyle

# Un "coup" décrit comment l'arme bouge et d'où vient la tranche.
# Angles en degrés, repère du héros (0 = lame vers le haut, sens horaire ;
# +90 = vers l'avant/ennemi). CombatantView miroite pour les ennemis.
#   raise : angle de l'arme pendant l'armement (tell)
#   swing : angle final après la frappe (le balayage va de raise -> swing)
#   lunge : distance dont le corps avance vers la cible
#   slash : orientation de la tranche lumineuse à l'impact
const MOVES := {
	"overhead": {"raise": -155.0, "swing": 95.0, "lunge": 70.0, "slash": 90.0},   # de haut en bas
	"right":    {"raise": -25.0, "swing": 160.0, "lunge": 62.0, "slash": 35.0},   # de la droite, à l'horizontale
	"left":     {"raise": 195.0, "swing": 20.0, "lunge": 62.0, "slash": -35.0},   # de la gauche, en remontant
	"thrust":   {"raise": 80.0, "swing": 96.0, "lunge": 104.0, "slash": 90.0},    # estoc (avance loin)
	"chop":     {"raise": -170.0, "swing": 105.0, "lunge": 84.0, "slash": 90.0},  # coup lourd vertical
	"cast":     {"raise": -120.0, "swing": -120.0, "lunge": 16.0, "slash": 90.0}, # incantation (pas de balayage)
	"shoot":    {"raise": 90.0, "swing": 90.0, "lunge": 0.0, "slash": 90.0},      # tir à distance
}

# Pour chaque type d'unité : arme + enchaînement de coups + drapeaux.
# weapon "" = mains nues (griffes/poings) : pas de sprite d'arme, le corps frappe.
const STYLES := {
	"gardien":         {"weapon": "sword", "moves": ["overhead", "right", "left"]},
	"boss_chevalier":  {"weapon": "greatsword", "moves": ["chop", "right", "overhead"], "scale": 1.25},
	"paladin":         {"weapon": "sword", "moves": ["right", "overhead", "left"]},
	"duelliste":       {"weapon": "rapier", "moves": ["thrust", "left", "thrust", "right"]},
	"berserker":       {"weapon": "axe", "moves": ["overhead", "left", "chop"], "scale": 1.15},
	"rodeur":          {"weapon": "bow", "moves": ["shoot", "shoot"], "ranged": true},
	"moine":           {"weapon": "", "moves": ["left", "right", "left", "right"], "scale": 0.9},
	"pyromancien":     {"weapon": "staff_fire", "moves": ["cast"], "caster": true},
	"necromancien":    {"weapon": "staff_dark", "moves": ["cast"], "caster": true},
	"elementaliste":   {"weapon": "staff", "moves": ["cast"], "caster": true},
	"acolyte":         {"weapon": "staff_dark", "moves": ["cast"], "caster": true},
	"clerc":           {"weapon": "staff_holy", "moves": ["cast"], "caster": true},
	"garde_squelette": {"weapon": "sword", "moves": ["right", "overhead"]},
	"zombie":          {"weapon": "", "moves": ["overhead", "right"], "scale": 1.0},
	"goule":           {"weapon": "", "moves": ["left", "right", "left"], "scale": 0.95},
	"aberration":      {"weapon": "", "moves": ["chop"], "scale": 1.1},
}

const DEFAULT_STYLE := {"weapon": "sword", "moves": ["right", "left"]}


static func for_kind(kind: String) -> Dictionary:
	var s: Dictionary = STYLES.get(kind, DEFAULT_STYLE)
	return {
		"weapon": s.get("weapon", "sword"),
		"moves": s.get("moves", ["right", "left"]),
		"caster": s.get("caster", false),
		"ranged": s.get("ranged", false),
		"scale": s.get("scale", 1.0),
	}


## Paramètres géométriques d'un coup (clé issue de la liste "moves" du style).
static func move(key: String) -> Dictionary:
	return MOVES.get(key, MOVES["right"])
