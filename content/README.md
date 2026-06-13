# Contenu éditable (.tres)

Ce dossier accueille le contenu du jeu sous forme de **ressources `.tres`
éditables dans l'inspecteur Godot** (équipe, rencontres, zones).

## Comment générer les `.tres`

Les fichiers sont produits automatiquement à partir des builders en code
(`scripts/content/content_library.gd` et `world_library.gd`). Lance **une fois**,
depuis la racine du projet :

```powershell
& $godot --headless --path . --script res://tools/generate_content.gd
```

Cela crée :

- `content/party.tres` — l'équipe de départ (`PartyData`)
- `content/encounter_demo.tres` — la rencontre de démo (`EncounterData`)
- `content/world.tres` — les zones de l'overworld (`WorldData`)

## Comment ça marche

`ContentDB` (`scripts/content/content_db.gd`) est le **point d'accès unique** au
contenu :

1. si le `.tres` existe → il est chargé (c'est lui la source de vérité, éditable
   dans l'inspecteur) ;
2. sinon → repli automatique sur les builders en code, avec un avertissement.

Conséquence : **le jeu tourne avant comme après la génération**, sans jamais
casser. Une fois les `.tres` générés, modifie-les dans l'éditeur sans toucher au
code. Pour repartir des valeurs du code, supprime les `.tres` (ou relance le
générateur).
