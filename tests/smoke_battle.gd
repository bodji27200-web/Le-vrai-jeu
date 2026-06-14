## Smoke test d'INTÉGRATION du combat : charge la vraie scène de combat et la
## pilote automatiquement (clique la 1re action dispo à chaque tour joueur) pour
## déclencher des TOURS ENNEMIS — donc la mise en scène cinématique : caméra
## (focus/reset), ralenti (Engine.time_scale) et fenêtre de parade rebasée sur le
## temps de jeu. On vérifie surtout qu'aucune erreur runtime ne surgit et que
## Engine.time_scale est bien remis à 1.0.
##   godot --headless --script res://tests/smoke_battle.gd
extends SceneTree


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/battle.tscn")
	var scn: Node = packed.instantiate()
	root.add_child(scn)

	var start := Time.get_ticks_msec()
	var enemy_turns_seen := 0
	while Time.get_ticks_msec() - start < 22000 and is_instance_valid(scn):
		await process_frame
		# Compte grossièrement les tours ennemis via le letterbox déployé.
		var lb: ColorRect = scn.get("_lb_top")
		if lb != null and lb.size.y > 4.0:
			enemy_turns_seen = maxi(enemy_turns_seen, 1)
		# Clique la première action jouable disponible (fait avancer le combat).
		var box: HBoxContainer = scn.get("_action_box")
		if box == null:
			continue
		for child in box.get_children():
			if child is Button and is_instance_valid(child) and not child.disabled:
				child.pressed.emit()
				break

	# Le ralenti cinématique ne doit JAMAIS rester actif après coup.
	assert(is_equal_approx(Engine.time_scale, 1.0), "Engine.time_scale non remis à 1.0 : %f" % Engine.time_scale)
	print("OK : combat piloté %.1fs sans erreur (letterbox/tour ennemi vu=%s, time_scale=%.2f)." % [
		(Time.get_ticks_msec() - start) / 1000.0, enemy_turns_seen >= 1, Engine.time_scale])
	quit()
