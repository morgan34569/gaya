extends TextureRect

@onready var cooldown_bar = $CooldownBar

# 플레이어 기마병(Cavalry) 노드를 연결할 변수
var player : Node = null

func _ready():
	# 게임이 시작되면, 현재 씬에서 플레이어 노드를 찾아서 연결합니다.
	# (플레이어 노드의 정확한 이름이 "PlayerCavalry"라고 가정합니다. 다르면 바꿔주세요!)
	player = get_tree().current_scene.get_node_or_null("Cavalry") 
	
	# 쿨타임 바 기본 설정 (최대치는 8초로 설정)
	cooldown_bar.max_value = 8.0 
	cooldown_bar.value = 0
	cooldown_bar.hide()

func _process(delta):
	if player == null:
		return # 플레이어가 없으면 작동하지 않음
		
	# 플레이어의 E 스킬 쿨타임이 남아있다면
	if player.e_skill_cooldown > 0:
		if not cooldown_bar.visible:
			cooldown_bar.show() # 검은 막 보이기
			
		# 게이지에 현재 남은 쿨타임을 실시간으로 반영!
		cooldown_bar.value = player.e_skill_cooldown 
	else:
		# 쿨타임이 0이 되면 게이지를 숨김
		if cooldown_bar.visible:
			cooldown_bar.hide()
