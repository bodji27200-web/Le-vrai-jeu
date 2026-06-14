## Scène de combat jouable.
## Tour par tour, 3 héros contre un boss. La défense est une RÉACTION à
## l'animation d'attaque ennemie : l'ennemi s'élance, et au moment de l'impact
## le joueur presse ESPACE (parer) ou MAJ (esquiver). Aucune barre de timing :
## c'est l'animation qui sert de repère, pour une sensation de vrai combat.
extends Node2D

# --- Fenêtres de timing (secondes), relatives à l'impact ---------------------
const PARRY_HALF := 0.12     ## Demi-fenêtre de parade (±), resserrée par la difficulté.
const DODGE_EARLY := 0.28    ## Esquive valide jusqu'à 0.28 s avant l'impact...
const DODGE_LATE := 0.16     ## ...et 0.16 s après.
const TAIL := 0.12           ## Marge d'écoute après l'impact.
const PARRY_MANA_GAIN := 1   ## Volontairement modeste (équilibrage).

# --- Placement sur le champ de bataille ---------------------------------------
const HERO_POS := [Vector2(300, 230), Vector2(300, 350), Vector2(300, 470)]
const SUMMON_POS := [Vector2(140, 300), Vector2(140, 440)]   ## Max 2 invocations.
const ENEMY_SLOTS := [Vector2(920, 320), Vector2(740, 200), Vector2(740, 440)]

# --- État du combat ----------------------------------------------------------
var _players: Array[Combatant] = []    ## Les héros (déterminent victoire/défaite).
var _summons: Array[Combatant] = []    ## Invocations actives (max 2).
var _summon_slots := {}                ## Combatant -> index de SUMMON_POS
var _enemies: Array[Combatant] = []
var _views := {}                       ## Combatant -> CombatantView
var _last_target: Combatant = null     ## Pour varier le ciblage ennemi.
var _round := 0
var _battle_xp := 0                     ## XP totale de la rencontre (somme des ennemis).
var _camera: BattleCamera
var _stage: BattleStage                 ## Décor isométrique (fond + sol).
var _field: Node2D                      ## Combattants, triés en profondeur (y-sort).
var _fx_root: Node2D                    ## FX (tranches, nombres, étincelles) au-dessus.

# --- Capture de défense active -----------------------------------------------
var _capturing := false
var _capture_start_ms := 0
var _def_input := ""                    ## "", "parry" ou "dodge"
var _def_time := -1.0
var _current_defender_view: CombatantView = null

# --- Références HUD -----------------------------------------------------------
var _enemy_name: Label
var _enemy_hp: ProgressBar
var _status: Label
var _log_label: RichTextLabel
var _action_box: HBoxContainer
var _diff_label: Label
var _end_box: VBoxContainer
var _timeline_box: HBoxContainer

signal _ui_action(kind: String, payload: Variant)


func _ready() -> void:
	_build_teams()
	_build_stage()
	_build_views()
	_build_hud()
	_refresh_ui()
	_run_battle()


## Construit la pile de rendu : décor isométrique (fond), terrain trié en
## profondeur (y-sort), puis FX par-dessus.
func _build_stage() -> void:
	_stage = BattleStage.new()
	_stage.screen = get_viewport_rect().size
	# Sol dimensionné et centré pour contenir TOUS les emplacements (héros,
	# invocations, ennemis) avec marge : sinon les unités du haut/gauche
	# débordaient du losange. Coordonnées en repère de base 1152x648 (l'étirement
	# canvas_items garde get_viewport_rect() à cette taille).
	_stage.floor_center = Vector2(560, 380)
	_stage.floor_half = Vector2(760, 330)
	add_child(_stage)

	_field = Node2D.new()
	_field.y_sort_enabled = true       # les unités au premier plan passent devant
	add_child(_field)

	_fx_root = Node2D.new()
	add_child(_fx_root)


func _unhandled_input(event: InputEvent) -> void:
	if not _capturing or _def_input != "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_register_defense("parry")
		elif event.keycode == KEY_SHIFT:
			_register_defense("dodge")


## Enregistre l'input ET joue immédiatement la réaction visuelle (game feel).
func _register_defense(kind: String) -> void:
	_def_input = kind
	_def_time = (Time.get_ticks_msec() - _capture_start_ms) / 1000.0
	if _current_defender_view != null:
		if kind == "parry":
			_current_defender_view.play_parry()
		else:
			_current_defender_view.play_dodge()


# =============================================================================
# Mise en place
# =============================================================================

func _build_teams() -> void:
	# Équipe PERSISTANTE (la même d'un combat à l'autre, elle gagne de l'XP).
	for c in Game.get_party():
		_players.append(Combatant.from_character(c))
	for e in ContentDB.demo_encounter():
		var foe := Combatant.from_enemy(e)
		_enemies.append(foe)
		_battle_xp += foe.xp_reward


func _build_views() -> void:
	for i in _players.size():
		var v := CombatantView.new()
		_field.add_child(v)
		v.setup(_players[i].display_name, _players[i].sprite_kind, Vector2(60, 90), false)
		v.set_home(HERO_POS[i])
		_views[_players[i]] = v
	for i in _enemies.size():
		var e := _enemies[i]
		var ev := CombatantView.new()
		_field.add_child(ev)
		var size := Vector2(95, 135) if e.is_boss else Vector2(70, 100)
		ev.setup(e.display_name, e.sprite_kind, size, true)
		ev.set_home(ENEMY_SLOTS[i] if i < ENEMY_SLOTS.size() else Vector2(740, 320))
		_views[e] = ev

	# Caméra centrée : les coordonnées du monde correspondent à l'écran 1:1.
	_camera = BattleCamera.new()
	add_child(_camera)
	_camera.position = get_viewport_rect().size * 0.5


func _all() -> Array:
	var a: Array = []
	a.append_array(_players)
	a.append_array(_summons)
	a.append_array(_enemies)
	return a


## Cibles potentielles du camp ennemi : héros + invocations.
func _player_allies() -> Array:
	var a: Array = []
	a.append_array(_players)
	a.append_array(_summons)
	return a


func _alive(team: Array) -> Array:
	return team.filter(func(c: Combatant) -> bool: return c.is_alive())


# =============================================================================
# Boucle principale
# =============================================================================

func _run_battle() -> void:
	_log("[b]Le combat commence ![/b] Au tour ennemi, réagis à l'animation : [color=aqua]ESPACE[/color] = parer (précis), [color=yellow]MAJ[/color] = esquiver.")
	while not _is_over():
		_round += 1
		var order := CombatResolver.turn_order(_all())
		for idx in order.size():
			var actor: Combatant = order[idx]
			# Ignore les morts et les invocations renvoyées (vue libérée).
			if not actor.is_alive() or _is_over() or not _views.has(actor):
				continue
			_begin_turn(actor)
			_refresh_timeline(order, idx)
			if not actor.is_player:
				await _enemy_turn(actor)
			elif actor.auto_act:
				await _summon_turn(actor)
			else:
				await _player_turn(actor)
			_end_turn(actor)
			_refresh_ui()
			await get_tree().create_timer(0.15).timeout
	_show_end_screen()


## Début de tour : on lève les effets "jusqu'à ma prochaine action"
## (la garde a fait son office pendant les tours adverses).
func _begin_turn(actor: Combatant) -> void:
	actor.damage_taken_mult = 1.0
	actor.guarding = null


## Fin de tour : on consomme les effets liés à l'action de l'unité (renfort/affaiblissement).
func _end_turn(actor: Combatant) -> void:
	actor.damage_dealt_mult = 1.0


func _is_over() -> bool:
	return _alive(_players).is_empty() or _alive(_enemies).is_empty()


# =============================================================================
# Tour du joueur
# =============================================================================

func _player_turn(actor: Combatant) -> void:
	_set_status("%s — choisis une action" % actor.display_name)
	while true:
		_clear_actions()
		var atk := _add_action_button("Attaque")
		atk.pressed.connect(func() -> void: _ui_action.emit("attack", null), CONNECT_ONE_SHOT)
		for i in actor.skills.size():
			var sk := actor.skills[i]
			var btn := _add_action_button("%s\n(%d mana)" % [sk.display_name, sk.mana_cost])
			btn.disabled = actor.mana < sk.mana_cost
			btn.pressed.connect(func() -> void: _ui_action.emit("skill", i), CONNECT_ONE_SHOT)

		var result: Array = await _ui_action
		var kind: String = result[0]
		var payload: Variant = result[1]

		var power := 1.0
		var cost := 0
		var label := "Attaque"
		var hits := 1
		var heal_power := 0.0
		var ttype := GameEnums.TargetType.SINGLE_ENEMY
		if kind == "skill":
			var sk := actor.skills[payload]
			# Compétence d'invocation : pas de cible ennemie, on convoque.
			if sk.summon != null:
				actor.spend_mana(sk.mana_cost)
				_clear_actions()
				await _do_summon(actor, sk.summon)
				break
			power = sk.power
			cost = sk.mana_cost
			label = sk.display_name
			hits = maxi(1, sk.hits)
			heal_power = sk.heal_power
			ttype = sk.target_type

		# Compétence de soin / soutien : cible des alliés, ne fait pas de dégâts.
		if heal_power > 0.0:
			var healed := await _do_heal(actor, label, cost, heal_power, ttype)
			if not healed:
				continue   # soin annulé : on rouvre le menu
			break

		# Le bonus de spécialisation (ex : Faucheur d'Âmes) renforce l'offensive.
		power *= actor.skill_power_mult

		var targets := _alive(_enemies)
		var target: Combatant
		if targets.size() == 1:
			target = targets[0]
		else:
			target = await _pick_target(targets)
			if target == null:
				continue

		# Un protecteur peut intercepter l'attaque pour son allié.
		var guardian := _guardian_of(target)
		if guardian != null:
			_log("[color=violet]%s intercepte l'attaque pour %s ![/color]" % [guardian.display_name, target.display_name])
			target = guardian

		if cost > 0:
			actor.spend_mana(cost)

		_clear_actions()
		await _do_player_attack(actor, target, power, label, hits)
		break

	_clear_actions()


## Exécute l'attaque du joueur. `hits` > 1 = combo multi-frappes (duelliste, salve).
func _do_player_attack(actor: Combatant, target: Combatant, power: float, label: String, hits: int) -> void:
	var actor_view: CombatantView = _views[actor]
	for h in maxi(1, hits):
		if not target.is_alive():
			break
		var target_view: CombatantView = _views[target]
		actor_view.play_attack(target_view.home, h)
		await get_tree().create_timer(CombatantView.WINDUP + CombatantView.STRIKE).timeout
		var dmg: Dictionary = CombatResolver.attack_damage(actor, target, power)
		target.take_damage(dmg.damage)
		target_view.play_hit()
		_spawn_slash(target_view, actor_view.attack_geometry(h), Color(1, 0.95, 0.78) if not dmg.crit else Color(1, 0.8, 0.35))
		_impact_fx(target_view, str(dmg.damage), Color(1, 0.85, 0.3) if dmg.crit else Color(1, 0.95, 0.95), dmg.crit)
		if dmg.crit:
			await _hitstop()
		var crit_txt := " [color=orange]CRITIQUE ![/color]" if dmg.crit else ""
		var hit_txt := " [color=gray](%d/%d)[/color]" % [h + 1, hits] if hits > 1 else ""
		_log("%s utilise [b]%s[/b] sur %s : [color=red]%d[/color]%s%s" % [actor.display_name, label, target.display_name, dmg.damage, crit_txt, hit_txt])
		_refresh_ui()
		if not target.is_alive():
			target_view.set_dead()
			break
		if hits > 1:
			await get_tree().create_timer(0.18).timeout


## Exécute un soin. Retourne false si le joueur annule (menu rouvert sans coût).
func _do_heal(actor: Combatant, label: String, cost: int, heal_power: float, ttype: GameEnums.TargetType) -> bool:
	var allies := _alive(_player_allies())
	var targets: Array = []
	match ttype:
		GameEnums.TargetType.SELF:
			targets = [actor]
		GameEnums.TargetType.ALL_ALLIES:
			targets = allies
		_:   # SINGLE_ALLY (et repli pour les autres types)
			if allies.size() <= 1:
				targets = [actor]
			else:
				var chosen := await _pick_ally(allies)
				if chosen == null:
					return false
				targets = [chosen]

	if cost > 0:
		actor.spend_mana(cost)
	_clear_actions()
	# Bref temps d'incantation (pas d'animation de charge pour rester sobre).
	await get_tree().create_timer(0.25).timeout

	var amount := CombatResolver.heal_amount(actor, heal_power)
	for t in targets:
		t.heal(amount)
		_spawn_spark(_views[t], Color(0.6, 1.0, 0.7))
		_spawn_damage(_views[t], "+%d" % amount, Color(0.55, 1.0, 0.6), targets.size() == 1)
	_camera.add_trauma(0.15)
	var group_txt := " [color=gray](groupe)[/color]" if targets.size() > 1 else ""
	_log("%s lance [b]%s[/b] : [color=lime]+%d PV[/color]%s" % [actor.display_name, label, amount, group_txt])
	_refresh_ui()
	return true


func _pick_target(targets: Array) -> Combatant:
	_set_status("Choisis une cible")
	_clear_actions()
	for t in targets:
		var btn := _add_action_button("%s\n%d PV" % [t.display_name, t.health])
		btn.pressed.connect(func() -> void: _ui_action.emit("target", t), CONNECT_ONE_SHOT)
	var cancel := _add_action_button("Annuler")
	cancel.pressed.connect(func() -> void: _ui_action.emit("target", null), CONNECT_ONE_SHOT)
	var result: Array = await _ui_action
	return result[1]


func _pick_ally(allies: Array) -> Combatant:
	_set_status("Choisis un allié à soigner")
	_clear_actions()
	for t in allies:
		var btn := _add_action_button("%s\n%d/%d PV" % [t.display_name, t.health, t.max_health])
		btn.pressed.connect(func() -> void: _ui_action.emit("ally", t), CONNECT_ONE_SHOT)
	var cancel := _add_action_button("Annuler")
	cancel.pressed.connect(func() -> void: _ui_action.emit("ally", null), CONNECT_ONE_SHOT)
	var result: Array = await _ui_action
	return result[1]


# =============================================================================
# Tour ennemi + défense active
# =============================================================================

func _enemy_turn(enemy: Combatant) -> void:
	_clear_actions()

	# L'IA choisit une action qui réagit à la situation.
	var intent: Dictionary = EnemyBrain.decide(enemy, _enemies, _players, _round)
	match intent.action:
		"defend":
			enemy.damage_taken_mult = EnemyBrain.DEFEND_MULT
			_spawn_damage(_views[enemy], "EN GARDE", Color(0.7, 0.85, 1.0))
			_log("[color=violet]%s se met en garde (dégâts réduits).[/color]" % enemy.display_name)
			return
		"protect":
			enemy.guarding = intent.ally
			_spawn_damage(_views[enemy], "PROTÈGE", Color(0.7, 0.85, 1.0))
			_log("[color=violet]%s protège %s ![/color]" % [enemy.display_name, intent.ally.display_name])
			return
		"empower":
			intent.ally.damage_dealt_mult = EnemyBrain.EMPOWER_MULT
			_spawn_damage(_views[intent.ally], "RENFORCÉ", Color(1, 0.6, 0.9))
			_log("[color=violet]%s renforce %s ![/color]" % [enemy.display_name, intent.ally.display_name])
			return
		"weaken":
			intent.target.damage_dealt_mult = EnemyBrain.WEAKEN_MULT
			_spawn_damage(_views[intent.target], "AFFAIBLI", Color(0.8, 0.5, 0.9))
			_log("[color=violet]%s affaiblit %s ![/color]" % [enemy.display_name, intent.target.display_name])
			return

	# Action "attack".
	var target: Combatant = intent.target
	if target == null:
		target = CombatResolver.choose_target(enemy, _player_allies(), _last_target)
	if target == null:
		return
	_last_target = target
	var target_is_hero := not target.is_summon

	var seq := _scaled_hits(intent.hits)
	_log("[color=violet][b]%s[/b] enchaîne %d attaque(s) sur %s ![/color]" % [enemy.display_name, seq, target.display_name])

	var parried_all := true
	for i in seq:
		if not target.is_alive():
			parried_all = false
			break
		if target_is_hero:
			# Cible un héros : le joueur défend activement.
			_set_status("%s frappe ! Coup %d/%d — réagis !" % [enemy.display_name, i + 1, seq])
			var outcome: GameEnums.DefenseResult = await _defense_window(enemy, target, i)
			match outcome:
				GameEnums.DefenseResult.PARRY:
					target.gain_mana(PARRY_MANA_GAIN)
					_spawn_spark(_views[target], Color(0.65, 0.95, 1.0))
					_spawn_damage(_views[target], "PARÉ !", Color(0.6, 0.95, 1.0), true)
					_camera.punch_zoom(0.08, 0.18)
					_camera.add_trauma(0.18)
					_log("  [color=aqua]PARADE ![/color] %s bloque tout (+%d mana)." % [target.display_name, PARRY_MANA_GAIN])
				GameEnums.DefenseResult.DODGE:
					parried_all = false
					_spawn_damage(_views[target], "ESQUIVE", Color(1, 0.9, 0.4))
					_log("  [color=yellow]Esquive.[/color] %s évite le coup." % target.display_name)
				GameEnums.DefenseResult.HIT:
					parried_all = false
					var dmg: Dictionary = CombatResolver.attack_damage(enemy, target)
					target.take_damage(dmg.damage)
					_views[target].play_hit()
					_impact_fx(_views[target], str(dmg.damage), Color(1, 0.4, 0.4), false)
					_log("  [color=red]Touché ![/color] %s subit %d dégâts." % [target.display_name, dmg.damage])
		else:
			# Cible une invocation : pas de parade, elle encaisse (rôle du tank).
			parried_all = false
			_views[enemy].play_attack(_views[target].home, i)
			await get_tree().create_timer(CombatantView.WINDUP + CombatantView.STRIKE).timeout
			var dmg: Dictionary = CombatResolver.attack_damage(enemy, target)
			target.take_damage(dmg.damage)
			_views[target].play_hit()
			_spawn_slash(_views[target], _views[enemy].attack_geometry(i), Color(1, 0.72, 0.66))
			_impact_fx(_views[target], str(dmg.damage), Color(1, 0.5, 0.4), false)
			_log("  %s frappe %s : %d dégâts." % [enemy.display_name, target.display_name, dmg.damage])
		_refresh_ui()
		if not target.is_alive():
			_handle_death(target)
			break
		await get_tree().create_timer(0.3).timeout

	# Contre Parfait : uniquement quand un héros pare TOUTE la séquence.
	if parried_all and target_is_hero and seq > 0 and target.is_alive():
		_log("[b][color=lime]CONTRE PARFAIT ![/color][/b] %s riposte gratuitement !" % target.display_name)
		_spawn_damage(_views[target], "CONTRE PARFAIT !", Color(0.5, 1.0, 0.5), true)
		_camera.punch_zoom(0.16, 0.3)
		_views[target].play_attack(_views[enemy].home, 0)
		await get_tree().create_timer(CombatantView.WINDUP + CombatantView.STRIKE).timeout
		var dmg: Dictionary = CombatResolver.attack_damage(target, enemy, 1.5)
		enemy.take_damage(dmg.damage)
		_views[enemy].play_hit()
		_spawn_slash(_views[enemy], _views[target].attack_geometry(0), Color(0.7, 1.0, 0.7))
		_spawn_spark(_views[enemy], Color(0.6, 1.0, 0.6))
		_spawn_damage(_views[enemy], str(dmg.damage), Color(0.6, 1.0, 0.6), true)
		_camera.add_trauma(0.5)
		await _hitstop(0.04, 0.09)
		_log("  Riposte : [color=lime]%d[/color] dégâts sur %s !" % [dmg.damage, enemy.display_name])
		_refresh_ui()

	_set_status("")


## Applique l'agressivité de la difficulté au nombre de coups choisi par l'IA.
func _scaled_hits(base: int) -> int:
	return maxi(1, int(round(base * GameSettings.enemy_aggression_scale())))


## Joue l'attaque ennemie et capture la réaction du joueur. L'impact survient à
## WINDUP + STRIKE après le début de l'élan ; le joueur doit réagir à ce moment.
func _defense_window(attacker: Combatant, defender: Combatant, move_index: int = 0) -> GameEnums.DefenseResult:
	_def_input = ""
	_def_time = -1.0
	_current_defender_view = _views[defender]
	_capture_start_ms = Time.get_ticks_msec()
	_capturing = true

	var attacker_view: CombatantView = _views[attacker]
	attacker_view.play_attack(_views[defender].home, move_index)
	var impact := CombatantView.WINDUP + CombatantView.STRIKE
	await get_tree().create_timer(impact).timeout
	# La tranche apparaît au contact, que le joueur pare ou non (le coup A eu lieu).
	_spawn_slash(_views[defender], attacker_view.attack_geometry(move_index), Color(1, 0.78, 0.72))
	await get_tree().create_timer(TAIL).timeout

	_capturing = false
	_current_defender_view = null

	if _def_input == "parry":
		var parry_half := PARRY_HALF * GameSettings.parry_window_scale()
		if absf(_def_time - impact) <= parry_half:
			return GameEnums.DefenseResult.PARRY
		return GameEnums.DefenseResult.HIT  # parade ratée = risque assumé
	if _def_input == "dodge":
		if _def_time >= impact - DODGE_EARLY and _def_time <= impact + DODGE_LATE:
			return GameEnums.DefenseResult.DODGE
		return GameEnums.DefenseResult.HIT
	return GameEnums.DefenseResult.HIT


# =============================================================================
# Invocations
# =============================================================================

## Tour d'une invocation (IA simple selon son rôle).
func _summon_turn(summon: Combatant) -> void:
	_clear_actions()
	var targets := _alive(_enemies)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.health < b.health)
	var target: Combatant = targets[0]
	var guardian := _guardian_of(target)
	if guardian != null:
		target = guardian
	_set_status("%s agit..." % summon.display_name)

	for i in maxi(1, summon.attacks_per_turn):
		if not target.is_alive():
			break
		_views[summon].play_attack(_views[target].home, i)
		await get_tree().create_timer(CombatantView.WINDUP + CombatantView.STRIKE).timeout
		var dmg: Dictionary = CombatResolver.attack_damage(summon, target)
		target.take_damage(dmg.damage)
		_views[target].play_hit()
		_spawn_slash(_views[target], _views[summon].attack_geometry(i), summon.body_color)
		_impact_fx(_views[target], str(dmg.damage), summon.body_color, dmg.crit)
		_refresh_ui()
		if not target.is_alive():
			_views[target].set_dead()
			break
		await get_tree().create_timer(0.2).timeout
	_set_status("")


## Convoque une créature. Max 2 actives : la plus ancienne est renvoyée.
func _do_summon(master: Combatant, data: SummonData) -> void:
	if _summons.size() >= SUMMON_POS.size():
		var oldest: Combatant = _summons[0]
		_log("  %s renvoie %s." % [master.display_name, oldest.display_name])
		_remove_summon(oldest)

	var slot := _free_summon_slot()
	var summon := Combatant.from_summon(data, master)
	_summons.append(summon)
	_summon_slots[summon] = slot

	var v := CombatantView.new()
	_field.add_child(v)
	v.setup(summon.display_name, summon.sprite_kind, Vector2(54, 80), false)
	v.set_home(SUMMON_POS[slot])
	_views[summon] = v

	_spawn_spark(v, summon.body_color)
	_spawn_damage(v, "INVOCATION", summon.body_color, false)
	_camera.add_trauma(0.2)
	_log("[color=violet]%s invoque [b]%s[/b] ![/color]" % [master.display_name, summon.display_name])
	_refresh_ui()
	await get_tree().create_timer(0.35).timeout


## Le boss à afficher dans la barre du haut (premier is_boss, sinon premier ennemi).
func _primary_boss() -> Combatant:
	for e in _enemies:
		if e.is_boss:
			return e
	return _enemies[0]


## Renvoie le protecteur vivant qui garde `target`, sinon null.
func _guardian_of(target: Combatant) -> Combatant:
	for e in _enemies:
		if e.is_alive() and e.guarding == target and e != target:
			return e
	return null


func _free_summon_slot() -> int:
	var used := {}
	for s in _summons:
		used[_summon_slots.get(s, -1)] = true
	for i in SUMMON_POS.size():
		if not used.has(i):
			return i
	return 0


func _remove_summon(summon: Combatant) -> void:
	_summons.erase(summon)
	_summon_slots.erase(summon)
	if _views.has(summon):
		_views[summon].queue_free()
		_views.erase(summon)


## Gère la mort d'un combattant (héros K.O. ou invocation détruite).
func _handle_death(c: Combatant) -> void:
	if c.is_summon:
		# Faucheur d'Âmes : le maître récupère du mana au sacrifice.
		var m: Combatant = c.owner
		if m != null and m.is_alive() and m.mana_on_summon_death > 0 and _views.has(m):
			m.gain_mana(m.mana_on_summon_death)
			_spawn_damage(_views[m], "+%d mana" % m.mana_on_summon_death, Color(0.6, 0.6, 1.0))
		_log("[color=gray]%s est détruit.[/color]" % c.display_name)
		_remove_summon(c)
	else:
		_views[c].set_dead()
		_log("[color=gray]%s est K.O.[/color]" % c.display_name)


# =============================================================================
# HUD
# =============================================================================

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_enemy_name = _make_label("", 24)
	_enemy_name.position = Vector2(440, 18)
	layer.add_child(_enemy_name)

	_enemy_hp = ProgressBar.new()
	_enemy_hp.position = Vector2(376, 52)
	_enemy_hp.size = Vector2(400, 24)
	layer.add_child(_enemy_hp)

	_diff_label = _make_label("", 16)
	_diff_label.position = Vector2(900, 18)
	layer.add_child(_diff_label)
	var diff_box := HBoxContainer.new()
	diff_box.position = Vector2(800, 46)
	layer.add_child(diff_box)
	for d in [GameEnums.Difficulty.EASY, GameEnums.Difficulty.NORMAL, GameEnums.Difficulty.HARD, GameEnums.Difficulty.HARDCORE]:
		var b := Button.new()
		GameSettings.difficulty = d
		b.text = GameSettings.difficulty_name()
		b.pressed.connect(func() -> void:
			GameSettings.difficulty = d
			_refresh_ui())
		diff_box.add_child(b)
	GameSettings.difficulty = GameEnums.Difficulty.NORMAL

	# Timeline d'ordre des tours (coin haut gauche).
	_timeline_box = HBoxContainer.new()
	_timeline_box.position = Vector2(20, 18)
	_timeline_box.add_theme_constant_override("separation", 6)
	layer.add_child(_timeline_box)

	# Log relégué au second plan : le feedback principal est visuel.
	_log_label = RichTextLabel.new()
	_log_label.bbcode_enabled = true
	_log_label.scroll_following = true
	_log_label.add_theme_font_size_override("normal_font_size", 13)
	_log_label.modulate = Color(1, 1, 1, 0.7)
	_log_label.position = Vector2(20, 72)
	_log_label.size = Vector2(340, 58)
	layer.add_child(_log_label)

	# Les PV/mana s'affichent sous chaque personnage (voir _refresh_ui),
	# plus besoin d'un panneau central qui chevauchait les ennemis.

	_status = _make_label("", 18)
	_status.position = Vector2(30, 552)
	layer.add_child(_status)

	_action_box = HBoxContainer.new()
	_action_box.position = Vector2(30, 585)
	_action_box.add_theme_constant_override("separation", 12)
	layer.add_child(_action_box)

	_end_box = VBoxContainer.new()
	_end_box.position = Vector2(450, 280)
	_end_box.visible = false
	layer.add_child(_end_box)


func _make_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func _add_action_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 56)
	_action_box.add_child(b)
	return b


func _clear_actions() -> void:
	for c in _action_box.get_children():
		c.queue_free()


func _set_status(text: String) -> void:
	_status.text = text


func _log(bbcode: String) -> void:
	_log_label.append_text(bbcode + "\n")


# =============================================================================
# Effets / juice
# =============================================================================

## Spark + nombre flottant + secousse, regroupés (impact standard).
func _impact_fx(view: CombatantView, text: String, color: Color, big: bool) -> void:
	_spawn_spark(view, color)
	_spawn_damage(view, text, color, big)
	_camera.add_trauma(0.45 if big else 0.28)


func _spawn_damage(view: CombatantView, text: String, color: Color, big: bool = false) -> void:
	var dn := DamageNumber.new()
	_fx_root.add_child(dn)
	dn.position = view.home + Vector2(0, -70)
	dn.show_value(text, color, big)


func _spawn_spark(view: CombatantView, color: Color) -> void:
	var s := HitSpark.new()
	_fx_root.add_child(s)
	s.position = view.home
	s.burst(color)


## Tranche lumineuse à l'impact, orientée selon le coup de l'attaquant.
## `geo` provient de CombatantView.attack_geometry(move_index).
func _spawn_slash(target_view: CombatantView, geo: Dictionary, color: Color) -> void:
	if geo.get("caster", false):
		return   # les lanceurs de sorts : éclat magique (spark), pas de tranche d'arme
	var s := SlashFX.new()
	_fx_root.add_child(s)
	s.position = target_view.home + Vector2(0, -10)
	s.slash(geo.slash, color, 72.0, geo.flip)


## Micro-arrêt du temps pour donner du poids aux coups (temps réel, ignore time_scale).
func _hitstop(scale: float = 0.05, duration: float = 0.06) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _refresh_timeline(order: Array, current_idx: int) -> void:
	for c in _timeline_box.get_children():
		c.queue_free()
	for i in order.size():
		var cb: Combatant = order[i]
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(46, 46)
		if i == current_idx:
			panel.modulate = Color(1, 1, 0.4)
		elif not cb.is_alive():
			panel.modulate = Color(0.4, 0.4, 0.4, 0.5)
		else:
			panel.modulate = Color(0.7, 0.8, 1.0) if cb.is_player else Color(1.0, 0.7, 0.7)
		var lbl := Label.new()
		lbl.text = cb.display_name.substr(0, 3)
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.position = Vector2(6, 13)
		panel.add_child(lbl)
		_timeline_box.add_child(panel)


func _refresh_ui() -> void:
	var boss: Combatant = _primary_boss()
	_enemy_name.text = "%s%s" % [boss.display_name, "  [BOSS]" if boss.is_boss else ""]
	_enemy_hp.max_value = boss.max_health
	_enemy_hp.value = boss.health

	_diff_label.text = "Difficulté : %s" % GameSettings.difficulty_name()

	# Infos affichées sous chaque unité.
	for c in _all():
		if not _views.has(c):
			continue
		var info := "PV %d/%d" % [c.health, c.max_health]
		if c.is_player and not c.is_summon:
			info += "\nMana %d/%d" % [c.mana, Combatant.MAX_MANA]
		if not c.is_alive():
			info = "K.O." if not c.is_summon else "—"
		_views[c].set_info(info)


func _show_end_screen() -> void:
	_clear_actions()
	_set_status("")
	var won := not _alive(_players).is_empty()
	var title := _make_label("VICTOIRE !" if won else "DÉFAITE...", 40)
	_end_box.add_child(title)

	if won:
		_award_xp()

	var cont := Button.new()
	cont.text = "Continuer" if won else "Réessayer"
	cont.custom_minimum_size = Vector2(220, 60)
	if won:
		cont.pressed.connect(func() -> void: Game.return_from_battle())
	else:
		cont.pressed.connect(func() -> void: get_tree().reload_current_scene())
	_end_box.add_child(cont)
	_end_box.visible = true
	_log("[b]%s[/b]" % ("Victoire !" if won else "Défaite..."))


## Récompense d'XP à la victoire : toute l'équipe persistante gagne l'XP de la
## rencontre, monte de niveau, débloque des compétences (et la spé au niv.5).
func _award_xp() -> void:
	var party := Game.get_party()
	if party.is_empty() or _battle_xp <= 0:
		return
	_end_box.add_child(_make_label("Expérience : +%d XP" % _battle_xp, 22))
	for cd in party:
		var res := Progression.gain_xp(cd, _battle_xp)
		var line := ""
		if res.leveled:
			line = "%s  niveau %d → %d !" % [cd.display_name, res.from, res.to]
		else:
			line = "%s  niv.%d  (%d/%d XP)" % [cd.display_name, cd.level, cd.xp, Progression.xp_for_next(cd.level)]
		var lbl := _make_label(line, 17)
		if res.leveled:
			lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		_end_box.add_child(lbl)
		# Nouvelles compétences débloquées par la montée de niveau.
		for sk in Progression.newly_unlocked_skills(cd.character_class, res.from, res.to):
			var sl := _make_label("    → nouvelle compétence : %s" % sk.display_name, 14)
			sl.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
			_end_box.add_child(sl)
		# Spécialisation désormais disponible (choix dans le menu Équipe).
		if Progression.can_choose_spec(cd):
			var pl := _make_label("    ★ %s peut choisir sa spécialisation — menu Équipe (touche P)" % cd.display_name, 14)
			pl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
			_end_box.add_child(pl)

	# Butin : bonne chance de récupérer une arme d'identité (→ inventaire).
	if randf() < 0.7:
		var loot := ContentLibrary.random_loot()
		Game.inventory.append(loot)
		var ll := _make_label("Butin : %s (%s) — à équiper dans le menu Équipe (P)" % [loot.display_name, ContentLibrary.rarity_name(loot.rarity)], 16)
		ll.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35))
		_end_box.add_child(ll)

	# La progression est sauvegardée (persiste entre les sessions).
	Game.save_game()
