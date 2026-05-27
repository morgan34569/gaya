extends Node2D

var archer_scene = preload("res://Archer.tscn")
var warrior_scene = preload("res://Warrior.tscn")
var lancer_scene = preload("res://Lancer.tscn")
var enemy_scenes = [warrior_scene, lancer_scene, archer_scene]
var arrow_scene = preload("res://arrow.tscn")
var is_victory: bool = false
var current_food: int = 100 
var food_per_second: int = 10 
var current_stage: int = 1        
var time_passed: int = 0          
var stage_duration: int = 30      
var enemy_stat_multiplier: float = 1.0 
var ally_buff_multiplier: float = 1.0
var buff_radius: float = 300.0
var aura_duration_left: float = 0.0
var w_skill_cooldown: float = 0.0 
var r_skill_cooldown: float = 0.0
var is_raining_arrows: bool = false
var arrow_duration: float = 0.0


@onready var game_over_panel = get_node_or_null("CanvasLayer/GameOverPanel")
@onready var result_label = get_node_or_null("CanvasLayer/GameOverPanel/ResultLabel")
@onready var food_label = get_node_or_null("CanvasLayer/TopBarContainer/FoodLabel")
@onready var stage_label = get_node_or_null("CanvasLayer/TopBarContainer/StageLabel")
@onready var enemy_spawn_timer = $EnemySpawnTimer
@onready var retry_button = get_node_or_null("CanvasLayer/GameOverPanel/RetryButton")
@onready var retreat_button = get_node_or_null("CanvasLayer/GameOverPanel/RetreatButton")
@onready var skill_cooldown_timer = $SkillCooldownTimer
@onready var general_node = $CharacterBody2D

func _ready():
	food_per_second = 10 + (Global.farm_level * 5)
	print("현재 농장 레벨: ", Global.farm_level, " / 초당 식량 생산량: ", food_per_second)
	
	ally_buff_multiplier = 1.0 + (Global.aragaya_forge_level * 0.15)
	print("🛡️ 아라가야 철갑 버프 적용! 아군 스탯 배율: ", ally_buff_multiplier)
	
	# 점령한 국가 수에 따른 '기본 난이도' 증가 로직
	# (대가야 1개를 제외한 순수 정복 국가 수)
	var conquered_count = Global.unlocked_territories.size() - 1 
	
	# 점령한 국가 1곳당 적 스탯이 30%씩 강해지고 시작합니다. (원하는 수치로 변경 가능)
	enemy_stat_multiplier = 1.0 + (conquered_count * 0.3)
	
	# 기본 스폰 쿨타임도 점령한 곳 1곳당 0.2초씩 짧게 시작합니다. (최소 1초 제한)
	var starting_spawn_time = max(1.0, 3.0 - (conquered_count * 0.2))
	if enemy_spawn_timer:
		enemy_spawn_timer.wait_time = starting_spawn_time
		
	print("🌍 현재 정복한 적국 수: ", conquered_count, " / 😈 적군 시작 스탯 배율: ", enemy_stat_multiplier)
	
	if Global.current_target_city == "Baekje_Invasion":
		enemy_stat_multiplier = 2.0
		print("⚔️ 백제 강군 등장! 스탯 2배 보정")
	elif Global.current_target_city == "Silla_Invasion":
		enemy_stat_multiplier = 3.0
		print("⚔️ 신라 정예군 등장! 스탯 3배 보정")
	elif Global.current_target_city == "Goguryeo_Invasion":
		enemy_stat_multiplier = 4.0
		print("🔥 고구려 개마무사 대군 등장!! 스탯 4배 보정")
	update_food_ui()
	update_stage_ui()
	
	if general_node:
		var stat_multiplier = 1.0 + ((Global.gen_stat_level - 1) * 0.2)
		general_node.max_hp = int(general_node.max_hp * stat_multiplier)
		general_node.damage = int(general_node.damage) + ((Global.gen_stat_level - 1) * 50)
		general_node.current_hp = general_node.max_hp # 최대 체력으로 꽉 채워주기
		
		if general_node.hp_bar:
			general_node.hp_bar.max_value = general_node.max_hp
			general_node.hp_bar.value = general_node.current_hp
			
	# Q 스킬 반경 증가 적용 (레벨당 50씩 증가, 300 ~ 500)
	buff_radius = 300.0 + ((Global.gen_q_level - 1) * 50.0)
	
func update_food_ui():
	if food_label:
		food_label.text = "🌾 식량: " + str(current_food)
		
func update_stage_ui():
	if stage_label:
		var enemy_name = get_enemy_name()
		stage_label.text = enemy_name

# --- [병사 소환 (강화 레벨 적용)] ---

func _on_warrior_button_pressed() -> void:
	var cost = 30 
	if current_food >= cost:
		current_food -= cost 
		update_food_ui()     
		
		var new_warrior = warrior_scene.instantiate()
		
		# 보병 레벨 배율 (레벨당 20% 증가)
		var level_multiplier = 1.0 + ((Global.warrior_level - 1) * 0.2)
		new_warrior.max_hp = int(new_warrior.max_hp * ally_buff_multiplier * level_multiplier)
		new_warrior.damage = int(new_warrior.damage * ally_buff_multiplier * level_multiplier)
		
		new_warrior.global_position = $AllyBase/SpawnPoint.global_position
		add_child(new_warrior)
	else:
		print("전사를 소환하기엔 식량이 부족합니다!")

func _on_lancer_button_pressed() -> void:
	var cost = 40 
	if current_food >= cost:
		current_food -= cost
		update_food_ui()
		
		var new_lancer = lancer_scene.instantiate()
		
		# 창병 레벨 배율 (레벨당 20% 증가)
		var level_multiplier = 1.0 + ((Global.lancer_level - 1) * 0.2)
		new_lancer.max_hp = int(new_lancer.max_hp * ally_buff_multiplier * level_multiplier)
		new_lancer.damage = int(new_lancer.damage * ally_buff_multiplier * level_multiplier)
		
		new_lancer.global_position = $AllyBase/SpawnPoint.global_position
		add_child(new_lancer)
	else:
		print("창병을 소환하기엔 식량이 부족합니다!")

func _on_button_pressed() -> void: # (궁병 버튼)
	var cost = 50 
	if current_food >= cost:
		current_food -= cost
		update_food_ui()
		
		var new_archer = archer_scene.instantiate()
		
		# 궁병 레벨 배율 (레벨당 20% 증가)
		var level_multiplier = 1.0 + ((Global.archer_level - 1) * 0.2)
		new_archer.max_hp = int(new_archer.max_hp * ally_buff_multiplier * level_multiplier)
		new_archer.damage = int(new_archer.damage * ally_buff_multiplier * level_multiplier)
		
		new_archer.global_position = $AllyBase/SpawnPoint.global_position
		add_child(new_archer)
	else:
		print("궁수를 소환하기엔 식량이 부족합니다!")


# --- [게임 오버 및 시스템 함수] ---
func game_over(is_ally_base_destroyed: bool):
	is_victory = not is_ally_base_destroyed
	if game_over_panel and result_label:
		if is_ally_base_destroyed:
			# 💀 패배 처리
			if Global.current_target_city in ["Silla_Invasion", "Baekje_Invasion", "Goguryeo_Invasion"]:
				var penalty = 0.20 # 20% 약탈 (원하는 수치로 변경 가능)
				
				var lost_gold = int(Global.total_gold * penalty)
				var lost_wood = int(Global.total_wood * penalty)
				var lost_food = int(Global.total_food * penalty)
				var lost_iron = int(Global.total_iron * penalty)
				
				Global.total_gold -= lost_gold
				Global.total_wood -= lost_wood
				Global.total_food -= lost_food
				Global.total_iron -= lost_iron
				
				result_label.text = "DEFEAT\n침공을 막지 못해 자원을 약탈당했습니다!\n(모든 자원 20% 손실)"
				print("🔥 약탈당한 자원 - 금:", lost_gold, " 목재:", lost_wood, " 식량:", lost_food, " 철:", lost_iron)
			
			# ⚔️ 일반 가야 정벌전에서 패배했다면? (약탈 없음)
			else:
				result_label.text = "DEFEAT\n전투에서 패배했습니다...\n후퇴하여 전열을 가다듬겠습니까?"

			# 공통 UI 처리 (다시하기, 후퇴 버튼 보이기)
			if retry_button: 
				retry_button.visible = true
				retry_button.text = "다시하기"
			if retreat_button: 
				retreat_button.visible = true
				retreat_button.text = "월드맵 후퇴"
				
		else:
			# 🛡️ 이벤트 전투 승리 (신라, 백제, 고구려 방어 성공!)
			if Global.current_target_city == "Silla_Invasion":
				Global.is_silla_defeated = true
				# 💰 신라 방어 보상 (초반부 쏠쏠한 자원)
				Global.total_gold += 1000
				Global.total_wood += 500
				Global.total_food += 500
				Global.total_iron += 250
				result_label.text = "VICTORY\n신라군의 침공을 막아냈습니다!\n적의 보급품 노획: 금 1000, 목재 500, 식량 500, 철 250"
				if retry_button: retry_button.text = "월드맵 귀환"
				
			elif Global.current_target_city == "Baekje_Invasion":
				Global.is_baekje_defeated = true
				# 💰 백제 방어 보상 (중반부 폭발적인 자원)
				Global.total_gold += 2000
				Global.total_wood += 1000
				Global.total_food += 1000
				Global.total_iron += 500
				result_label.text = "VICTORY\n백제군의 침공을 막아냈습니다!\n엄청난 전리품: 금 2000, 목재 1000, 식량 1000, 철 500"
				if retry_button: retry_button.text = "월드맵 귀환"
				
			elif Global.current_target_city == "Goguryeo_Invasion":
				Global.is_goguryeo_defeated = true
				# 💰 고구려 방어 보상 (엔딩 직전 상징적인 초대박 보상)
				Global.total_gold += 10000
				Global.total_wood += 5000
				Global.total_food += 5000
				Global.total_iron += 3000
				result_label.text = "🌟 엔딩(Ending) 🌟\n고구려 대군마저 꺾었습니다!\n이제 가야는 하나의 나라로 성장했고 그 누구도 넘볼 수 없습니다!"
				if retry_button: retry_button.text = "월드맵 귀환"
				
			# ⚔️ 일반 가야 점령 전투 승리 (기존 로직 유지)
			else:
				result_label.text = "VICTORY\n승리했습니다!! 🎉"
				if retry_button: retry_button.text = "월드맵 귀환"
				
				# 영토 확장 및 전리품 획득 로직
				if Global.current_target_city != "" and not Global.unlocked_territories.has(Global.current_target_city):
					Global.unlocked_territories.append(Global.current_target_city)
					print(Global.current_target_city, " 점령 완료!")
					
					var conquered_count = Global.unlocked_territories.size() - 1
					var reward_multiplier = 1.0 + (conquered_count * 0.5) 
					
					var reward_gold = int(500 * reward_multiplier)
					var reward_wood = int(300 * reward_multiplier)
					var reward_food = int(300 * reward_multiplier)
					var reward_iron = int(150 * reward_multiplier)
					
					Global.total_gold += reward_gold
					Global.total_wood += reward_wood
					Global.total_food += reward_food
					Global.total_iron += reward_iron
					
					print("🎁 단계별 전리품 획득! 금:", reward_gold, " 목재:", reward_wood, " 식량:", reward_food, " 철:", reward_iron, " (보상 배율: ", reward_multiplier, "x)")

		game_over_panel.visible = true
	get_tree().paused = true
	
func _on_enemy_spawn_timer_timeout() -> void:
	var selected_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var new_enemy = selected_scene.instantiate()
	new_enemy.is_ally = false
	
	new_enemy.max_hp = int(new_enemy.max_hp * enemy_stat_multiplier)
	new_enemy.damage = int(new_enemy.damage * enemy_stat_multiplier)
	
	new_enemy.global_position = $EnemyBase/SpawnPoint.global_position
	add_child(new_enemy)

# 게임 결과 창의 버튼(다시하기/월드맵 귀환)을 눌렀을 때 실행되는 함수
func _on_retry_button_pressed() -> void:
	get_tree().paused = false 
	get_tree().reload_current_scene()
	
func _on_retreat_button_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://WorldMap.tscn")

func _on_gold_timer_timeout() -> void:
	current_food += food_per_second
	update_food_ui()
	if current_stage < 5: 
		time_passed += 1
		if time_passed >= stage_duration:
			level_up_stage()
			
func level_up_stage():
	current_stage += 1
	time_passed = 0 
	update_stage_ui()
	print("🚨 스테이지 업! 현재 단계: ", current_stage)
	
	# 스폰 쿨타임을 현재 남은 시간에서 0.4초씩 추가로 줄입니다. (최소 0.5초)
	enemy_spawn_timer.wait_time = max(0.5, enemy_spawn_timer.wait_time - 0.4)
	
	# 적 스탯 배율을 덮어씌우지 않고, 스테이지마다 20%씩 '추가'합니다.
	enemy_stat_multiplier += 0.2
	
	print("현재 적군 전체 스탯 배율: ", enemy_stat_multiplier)
	
# 현재 교전 중인 적군의 한글 이름을 반환하는 함수
func get_enemy_name() -> String:
	match Global.current_target_city:
		"GeumgwanGayaButton": return "금관가야"
		"SeongsanGayaButton": return "성산가야"
		"GoryeongGayaButton": return "고령가야"
		"SoGayaButton": return "소가야"
		"AraGayaButton": return "아라가야"
		"Silla_Invasion": return "신라군"
		"Baekje_Invasion": return "백제군"
		"Goguryeo_Invasion": return "고구려군"
		_: return "알 수 없는 적"
		
func _process(delta):
	# 1. 스킬 발동 (Q 키 입력)
	if Input.is_action_just_pressed("skill_q"):
		if skill_cooldown_timer.is_stopped():
			activate_skill()
			
	if w_skill_cooldown > 0:
		w_skill_cooldown -= delta
		
	if Input.is_action_just_pressed("skill_w") and w_skill_cooldown <= 0:
		activate_w_skill()

	# 2. 오라(Aura) 유지 및 실시간 버프 부여 로직
	if aura_duration_left > 0:
		aura_duration_left -= delta # 매 프레임마다 남은 시간을 깎습니다.
		
		# 💡 시간이 다 깎여서 0 이하가 되는 순간! 장판을 끕니다.
		if aura_duration_left <= 0:
			if general_node and general_node.has_method("turn_off_aura"):
				general_node.turn_off_aura()
		
		# 장군 노드가 정상적으로 있을 때만 거리 검사 진행
		if general_node != null:
			for node in get_children():
				# 아군이고, 플레이어(장군) 자신이 아니라면
				if "is_ally" in node and node.is_ally == true and node != general_node:
					
					# 거리 계산
					var distance = general_node.global_position.distance_to(node.global_position)
					
					# 반경 안(300)에 들어왔다면 버프 부여!
					if distance <= buff_radius:
						if node.has_method("receive_buff"):
							node.receive_buff()
	# 1. 쿨타임 감소 로직
	if r_skill_cooldown > 0:
		r_skill_cooldown -= delta
		
	# 2. R키 입력 감지 및 스킬 발동
	if Input.is_action_just_pressed("skill_r") and r_skill_cooldown <= 0:
		activate_r_skill()
		
	# 3. 화살비가 내리는 2초 동안 '진짜 화살 객체'를 매 프레임 소환합니다.
	if is_raining_arrows:
		arrow_duration -= delta
		
		var arrow_count = 3 + int((Global.gen_r_level - 1) * 0.75)

		for i in range(arrow_count):
			var new_arrow = arrow_scene.instantiate()
			new_arrow.is_ally_arrow = true
			new_arrow.is_raining = true 
			
			# 현재 화면을 찍고 있는 카메라를 가져옵니다
			var camera = get_viewport().get_camera_2d()
			var screen_width = get_viewport_rect().size.x
			var random_x = 0.0
			
			if camera:
				# 카메라 중심점에서 화면 절반만큼 왼쪽/오른쪽으로 범위를 잡습니다
				var left_edge = camera.global_position.x - (screen_width / 2.0)
				random_x = randf_range(left_edge, left_edge + screen_width)
			else:
				random_x = randf_range(0, screen_width)
				
			var random_y = randf_range(-200, 0)
			new_arrow.position = Vector2(random_x, random_y)
			
			add_child(new_arrow)
		
		# 2초가 지나면 비 멈춤
		if arrow_duration <= 0:
			is_raining_arrows = false

func activate_skill():
	var duration = 5.0 + ((Global.gen_q_level - 1) * 1.0) 
	aura_duration_left = duration     
	print("📣 장군의 함성 발동! ", duration, "초간 주변 아군 지속 강화! (반경: ", buff_radius, ")")
	
	if general_node and general_node.has_method("turn_on_aura"):
		general_node.turn_on_aura()
	
	print("📣 장군의 함성 발동! 5초간 주변 아군 지속 강화!")
	
	# 스킬이 켜지는 순간, 장군의 발밑에 푸른색 장판을 그려줍니다.
	if general_node and general_node.has_method("turn_on_aura"):
		general_node.turn_on_aura()
			
# --- [스크립트 맨 아래에 추가] ---
func activate_w_skill():
	# W 스킬 5레벨(만렙) 달성 시 쿨타임 15초 -> 12초로 감소
	var cooldown = 12.0 if Global.gen_w_level >= 5 else 15.0
	w_skill_cooldown = cooldown 
	
	print("🛡️ 결속의 가시 갑옷 발동! 5초간 피해 반사! (쿨타임: ", cooldown, "초)")
	
	if general_node:
		if general_node.has_method("receive_thorn_buff"):
			general_node.receive_thorn_buff()
		
		for node in get_children():
			if "is_ally" in node and node.is_ally == true and node != general_node:
				var distance = general_node.global_position.distance_to(node.global_position)
				if distance <= buff_radius:
					if node.has_method("receive_thorn_buff"):
						node.receive_thorn_buff()
	
func activate_r_skill():
	r_skill_cooldown = 30.0 # 쿨타임 30초
	is_raining_arrows = true
	arrow_duration = 2.0    # 2초 동안 발동
	
	print("🏹 천벌의 화살비 발동!! 하늘에서 화살이 쏟아집니다!")
