## Énumérations partagées de tout le jeu.
## Centralisées ici pour rester data-driven et éviter les "chaînes magiques".
class_name GameEnums

enum Element { NONE, FIRE, ICE, LIGHTNING, EARTH, HOLY, SHADOW }

enum Rarity { COMMON, RARE, EPIC, LEGENDARY, UNIQUE }

## Comportements d'IA des ennemis (cf. vision : archétypes).
enum Archetype { AGGRESSIVE, DEFENSIVE, OPPORTUNIST, PROTECTOR, MANIPULATOR }

enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SELF, SINGLE_ALLY, ALL_ALLIES }

## Résultat d'une fenêtre de défense active.
enum DefenseResult { HIT, PARRY, DODGE }

## Rôles d'invocation (cf. vision Nécromancien : rôles distincts).
enum SummonRole { TANK, FAST, OFFENSIVE }

enum Difficulty { EASY, NORMAL, HARD, HARDCORE }
