extends "res://base_unit.gd" 

@onready var run_sound = $RunSound
@onready var skill_sound = $SkillSound # 💡 스킬 전용 효과음 노드 연결!

var is_aura_active: bool = false
var time_passed: float = 0.0
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_duration: float = 0.2   # 돌진이 유지되는 시간 (0.2초)
var dash_speed: float = 1500.0   # 번개 같은 돌진 속도!
var facing_dir: int = 1          # 현재 바라보는 방향 (1:우, -1:좌)
var e_skill_cooldown: float = 0.0 # E 스킬 쿨타임
var dashed_enemies: Array = []   # 한 번의 돌진에서 이미 때린 적을 기억하는 명부

func _ready():
	# 부모(BaseUnit)의 _ready() 함수를 먼저 실행 (체력 세팅, 피아식별 세팅)
	super._ready() 
	
	# 내 전용 말발굽 소리 세팅 (무한 반복 설정만 하고 시작하자마자 재생하진 않음!)
	if run_sound and run_sound.stream:
		run_sound.stream.loop = true 


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
					
					# E 스킬 레벨에 따른 넉백/데미지/기절 시간 강화!
					var e_damage = 100 + ((Global.gen_e_level - 1) * 100)       # 100 ~ 500 데미지
					var e_knockback = 250 + ((Global.gen_e_level - 1) * 50)     # 250 ~ 450 밀치기
					var e_stun = 0.3 + ((Global.gen_e_level - 1) * 0.15)        # 0.3초 ~ 0.9초 기절
					
					if node.has_method("take_knockback"):
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
		
		# 💡 [추가] E 스킬 (기마 돌진) 효과음 재생!
		if skill_sound:
			skill_sound.stream = preload("res://BGM/skill_E.mp3")
			skill_sound.play()
			
		print("🐎 장군 기마 돌진 발동!")
		return # 발동 프레임 종료

	# 5. [기존 일반 이동 로직 + 사운드 제어]
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		facing_dir = input_dir # 마지막으로 바라본 방향 저장 (돌진할 때 쓰임)
		velocity.x = input_dir * speed
		anim_player.play("Run")
		
		# 움직일 때 말발굽 소리가 꺼져있다면 켭니다!
		if run_sound and not run_sound.playing:
			run_sound.play()
			
		main_sprite.flip_h = (input_dir < 0)
		if raycast:
			raycast.target_position.x = abs(raycast.target_position.x) * input_dir
	else:
		velocity.x = 0
		anim_player.play("Idle") 
		
		# 멈춰 있을 때 말발굽 소리가 나고 있다면 끕니다!
		if run_sound and run_sound.playing:
			run_sound.stop()

	if Input.is_action_just_pressed("ui_accept"):
		anim_player.play("Attack")
		velocity.x = 0
		
		# 공격하느라 멈췄을 때도 말발굽 소리를 끕니다!
		if run_sound and run_sound.playing:
			run_sound.stop()

	move_and_slide()
	
func die():
	is_dead = true 
	
	# 1. 말발굽 소리 강제 종료
	if run_sound and run_sound.playing:
		run_sound.stop()
		
	print(name, " (플레이어 기마병) 유닛이 쓰러집니다... 게임 오버!")
	velocity = Vector2.ZERO
	
	# 시체 충돌 무시
	for i in range(1, 4):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
		
	# 데스 스프라이트로 교체 (안 보일 수도 있지만 일단 처리)
	if main_sprite: main_sprite.visible = false
	if death_sprite: death_sprite.visible = true
	
	# 비명 소리를 틀자마자 애니메이션을 기다리지 않고 넘어갑니다!
	var death_sound = get_node_or_null("DeathSound")
	if death_sound:
		death_sound.play(0.7)
		
	if anim_player and anim_player.has_animation("Death"):
		anim_player.play("Death") # 실행만 시켜둠
		
	#기다리지 않고 곧바로 메인 씬의 game_over를 불러 패배 창을 띄웁니다!
	if get_tree().current_scene.has_method("game_over"):
		get_tree().current_scene.game_over(true, true)
		

	if death_sound:
		await death_sound.finished
		
	queue_free()
	
# 💡 [추가] Q 스킬 (오라 버프) 효과음 재생!
func turn_on_aura():
	is_aura_active = true
	
	if skill_sound:
		skill_sound.stream = preload("res://BGM/Skill_Q.mp3")
		skill_sound.play()
		
	queue_redraw() # 화면에 다시 그리도록(업데이트) 엔진에 요청

func turn_off_aura():
	is_aura_active = false
	queue_redraw()

# 💡 [추가] W 스킬 (가시 갑옷) 효과음 재생! (부모의 함수를 가져와 소리만 얹음)
func receive_thorn_buff():
	super.receive_thorn_buff() # 부모(base_unit.gd)에 작성된 가시 갑옷 효과 발동
	
	if skill_sound:
		skill_sound.stream = preload("res://BGM/Skill_W.mp3")
		skill_sound.play()

# 고도 엔진이 화면을 그릴 때 자동으로 실행되는 내장 함수입니다.
func _draw():
	
	# 1. [W 스킬] 장군의 중심에서 사방으로 뻗어나가는 360도 원형 파동
	if is_thorn_buffed:
		var center_pos = Vector2(100, -100) 
		var max_radius = 220.0 
		var wave_speed = 300.0 
		
		var current_time = Time.get_ticks_msec() * 0.001
		
		for i in range(3):
			var current_radius = fmod(current_time * wave_speed + (i * (max_radius / 3.0)), max_radius)
			var alpha = 1.0 - (current_radius / max_radius)
			var wave_color = Color(1.0, 0.2, 0.2, alpha * 0.9) 
			
			draw_arc(center_pos, current_radius, 0, TAU, 128, wave_color, 5.0, true)
	
	if is_aura_active:
		var center_offset = Vector2(100, -20)
		draw_set_transform(center_offset, 0, Vector2(1.0, 0.4))
		
		var max_radius = 500.0 
		var speed = 300.0      
		
		for i in range(3):
			var current_radius = fmod(time_passed * speed + (i * (max_radius / 3.0)), max_radius)
			var alpha = 1.0 - (current_radius / max_radius)
			var current_color = Color(0.4, 0.8, 1.0, alpha)
			
			draw_arc(Vector2.ZERO, current_radius, 0, TAU, 128, current_color, 4.0, true)
			
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		

func create_dash_trail():
	var trail = Sprite2D.new()
	trail.texture = main_sprite.texture
	trail.hframes = main_sprite.hframes
	trail.vframes = main_sprite.vframes
	trail.frame = main_sprite.frame
	trail.flip_h = main_sprite.flip_h
	
	trail.global_transform = main_sprite.global_transform
	
	trail.z_index = -1
	trail.modulate = Color(1.0, 0.9, 0.0, 0.6) 
	
	get_tree().current_scene.add_child(trail)
	
	var tween = create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)
