extends Node2D

# 상단 자원 UI 노드
@onready var gold_label = $CanvasLayer/ResourceBar/HBoxContainer/GoldLabel
@onready var wood_label = $CanvasLayer/ResourceBar/HBoxContainer/WoodLabel
@onready var food_label = $CanvasLayer/ResourceBar/HBoxContainer/FoodLabel
@onready var iron_label = $CanvasLayer/ResourceBar/HBoxContainer/IronLabel

# 도시 관리 팝업창 및 기본 내정 버튼
@onready var city_panel = $CanvasLayer/CityPanel
@onready var farm_button = $CanvasLayer/CityPanel/VBoxContainer/FarmButton
@onready var lumber_button = $CanvasLayer/CityPanel/VBoxContainer/LumberButton
@onready var mine_button = $CanvasLayer/CityPanel/VBoxContainer/MineButton

# 특산물 버튼 5개
@onready var geumgwan_button = $CanvasLayer/CityPanel/VBoxContainer/GeumgwanTradeButton
@onready var sogaya_button = $CanvasLayer/CityPanel/VBoxContainer/SogayaFishButton
@onready var aragaya_button = $CanvasLayer/CityPanel/VBoxContainer/AragayaForgeButton
@onready var goryeong_button = $CanvasLayer/CityPanel/VBoxContainer/GoryeongSilkButton
@onready var seongsan_button = $CanvasLayer/CityPanel/VBoxContainer/SeongsanIronButton

# 병사 강화 버튼 3개
@onready var warrior_up_btn = $CanvasLayer/CityPanel/VBoxContainer/WarriorUpgradeButton
@onready var lancer_up_btn = $CanvasLayer/CityPanel/VBoxContainer/LancerUpgradeButton
@onready var archer_up_btn = $CanvasLayer/CityPanel/VBoxContainer/ArcherUpgradeButton
# 이벤트 발생시 
@onready var invasion_panel = $CanvasLayer/InvasionPanel
@onready var invasion_label = $CanvasLayer/InvasionPanel/InvasionLabel
@onready var invasion_button = $CanvasLayer/InvasionPanel/InvasionButton
var pending_invasion_target: String = ""

# 👑 장군 강화 버튼 5개
@onready var gen_stat_btn = $CanvasLayer/CityPanel/VBoxContainer/GenStatButton
@onready var gen_q_btn = $CanvasLayer/CityPanel/VBoxContainer/GenQButton
@onready var gen_w_btn = $CanvasLayer/CityPanel/VBoxContainer/GenWButton
@onready var gen_e_btn = $CanvasLayer/CityPanel/VBoxContainer/GenEButton
@onready var gen_r_btn = $CanvasLayer/CityPanel/VBoxContainer/GenRButton
# 초기화 버튼  
@onready var reset_military_btn = $CanvasLayer/CityPanel/VBoxContainer/ResetMilitaryButton
@onready var ending_panel = $CanvasLayer/EndingPanel


func _ready():
	# 1. 시작할 때 팝업창들 숨기기
	if city_panel: city_panel.visible = false
	if invasion_panel: invasion_panel.visible = false # 침공 경고창 숨기기
	if ending_panel: ending_panel.visible = false
	# 2. 침공 경고창의 '전투 돌입' 버튼 시그널 연결
	if invasion_button:
		invasion_button.pressed.connect(_on_invasion_button_pressed)
		
	# 3. 상단 자원 UI 업데이트
	update_resource_ui()
	
	# 4. 월드맵의 적국(가야) 버튼들 세팅
	var enemies = get_tree().get_nodes_in_group("enemy_cities")
	for enemy_btn in enemies:
		if Global.unlocked_territories.has(enemy_btn.name):
			# 이미 점령한 땅이면 초록색으로 표시
			enemy_btn.modulate = Color(0.5, 1.0, 0.5) 
			enemy_btn.pressed.connect(_on_enemy_city_pressed.bind(enemy_btn.name))
		else:
			# 아직 점령하지 않은 땅
			enemy_btn.pressed.connect(_on_enemy_city_pressed.bind(enemy_btn.name))

	# 5. 💡 월드맵 진입 시 침공 이벤트(백제/신라/고구려)가 있는지 체크!
	check_invasion_events()
	check_ending_event()
	

# 💡 [새로 추가] 침공 이벤트 체크 함수
func check_invasion_events():
	var conquered_gaya = Global.unlocked_territories.size() - 1 # 대가야(수도)를 제외한 점령 국가 수
	
	# 1. 가야 2곳 점령 시 -> 백제 침공
	if conquered_gaya >= 2 and not Global.is_baekje_defeated:
		trigger_invasion("Baekje_Invasion", "백제")
	# 2. 가야 4곳 점령 시 -> 신라 침공 
	elif conquered_gaya >= 4 and not Global.is_silla_defeated:
		trigger_invasion("Silla_Invasion", "신라")
	# 3. 가야 5곳(전부) 점령 시 -> 고구려 대군 침공
	elif conquered_gaya >= 5 and not Global.is_goguryeo_defeated:
		trigger_invasion("Goguryeo_Invasion", "고구려") 

func trigger_invasion(event_id: String, country_name: String):
	pending_invasion_target = event_id # 쳐들어온 국가 기억
	
	# 침공 국가에 따라 비장한 경고 메시지 띄우기
	if event_id == "Baekje_Invasion":
		invasion_label.text = "🚨 [긴급 상황]\n국경에 백제 강군이 집결했습니다!\n군대를 소집하여 방어전을 준비하십시오!"
	elif event_id == "Silla_Invasion":
		invasion_label.text = "🚨 [긴급 상황]\n신라 정예군이 영토를 침범했습니다!\n전군을 출격시켜 막아내십시오!"
	elif event_id == "Goguryeo_Invasion":
		invasion_label.text = "🔥 [국가 비상사태] 🔥\n고구려 개마무사 대군이 남하하고 있습니다!!\n가야 연맹의 명운을 건 총력전입니다!"
	
	invasion_panel.visible = true # 경고창 띄우기!
	# 경고창의 "전투 돌입" 버튼을 눌렀을 때 실행되는 함수
func _on_invasion_button_pressed():
	Global.current_target_city = pending_invasion_target
	get_tree().change_scene_to_file("res://main_battle.tscn")

func update_resource_ui():
	if gold_label: gold_label.text = "🪙 금: " + str(Global.total_gold)
	if wood_label: wood_label.text = "🪵 목재: " + str(Global.total_wood)
	if food_label: food_label.text = "🌾 식량: " + str(Global.total_food)
	if iron_label: iron_label.text = "⛏️ 철: " + str(Global.total_iron)

func open_city_panel(city_name: String):
	city_panel.visible = true
	
	# 1. 모든 버튼 숨기기
	farm_button.visible = false
	lumber_button.visible = false
	mine_button.visible = false
	geumgwan_button.visible = false
	sogaya_button.visible = false
	aragaya_button.visible = false
	goryeong_button.visible = false
	seongsan_button.visible = false
	warrior_up_btn.visible = false
	lancer_up_btn.visible = false
	archer_up_btn.visible = false
	gen_stat_btn.visible = false
	gen_q_btn.visible = false
	gen_w_btn.visible = false
	gen_e_btn.visible = false
	gen_r_btn.visible = false
	reset_military_btn.visible = false
	
	
	# 2. 선택한 도시의 버튼만 켜기
	if city_name == "DaegayaButton":
		farm_button.visible = true
		lumber_button.visible = true
		mine_button.visible = true
		warrior_up_btn.visible = true
		lancer_up_btn.visible = true
		archer_up_btn.visible = true
		gen_stat_btn.visible = true
		gen_q_btn.visible = true
		gen_w_btn.visible = true
		gen_e_btn.visible = true
		gen_r_btn.visible = true
		reset_military_btn.visible = true
	elif city_name == "GeumgwanGayaButton": geumgwan_button.visible = true
	elif city_name == "SoGayaButton": sogaya_button.visible = true
	elif city_name == "AraGayaButton": aragaya_button.visible = true
	elif city_name == "GoryeongGayaButton": goryeong_button.visible = true
	elif city_name == "SeongsanGayaButton": seongsan_button.visible = true
		
	update_building_ui()

func update_building_ui():
	# [만렙 제한 5] 기본 건물
	if Global.farm_level >= 5: farm_button.text = "🌾 농장 Lv.MAX (최대 레벨)"
	else: farm_button.text = "🌾 농장 Lv." + str(Global.farm_level) + " (비용: 목재 " + str(Global.farm_level * 50) + " / 금 " + str(Global.farm_level * 100) + ")"
	
	if Global.lumber_level >= 5: lumber_button.text = "🪵 제재소 Lv.MAX (최대 레벨)"
	else: lumber_button.text = "🪵 제재소 Lv." + str(Global.lumber_level) + " (비용: 목재 " + str(Global.lumber_level * 50) + " / 금 " + str(Global.lumber_level * 150) + ")"
	
	if Global.mine_level >= 5: mine_button.text = "⛏️ 철광산 Lv.MAX (최대 레벨)"
	else: mine_button.text = "⛏️ 철광산 Lv." + str(Global.mine_level) + " (비용: 목재 " + str(Global.mine_level * 100) + " / 금 " + str(Global.mine_level * 200) + ")"
	
	# [만렙 제한 3] 특산물 건물
	if Global.geumgwan_trade_level >= 3: geumgwan_button.text = "🚢 해상 무역소 Lv.MAX (최대 레벨)"
	else: geumgwan_button.text = "🚢 해상 무역소 Lv." + str(Global.geumgwan_trade_level) + " (비용: 목재 " + str(100 + Global.geumgwan_trade_level * 100) + " / 금 " + str(200 + Global.geumgwan_trade_level * 100) + ")"
	
	if Global.sogaya_fish_level >= 3: sogaya_button.text = "🐟 해산물 시장 Lv.MAX (최대 레벨)"
	else: sogaya_button.text = "🐟 해산물 시장 Lv." + str(Global.sogaya_fish_level) + " (비용: 목재 " + str(100 + Global.sogaya_fish_level * 50) + " / 금 " + str(150 + Global.sogaya_fish_level * 50) + ")"
	
	if Global.aragaya_forge_level >= 3: aragaya_button.text = "🛡️ 철갑 무기고 Lv.MAX (최대 레벨)"
	else: aragaya_button.text = "🛡️ 철갑 무기고 Lv." + str(Global.aragaya_forge_level) + " (비용: 목재 " + str(150 + Global.aragaya_forge_level * 50) + " / 금 " + str(150 + Global.aragaya_forge_level * 50) + ")"
	
	if Global.goryeong_silk_level >= 3: goryeong_button.text = "🪵 대규모 벌목장 Lv.MAX (최대 레벨)"
	else: goryeong_button.text = "🪵 대규모 벌목장 Lv." + str(Global.goryeong_silk_level) + " (비용: 목재 " + str(100 + Global.goryeong_silk_level * 80) + " / 금 " + str(150 + Global.goryeong_silk_level * 50) + ")"
	
	if Global.seongsan_iron_level >= 3: seongsan_button.text = "⚒️ 고급 야철지 Lv.MAX (최대 레벨)"
	else: seongsan_button.text = "⚒️ 고급 야철지 Lv." + str(Global.seongsan_iron_level) + " (비용: 목재 " + str(200 + Global.seongsan_iron_level * 100) + " / 금 " + str(300 + Global.seongsan_iron_level * 100) + ")"

	# [만렙 제한 5] 병사 강화
	if Global.warrior_level >= 5: warrior_up_btn.text = "⚔️ 보병 강화 Lv.MAX (최대 레벨)"
	else: warrior_up_btn.text = "⚔️ 보병 강화 Lv." + str(Global.warrior_level) + " (비용: 식량 " + str(Global.warrior_level * 50) + " / 철 " + str(Global.warrior_level * 50) + " / 금 " + str(Global.warrior_level * 50) + ")"
	
	if Global.lancer_level >= 5: lancer_up_btn.text = "🔱 창병 강화 Lv.MAX (최대 레벨)"
	else: lancer_up_btn.text = "🔱 창병 강화 Lv." + str(Global.lancer_level) + " (비용: 식량 " + str(Global.lancer_level * 70) + " / 철 " + str(Global.lancer_level * 70) + " / 금 " + str(Global.lancer_level * 70) + ")"
	
	if Global.archer_level >= 5: archer_up_btn.text = "🏹 궁병 강화 Lv.MAX (최대 레벨)"
	else: archer_up_btn.text = "🏹 궁병 강화 Lv." + str(Global.archer_level) + " (비용: 식량 " + str(Global.archer_level * 80) + " / 철 " + str(Global.archer_level * 80) + " / 금 " + str(Global.archer_level * 80) + ")"

	# [만렙 제한 5] 장군 훈련소 UI 갱신 (비용이 아주 비쌉니다!)
	if Global.gen_stat_level >= 5: gen_stat_btn.text = "👑 장군 기본 훈련 Lv.MAX"
	else: gen_stat_btn.text = "👑 장군 기본 훈련 Lv." + str(Global.gen_stat_level) + " (금 " + str(Global.gen_stat_level * 200) + ")"
	
	if Global.gen_q_level >= 5: gen_q_btn.text = "📣 함성(Q) 수련 Lv.MAX"
	else: gen_q_btn.text = "📣 함성(Q) 수련 Lv." + str(Global.gen_q_level) + " (금 " + str(Global.gen_q_level * 150) + ")"
	
	if Global.gen_w_level >= 5: gen_w_btn.text = "🛡️ 가시갑옷(W) 수련 Lv.MAX"
	else: gen_w_btn.text = "🛡️ 가시갑옷(W) 수련 Lv." + str(Global.gen_w_level) + " (금 " + str(Global.gen_w_level * 150) + ")"
	
	if Global.gen_e_level >= 5: gen_e_btn.text = "🐎 돌진(E) 수련 Lv.MAX"
	else: gen_e_btn.text = "🐎 돌진(E) 수련 Lv." + str(Global.gen_e_level) + " (금 " + str(Global.gen_e_level * 150) + ")"
	
	if Global.gen_r_level >= 5: gen_r_btn.text = "🏹 화살비(R) 수련 Lv.MAX"
	else: gen_r_btn.text = "🏹 화살비(R) 수련 Lv." + str(Global.gen_r_level) + " (금 " + str(Global.gen_r_level * 500) + ")"

# --- [상호작용 함수들] ---

func _on_daegaya_button_pressed() -> void: open_city_panel("DaegayaButton")
func _on_close_button_pressed() -> void: if city_panel: city_panel.visible = false

func _on_enemy_city_pressed(city_name: String):
	if Global.unlocked_territories.has(city_name):
		open_city_panel(city_name)
	else:
		Global.current_target_city = city_name
		get_tree().change_scene_to_file("res://main_battle.tscn")

# --- [자동 자원 타이머] ---
func _on_resource_timer_timeout() -> void:
	var food_yield = Global.farm_level * 10
	var wood_yield = Global.lumber_level * 10
	var iron_yield = Global.mine_level * 5
	
	if Global.geumgwan_trade_level > 0: 
		wood_yield += Global.geumgwan_trade_level * 30
		iron_yield += Global.geumgwan_trade_level * 10
		
	if Global.sogaya_fish_level > 0: food_yield += Global.sogaya_fish_level * 40             
	if Global.goryeong_silk_level > 0: wood_yield += Global.goryeong_silk_level * 50
	if Global.seongsan_iron_level > 0: iron_yield += Global.seongsan_iron_level * 15         
		
	Global.total_food += food_yield
	Global.total_wood += wood_yield
	Global.total_iron += iron_yield
	# 골드는 이제 전투 보상으로만 얻습니다.
	
	update_resource_ui()

# --- [기본 건물 업그레이드 로직] ---

func _on_farm_button_pressed() -> void:
	var wood_cost = Global.farm_level * 50
	var gold_cost = Global.farm_level * 100
	
	if Global.farm_level >= 5:
		print("창고에 곡식이 산처럼 쌓여, 더 이상 개간할 영지가 없습니다.")
		return 
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.farm_level += 1
		update_resource_ui()
		update_building_ui()

func _on_lumber_button_pressed() -> void:
	var wood_cost = Global.lumber_level * 50
	var gold_cost = Global.lumber_level * 150
	
	if Global.lumber_level >= 5:
		print("가야의 모든 산맥에서 최고급 목재가 쉴 새 없이 쏟아져 들어오고 있습니다!")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.lumber_level += 1
		update_resource_ui()
		update_building_ui()

func _on_mine_button_pressed() -> void:
	var wood_cost = Global.mine_level * 100
	var gold_cost = Global.mine_level * 200
	
	if Global.mine_level >= 5:
		print("용광로의 불꽃이 밤낮으로 꺼지지 않습니다! 대륙 최고의 철 생산량을 달성했습니다.")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.mine_level += 1
		update_resource_ui()
		update_building_ui()

# --- [특산물 건물 업그레이드 로직] ---

func _on_geumgwan_trade_button_pressed() -> void:
	var wood_cost = 100 + (Global.geumgwan_trade_level * 100) 
	var gold_cost = 200 + (Global.geumgwan_trade_level * 100)
	
	if Global.geumgwan_trade_level >= 3:
		print("해동 제일의 무역항이 완성되었습니다. 천하의 부가 이곳으로 모여듭니다!")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.geumgwan_trade_level += 1
		
		# 레벨이 오를수록 들어오는 한탕 수익도 커집니다. 
		var trade_bonus_gold = 500 + (Global.geumgwan_trade_level * 500)
		Global.total_gold += trade_bonus_gold
		
		print("🚢 금관가야 해상 무역소 레벨 업! 무역 수익으로 금 " + str(trade_bonus_gold) + "을(를) 벌어왔습니다!")
		
		update_resource_ui()
		update_building_ui()

func _on_sogaya_fish_button_pressed() -> void:
	var wood_cost = 100 + (Global.sogaya_fish_level * 50) 
	var gold_cost = 150 + (Global.sogaya_fish_level * 50)
	
	if Global.sogaya_fish_level >= 3:
		print("매일 아침 끝없는 바다의 축복이 쏟아집니다! 포구로 돌아오는 모든 어선이 항시 만선을 이룹니다")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.sogaya_fish_level += 1
		update_resource_ui()
		update_building_ui()

func _on_aragaya_forge_button_pressed() -> void:
	var wood_cost = 150 + (Global.aragaya_forge_level * 50)
	var gold_cost = 150 + (Global.aragaya_forge_level * 50)
	
	if Global.aragaya_forge_level >= 3:
		print("천하에 이보다 단단하고 정교한 철갑을 벼려낼 장인은 없습니다!")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.aragaya_forge_level += 1
		update_resource_ui()
		update_building_ui()

func _on_goryeong_silk_button_pressed() -> void:
	var wood_cost = 100 + (Global.goryeong_silk_level * 80) 
	var gold_cost = 150 + (Global.goryeong_silk_level * 50)
	
	if Global.goryeong_silk_level >= 3:
		print("천년의 숲을 아우르는 거대한 대규모 벌목장이 마침내 완성되었습니다! 수천 명의 벌목꾼과 수레가 산맥을 뒤덮으며 목재 생산의 정점에 도달했습니다")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.goryeong_silk_level += 1
		update_resource_ui()
		update_building_ui()

func _on_seongsan_iron_button_pressed() -> void:
	var wood_cost = 200 + (Global.seongsan_iron_level * 100) 
	var gold_cost = 300 + (Global.seongsan_iron_level * 100)
	
	if Global.seongsan_iron_level >= 3:
		print("철산의 깊은 맥까지 닿았습니다. 이보다 더 거대한 광산은 없습니다!")
		return
	
	if Global.total_wood >= wood_cost and Global.total_gold >= gold_cost:
		Global.total_wood -= wood_cost
		Global.total_gold -= gold_cost
		Global.seongsan_iron_level += 1
		update_resource_ui()
		update_building_ui()


# --- [병사 강화 업그레이드 로직 (식량, 철, 금 소모)] ---

func _on_warrior_upgrade_button_pressed() -> void:
	var food_cost = Global.warrior_level * 50
	var iron_cost = Global.warrior_level * 50
	var gold_cost = Global.warrior_level * 50
	
	if Global.warrior_level >= 5:
		print("보병은 이미 최고 수준으로 훈련되었습니다!")
		return
	
	if Global.total_food >= food_cost and Global.total_iron >= iron_cost and Global.total_gold >= gold_cost:
		Global.total_food -= food_cost
		Global.total_iron -= iron_cost
		Global.total_gold -= gold_cost
		Global.warrior_level += 1
		update_resource_ui()
		update_building_ui()
	else:
		print("보병을 강화하기엔 자원(식량/철/금)이 부족합니다!")

func _on_lancer_upgrade_button_pressed() -> void:
	var food_cost = Global.lancer_level * 70
	var iron_cost = Global.lancer_level * 70
	var gold_cost = Global.lancer_level * 70
	
	if Global.lancer_level >= 5:
		print("창병은 이미 최고 수준으로 훈련되었습니다")
		return
	
	if Global.total_food >= food_cost and Global.total_iron >= iron_cost and Global.total_gold >= gold_cost:
		Global.total_food -= food_cost
		Global.total_iron -= iron_cost
		Global.total_gold -= gold_cost
		Global.lancer_level += 1
		update_resource_ui()
		update_building_ui()
	else:
		print("창병을 강화하기엔 자원(식량/철/금)이 부족합니다!")

func _on_archer_upgrade_button_pressed() -> void:
	var food_cost = Global.archer_level * 80
	var iron_cost = Global.archer_level * 80
	var gold_cost = Global.archer_level * 80
	
	if Global.archer_level >= 5:
		print("궁병은 이미 최고 수준으로 훈련되었습니다!")
		return
	
	if Global.total_food >= food_cost and Global.total_iron >= iron_cost and Global.total_gold >= gold_cost:
		Global.total_food -= food_cost
		Global.total_iron -= iron_cost
		Global.total_gold -= gold_cost
		Global.archer_level += 1
		update_resource_ui()
		update_building_ui()
	else:
		print("궁병을 강화하기엔 자원(식량/철/금)이 부족합니다!")
		


func _on_gen_stat_button_pressed() -> void:
	var cost = Global.gen_stat_level * 200
	if Global.gen_stat_level >= 5: return
	if Global.total_gold >= cost:
		Global.total_gold -= cost
		Global.gen_stat_level += 1
		update_resource_ui()
		update_building_ui()


func _on_gen_q_button_pressed() -> void:
	var cost = Global.gen_q_level * 150
	if Global.gen_q_level >= 5: return
	if Global.total_gold >= cost:
		Global.total_gold -= cost
		Global.gen_q_level += 1
		update_resource_ui()
		update_building_ui()


func _on_gen_w_button_pressed() -> void:
	var cost = Global.gen_w_level * 150
	if Global.gen_w_level >= 5: return
	if Global.total_gold >= cost:
		Global.total_gold -= cost
		Global.gen_w_level += 1
		update_resource_ui()
		update_building_ui()


func _on_gen_e_button_pressed() -> void:
	var cost = Global.gen_e_level * 150
	if Global.gen_e_level >= 5: return
	if Global.total_gold >= cost:
		Global.total_gold -= cost
		Global.gen_e_level += 1
		update_resource_ui()
		update_building_ui()


func _on_gen_r_button_pressed() -> void:
	var cost = Global.gen_r_level * 500
	if Global.gen_r_level >= 5: return
	if Global.total_gold >= cost:
		Global.total_gold -= cost
		Global.gen_r_level += 1
		update_resource_ui()
		update_building_ui()


func _on_reset_military_button_pressed():
	var spent_gold = 0
	var spent_food = 0
	var spent_iron = 0
	
	# 1. 장군 스킬에 소모된 골드 누적 계산 (for문 활용)
	for i in range(1, Global.gen_stat_level): spent_gold += i * 200
	for i in range(1, Global.gen_q_level): spent_gold += i * 150
	for i in range(1, Global.gen_w_level): spent_gold += i * 150
	for i in range(1, Global.gen_e_level): spent_gold += i * 150
	for i in range(1, Global.gen_r_level): spent_gold += i * 500
	
	# 2. 병사 강화에 소모된 자원(금, 식량, 철) 누적 계산
	for i in range(1, Global.warrior_level):
		spent_gold += i * 50
		spent_food += i * 50
		spent_iron += i * 50
		
	for i in range(1, Global.lancer_level):
		spent_gold += i * 70
		spent_food += i * 70
		spent_iron += i * 70
		
	for i in range(1, Global.archer_level):
		spent_gold += i * 80
		spent_food += i * 80
		spent_iron += i * 80
		
	# 아무것도 업그레이드 안 한 상태(모두 1레벨)라면 함수 조기 종료
	if spent_gold == 0 and spent_food == 0 and spent_iron == 0:
		print("초기화할 군사 업그레이드가 없습니다!")
		return
		
	# 3. 누적된 총비용의 80%를 계산하여 현재 자원에 환불 (소수점은 버림)
	Global.total_gold += int(spent_gold * 0.8)
	Global.total_food += int(spent_food * 0.8)
	Global.total_iron += int(spent_iron * 0.8)
	
	# 4. 모든 군사 및 장군 레벨을 초기 상태(1)로 되돌림
	Global.gen_stat_level = 1
	Global.gen_q_level = 1
	Global.gen_w_level = 1
	Global.gen_e_level = 1
	Global.gen_r_level = 1
	Global.warrior_level = 1
	Global.lancer_level = 1
	Global.archer_level = 1
	
	# 5. UI 및 자원 표기 새로고침
	update_resource_ui()
	update_building_ui()
	
	print("🔄 군사 특성 초기화 완료! 80% 환불 적용 됨.")
	print("환불 내역 - 골드: ", int(spent_gold * 0.8), " / 식량: ", int(spent_food * 0.8), " / 철: ", int(spent_iron * 0.8))
	
func check_ending_event():
	# 고구려가 격파되었는지 확인 (이 변수는 기존 침공 이벤트 기획에 맞춰져 있습니다)
	if Global.is_goguryeo_defeated == true:
		# 고구려를 꺾었다면 웅장하게 엔딩 팝업 등장!
		ending_panel.visible = true


func _on_ending_close_button_pressed() -> void:
	if ending_panel:
		ending_panel.visible = false
		print("엔딩 이후 계속 플레이 모드로 진입합니다.")
