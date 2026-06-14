## Générateur de sprites pixel art "maison" (dessinés par code, pixel par pixel).
## Aucune dépendance à des assets externes : tout est généré au lancement.
##
## Refonte "visuel riche" : canvas 48×64 (au lieu de 24×32), ombrage VOLUMÉTRIQUE
## (sphères éclairées pour têtes/orbes, edge-lighting sur les volumes, dégradés
## de robe), et silhouettes détaillées par archétype. Lumière conventionnelle =
## haut-gauche. L'API publique est inchangée : `for_unit(kind)` / `for_weapon(kind)`
## renvoient une Texture2D mise en cache (les consommateurs auto-scalent sur la
## hauteur de texture, donc le changement de résolution ne casse rien).
class_name PixelArt

const W := 48
const H := 64
const OUTLINE := Color8(18, 16, 26)

## Direction de la lumière (haut-gauche, vers l'avant) pour l'ombrage des sphères.
const LIGHT := Vector3(-0.5, -0.62, 0.6)

static var _cache: Dictionary = {}


## Retourne (et met en cache) la texture pixel art d'un type d'unité.
static func for_unit(kind: String) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint(img, kind)
	_apply_outline(img, OUTLINE)
	_apply_shadow_band(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[kind] = tex
	return tex


static func _paint(img: Image, kind: String) -> void:
	match kind:
		"gardien":
			_knight(img, Color8(126, 146, 172), Color8(72, 88, 116), Color8(236, 200, 165), Color8(228, 196, 96))
		"boss_chevalier":
			_knight(img, Color8(92, 78, 108), Color8(46, 38, 60), Color8(150, 120, 150), Color8(214, 58, 70), true)
		"bandit_chef":
			_knight(img, Color8(104, 86, 70), Color8(56, 46, 40), Color8(212, 182, 152), Color8(196, 72, 60))
		"paladin":
			_knight(img, Color8(220, 210, 176), Color8(154, 134, 84), Color8(236, 200, 165), Color8(248, 228, 124))
		"pyromancien":
			_mage(img, Color8(192, 72, 56), Color8(120, 38, 34), Color8(236, 200, 165), Color8(255, 176, 70), HAT_POINTED, Color8(70, 40, 30))
		"necromancien":
			_mage(img, Color8(78, 60, 104), Color8(40, 30, 60), Color8(206, 200, 192), Color8(150, 232, 160), HAT_HOOD, Color8(20, 18, 26))
		"acolyte":
			_mage(img, Color8(60, 54, 78), Color8(32, 28, 46), Color8(202, 196, 186), Color8(176, 96, 206), HAT_HOOD, Color8(20, 18, 26))
		"clerc":
			_mage(img, Color8(234, 232, 240), Color8(168, 168, 188), Color8(236, 200, 165), Color8(242, 212, 96), HAT_HOOD_OPEN, Color8(110, 80, 50))
		"elementaliste":
			_mage(img, Color8(72, 152, 182), Color8(40, 92, 122), Color8(236, 200, 165), Color8(150, 212, 255), HAT_NONE, Color8(60, 70, 90))
		"garde_squelette":
			_skeleton(img, Color8(230, 224, 204), Color8(150, 144, 126))
		"zombie":
			_humanoid(img, Color8(126, 168, 104), Color8(96, 86, 72), Color8(60, 54, 48), Color8(150, 60, 60), Color8(54, 44, 36), true)
		"goule":
			_humanoid(img, Color8(190, 178, 208), Color8(84, 74, 96), Color8(50, 44, 60), Color8(124, 92, 142), Color8(40, 34, 48), true)
		"aberration":
			_blob(img, Color8(214, 114, 60), Color8(140, 62, 40), Color8(255, 234, 122))
		"loup":
			_wolf(img, Color8(118, 112, 124), Color8(64, 60, 72), Color8(224, 92, 70))
		"duelliste":
			_humanoid(img, Color8(236, 200, 165), Color8(62, 84, 128), Color8(36, 50, 84), Color8(222, 222, 236), Color8(58, 38, 28))
		"berserker":
			_humanoid(img, Color8(236, 200, 165), Color8(162, 54, 48), Color8(96, 32, 30), Color8(222, 192, 72), Color8(150, 60, 30))
		"rodeur":
			_humanoid(img, Color8(236, 200, 165), Color8(72, 112, 72), Color8(42, 68, 44), Color8(150, 112, 72), Color8(60, 42, 28), false, true)
		"moine":
			_humanoid(img, Color8(236, 200, 165), Color8(214, 144, 72), Color8(152, 92, 46), Color8(242, 222, 152), Color8(36, 30, 26))
		"bandit":
			_humanoid(img, Color8(214, 182, 152), Color8(80, 72, 66), Color8(44, 40, 38), Color8(172, 62, 56), Color8(40, 32, 26), false, true)
		"pnj_aubergiste":
			_humanoid(img, Color8(236, 198, 162), Color8(150, 96, 56), Color8(92, 60, 38), Color8(232, 226, 210), Color8(70, 50, 34))
		"pnj_forgeronne":
			_humanoid(img, Color8(228, 184, 150), Color8(96, 70, 54), Color8(52, 38, 30), Color8(180, 120, 60), Color8(120, 60, 40))
		"pnj_marchande":
			_mage(img, Color8(70, 110, 160), Color8(40, 70, 110), Color8(232, 196, 162), Color8(232, 216, 120), HAT_HOOD_OPEN, Color8(60, 40, 30))
		"pnj_ivrogne":
			_humanoid(img, Color8(214, 176, 150), Color8(120, 108, 92), Color8(70, 62, 52), Color8(140, 110, 70), Color8(90, 80, 70))
		"pnj_ancien":
			_mage(img, Color8(228, 200, 176), Color8(150, 152, 162), Color8(228, 200, 176), Color8(210, 210, 220), HAT_HOOD_OPEN, Color8(220, 220, 226))
		_:
			_humanoid(img, Color8(222, 202, 172), Color8(112, 122, 162), Color8(70, 78, 110), Color8(222, 202, 122), Color8(60, 44, 32))


# =============================================================================
# GABARITS D'UNITÉS
# =============================================================================

## Humanoïde générique (tunique + pantalon). `gaunt` = creusé (mort-vivant),
## `cowl` = capuchon léger (rôdeur/bandit).
static func _humanoid(img: Image, skin: Color, main: Color, dark: Color, accent: Color, hair: Color, gaunt := false, cowl := false) -> void:
	var cx := 24
	# Jambes (pantalon).
	_box(img, cx - 8, 44, 6, 17, dark)
	_box(img, cx + 2, 44, 6, 17, dark)
	# Bottes.
	_box(img, cx - 9, 59, 8, 3, dark.darkened(0.4))
	_box(img, cx + 1, 59, 8, 3, dark.darkened(0.4))
	# Bras (derrière le torse).
	_box(img, cx - 13, 24, 5, 17, main.darkened(0.1))
	_box(img, cx + 8, 24, 5, 17, main.darkened(0.1))
	_box(img, cx - 13, 39, 5, 4, skin)        # mains
	_box(img, cx + 8, 39, 5, 4, skin)
	# Torse (tunique) avec col.
	_box(img, cx - 9, 23, 18, 19, main)
	_shade_v(img, cx - 9, 23, 18, 19, 0.10)   # ombrage vertical léger
	_box(img, cx - 9, 39, 18, 3, accent)      # ceinture
	_px(img, cx - 1, 40, accent.darkened(0.3)) # boucle
	_px(img, cx, 40, accent.lightened(0.3))
	# Cou.
	_box(img, cx - 3, 20, 6, 4, skin.darkened(0.12))
	# Tête (sphère ombrée).
	_sphere(img, cx, 13, 8, 9, skin)
	_face(img, cx, 13, skin, gaunt)
	# Cheveux / capuchon.
	if cowl:
		_hood(img, cx, hair, true)
	else:
		_hair(img, cx, hair)


## Chevalier en armure de plaques : casque à visière + plume, pauldrons, plastron
## nervuré, bouclier au bras gauche. `crowned` = couronne de boss.
static func _knight(img: Image, main: Color, dark: Color, skin: Color, accent: Color, crowned := false) -> void:
	var cx := 24
	# Jambes blindées (grèves).
	_box(img, cx - 8, 44, 6, 17, dark)
	_box(img, cx + 2, 44, 6, 17, dark)
	_box(img, cx - 8, 50, 6, 1, main.lightened(0.2))   # reflet genou
	_box(img, cx + 2, 50, 6, 1, main.lightened(0.2))
	_box(img, cx - 9, 59, 8, 3, dark.darkened(0.35))   # sabatons
	_box(img, cx + 1, 59, 8, 3, dark.darkened(0.35))
	# Bras blindés.
	_box(img, cx - 13, 24, 5, 16, main.darkened(0.08))
	_box(img, cx + 8, 24, 5, 16, main.darkened(0.08))
	_box(img, cx - 13, 38, 5, 4, dark)                 # gantelets
	_box(img, cx + 8, 38, 5, 4, dark)
	# Plastron.
	_box(img, cx - 10, 22, 20, 20, main)
	_tri(img, Vector2(cx - 10, 22), Vector2(cx, 36), Vector2(cx + 10, 22), main.lightened(0.12))  # bombé
	_box(img, cx - 1, 24, 2, 14, dark)                 # nervure centrale
	_box(img, cx - 10, 39, 20, 3, accent)              # ceinturon
	# Pauldrons (épaules).
	_sphere(img, cx - 11, 25, 6, 5, main.lightened(0.06))
	_sphere(img, cx + 11, 25, 6, 5, main.lightened(0.06))
	# Bouclier (bras gauche, côté joueur = droite écran ; on le met à gauche sprite).
	_box(img, cx - 17, 26, 6, 16, accent.darkened(0.1))
	_box(img, cx - 16, 28, 4, 12, accent)
	_px(img, cx - 14, 33, accent.lightened(0.3))
	# Cou + tête sous le heaume.
	_box(img, cx - 3, 19, 6, 4, dark)
	# Heaume.
	_box(img, cx - 8, 5, 16, 16, main)
	_tri(img, Vector2(cx - 8, 5), Vector2(cx, 1), Vector2(cx + 8, 5), main.lightened(0.1))  # crête
	_box(img, cx - 8, 11, 16, 3, OUTLINE)              # fente de visière
	_box(img, cx - 5, 12, 2, 1, accent)                # lueur des yeux
	_box(img, cx + 3, 12, 2, 1, accent)
	_box(img, cx - 8, 5, 1, 16, main.lightened(0.18))  # arête éclairée
	_box(img, cx + 7, 5, 1, 16, main.darkened(0.2))    # côté ombre
	# Cimier / plume.
	if crowned:
		for k in 5:
			_box(img, cx - 8 + k * 4, 0, 2, 4 + (k % 2), accent)
	else:
		_box(img, cx - 1, 0, 2, 5, accent)             # plumet
		_sphere(img, cx, 1, 3, 3, accent.lightened(0.1))


## Mage : robe drapée (dégradé + ourlet), manches amples, et coiffe variable.
const HAT_NONE := 0
const HAT_POINTED := 1
const HAT_HOOD := 2
const HAT_HOOD_OPEN := 3

static func _mage(img: Image, main: Color, dark: Color, skin: Color, accent: Color, hat: int, hair: Color) -> void:
	var cx := 24
	# Robe : s'évase vers le bas (trapèze drapé).
	_trap(img, cx, 24, 18, 30, 36, main, dark)
	# Plis verticaux.
	_box(img, cx - 1, 30, 2, 30, dark.lightened(0.05))
	_box(img, cx - 8, 32, 1, 26, dark)
	_box(img, cx + 7, 32, 1, 26, dark)
	# Ourlet bas + pieds.
	_box(img, cx - 17, 58, 34, 3, dark.darkened(0.2))
	# Manches.
	_box(img, cx - 13, 24, 5, 16, main.darkened(0.08))
	_box(img, cx + 8, 24, 5, 16, main.darkened(0.08))
	_box(img, cx - 13, 38, 5, 4, skin)        # mains
	_box(img, cx + 8, 38, 5, 4, skin)
	# Ceinture/cordon.
	_box(img, cx - 9, 38, 18, 2, accent)
	# Sceau magique sur la poitrine.
	_sphere(img, cx, 32, 3, 3, accent.lightened(0.15))
	# Cou + tête.
	_box(img, cx - 3, 20, 6, 4, skin.darkened(0.1))
	_sphere(img, cx, 13, 8, 9, skin)
	_face(img, cx, 13, skin, false)
	match hat:
		HAT_POINTED:
			# Chapeau pointu retombant.
			_tri(img, Vector2(cx - 9, 5), Vector2(cx + 6, -6), Vector2(cx + 9, 5), main)
			_box(img, cx - 11, 4, 22, 3, accent)       # large bord
			_sphere(img, cx + 6, -6, 2, 2, accent.lightened(0.2))
		HAT_HOOD:
			_hood(img, cx, dark, false)
			_box(img, cx - 4, 12, 2, 1, accent)        # yeux luisants dans l'ombre
			_box(img, cx + 2, 12, 2, 1, accent)
		HAT_HOOD_OPEN:
			_hair(img, cx, hair)
			# Capuche rabattue dans le dos (col haut).
			_box(img, cx - 9, 18, 18, 4, main.darkened(0.05))
		_:
			_hair(img, cx, hair)


## Squelette : crâne, cage thoracique côtelée, os fins.
static func _skeleton(img: Image, bone: Color, dark: Color) -> void:
	var cx := 24
	# Jambes (tibias).
	_box(img, cx - 6, 44, 3, 17, bone)
	_box(img, cx + 3, 44, 3, 17, bone)
	_box(img, cx - 8, 60, 6, 2, bone.darkened(0.2))
	_box(img, cx + 2, 60, 6, 2, bone.darkened(0.2))
	# Bras (humérus + cubitus).
	_box(img, cx - 12, 24, 3, 17, bone)
	_box(img, cx + 9, 24, 3, 17, bone)
	_box(img, cx - 13, 40, 4, 4, bone)        # mains
	_box(img, cx + 9, 40, 4, 4, bone)
	# Bassin.
	_box(img, cx - 6, 40, 12, 4, bone.darkened(0.08))
	# Colonne + cage thoracique côtelée.
	_box(img, cx - 1, 22, 2, 18, bone.darkened(0.15))
	for r in 4:
		var ry := 24 + r * 4
		_box(img, cx - 7, ry, 14, 2, bone)
		_box(img, cx - 7, ry + 2, 14, 2, dark.darkened(0.1))   # creux
	_box(img, cx - 7, 24, 1, 14, bone.lightened(0.15))         # côté éclairé
	# Crâne.
	_sphere(img, cx, 13, 8, 9, bone)
	_box(img, cx - 5, 14, 4, 4, OUTLINE)      # orbite
	_box(img, cx + 1, 14, 4, 4, OUTLINE)
	_box(img, cx - 4, 15, 1, 1, Color8(180, 40, 40))  # lueur
	_box(img, cx + 2, 15, 1, 1, Color8(180, 40, 40))
	_box(img, cx - 1, 18, 2, 2, dark)         # cavité nasale
	for t in 5:                                # dents
		_px(img, cx - 4 + t * 2, 21, dark)


## Aberration : masse organique pulsante, œil unique, pseudopodes.
static func _blob(img: Image, main: Color, dark: Color, accent: Color) -> void:
	var cx := 24
	# Pseudopodes au sol.
	_box(img, cx - 16, 54, 5, 8, dark)
	_box(img, cx + 11, 52, 5, 10, dark)
	_box(img, cx - 4, 56, 6, 6, dark.lightened(0.05))
	# Masse principale (grosse sphère molle).
	_sphere(img, cx, 34, 18, 16, main)
	_sphere(img, cx - 6, 22, 9, 8, main.lightened(0.06))   # bosse
	_sphere(img, cx + 9, 28, 7, 7, main)
	# Taches sombres (texture organique).
	_sphere(img, cx - 8, 40, 4, 3, dark)
	_sphere(img, cx + 7, 42, 3, 3, dark)
	# Pics dorsaux.
	_tri(img, Vector2(cx - 12, 22), Vector2(cx - 9, 8), Vector2(cx - 6, 22), dark)
	_tri(img, Vector2(cx + 4, 20), Vector2(cx + 8, 6), Vector2(cx + 12, 20), dark)
	# Gros œil.
	_sphere(img, cx, 32, 6, 6, accent)
	_sphere(img, cx + 1, 33, 3, 3, OUTLINE)
	_px(img, cx - 1, 30, Color.WHITE)         # reflet


## Loup / bête quadrupède (de profil, face à gauche).
static func _wolf(img: Image, fur: Color, dark: Color, eye: Color) -> void:
	var cx := 24
	# Pattes.
	_box(img, cx - 13, 44, 4, 16, dark)
	_box(img, cx - 4, 46, 4, 14, dark)
	_box(img, cx + 6, 44, 4, 16, dark)
	_box(img, cx + 13, 46, 4, 14, dark)
	_box(img, cx - 14, 59, 6, 3, dark.darkened(0.3))  # pattes avant
	_box(img, cx + 12, 59, 6, 3, dark.darkened(0.3))
	# Corps (masse allongée).
	_sphere(img, cx, 34, 18, 11, fur)
	_box(img, cx - 14, 30, 28, 12, fur)
	_shade_v(img, cx - 14, 30, 28, 12, 0.16)
	# Échine hérissée.
	for k in 6:
		_tri(img, Vector2(cx - 12 + k * 4, 28), Vector2(cx - 10 + k * 4, 22), Vector2(cx - 8 + k * 4, 28), dark)
	# Queue touffue.
	_sphere(img, cx + 17, 30, 6, 4, fur)
	_tri(img, Vector2(cx + 14, 32), Vector2(cx + 23, 22), Vector2(cx + 18, 34), fur.darkened(0.1))
	# Tête (vers la gauche) + museau.
	_sphere(img, cx - 14, 22, 8, 7, fur)
	_tri(img, Vector2(cx - 22, 22), Vector2(cx - 14, 20), Vector2(cx - 14, 28), dark)  # museau
	_box(img, cx - 23, 23, 3, 2, dark.darkened(0.2))   # truffe
	# Oreilles dressées.
	_tri(img, Vector2(cx - 16, 16), Vector2(cx - 14, 8), Vector2(cx - 11, 16), fur)
	_tri(img, Vector2(cx - 11, 16), Vector2(cx - 8, 9), Vector2(cx - 6, 16), fur.darkened(0.08))
	# Œil luisant.
	_box(img, cx - 16, 20, 2, 2, eye)
	_px(img, cx - 15, 20, eye.lightened(0.4))


# =============================================================================
# DÉTAILS PARTAGÉS (visage, cheveux, capuchon)
# =============================================================================

static func _face(img: Image, cx: int, cy: int, skin: Color, gaunt: bool) -> void:
	# Yeux.
	var eye := Color8(40, 36, 50) if not gaunt else Color8(150, 30, 30)
	_box(img, cx - 5, cy + 1, 2, 2, eye)
	_box(img, cx + 3, cy + 1, 2, 2, eye)
	_px(img, cx - 5, cy + 1, Color.WHITE if not gaunt else eye)   # reflet
	_px(img, cx + 3, cy + 1, Color.WHITE if not gaunt else eye)
	# Ombre sous l'arcade / nez.
	_box(img, cx - 1, cy + 2, 2, 2, skin.darkened(0.16))
	if gaunt:
		_box(img, cx - 6, cy + 4, 3, 1, skin.darkened(0.28))      # joues creuses
		_box(img, cx + 3, cy + 4, 3, 1, skin.darkened(0.28))


static func _hair(img: Image, cx: int, hair: Color) -> void:
	# Calotte de cheveux épousant le crâne (haut + tempes).
	var rx := 8.0
	var ry := 9.0
	for j in range(4, 12):
		var ny := (float(j) - 13.0) / ry
		var span := int(rx * sqrt(maxf(0.0, 1.0 - ny * ny)))
		var shade := hair.lightened(0.12) if j < 7 else hair
		for i in range(cx - span, cx + span + 1):
			_px(img, i, j, shade)
	# Mèches latérales.
	_box(img, cx - 8, 8, 2, 6, hair.darkened(0.08))
	_box(img, cx + 6, 8, 2, 6, hair.darkened(0.08))


static func _hood(img: Image, cx: int, col: Color, full: bool) -> void:
	# Capuchon : dôme + retombée encadrant le visage, visage dans l'ombre.
	for j in range(2, 22):
		var ny := (float(j) - 12.0) / 11.0
		var span := int(10.0 * sqrt(maxf(0.0, 1.0 - ny * ny * 0.7)))
		var shade := col.lightened(0.1) if j < 8 else col
		for i in range(cx - span, cx + span + 1):
			# Évide l'ouverture du visage.
			if full and j >= 8 and j <= 18 and absi(i - cx) <= span - 3:
				continue
			_px(img, i, j, shade)
	if full:
		# Assombrit le visage encadré.
		for j in range(9, 19):
			for i in range(cx - 5, cx + 6):
				if img.get_pixel(i, j).a > 0.0:
					img.set_pixel(i, j, img.get_pixel(i, j).darkened(0.32))


# =============================================================================
# ARMES (sprites tenus en main, lame vers le HAUT, poignée en bas)
# Pivot d'animation = bas-centre (le pommeau). Canvas 24×52.
# =============================================================================

const WW := 24
const WH := 52
static var _wcache: Dictionary = {}

const STEEL := Color8(202, 210, 224)
const STEEL_HI := Color8(244, 248, 255)
const STEEL_DK := Color8(112, 120, 138)
const GOLD := Color8(208, 172, 86)
const GOLD_HI := Color8(248, 222, 140)
const WOOD := Color8(122, 90, 58)
const WOOD_DK := Color8(80, 56, 36)
const GRIP := Color8(72, 48, 34)


## Retourne (et met en cache) la texture d'une arme. "" = pas d'arme (poings/griffes).
static func for_weapon(kind: String) -> Texture2D:
	if kind == "":
		return null
	if _wcache.has(kind):
		return _wcache[kind]
	var img := Image.create(WW, WH, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match kind:
		"sword":      _w_sword(img, 4, 26)
		"greatsword": _w_sword(img, 5, 32)
		"rapier":     _w_rapier(img)
		"dagger":     _w_sword(img, 3, 15)
		"axe":        _w_axe(img)
		"staff":      _w_staff(img, Color8(150, 210, 255))
		"staff_fire": _w_staff(img, Color8(255, 170, 80))
		"staff_dark": _w_staff(img, Color8(170, 130, 230))
		"staff_holy": _w_staff(img, Color8(255, 232, 150))
		"spear":      _w_spear(img)
		"mace":       _w_mace(img)
		"bow":        _w_bow(img)
		_:            _w_sword(img, 4, 26)
	_apply_outline(img, OUTLINE)
	var tex := ImageTexture.create_from_image(img)
	_wcache[kind] = tex
	return tex


static func _w_sword(img: Image, bw: int, blade_h: int) -> void:
	var cx := WW / 2
	var x := cx - bw / 2
	_box(img, x, 3, bw, blade_h, STEEL)                  # lame
	_box(img, x, 3, 1, blade_h, STEEL_HI)                # tranchant lumineux
	_box(img, x + bw - 1, 3, 1, blade_h, STEEL_DK)       # tranchant ombré
	_tri(img, Vector2(x, 3), Vector2(cx, 0), Vector2(x + bw, 3), STEEL_HI)  # pointe
	var guard_y := 3 + blade_h
	_box(img, x - 3, guard_y, bw + 6, 2, GOLD)           # garde
	_box(img, x - 3, guard_y, bw + 6, 1, GOLD_HI)
	_box(img, cx - 1, guard_y + 2, 3, 9, GRIP)           # poignée
	_box(img, cx - 2, guard_y + 11, 5, 3, GOLD)          # pommeau
	_box(img, cx - 1, guard_y + 11, 2, 1, GOLD_HI)


static func _w_rapier(img: Image) -> void:
	var cx := WW / 2
	_box(img, cx, 1, 2, 32, STEEL)
	_box(img, cx, 1, 1, 32, STEEL_HI)
	_box(img, cx - 3, 33, 7, 2, GOLD)                    # garde en coupe
	_sphere(img, cx, 36, 4, 4, GOLD)                     # coquille
	_box(img, cx, 40, 2, 9, GRIP)
	_box(img, cx - 1, 49, 4, 2, GOLD)


static func _w_axe(img: Image) -> void:
	var cx := WW / 2
	_box(img, cx - 1, 3, 3, 46, WOOD)                    # manche
	_box(img, cx - 1, 3, 1, 46, WOOD.lightened(0.15))
	_box(img, cx + 1, 3, 1, 46, WOOD_DK)
	# Fer (croissant).
	_tri(img, Vector2(cx + 1, 4), Vector2(cx + 11, 9), Vector2(cx + 1, 18), STEEL)
	_box(img, cx + 8, 6, 2, 8, STEEL_HI)                 # tranchant
	_tri(img, Vector2(cx + 1, 5), Vector2(cx - 8, 9), Vector2(cx + 1, 16), STEEL_DK)  # contre-fer


static func _w_staff(img: Image, orb: Color) -> void:
	var cx := WW / 2
	_box(img, cx - 1, 10, 3, 41, WOOD)                   # hampe
	_box(img, cx - 1, 10, 1, 41, WOOD.lightened(0.15))
	_box(img, cx + 1, 10, 1, 41, WOOD_DK)
	# Monture + orbe rayonnante.
	_sphere(img, cx, 6, 6, 6, orb)
	_sphere(img, cx - 1, 4, 2, 2, Color(1, 1, 1, 0.92))  # éclat
	_box(img, cx - 4, 9, 8, 2, GOLD)                     # collerette


static func _w_spear(img: Image) -> void:
	var cx := WW / 2
	_box(img, cx - 1, 10, 3, 41, WOOD)                   # hampe
	_box(img, cx - 1, 10, 1, 41, WOOD.lightened(0.12))
	_tri(img, Vector2(cx - 3, 12), Vector2(cx, 0), Vector2(cx + 3, 12), STEEL)  # fer foliacé
	_box(img, cx - 1, 2, 1, 9, STEEL_HI)
	_box(img, cx - 4, 11, 8, 2, GOLD)                    # collet


static func _w_mace(img: Image) -> void:
	var cx := WW / 2
	_box(img, cx - 1, 16, 3, 33, WOOD)                   # manche
	_box(img, cx - 1, 16, 1, 33, WOOD.lightened(0.12))
	# Tête sphérique à pointes.
	_sphere(img, cx, 8, 7, 7, STEEL)
	for a in 8:
		var ang := TAU * float(a) / 8.0
		var px := cx + int(round(cos(ang) * 8.0))
		var py := 8 + int(round(sin(ang) * 8.0))
		_box(img, px - 1, py - 1, 2, 2, STEEL_DK)
	_sphere(img, cx - 2, 6, 2, 2, STEEL_HI)              # reflet


static func _w_bow(img: Image) -> void:
	var cx := WW / 2
	# Arc en C + corde.
	for j in range(3, 49):
		var t := float(j - 3) / 45.0
		var bend := int(round(sin(t * PI) * 7.0))
		_box(img, cx - 2 - bend, j, 3, 1, WOOD)
		_px(img, cx - 2 - bend, j, WOOD.lightened(0.15))
	_box(img, cx, 4, 1, 44, Color(0.92, 0.92, 0.92, 0.7))  # corde
	# Embouts.
	_box(img, cx - 2, 2, 3, 2, GOLD)
	_box(img, cx - 2, 48, 3, 2, GOLD)


# =============================================================================
# PRIMITIVES DE DESSIN (avec ombrage)
# =============================================================================

static func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)


static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			_px(img, i, j, color)


## Volume "boîte" avec edge-lighting automatique (lumière haut-gauche).
static func _box(img: Image, x: int, y: int, w: int, h: int, base: Color) -> void:
	_rect(img, x, y, w, h, base)
	if w >= 2 and h >= 2:
		_rect(img, x, y, w, 1, base.lightened(0.22))          # arête haute
		_rect(img, x, y, 1, h, base.lightened(0.12))          # arête gauche
		_rect(img, x, y + h - 1, w, 1, base.darkened(0.3))     # arête basse
		_rect(img, x + w - 1, y, 1, h, base.darkened(0.18))    # arête droite


## Dégradé vertical (assombrit progressivement vers le bas) sur une zone déjà peinte.
static func _shade_v(img: Image, x: int, y: int, w: int, h: int, amount: float) -> void:
	for j in range(h):
		var t := float(j) / maxf(1.0, float(h - 1))
		for i in range(x, x + w):
			var c := img.get_pixel(i, y + j)
			if c.a > 0.0:
				img.set_pixel(i, y + j, c.darkened(amount * t))


## Trapèze drapé (robe) : large en bas, dégradé haut->bas.
static func _trap(img: Image, cx: int, top: int, top_w: int, bot_w: int, h: int, top_col: Color, bot_col: Color) -> void:
	for j in range(h):
		var t := float(j) / maxf(1.0, float(h - 1))
		var hw := int(lerpf(float(top_w) * 0.5, float(bot_w) * 0.5, t))
		var col := top_col.lerp(bot_col, t * 0.7)
		_rect(img, cx - hw, top + j, hw * 2, 1, col)
		_px(img, cx - hw, top + j, col.lightened(0.14))
		_px(img, cx + hw - 1, top + j, col.darkened(0.18))


## Triangle plein (par balayage de scanlines).
static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var min_y := int(floor(minf(a.y, minf(b.y, c.y))))
	var max_y := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	for y in range(min_y, max_y + 1):
		var xs: Array[float] = []
		_edge_x(a, b, y, xs)
		_edge_x(b, c, y, xs)
		_edge_x(c, a, y, xs)
		if xs.size() >= 2:
			xs.sort()
			var x0 := int(floor(xs[0]))
			var x1 := int(ceil(xs[xs.size() - 1]))
			for x in range(x0, x1 + 1):
				_px(img, x, y, col)


static func _edge_x(p: Vector2, q: Vector2, y: int, out: Array[float]) -> void:
	if (p.y <= y and q.y > y) or (q.y <= y and p.y > y):
		var t := (float(y) - p.y) / (q.y - p.y)
		out.append(p.x + t * (q.x - p.x))


## Sphère/ellipsoïde ombrée (éclairage diffus, lumière LIGHT).
static func _sphere(img: Image, cx: int, cy: int, rx: float, ry: float, base: Color) -> void:
	for j in range(int(cy - ry), int(cy + ry) + 1):
		for i in range(int(cx - rx), int(cx + rx) + 1):
			var nx := (float(i) - cx) / rx
			var ny := (float(j) - cy) / ry
			var d := nx * nx + ny * ny
			if d > 1.0:
				continue
			var nz := sqrt(maxf(0.0, 1.0 - d))
			var lit := Vector3(nx, ny, -nz).dot(LIGHT)
			var col := base
			if lit > 0.35:
				col = base.lightened((lit - 0.35) * 0.95)
			elif lit < 0.0:
				col = base.darkened(minf(0.55, -lit * 0.65))
			_px(img, i, j, col)


## Ajoute un contour 1px autour de la silhouette.
static func _apply_outline(img: Image, color: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate()
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			var touch := false
			for dxy in dirs:
				var nx := x + dxy.x
				var ny := y + dxy.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h and src.get_pixel(nx, ny).a > 0.0:
					touch = true
					break
			if touch:
				img.set_pixel(x, y, color)


## Renforce l'ancrage au sol : assombrit la rangée de pixels la plus basse.
static func _apply_shadow_band(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for x in w:
		for y in range(h - 1, maxi(0, h - 4), -1):
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c != OUTLINE:
				img.set_pixel(x, y, c.darkened(0.22))
				break
