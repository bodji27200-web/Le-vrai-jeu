## Test runtime des vues de combat (armes, ombres, animations directionnelles,
## tranches). Instancie une vue par type d'unité, joue les animations et fait
## tourner les tweens quelques frames. Détecte les erreurs (tween sur null, etc.).
##   godot --headless --script res://tests/smoke_view.gd
extends SceneTree


func _initialize() -> void:
	var kinds := [
		"gardien", "boss_chevalier", "paladin", "duelliste", "berserker", "rodeur",
		"moine", "pyromancien", "necromancien", "elementaliste", "acolyte", "clerc",
		"garde_squelette", "zombie", "goule", "aberration", "",
	]
	var x := 80
	for i in kinds.size():
		var k: String = kinds[i]
		var enemy := i % 2 == 0
		var v := CombatantView.new()
		root.add_child(v)
		v.setup("T", k, Vector2(60, 90), enemy)
		v.set_home(Vector2(x, 300))
		# Joue chaque coup de l'enchaînement (anims différentes) + une tranche.
		var geo0: Dictionary = v.attack_geometry(0)
		var geo1: Dictionary = v.attack_geometry(1)
		assert(geo0.has("slash") and geo0.has("flip") and geo0.has("caster"))
		v.play_attack(Vector2(x + 200, 300), 0)
		var s := SlashFX.new()
		root.add_child(s)
		s.position = Vector2(x, 290)
		s.slash(geo1.slash, Color(1, 0.9, 0.7), 70.0, geo1.flip)
		v.play_parry()
		v.play_dodge()
		v.play_hit()
		x += 60

	# Quelques frames pour exécuter les tweens (là où les bugs apparaissent).
	for _i in 24:
		await process_frame

	print("OK : %d vues (armes + ombres + anims directionnelles + tranches) sans erreur." % kinds.size())
	quit()
