extends Resource

@export var name: String = "Enemy"
@export var type: String = "Defender"
@export var animation: SpriteFrames = null
@export var health: int = 30
@export var current_health: int = 30
@export var damage: int = 20
@export var speed: int = 25
@export var magic: int = 0
@export var actions: Array = ["attack"]
@export var audio: AudioStream = null
