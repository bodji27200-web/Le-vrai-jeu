# Le vrai jeu — RPG 2D tour par tour (Godot 4.6)

RPG fantasy médiéval 2D centré sur l'aventure, l'attachement aux personnages,
la difficulté et la maîtrise du joueur. Inspirations d'esprit (sans copier) :
Clair Obscur: Expédition 33 (esprit du combat, personnages, armes, progression),
Baldur's Gate 3 (choix, relations & conséquences). Vue de combat isométrique 2D.
Identité propre — pas de copie.

## Principes d'architecture (à respecter)

- **Data-driven** : les définitions (classes, compétences, armes, ennemis,
  personnages) sont des `Resource` typées dans `scripts/data/`. La logique ne
  contient pas de valeurs de gameplay en dur.
- **Séparation données / état / logique / présentation** :
  - `scripts/data/` — définitions immuables (`Resource`).
  - `scripts/combat/combatant.gd` — état runtime d'un combattant.
  - `scripts/combat/combat_resolver.gd` — calculs purs (dégâts, ordre, ciblage).
  - `scripts/combat/battle.gd` — flux de combat + UI.
- **Pas de scripts géants, pas de refactor massif gratuit.** On améliore
  l'existant progressivement.

## Arborescence actuelle

```
scripts/
  core/      game_enums.gd, game_settings.gd   (enums partagés, difficulté)
  data/      stat_block, weapon_data, skill_data, class_data,
             character_data, enemy_data         (Resources data-driven)
  combat/    combatant.gd, combat_resolver.gd, battle.gd
  content/   content_library.gd                 (contenu de démo, en code)
scenes/
  battle.tscn                                   (scène principale)
```

## Système de combat (cœur du jeu — implémenté en Milestone 1)

Tour par tour, équipe de 3 héros contre boss/ennemis. **Pas de grille, pas de
déplacement case par case.** Ordre des tours par **agilité** décroissante.

### Défense active (le cœur)
**Pas de barre ni d'indicateur de timing.** La défense est une RÉACTION à
l'animation d'attaque ennemie (`scripts/combat/combatant_view.gd`) : l'ennemi
recule (tell), s'élance, et l'impact a lieu à `WINDUP + STRIKE`. Le joueur lit
l'animation et réagit au moment du contact. L'appui déclenche immédiatement
l'animation de réaction (game feel), la validité est jugée par le timing.
- **Parade** (`ESPACE`) : fenêtre étroite (`PARRY_HALF`, ± resserré par la
  difficulté). Réussie → 0 dégât **+1 mana** (récompense volontairement modeste
  pour l'équilibrage). Ratée → coup encaissé (risque assumé).
- **Esquive** (`MAJ`) : fenêtre large + bond visuel en arrière puis retour.
  Réussie → 0 dégât, **aucun avantage**.
- **Contre Parfait** : parer *toutes* les attaques d'une séquence ennemie
  déclenche une riposte gratuite automatique (×1.5). Pas un nouveau tour — une
  récompense de skill.

### IA ennemie par archétype (`scripts/combat/enemy_brain.gd`)
`EnemyBrain.decide(enemy, enemies, heroes, round)` renvoie une **intention** qui
réagit à la situation, pas un script fixe :
- **AGRESSIF** : attaque ; séquence longue si un héros est bas (va pour le kill).
- **OPPORTUNISTE** : frappe fort si une proie est vulnérable (PV bas / plus de mana).
- **DÉFENSIF** : se met *en garde* (`damage_taken_mult`) quand il est blessé.
- **PROTECTEUR** : *protège* un allié faible (`guarding`) ; ses coups sont
  interceptés (`_guardian_of` redirige les attaques du joueur sur lui).
- **MANIPULATEUR** : *renforce* un allié (`damage_dealt_mult`) ou *affaiblit* un héros.

Effets temporaires sur `Combatant` : `damage_taken_mult` (levé en début de tour,
protège pendant les tours adverses), `damage_dealt_mult` (levé en fin de tour,
consommé par l'action), `guarding`. Cycle géré par `_begin_turn`/`_end_turn`.
Les attaques sur une invocation n'ouvrent pas de parade (le tank encaisse).

### Ciblage ennemi
`CombatResolver.choose_target` : score pondéré par archétype (agressif vise les
blessés/fragiles, opportuniste sécurise les kills, manipulateur neutralise les
gros DPS…), tirage pondéré pour rester vivant, pénalité sur la dernière cible,
et **aggro du tank** (`taunt`). Combat de démo = groupe de 3 ennemis
(`ContentLibrary.demo_encounter` : boss agressif + protecteur + manipulateur).

### Présentation / juice (feel visuel — objectif type Expédition 33)
Le feedback de combat est **visuel**, pas textuel. Le log est secondaire.
- `scripts/combat/fx/damage_number.gd` — dégâts/états flottants (rouge, orange+gros
  sur crit, cyan « PARÉ », jaune « ESQUIVE », vert « CONTRE PARFAIT »).
- `scripts/combat/fx/hit_spark.gd` — éclat radial au point d'impact.
- `scripts/combat/battle_camera.gd` — `BattleCamera` : secousse (trauma) +
  `punch_zoom`. N'affecte que le champ de bataille (HUD sur CanvasLayer = stable).
- Hitstop (`_hitstop` dans `battle.gd`) : micro-arrêt du temps sur crit et Contre
  Parfait pour le poids des coups.
- Timeline d'ordre des tours en haut (`_refresh_timeline`).

## Art : pixel art généré par code

Direction choisie par l'utilisateur : **pixel art "maison"** (pas d'artiste, pas
d'assets externes). `scripts/visual/pixel_art.gd` (`PixelArt.for_unit(kind)`)
dessine chaque sprite pixel par pixel dans une `Image` (24×32) avec contour
automatique, puis met en cache la `Texture2D`. Gabarits actuels : knight, mage
(chapeau/capuche), skeleton, humanoid, blob — déclinés par palette.

Le `kind` est data-driven : champ `sprite_kind` sur `ClassData` / `EnemyData` /
`SummonData`, repris par `Combatant.sprite_kind`, passé à
`CombatantView.setup(...)` et `PlayerAvatar.setup(...)`. Sprites affichés via
`Sprite2D` (filtre NEAREST = pixels nets). Repli `Polygon2D` coloré si `kind`
vide. Les flashs d'animation passent par `modulate` (marche sprite ou rectangle).

Cible visuelle visée : esprit **Sword of Convallaria** (pixel art 2D). Le niveau
pro nécessiterait un·e pixel-artiste ; ici on a une base cohérente, charmante et
extensible (ajouter frames d'animation idle/attaque, plus de détails). Viser
Clair Obscur (3D) n'est pas l'objectif. Améliorer les sprites = enrichir
`pixel_art.gd` sans toucher à la logique.

### Mana
Ressource 0→10 (`Combatant.MAX_MANA`). Les compétences la consomment, les
parades en donnent. Tension : risquer la parade pour du mana, ou jouer sûr.

### Difficulté (`game_settings.gd`)
Facile / Normal / Difficile / Hardcore. N'est **pas** qu'un +dégâts :
- `parry_window_scale()` resserre la fenêtre de parade.
- `enemy_aggression_scale()` allonge les séquences d'attaque.

## Monde & exploration (hors combat)

Overworld façon Expédition 33 (carte du monde miniature → zone "en grand") :
- **Scène principale** = `scenes/overworld.tscn` (`scripts/world/overworld.gd`) :
  personnage minuscule, caméra fixe dézoomée, toutes les zones visibles en
  miniature. S'approcher d'une zone + Entrée → on y entre.
- `scenes/zone.tscn` (`scripts/world/zone.gd`) : décor vaste, caméra rapprochée
  qui suit le perso (sensation "gigantesque"). Contient une **Sortie** (retour
  overworld) et un **marqueur d'Ennemi** (entre en collision → combat).
- `scripts/world/player_avatar.gd` : déplacement libre (flèches / ZQSD), borné.
- Routeur de scènes = autoload **`Game`** (`scripts/core/game.gd`) :
  `goto_overworld` / `enter_zone(zone)` / `start_battle` / `return_from_battle`.
  Garde l'état `current_zone` entre les scènes.
- Zones data-driven : `scripts/data/zone_data.gd`, contenu dans
  `scripts/content/world_library.gd` (5 zones de démo).

Flux : overworld → (Entrée) zone → (marqueur ennemi) combat → (Continuer)
retour zone → (Sortie) overworld.

## Système d'invocations & spécialisations (Nécromancien)

Classe centrée sur les invocations (`scripts/data/summon_data.gd`,
`scripts/data/specialization_data.gd`) :
- Une `SkillData` avec un champ `summon` convoque une créature au lieu d'attaquer.
- **Max 2 invocations actives** (`SUMMON_POS` dans `battle.gd`) ; au-delà, la plus
  ancienne est renvoyée. Elles apparaissent comme combattants sur le terrain,
  jouent en IA (`_summon_turn`) et profitent de toute la présentation/juice.
- **Rôles distincts** : Zombie Cuirassé (tank, `taunt` = attire l'aggro), Goule
  Rapide (2 attaques/tour), Aberration (offensive). Un ennemi qui cible une
  invocation ne déclenche PAS de parade (le tank encaisse à la place des héros).
- **Spécialisations** (`ClassData.specializations`, `CharacterData.chosen_specialization`)
  qui changent le jeu : *Seigneur de la Charogne* (invocations puissantes) vs
  *Faucheur d'Âmes* (sorts directs +50%, mana au sacrifice d'une invocation).
  Modificateurs appliqués dans `Combatant.from_character` / `from_summon`.

Victoire/défaite = état des **héros** (`_players`) uniquement ; les invocations
ne comptent pas pour la survie.

## Lancer / valider

Exécutable utilisé : `Godot_v4.6.3-stable_win64_console.exe` (dans Downloads).
Scène principale = `scenes/overworld.tscn` (le combat se lance depuis une zone).

```powershell
& $godot --headless --path . --import        # réimporte, vérifie le parsing
& $godot --headless --path . --quit-after 90 # smoke test runtime (overworld)
& $godot --headless --path . res://scenes/battle.tscn --quit-after 90  # tester une scène précise
& $godot --headless --path . --script res://tests/smoke_logic.gd  # test logique (sans UI)
& $godot --headless --path . --script res://tools/generate_content.gd  # (re)générer les .tres éditables
```
Pour jouer : ouvrir le projet dans l'éditeur et lancer (F5).
En jeu : choisir une action ; au tour du boss, presser `ESPACE`/`MAJ` quand le
curseur du télégraphe atteint la zone bleue.

## Feuille de route (prochains milestones)

Construire dans cet ordre, un système à la fois, en testant avant d'enchaîner :

1. **Migration contenu → `.tres`** : ✅ FAIT (sans casse). `ContentDB`
   (`scripts/content/content_db.gd`) est le point d'accès unique : il charge les
   `.tres` éditables de `content/` s'ils existent, sinon retombe sur les builders
   code (`ContentLibrary`/`WorldLibrary`) avec un avertissement → le build tourne
   toujours. `.tres` générés par `tools/generate_content.gd` (via `ResourceSaver`,
   donc garantis valides) : `content/party.tres`, `encounter_demo.tres`,
   `world.tres` + conteneurs `PartyData`/`EncounterData`/`WorldData`. Voir
   `content/README.md`. Reste : éclater en `.tres` plus granulaires si besoin
   (une classe/un ennemi par fichier) et brancher une UI d'édition en jeu.
2. **Classes profondes** (~10) : ✅ FAIT. **10 classes** au catalogue
   (`ContentLibrary.all_classes()`) : Gardien, Pyromancien, Nécromancien,
   Duelliste, Clerc, Berserker, Rôdeur, Paladin, Élémentaliste, Moine — chacune
   avec 2 spécialisations qui changent le jeu. Mécaniques data-driven :
   compétences **multi-frappes** (`SkillData.hits`), **soins** ciblés/de groupe
   (`heal_power` + `target_type` SELF/SINGLE_ALLY/ALL_ALLIES, calcul pur
   `CombatResolver.heal_amount`), **déblocage par niveau** (`unlock_level`), specs
   étendues (`crit_bonus`, `heal_power_mult`, `max_health_mult`).
   **UI d'équipe + arbre de compétences** :
   `scenes/party_select.tscn` (`scripts/world/party_select.gd`), ouverte depuis
   l'overworld par la touche **P**. On parcourt les classes, on consulte l'arbre
   (compétences débloquées par niveau), on ajoute/retire des héros, et — au
   niveau 5 — on choisit la spécialisation de chaque héros. L'équipe persistante
   est dans `Game.active_party`. L'avatar d'exploration prend le sprite du meneur.
   Reste : nœuds d'arbre à embranchements (choix exclusifs), montée des stats
   visible.
3. **IA ennemie par archétype** : ✅ FAIT (`EnemyBrain` : agressif/défensif/
   opportuniste/protecteur/manipulateur réagissant à la situation + groupe de 3
   ennemis de démo). Reste : plus d'archétypes/comportements, réactions à l'échec.
4. **Monde & exploration** : ✅ BASE FAITE (overworld miniature + zones "en grand"
   + déplacement + transitions). **Village-hub** : `scenes/village.tscn`
   (`scripts/world/village.gd`), zone `is_village` (`ZoneData.is_village`,
   routée par `Game.enter_zone`). Hameau habité de PNJ avec dialogues + léger
   balancement idle (pas des statues) : aubergiste, forgeronne (ouvre
   l'équipement), marchande (ouvre la boutique), ivrogne, ancien.
   **Première zone détaillée** = Clairière d'Émeraude (forêt) : plusieurs
   rencontres VARIÉES + un boss, via `ContentLibrary.encounters_for_zone(id)` →
   `zone.gd` place un marqueur par rencontre (la rencontre choisie passe par
   `Game.pending_encounter`, lue par `battle.gd`). Les autres zones gardent la
   rencontre de démo générique (on les détaillera plus tard). **Le focus actuel
   est de rendre cette 1re zone "insane" (démo ~1h) avant d'étoffer les autres.**
   **Événements à choix** (`scenes/event.tscn` / `event.gd`, data-driven via
   `Game.start_event`/`pending_event`, one-shot via `Game.event_flags`) : la forêt
   contient un **recrutement de compagnon** (choix nuancés) et un **secret**
   (arme légendaire cachée dans un recoin = récompense d'exploration).
   Reste : routines/horaires PNJ, plus de secrets/événements, quêtes, dialogues
   à conséquences durables.
5. **Boss avancés** : ✅ BASE FAITE. Boss à PHASES via `EnemyData.enrage_threshold` :
   sous ce ratio de PV, le boss ENRAGE une fois (`battle._maybe_enrage`) — il
   change de façon de jouer (devient AGRESSIF, frappe plus fort, enchaîne plus),
   pas un simple +PV. Ex. Gorth (chef bandit) : défensif puis enragé à 50 %.
   Reste : mécaniques propres par boss, multi-phases, boss secrets.
6. **Progression** : ✅ BASE FAITE. Boucle XP/niveaux (`scripts/core/progression.gd`)
   gagnée en combat : chaque ennemi donne de l'XP (`EnemyData.xp_reward`), l'équipe
   **persistante** (`Game.get_party()` / `active_party`) gagne de l'XP à la victoire,
   monte de niveau (courbe rapide au début puis ralentit), ce qui débloque les
   compétences (`unlock_level`) et, **au niveau 5**, le choix de spécialisation
   (`Progression.SPEC_UNLOCK_LEVEL`). Les héros démarrent **niveau 1 sans spé**.
   Écran de fin de combat = récap XP/niveaux/compétences/spé débloquée.
   **Sauvegarde** (`scripts/core/save_system.gd`) : équipe + difficulté en JSON dans
   `user://save.json` (sur le web = IndexedDB du navigateur → persiste, y compris sur
   Xbox/Edge). `Game._ready` charge au lancement ; sauvegarde auto à la victoire, au
   choix de spé et à la validation d'équipe ; bouton « Nouvelle partie » dans l'écran
   d'équipe (`Game.reset_progress`).
   **Équipement / butin** : `WeaponData` porte des bonus d'identité (agilité,
   défense, PV, crit) appliqués dans `Combatant.from_character` — une arme n'est
   pas "plus forte" mais DIFFÉRENTE. Catalogue `ContentLibrary.loot_weapons()` ;
   `random_loot()` tombe à la victoire (~70 %) dans `Game.inventory` (sauvegardé) ;
   on équipe depuis l'écran d'équipe (bouton « Changer d'arme »).
   **Or & boutique** : les ennemis donnent de l'or (`EnemyData.gold_reward` →
   `Game.gold`, sauvegardé) ; la marchande du village ouvre `scenes/shop.tscn`
   (`shop.gd`) pour acheter des armes (`ContentLibrary.shop_weapons` /
   `weapon_price`). Reste : montée des stats affichée, amélioration d'armes (forge),
   consommables/objets.
7. **Compagnons & relations** : ✅ BASE FAITE. On rencontre les compagnons dans
   l'aventure (recrutement NON automatique, via événement à choix) — pas de
   trio imposé en plus du départ. `CharacterData.is_companion` / `loyalty` / `bio`.
   Kael (`ContentLibrary.companion_kael`) se recrute dans la forêt ; le choix
   façonne sa **loyauté** de départ (qui donne un bonus de combat ≥ 50).
   Recrutés → `Game.recruit` (équipe si place, sinon **réserve** `Game.bench`,
   gérée dans l'écran d'équipe : intégrer/mettre en réserve sans perte de
   progression). Sauvegardés. Reste : moments personnels, désaccords, départs/
   trahisons selon les choix, plusieurs compagnons, conséquences durables.
8. **New Game+ / mémoire des boss** : ennemis qui « ont progressé », plus
   intelligents et dangereux.

> Note : l'art final (sprites dessinés, décors) reste à intégrer via asset packs/
> artiste. Tous les placeholders (`Polygon2D`) sont conçus pour être remplacés
> sans toucher à la logique.

## Conventions de code

- GDScript typé statiquement quand c'est raisonnable (`func f() -> Type`).
- Enums via `GameEnums.*` plutôt que des entiers/chaînes magiques.
- Texte de jeu en français (cohérence avec le contenu existant).
