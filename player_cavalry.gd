extends "res://base_unit.gd" 

var is_aura_active: bool = false
var time_passed: float = 0.0
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_duration: float = 0.2   # 돌진이 유지되는 시간 (0.2초)
var dash_speed: float = 1500.0   # 번개 같은 돌진 속도!
var facing_dir: int = 1          # 현재 바라보는 방향 (1:우, -1:좌)
var e_skill_cooldown: float = 0.0 # E 스킬 쿨타임
var dashed_enemies: Array = []   # 한 번의 돌진에서 이미 때린 적을 기억하는 명부



func _physics_process(delta):
	# 1. 쿨타임 계산 및 Q 스킬 장판 애니메이션 처리
	if e_skill_cooldown > 0:
		e_skill_cooldown -= delta
	if is_aura_active:
		time_passed += delta
		queue_redraw()
	if is_thorn_buffed:
		queue_redraw()

	if current_hp <= 0:
		return
	
	# 🚀 2. [돌진 중일 때의 특수 이동 로직]
	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_speed * facing_dir # 엄청난 속도로 강제 이동!
		create_dash_trail()
		
		# 돌진하면서 길을 막는 적들을 감지해서 날려버립니다.
		for node in get_tree().current_scene.get_children():
			# 적군이고, 아직 이번 돌진에서 안 맞은 녀석이라면
			if "is_ally" in node and node.is_ally == false and node not in dashed_enemies:
				# 장군과 적 사이의 거리가 150 이내로 부딪혔다면!
				if global_position.distance_to(node.global_position) < 150:
					dashed_enemies.append(node) 
					
					# 💡 E 스킬 레벨에 따른 넉백/데미지/기절 시간 강화!
					var e_damage = 100 + ((Global.gen_e_level - 1) * 100)       # 100 ~ 500 데미지
					var e_knockback = 250 + ((Global.gen_e_level - 1) * 50)     # 250 ~ 450 밀치기
					var e_stun = 0.3 + ((Global.gen_e_level - 1) * 0.15)        # 0.3초 ~ 0.9초 기절
					
					if node.has_method("take_knockback"):
						# 3번째 파라미터로 스턴 시간(e_stun)을 추가로 넘겨줍니다!
						node.take_knockback(facing_dir * e_knockback, e_damage, e_stun)
		
		move_and_slide()
		
		# 돌진 시간이 끝나면 멈춤
		if dash_time_left <= 0:
			is_dashing = false
			set_collision_mask_value(3, true)
		return # 돌진 중에는 일반 키보드 조작을 무시하고 아래 코드를 실행하지 않음!


	# 3. 공격 애니메이션 재생 중엔 조작 불가
	if anim_player.current_animation == "Attack":
		return

	# 🚀 4. [E 스킬 발동 버튼]
	if Input.is_action_just_pressed("skill_e") and e_skill_cooldown <= 0:
		is_dashing = true
		dash_time_left = dash_duration
		e_skill_cooldown = 8.0  # 쿨타임 8초로 설정
		dashed_enemies.clear()  # 때린 적 명부 초기화
		anim_player.play("Run") # 돌진하는 동안 뛸 수 있게
		set_collision_mask_value(3, false)
		print("🐎 장군 기마 돌진 발동!")
		return # 발동 프레임 종료

	# 5. [기존 일반 이동 로직]
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		facing_dir = input_dir # 마지막으로 바라본 방향 저장 (돌진할 때 쓰임)
		velocity.x = input_dir * speed
		anim_player.play("Run")
		main_sprite.flip_h = (input_dir < 0)
		if raycast:
			raycast.target_position.x = abs(raycast.target_position.x) * input_dir
	else:
		velocity.x = 0
		anim_player.play("Idle") 

	if Input.is_action_just_pressed("ui_accept"):
		anim_player.play("Attack")
		velocity.x = 0

	move_and_slide()
	
func die():
	is_dead = true 
	print(name, " (플레이어 기마병) 유닛이 쓰러집니다... 게임 오버!")
	velocity = Vector2.ZERO
	
	# 시체 충돌 무시
	for i in range(1, 4):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
		
	# 데스 전용 스프라이트로 교체 후 애니메이션 재생
	if main_sprite: main_sprite.visible = false
	if death_sprite: death_sprite.visible = true
	
	if anim_player and anim_player.has_animation("Death"):
		anim_player.play("Death")
		
	# 플레이어가 죽었으므로 메인 씬의 game_over 함수를 호출합니다!
	# 아군 기지가 부서진 것과 동일하게 패배 처리하기 위해 true를 넘겨줍니다.
	if get_tree().current_scene.has_method("game_over"):
		get_tree().current_scene.game_over(true)
		
	# 애니메이션이 끝나는 것을 기다린 후 삭제
	if anim_player and anim_player.has_animation("Death"):
		await anim_player.animation_finished
		
	queue_free()
	
func turn_on_aura():
	is_aura_active = true
	queue_redraw() # 화면에 다시 그리도록(업데이트) 엔진에 요청

func turn_off_aura():
	is_aura_active = false
	queue_redraw()


# 고도 엔진이 화면을 그릴 때 자동으로 실행되는 내장 함수입니다.
func _draw():
	
	# 💡 1. [W 스킬] 장군의 중심에서 사방으로 뻗어나가는 360도 원형 파동
	if is_thorn_buffed:
		# 바닥이 아니라 장군(말)의 몸통 한가운데로 중심점을 올립니다 (-50)
		var center_pos = Vector2(100, -100) 
		var max_radius = 220.0 
		var wave_speed = 300.0 
		
		var current_time = Time.get_ticks_msec() * 0.001
		
		for i in range(3):
			var current_radius = fmod(current_time * wave_speed + (i * (max_radius / 3.0)), max_radius)
			var alpha = 1.0 - (current_radius / max_radius)
			var wave_color = Color(1.0, 0.2, 0.2, alpha * 0.9) 
			
			# 💡 시작 각도 0, 끝 각도 TAU로 설정하여 완벽한 원을 그립니다!
			# 원이 크므로 선명하게 보이도록 조각 수(128)를 늘려줍니다.
			draw_arc(center_pos, current_radius, 0, TAU, 128, wave_color, 5.0, true)
	
	if is_aura_active:
		# 1. 💡 장군 스프라이트 위치에 맞게 중심점 이동 (오른쪽으로 100, 위로 살짝)
		# (스크린샷을 바탕으로 말의 발밑에 딱 맞게 좌표를 수정했습니다!)
		var center_offset = Vector2(100, -20)
		draw_set_transform(center_offset, 0, Vector2(1.0, 0.4))
		
		var max_radius = 500.0 # 버프 최대 반경 (300 반경 / 0.6 스케일)
		var speed = 300.0      # ⚡ 원이 바깥으로 퍼져나가는 속도
		
		# 3개의 물결(원)이 시차를 두고 퍼져나가도록 만듭니다.
		for i in range(3):
			# fmod를 사용해 원이 계속 커지다가 max_radius에 닿으면 다시 0부터 커지게 합니다.
			var current_radius = fmod(time_passed * speed + (i * (max_radius / 3.0)), max_radius)
			
			# 원이 바깥으로 퍼질수록 점점 투명해지도록(자연스럽게 사라지도록) 처리
			var alpha = 1.0 - (current_radius / max_radius)
			var current_color = Color(0.4, 0.8, 1.0, alpha)
			
			# 테두리 그리기
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 128, current_color, 4.0, true)
			
		# 그림 그리기가 끝난 후 변환 초기화
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		

func create_dash_trail():
	var trail = Sprite2D.new()
	trail.texture = main_sprite.texture
	trail.hframes = main_sprite.hframes
	trail.vframes = main_sprite.vframes
	trail.frame = main_sprite.frame
	trail.flip_h = main_sprite.flip_h
	
	# 위치와 크기를 현재 장군의 스프라이트와 완전히 똑같이 맞춥니다.
	trail.global_transform = main_sprite.global_transform
	
	# 💡 핵심! 장군 뒤로 깔리게 만들고(z_index), 그림처럼 영롱한 시안색(Cyan)으로 덮어씌웁니다.
	trail.z_index = -1
	trail.modulate = Color(1.0, 0.9, 0.0, 0.6) # R, G, B, 투명도(60%)
	
	# 게임 화면(메인 씬)에 잔상을 추가합니다.
	get_tree().current_scene.add_child(trail)
	
	# 0.3초 동안 꼬리가 서서히 투명해지다가 공기 중으로 흩어지게(삭제) 만듭니다.
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)
