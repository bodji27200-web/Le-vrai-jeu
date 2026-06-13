## Réglages globaux (difficulté). Volontairement minimal pour le Milestone 1.
## La difficulté n'est PAS un simple multiplicateur de dégâts : elle resserre
## les fenêtres de parade et augmente l'agressivité ennemie (cf. vision Hardcore).
class_name GameSettings

static var difficulty: GameEnums.Difficulty = GameEnums.Difficulty.NORMAL

## Multiplie la largeur de la fenêtre de parade. < 1.0 = plus dur.
static func parry_window_scale() -> float:
	match difficulty:
		GameEnums.Difficulty.EASY:
			return 1.6
		GameEnums.Difficulty.NORMAL:
			return 1.0
		GameEnums.Difficulty.HARD:
			return 0.75
		GameEnums.Difficulty.HARDCORE:
			return 0.55
	return 1.0

## Multiplie la longueur des séquences d'attaque des boss (arrondi).
static func enemy_aggression_scale() -> float:
	match difficulty:
		GameEnums.Difficulty.EASY:
			return 0.7
		GameEnums.Difficulty.NORMAL:
			return 1.0
		GameEnums.Difficulty.HARD:
			return 1.15
		GameEnums.Difficulty.HARDCORE:
			return 1.35
	return 1.0

static func difficulty_name() -> String:
	match difficulty:
		GameEnums.Difficulty.EASY:
			return "Facile"
		GameEnums.Difficulty.NORMAL:
			return "Normal"
		GameEnums.Difficulty.HARD:
			return "Difficile"
		GameEnums.Difficulty.HARDCORE:
			return "Hardcore"
	return "Normal"
