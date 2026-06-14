extends TextureRect

@onready var cooldown_bar = $CooldownBar
var main_battle : Node = null

func _ready():
	# 현재 실행 중인 메인 씬(MainBattle)을 가져옵니다.
	main_battle = get_tree().current_scene 
	
	# 💡 W 스킬의 최대 쿨타임을 설정합니다 (기본 15초)
	cooldown_bar.max_value = 15.0 
	cooldown_bar.value = 0
	cooldown_bar.hide()

func _process(delta):
	if main_battle == null: return
		
	# 💡 Q 대신 W 스킬 쿨타임 변수(w_skill_cooldown)를 쳐다보게 합니다!
	if main_battle.w_skill_cooldown > 0: 
		if not cooldown_bar.visible: 
			cooldown_bar.show()
			
			# (선택) 만약 W 스킬 레벨이 5라서 쿨타임이 12초가 됐다면, 
			# 막대기의 최대 길이도 그에 맞춰서 12초로 줄여주는 센스있는 코드입니다!
			if cooldown_bar.max_value != main_battle.w_skill_cooldown and cooldown_bar.value == 0:
				cooldown_bar.max_value = main_battle.w_skill_cooldown
				
		# 쿨타임 숫자대로 까만 막대를 깎아냅니다.
		cooldown_bar.value = main_battle.w_skill_cooldown 
	else:
		if cooldown_bar.visible: 
			cooldown_bar.hide()
