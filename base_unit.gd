extends CharacterBody2D
class_name BaseUnit

@export var is_ally: bool = true
@export var max_hp: int = 100
@export var damage: int = 15
@export var speed: float = 100.0

var current_hp: int:
	set(value):
		
		if value < current_hp and not is_dead:
			var hit_sound = get_node_or_null("HitSound")
			if hit_sound:
				# 맞을 때마다 소리가 겹치지 않게 약간씩 피치를 다르게 재생
				hit_sound.pitch_scale = randf_range(0.9, 1.1)
				hit_sound.play()
				
		current_hp = value
		if hp_bar:
			hp_bar.value = current_hp
		if current_hp <= 0 and not is_dead: die()
var is_dead: bool = false 
var direction: int = 1
var is_buffed: bool = false
var is_knocked_back: bool = false
var is_thorn_buffed: bool = false

@onready var main_sprite = $Sprite2D
@onready var death_sprite = $DeathSprite2D
@onready var anim_player = $AnimationPlayer
@onready var raycast = $RayCast2D
@onready var hp_bar = get_node_or_null("ProgressBar")

func _ready():
	current_hp = max_hp
	direction = 1 if is_ally else -1
	main_sprite.visible = true
	death_sprite.visible = false
	
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	
	# 물리 레이어 및 마스크 초기화
	for i in range(1, 4):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
		raycast.set_collision_mask_value(i, false)
		
	# 1번 레이어(바닥/벽 등)는 기본으로 부딪히도록 설정
	set_collision_mask_value(1, true)
	
	# 아군/적군에 따른 레이어, 시각화, 방향 자동 세팅
	if is_ally:
		set_collision_layer_value(2, true) 
		set_collision_mask_value(3, true)  
		raycast.set_collision_mask_value(3, true) 
	else:
		set_collision_layer_value(3, true) 
		set_collision_mask_value(2, true)  
		raycast.set_collision_mask_value(2, true) 
		main_sprite.flip_h = true
		death_sprite.flip_h = true 
		raycast.target_position.x *= -1
		main_sprite.modulate = Color(1.0, 0.4, 0.4) # 붉은색으로 변경

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if is_thorn_buffed:
		queue_redraw()
	# 중력 적용 (플랫포머 뷰일 경우)
	if not is_on_floor():
		velocity.y += 980 * delta
	if is_knocked_back:
		move_and_slide()
		return
	if raycast.is_colliding():
		var target = raycast.get_collider()
		# 감지된 대상이 적군일 경우 이동 멈추고 공격
		if target and "is_ally" in target and target.is_ally != self.is_ally:
			velocity.x = 0
			if anim_player.current_animation != "Attack":
				anim_player.play("Attack")
		else:
			move_forward()
	else:
		move_forward()
		
	move_and_slide()

func move_forward():
	velocity.x = speed * direction
	if anim_player.current_animation != "Run":
		anim_player.play("Run")

func melee_attack():
	if raycast.is_colliding():
		$AttackSound.play()
		var target = raycast.get_collider()
		if target and "current_hp" in target and target.is_ally != self.is_ally:
			target.current_hp -= damage
			print(target.name, " 타격! 남은 체력: ", target.current_hp)
			
			# 💡 [가시 갑옷 핵심] 때린 대상이 가시 버프 상태라면, 때린 놈도 피해를 입는다!
			if "is_thorn_buffed" in target and target.is_thorn_buffed:
				# 💡 W 스킬 레벨에 따른 가시 반사율 적용 (50% ~ 최대 110%)
				var reflect_rate = 0.5 + ((Global.gen_w_level - 1) * 0.15)
				var reflected_damage = int(damage * reflect_rate)
				self.current_hp -= reflected_damage      
				print("💥 피해 반사! ", self.name, "가 ", reflected_damage, "의 찔림 데미지를 입었습니다!")

func die():
	is_dead = true 
	print(name, " 유닛이 쓰러집니다...")
	velocity = Vector2.ZERO
	
	# 시체 충돌 무시
	for i in range(1, 4):
		set_collision_layer_value(i, false)
		set_collision_mask_value(i, false)
		
	var death_sound = get_node_or_null("DeathSound")
	if death_sound:
		death_sound.play()
	# 데스 전용 스프라이트로 교체 후 애니메이션 재생
	main_sprite.visible = false
	death_sprite.visible = true
	anim_player.play("Death")
	await anim_player.animation_finished
	queue_free()
	
# 장군의 버프 스킬을 받았을 때 실행되는 함수
func receive_buff():
	# 이미 버프를 받았다면, 아래 코드를 무시하고 함수를 종료합니다!
	if is_buffed == true:
		return 
	is_buffed = true 
	# 1. 공격력이 기존보다 1.5배 강해집니다.
	damage = int(damage * 1.5)
	# 2. 몸 색깔을 영롱한 푸른빛으로 물들입니다.
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.4, 0.6, 1.0)
		
# 기마병의 돌진에 맞았을 때 뒤로 밀려나는(넉백) 함수
# 💡 파라미터에 stun_time: float = 0.3 추가
func take_knockback(push_distance: float, dash_damage: int, stun_time: float = 0.3):
	if is_dead: return 
	
	current_hp -= dash_damage
	is_knocked_back = true 
	
	velocity.y = -300 
	velocity.x = push_distance / 0.2
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)

	var tween = create_tween()
	# 💡 고정 0.3초였던 기절 시간을 업그레이드 된 stun_time으로 교체!
	tween.tween_interval(stun_time)
	tween.tween_callback(func():
		if is_instance_valid(self) and not is_dead:
			is_knocked_back = false
			if is_ally: set_collision_mask_value(3, true)
			else: set_collision_mask_value(2, true)
	)
	
func receive_thorn_buff():
	if is_thorn_buffed or is_dead: return
	
	is_thorn_buffed = true
	queue_redraw() # 💡 엔진에게 "나한테 쉴드 좀 그려줘!" 라고 요청합니다.
		
	# 5초 뒤에 자동으로 가시 쉴드 해제
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			is_thorn_buffed = false
			queue_redraw() # 쉴드 지우기 요청
	)

func _draw():
	if is_thorn_buffed:
		# 💡 병사의 가슴팍 위치로 중심점 설정
		var center_pos = Vector2(0, -20) 
		var max_radius = 70.0          # 파동이 도달할 최대 크기
		var wave_speed = 120.0         # 파동 속도 (장군보다는 약간 느리게)
		
		# 게임 실행 시간을 초 단위로 가져옵니다
		var current_time = Time.get_ticks_msec() * 0.001 
		
		# 병사들은 크기가 작으니 2개의 파동만 겹치게 그립니다
		for i in range(2):
			# 시간에 따라 0부터 max_radius까지 계속 커지는 반지름 계산
			var current_radius = fmod(current_time * wave_speed + (i * (max_radius / 2.0)), max_radius)
			
			# 파동이 커질수록 끝에서 투명해지도록 (알파 값 감소)
			var alpha = 1.0 - (current_radius / max_radius)
			var wave_color = Color(1.0, 0.2, 0.2, alpha * 0.8) # 붉은색 에너지
			
			# 💡 시작 각도 0, 끝 각도 TAU로 완벽한 360도 원형 파동 그리기
			draw_arc(center_pos, current_radius, 0, TAU, 32, wave_color, 3.0, true)
	
