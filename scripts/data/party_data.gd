## Conteneur éditable d'une équipe de héros (pour la migration vers .tres).
## Permet de stocker une Array[CharacterData] dans un seul fichier .tres
## éditable dans l'inspecteur Godot.
class_name PartyData
extends Resource

@export var members: Array[CharacterData] = []
