extends TextureRect

@onready var cooldown_bar = $CooldownBar
var main_battle : Node = null

func _ready():
  
	main_battle = get_tree().current_scene 
	
	cooldown_bar.max_value = 10.0 # Q 스킬의 총 쿨타임 (초)
	cooldown_bar.value = 0
	cooldown_bar.hide()

func _process(delta):
	if main_battle == null: return
		
   
	if main_battle.q_skill_cooldown > 0: 
		if not cooldown_bar.visible: cooldown_bar.show()
		cooldown_bar.value = main_battle.q_skill_cooldown 
	else:
		if cooldown_bar.visible: cooldown_bar.hide()
