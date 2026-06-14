extends TextureRect

@onready var cooldown_bar = $CooldownBar
var main_battle : Node = null

func _ready():
	# 현재 실행 중인 메인 씬(MainBattle)을 가져옵니다.
	main_battle = get_tree().current_scene 
	
	# 💡 R 스킬의 최대 쿨타임을 설정합니다 (30초)
	cooldown_bar.max_value = 30.0 
	cooldown_bar.value = 0
	cooldown_bar.hide()

func _process(delta):
	if main_battle == null: return
		
	# 💡 R 스킬 쿨타임 변수(r_skill_cooldown)를 쳐다보게 합니다!
	if main_battle.r_skill_cooldown > 0: 
		if not cooldown_bar.visible: 
			cooldown_bar.show()
			
			# 혹시 나중에 R 스킬 레벨업으로 쿨타임이 줄어들 것에 대비한 코드
			if cooldown_bar.max_value != main_battle.r_skill_cooldown and cooldown_bar.value == 0:
				cooldown_bar.max_value = main_battle.r_skill_cooldown
				
		# 쿨타임 숫자대로 까만 막대를 깎아냅니다.
		cooldown_bar.value = main_battle.r_skill_cooldown 
	else:
		if cooldown_bar.visible: 
			cooldown_bar.hide()
