extends Node

# 삼국 침공 이벤트 클리어 여부
var is_silla_defeated: bool = false
var is_baekje_defeated: bool = false
var is_goguryeo_defeated: bool = false

# 국가 공통 자원
var total_gold: int = 1000   # 총 보유 골드 (처음 시작 자본금)
var total_wood: int = 500    # 목재 
var total_food: int = 500    # 식량 
var total_iron: int = 300

# ⚔️ 병사 업그레이드 레벨
var warrior_level: int = 1
var lancer_level: int = 1
var archer_level: int = 1

# 🗺️ 정복한 영토 목록 (대가야로 시작)
var unlocked_territories: Array = ["대가야"]
var current_target_city: String = ""

var farm_level: int = 1     # 식량 생산
var lumber_level: int = 1   # 목재 생산
var mine_level: int = 1     # 철 생산
var geumgwan_trade_level: int = 0  # 금관가야: 해상 무역소
var sogaya_fish_level: int = 0     # 소가야: 해산물 시장
var goryeong_silk_level: int = 0   # 고령가야: 대규모 벌목장
var seongsan_iron_level: int = 0   # 성산가야: 고급 야철지
var aragaya_forge_level: int = 0   # 아라가야: 철갑 무기고 (전투력 버프)

# 👑 장군(플레이어) 업그레이드 레벨 (최대 5레벨)
var gen_stat_level: int = 1  # 기본 스탯 (체력/공격력)
var gen_q_level: int = 1     # Q 스킬 (오라 반경/시간)
var gen_w_level: int = 1     # W 스킬 (피해 반사율)
var gen_e_level: int = 1     # E 스킬 (돌진 넉백/데미지)
var gen_r_level: int = 1     # R 스킬 (화살 개수/데미지)
