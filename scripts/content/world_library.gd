## Contenu du monde : les zones de l'overworld (data-driven, en code pour l'instant).
class_name WorldLibrary

static func _zone(id: String, name: String, pos: Vector2, color: Color, desc: String, encounter: bool = true) -> ZoneData:
	var z := ZoneData.new()
	z.id = id
	z.display_name = name
	z.overworld_position = pos
	z.theme_color = color
	z.description = desc
	z.has_encounter = encounter
	return z

static func zones() -> Array[ZoneData]:
	var list: Array[ZoneData] = []
	list.append(_zone("clairiere", "Clairière d'Émeraude", Vector2(-420, -150),
		Color(0.30, 0.58, 0.35), "Une forêt paisible baignée de lumière verte."))
	list.append(_zone("givre", "Cols de Givre", Vector2(380, -230),
		Color(0.55, 0.7, 0.85), "Des cols enneigés balayés par le vent glacé."))
	list.append(_zone("marais", "Marais d'Ombre", Vector2(-330, 250),
		Color(0.4, 0.45, 0.3), "Un marécage brumeux où rôdent les morts."))
	list.append(_zone("ruines", "Cité en Ruines", Vector2(430, 210),
		Color(0.6, 0.55, 0.45), "Les vestiges d'une cité jadis glorieuse."))
	list.append(_zone("sanctuaire", "Sanctuaire Oublié", Vector2(10, -330),
		Color(0.85, 0.78, 0.5), "Un lieu sacré au calme inquiétant.", false))
	return list
