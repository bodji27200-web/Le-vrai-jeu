## Contenu du monde : les zones de l'overworld (data-driven, en code pour l'instant).
class_name WorldLibrary

static func _zone(id: String, name: String, pos: Vector2, color: Color, desc: String, encounter: bool = true, village: bool = false) -> ZoneData:
	var z := ZoneData.new()
	z.id = id
	z.display_name = name
	z.overworld_position = pos
	z.theme_color = color
	z.description = desc
	z.has_encounter = encounter
	z.is_village = village
	return z

static func zones() -> Array[ZoneData]:
	# Démo centrée sur UNE région : le Hameau (hub) et la forêt voisine.
	var list: Array[ZoneData] = []
	list.append(_zone("hameau", "Hameau de l'Aube", Vector2(140, 60),
		Color(0.74, 0.62, 0.42), "Un village de bois : taverne, forge et marché. Ton refuge.", false, true))
	list.append(_zone("clairiere", "Clairière d'Émeraude", Vector2(-320, -80),
		Color(0.26, 0.5, 0.32), "Une forêt profonde, vivante, où la lumière filtre entre les arbres."))
	return list
