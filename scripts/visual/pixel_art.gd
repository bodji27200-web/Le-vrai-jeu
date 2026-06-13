## Générateur de sprites pixel art "maison" (dessinés par code, pixel par pixel).
## Aucune dépendance à des assets externes : tout est généré au lancement.
## Échantillon de départ : silhouettes lisibles, palettes par personnage,
## contour automatique. À enrichir (frames d'animation, plus de détails) ensuite.
class_name PixelArt

const W := 24
const H := 32
const OUTLINE := Color8(20, 18, 28)

static var _cache: Dictionary = {}


## Retourne (et met en cache) la texture pixel art d'un type d'unité.
static func for_unit(kind: String) -> Texture2D:
	if _cache.has(kind):
		return _cache[kind]
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint(img, kind)
	_apply_outline(img, OUTLINE)
	var tex := ImageTexture.create_from_image(img)
	_cache[kind] = tex
	return tex


static func _paint(img: Image, kind: String) -> void:
	match kind:
		"gardien":
			_knight(img, Color8(120, 140, 165), Color8(70, 85, 110), Color8(235, 200, 165), Color8(225, 195, 95))
		"boss_chevalier":
			_knight(img, Color8(85, 72, 100), Color8(48, 40, 62), Color8(120, 100, 120), Color8(205, 60, 70))
		"pyromancien":
			_mage(img, Color8(190, 70, 55), Color8(130, 40, 35), Color8(235, 200, 165), Color8(255, 180, 70), true, false)
		"necromancien":
			_mage(img, Color8(74, 58, 100), Color8(42, 32, 62), Color8(205, 200, 190), Color8(150, 230, 160), true, true)
		"acolyte":
			_mage(img, Color8(58, 52, 74), Color8(32, 28, 46), Color8(200, 195, 185), Color8(175, 95, 205), false, true)
		"garde_squelette":
			_skeleton(img, Color8(228, 222, 202), Color8(150, 144, 126))
		"zombie":
			_humanoid(img, Color8(120, 165, 100), Color8(96, 84, 70), Color8(62, 56, 50), Color8(150, 60, 60))
		"goule":
			_humanoid(img, Color8(184, 172, 204), Color8(82, 72, 94), Color8(52, 46, 62), Color8(120, 90, 140))
		"aberration":
			_blob(img, Color8(212, 112, 60), Color8(140, 62, 40), Color8(255, 232, 120))
		"duelliste":
			_humanoid(img, Color8(235, 200, 165), Color8(60, 80, 120), Color8(36, 48, 78), Color8(220, 220, 235))
		"clerc":
			_mage(img, Color8(232, 230, 238), Color8(150, 150, 172), Color8(235, 200, 165), Color8(240, 210, 90), true, true)
		"berserker":
			_humanoid(img, Color8(235, 200, 165), Color8(160, 52, 46), Color8(96, 30, 28), Color8(220, 190, 70))
		"rodeur":
			_humanoid(img, Color8(235, 200, 165), Color8(70, 110, 70), Color8(40, 66, 42), Color8(150, 110, 70))
		"paladin":
			_knight(img, Color8(215, 205, 170), Color8(150, 130, 80), Color8(235, 200, 165), Color8(245, 225, 120))
		"elementaliste":
			_mage(img, Color8(70, 150, 180), Color8(40, 90, 120), Color8(235, 200, 165), Color8(150, 210, 255), true, false)
		"moine":
			_humanoid(img, Color8(235, 200, 165), Color8(210, 140, 70), Color8(150, 90, 44), Color8(240, 220, 150))
		_:
			_humanoid(img, Color8(220, 200, 170), Color8(110, 120, 160), Color8(70, 78, 110), Color8(220, 200, 120))


# --- Gabarits ----------------------------------------------------------------

static func _humanoid(img: Image, skin: Color, main: Color, dark: Color, accent: Color) -> void:
	# Jambes
	_rect(img, 9, 23, 3, 6, dark)
	_rect(img, 13, 23, 3, 6, dark)
	# Torse
	_rect(img, 8, 14, 9, 10, main)
	_rect(img, 8, 21, 9, 2, accent)   # ceinture
	# Bras
	_rect(img, 6, 15, 2, 7, main)
	_rect(img, 17, 15, 2, 7, main)
	_rect(img, 6, 21, 2, 2, skin)     # mains
	_rect(img, 17, 21, 2, 2, skin)
	# Tête
	_rect(img, 9, 5, 7, 8, skin)
	_rect(img, 10, 8, 1, 1, OUTLINE)  # yeux
	_rect(img, 14, 8, 1, 1, OUTLINE)


static func _knight(img: Image, main: Color, dark: Color, skin: Color, accent: Color) -> void:
	# Jambes blindées
	_rect(img, 9, 23, 3, 6, dark)
	_rect(img, 13, 23, 3, 6, dark)
	# Plastron
	_rect(img, 7, 14, 11, 10, main)
	_rect(img, 11, 15, 2, 8, dark)    # ligne centrale
	_rect(img, 7, 21, 11, 2, accent)  # ceinturon
	# Bras + bouclier
	_rect(img, 5, 15, 2, 8, main)
	_rect(img, 18, 15, 2, 8, main)
	_rect(img, 3, 15, 3, 9, accent)   # bouclier
	_rect(img, 4, 18, 1, 3, dark)
	# Casque
	_rect(img, 9, 4, 7, 9, main)
	_rect(img, 9, 8, 7, 2, dark)      # fente de visière
	_rect(img, 11, 8, 1, 2, accent)   # lueur des yeux
	_rect(img, 13, 8, 1, 2, accent)
	_rect(img, 11, 1, 3, 3, accent)   # cimier


static func _mage(img: Image, main: Color, dark: Color, skin: Color, accent: Color, staff: bool, hood: bool) -> void:
	# Robe (s'évase vers le bas)
	_rect(img, 8, 14, 9, 7, main)
	_rect(img, 7, 21, 11, 4, main)
	_rect(img, 6, 25, 13, 3, dark)
	# Bras
	_rect(img, 6, 15, 2, 7, main)
	_rect(img, 17, 15, 2, 7, main)
	# Tête + capuche / chapeau
	if hood:
		_rect(img, 8, 4, 9, 9, dark)      # capuche
		_rect(img, 10, 7, 5, 5, skin)     # visage dans l'ombre
		_rect(img, 10, 9, 1, 1, accent)   # yeux luisants
		_rect(img, 13, 9, 1, 1, accent)
	else:
		_rect(img, 9, 7, 7, 6, skin)      # visage
		_rect(img, 10, 9, 1, 1, OUTLINE)
		_rect(img, 14, 9, 1, 1, OUTLINE)
		# Chapeau pointu
		_rect(img, 12, 1, 1, 2, main)
		_rect(img, 11, 3, 3, 1, main)
		_rect(img, 10, 4, 5, 1, main)
		_rect(img, 8, 5, 9, 2, accent)    # bord du chapeau
	if staff:
		_rect(img, 19, 6, 1, 21, Color8(120, 90, 60))  # bâton
		_rect(img, 18, 4, 3, 3, accent)                # orbe
	else:
		_rect(img, 11, 15, 3, 3, accent)               # sceau magique


static func _skeleton(img: Image, bone: Color, dark: Color) -> void:
	# Jambes osseuses
	_rect(img, 9, 23, 2, 6, bone)
	_rect(img, 14, 23, 2, 6, bone)
	# Cage thoracique
	_rect(img, 8, 14, 9, 9, bone)
	_rect(img, 8, 16, 9, 1, dark)
	_rect(img, 8, 18, 9, 1, dark)
	_rect(img, 8, 20, 9, 1, dark)
	_rect(img, 11, 14, 2, 9, dark)
	# Bras
	_rect(img, 6, 15, 2, 7, bone)
	_rect(img, 17, 15, 2, 7, bone)
	# Crâne
	_rect(img, 9, 5, 7, 8, bone)
	_rect(img, 10, 8, 2, 2, OUTLINE)  # orbites
	_rect(img, 13, 8, 2, 2, OUTLINE)
	_rect(img, 11, 11, 3, 1, dark)    # mâchoire


static func _blob(img: Image, main: Color, dark: Color, accent: Color) -> void:
	# Masse principale irrégulière
	_rect(img, 6, 16, 13, 12, main)
	_rect(img, 8, 12, 9, 5, main)
	_rect(img, 5, 20, 2, 6, main)
	_rect(img, 18, 19, 2, 7, main)
	# Taches sombres
	_rect(img, 9, 22, 3, 3, dark)
	_rect(img, 14, 18, 2, 2, dark)
	# Pics
	_rect(img, 7, 13, 1, 3, dark)
	_rect(img, 16, 12, 1, 4, dark)
	# Gros œil
	_rect(img, 11, 16, 4, 4, accent)
	_rect(img, 12, 17, 2, 2, OUTLINE)


# --- Outils image ------------------------------------------------------------

static func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			if i >= 0 and i < img.get_width() and j >= 0 and j < img.get_height():
				img.set_pixel(i, j, color)


## Ajoute un contour 1px autour de la silhouette (tout pixel transparent
## voisin d'un pixel opaque devient la couleur de contour).
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
			for d in dirs:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h and src.get_pixel(nx, ny).a > 0.0:
					touch = true
					break
			if touch:
				img.set_pixel(x, y, color)
