# Capsule Sortie — Battlefield Update

Godot 4.7.2 standard / GDScript / WebGL 2.0 Compatibility / single-thread Web export.
실제 무료 SD RX78 모델을 조작해 자쿠 3기를 격파하는 싱글플레이 데모입니다. 비공식 팬 프로젝트이며 원작 게임의 코드·데이터를 사용하지 않습니다.

## 실행 및 조작

배포 주소: https://yum-sy.github.io/sd-capsule-fighter-demo/

- Enter 또는 화면 터치: 시작/재도전
- WASD 이동, Space 점프/길게 공중 부스터, Shift 방향 대시
- 좌클릭/F: 선택 무장 사용, 우클릭/V: 사벨
- R 재장전, Tab 표적 전환·시점 회전, Q/E 무장 전환
- 시작/결과 화면에서 N 또는 MAP 버튼: 전장 전환, H 또는 난이도 버튼: 표준/베테랑
- C 또는 터치 AUTO: 자유 조준 전환. Tab/TARGET은 표적 보조를 다시 켭니다.
- 화면 상단 **마우스 잠금** 버튼: 자유 시점. 지원하지 않으면 화면 드래그
- Esc 일시정지, M 음소거, L 저사양, T 터치 UI 표시
- 터치: 왼쪽 이동, 오른쪽 공격·부스터·대시·재장전·무장·표적 버튼, 나머지 영역 시점 드래그

화면 위에 조작 UI를 겹치며 별도 조작 패널로 게임 화면을 줄이지 않습니다. 가로 화면을 사용하세요. 모바일 브라우저에서 세로 화면이면 가로 회전 안내가 표시됩니다.

## 임무·엄폐물·표현 개선 (2026-11-15)

- Kenney 상자가 75HP의 파괴 가능한 엄폐물이 됩니다. 라이플 3발 또는 사벨 타격으로 파괴하면 충돌이 사라지고 AI 경로를 다시 생성합니다. 같은 상자를 여러 번 점수로 계산하지 않습니다.
- C 키/터치 AUTO로 자유 조준, Tab/TARGET으로 적 표적 보조 복귀. 자유 조준 상태에서 상자를 직접 겨눌 수 있습니다.
- H 키/난이도 버튼: STANDARD(자쿠 180HP) / VETERAN(240HP, 이동 1.18배, 발사 간격 0.8배, 탄속 20). 경고 준비 시간을 단축하지 않아 회피할 시간은 유지합니다.
- 승리 조건은 여전히 자쿠 3기 격파입니다. 보너스는 45초 이내, 잔여 HP 60 이상, 전장별 목표입니다. 화물장은 사벨 마무리 1회, 원형 전장은 엄폐물 2개 파괴가 목표입니다. 적 탄환으로 무너진 엄폐물도 열린 통로로 계산됩니다.
- 결과 점수는 격파·잔여 HP·시간·메달을 반영하고 베테랑은 1.4배입니다. 최고 점수/시간을 전장×난이도 4개 조합별로 분리 저장합니다. 전투 중 선택 목표 진행도를 표시합니다.
- 건담 사격 팔/무장 조준 자세, 공격 손의 회전, 실제 피해 방향 표시, 엄폐물 HP와 격파 알림을 추가했습니다.
- 검증: 기존 70개 + 임무/엄폐물/점수 20개 = 90개 자동 검사, 별도 PWA 검사. 브라우저에서 엄폐 파괴·통로 개방·사벨 보너스·모바일 AUTO 배치, 표준 16.6초/2,054점과 베테랑 13.9초/2,506점 승리 확인. 실제 스마트폰 성능 검사는 아닙니다.

## 공격 동기화·전장·전술 개선 (2026-11-14)

- 사벨은 입력 즉시 피해를 주지 않습니다. 1타 0.12/0.12/0.18초, 2타 0.14/0.14/0.18초, 3타 0.22/0.18/0.30초의 준비/타격/회복 구간을 사용합니다.
- `attack_clock.gd`가 칼날 포즈와 각 프레임 사이의 휩쓸기 판정을 함께 구동합니다. 손잡이 위치·1.6m 칼날·대상 캡슐 반경을 반영하며, 앞뒤/높이/벽/중복 피격을 검사합니다.
- 공격 시작 방향을 유지하므로 준비 중 이탈로 회피할 수 있습니다. 피격/대시로 공격 취소, 회복 중 0.18초 입력 버퍼, 이동 속도 제한을 적용합니다.
- 돌격형: 근접 압박, 0.55초 예고 후 타격/회복. 측면형: 엄폐 우회와 옆·뒤쪽 기동/2연사. 지원형: 고지 유지/주황 조준선/고정된 지점으로 3연사.
- 전장 2종: CARGO YARD(화물 통로·고지), REACTOR RING(중앙 구조물·양쪽 우회로·고지). 확보된 Kenney 소품을 재사용했습니다. AStarGrid 경로는 실제 충돌 풋프린트에 기체 여유 폭을 더해 생성합니다.
- 저장 경로를 `CapsuleSortie`로 고정해 향후 표시 제목 변경이 기록을 초기화하지 않도록 했습니다. 기존 개발판의 임시 저장 경로와는 별도입니다.
- 시작/결과 화면의 **N / MAP** 버튼 또는 N 키로 전장을 전환합니다. 진행 중 전장 변경은 잠그고, 최고 기록을 전장별로 구분합니다.
- Tab/터치 TARGET은 가려지지 않은 화면 밖 표적도 선택하고 시점을 부드럽게 회전합니다. 회전 중 사격은 대기하며 마우스 조작으로 보조 회전을 취소할 수 있습니다.
- 자동 테스트: 기존 44개 + 공격/전술 26개 = 70개, 생성된 PWA 별도 회귀 검사. 30/60/120Hz 및 프레임 건너뛰기 판정, 입력 버퍼, 피격 중단, 사거리 이탈/벽 생성, 두 맵 경로, 뒤쪽 표적 재획득 포함.

## 이전 전투 완성도 개선 (2026-11-14)

- 자쿠: 6개 강체 관절, 보행/조준/반동/피격/쓰러짐. 원본 mesh island를 유지하고 관절·재질별 58개로 병합
- 건담: 부품별 팔레트, 팔/무장 공통 회전축, 사격·재장전·사벨 대기 자세, 부스터 분사/기울기, 착지 반응
- 타격 파편/폭발/피해 숫자, 충격에 따른 제한적인 카메라 흔들림, 대시 FOV, 어깨 너머 카메라
- 자쿠 180HP, 빠른 첫 공격, 예고 후 2연사, 근접 공격(12 피해)과 사거리 밖 회피 가능. 적 배치 분산, 엄폐물 6개
- 레이더, 타겟 거리/공격 예고, 탄약 표시/재장전 진행, 결과 등급. 이전 밸런스 최고 기록과 분리 저장
- 최대 24개 동시 이펙트/자동 제거, 기본 MSAA 2x, 저사양에서는 그림자/안티앨리어싱 비활성화

완성도 개선을 위한 다음 단계는 정교한 자쿠 부품 분류/관절 보정, 스킨 기반 관절/애니메이션 클립, 전장별 미션 구성, 실기기 성능·터치 튜닝입니다. 현재는 절차적 강체 애니메이션이며 상용 게임 수준의 스킨/모션 클립을 갖춘 상태는 아닙니다.

## 구현

- 실제 SD 건담/자쿠 GLB 확보 및 Godot 변환. 플레이어 높이/방향 보정, 자쿠 메쉬 관절·재질별 병합, 자동 LOD
- 건담 분리 부품의 강체 관절 걷기·점프 자세 및 사벨 시각 효과. 스킨 리깅/모션 캡처 애니메이션은 아님
- 3인칭 SpringArm 카메라, 충돌, 이동·점프·부스터·방향 대시, 부스터 소진/재충전
- 시야·거리·가림을 고려한 자동 타겟팅과 수동 전환
- 라이플: 6발, 피해 25, 간격 0.28초, 재장전 1.6초, 빈 탄창 자동 재장전
- 사벨: 3타 콤보 25/30/45, 1.6m 칼날과 손잡이/대상 캡슐을 반영한 휩쓸기 판정, 마지막 타격 넉백
- 자쿠: HP 180, 추적/횡이동/거리 유지/피격 회피, 발사 예고 후 물리 탄환 2연사와 근접 공격
- 플레이어 HP 100, 적 탄환 피해 8, 짧은 피격 무적. 3기 격파 승리 / HP 0 패배 / 재도전
- 재질 기반 경량 이펙트 및 Kenney CC0 효과음/맵 소품
- 시작/일시정지/결과 화면, 음소거/저사양 설정, 최고 기록 저장
- 전체화면, PWA 설치 UI, 가로 방향 manifest, 오프라인 리소스 사전 저장, 명시적 업데이트 버튼

## 모델 검사 및 출처

| 파일 | RX78 | SD MS-06F Zaku II |
|---|---|---|
| 제작자 | nickqd | krit yamsaso |
| 확보 형식 / 업로드 원본 | GLB / FBX | GLB / DAE |
| 확보 파일 크기 | 590,356 bytes | 11,073,004 bytes |
| 메쉬 / 노드 | 13 / 41 | 824 / 1,435 |
| skins / animations | 0 / 0 | 0 / 0 |
| JOINTS_0 / WEIGHTS_0 | 없음 | 없음 |
| 재질 / 이미지 | 1 / 0 | 32 / 0 |
| 실행용 메쉬 | 13, 부품 유지 | 58, 6개 관절·재질별 병합 |

건담 원본은 흰색 단일 재질이며, 실행용에는 부품별 색상을 적용했습니다. 총·방패·머리·팔다리는 이름 있는 독립 메쉬입니다. 자쿠 원본은 일반 group/Material 노드 위주이며, 실행용은 부품 중심 위치로 6개 강체 관절을 구성했습니다. 원본 GLB 보존, 자쿠 선분 프리미티브 39개는 실행용에서 제외했습니다.

- [Rx78](https://sketchfab.com/3d-models/rx78-1af4f3cb6a2b4bbea488421d2da1aca3)
- [SD MS-06F Zaku II](https://sketchfab.com/3d-models/sd-ms-06f-zaku-ii-bbf1b12464cd4c158e3da1bdd13c5ce5)
- 모델 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). 제작자·변경사항은 CREDITS.txt와 게임 출처 창에 표시
- [Kenney Sci-fi Sounds](https://kenney.nl/assets/sci-fi-sounds), [Blaster Kit](https://kenney.nl/assets/blaster-kit): CC0. 원본 라이선스 assets/audio, assets/props에 포함

모델 제작자의 라이선스와 원작 캐릭터의 권리는 별개입니다.

## 빌드

저장소 루트에서 Godot 4.7.2 standard와 같은 버전 Web export templates를 준비합니다.

```sh
# GODOT_BIN을 설치한 엔진 경로로 지정하거나 build_web.py --godot 인자로 전달
export GODOT_BIN=/path/to/godot
"$GODOT_BIN" --headless --path sd-capsule --editor --import --quit
"$GODOT_BIN" --headless --path sd-capsule --script tests/combat_test.gd
"$GODOT_BIN" --headless --path sd-capsule --script tests/demo_test.gd
"$GODOT_BIN" --headless --path sd-capsule --script tests/polish_test.gd
"$GODOT_BIN" --headless --path sd-capsule --script tests/tactical_test.gd
"$GODOT_BIN" --headless --path sd-capsule --script tests/sortie_test.gd
python3 sd-capsule/tools/build_web.py --godot "$GODOT_BIN"
node sd-capsule/tests/pwa_test.mjs
python3 -m http.server 8063 --bind 127.0.0.1 --directory sd-capsule/dist
```

준비된 모델 재생성: `Godot --headless --path sd-capsule --script tools/prepare_models.gd`.
원본 GLB 검사: `python3 sd-capsule/tools/inspect_glb.py`.

`build_web.py`는 엔진 export 뒤 정적 PWA 셸, 설치/전체화면 도구, 캐시 버전, 아이콘을 생성합니다. 런타임 CDN/로그인/백엔드는 없습니다. 최초 온라인 방문 후 상단 **오프라인 준비 완료**가 표시되어야 오프라인 실행이 가능합니다. 캐시/저장소는 브라우저가 정리할 수 있습니다.

## 구조와 향후 4인 확장

- `pilot_input.gd`: 플랫폼 입력 → 프레임 명령
- `ai_input.gd`: AI 판단 → 이동/사격 의도
- `unit_state.gd`: HP/부스터/피격 무적 상태
- `unit_motor.gd`: 명령 소비, 물리 이동
- `beam_rifle.gd`, `combat.gd`: 무장 상태/전투 판정
- `zaku_target.gd`, `enemy_bolt.gd`: 적 물리/피해/탄환
- `game_hud.gd`: 표시만 담당
- `lab.gd.capture_snapshot(tick)`: ID·위치·속도·HP·탄약을 포함하는 JSON 직렬화 가능한 상태 경계

현재 네트워크 플레이는 없습니다. 추후 호스트 권위 모델에서 명령에 actor_id/sequence/tick을 붙이고 WebSocket/WebRTC 전송, 스냅샷 보간, 서버 피해 판정을 연결해야 합니다. Godot 물리의 결정론적 lockstep을 가정하지 않습니다.

## 검증 범위

2026-11-14 개발 환경 기준. 아래 FPS/오프라인 검사는 1차 데모 기준이며, 이후 모션·그림자가 추가된 빌드의 실기기 성능 보장이 아닙니다:

- 생성된 서비스워커를 오래된 HTTP 캐시/오프라인 조건에서 실행하는 Node 회귀 검사 통과
- headless 전투 13개 + 확장 14개 + 완성도 회귀 17개 + 공격/전술 26개 + 임무 20개 = 90개 통과
- 180HP 전투 설정, 자쿠 관절/반동/격파, 사벨 대기 자세, 부스터 표시, 적 근접 공격과 이탈 회피, 이펙트 최대 개수/소멸 검증
- 라이플 명중/쿨다운/재장전, 벽 가림/관통 방지, 범위, 승리 및 중복 격파 방지
- 사벨 3타/넉백, HP/무적, 대시/부스터 소진·회복, 동시 멀티터치 명령, AI 이동/회피, 패배
- 브라우저: 라이플 3기 격파 승리, 탄약을 쓰지 않은 사벨 1기 격파, 적에게 피격/패배, Q 무장 전환, 공중 부스터, 재도전
- 1280×720에서 관측 FPS 대체로 110~120, 평균 표시 107~119. 전체 기기 성능 보장이 아님
- 844×390 가로 화면에서 플로팅 터치 UI/전체 3D 화면 확인. 실제 스마트폰 터치·GPU 측정 아님
- HTTP 서버 중단(접속 실패 확인) 후 캐시에서 새로고침 및 3기 격파 완료
- 검증 시 브라우저 오류 로그 없음
- GitHub Pages 공개 배포본에서도 인앱 브라우저로 3기 격파/승리 및 오프라인 캐시 준비 완료 확인
- 개발 Mac의 Chrome에서는 WebGL2 미지원 오류가 발생해 전투 실행 불가. 같은 빌드는 인앱 브라우저에서 정상 실행. Chrome의 설치 버튼 노출은 확인했으나 OS 앱 설치·재실행 완료는 미검증

**남은 실기기 검증:** iPhone/iPad Safari 설치·가로 잠금 동작, Android 설치·동시 터치, 목표 모바일 30FPS의 장시간 실측. 저사양 모드는 내부 3D 해상도 65%와 LOD 임계값을 사용합니다. 이 항목은 실제 기기 없이 달성했다고 표시하지 않습니다.

Combat Update 브라우저 검증: 새 서비스워커의 **업데이트 적용** 버튼으로 빌드 교체, 사격/피해 숫자/사벨 대기/공중 부스터/레이더 표시, 이동과 사격으로 11.3초·HP 60·A 등급 승리, 844×390 플로팅 UI 확인. 오류·경고 로그 없음. 실제 모바일 터치/성능 측정은 아님.

Tactical Update 브라우저 검증: CARGO YARD 사벨 격파 + 엄폐 우회 + 원거리 전투로 22.8초/HP 52 승리, REACTOR RING 수동 표적 전환 포함 12.5초/HP 84 승리. 지원형 조준선·중앙 구조물 우회·후방 측면 기동 확인. 844×390 화면에서 MAP 버튼 전장 전환과 플로팅 조작 UI 확인. 오류·경고 로그 없음. 실제 휴대기기에서의 입력/성능 검증은 아직 별도 과제입니다.

## 수동 인수 테스트

1. 공개 HTTPS 주소를 열고 오프라인 준비 완료 확인. 사격과 사벨로 각각 적을 격파
2. 이동·시점·공격 동시 터치, 점프 후 부스터 고갈, 대시, 무장/표적 전환
3. 피격·패배/승리 후 재시작, 앱 전환 후 일시정지 유지
4. 홈 화면 설치 → 앱 종료 → 비행기 모드에서 재실행
5. 저사양/기본 설정으로 5분 전투, FPS/발열/입력 누락 기록


## Motion Update — 2026-11-15

Gundam locomotion, aiming, reload and evade poses now blend exponentially. Directional banking and tucked legs recover smoothly after boosting. Zaku uses a shooting stance, blended recoil, drawn-back melee preparation and clock-driven extension, plus a lowered sidestep stance. These remain rigid-part animations, not newly skinned models.

Saber ribbons use the authoritative attack clock's swept angles, capped at 12 nodes with a 0.14s lifetime. Hits and destruction emit expanding shock rings; the third combo hit has a larger effect and lower-pitched impact. Damage, attack intervals and invulnerability rules are unchanged.

Validation: 90 existing checks plus 8 motion checks, PWA checks and web export. Recoil regression now compares against the prepared aiming pose. Browser combat used saber finishing, rifle/reload and directional dash to win with 3 kills in 21.9s, HP80 and the saber medal. No browser errors/warnings. Physical mobile performance remains unverified.


## Combat Readability Update - 2026-11-15

Enemy melee now projects its committed 2.8m / dot>0.45 attack cone onto the ground during windup and contact. Stagger, recovery and death remove the warning. This is a cosmetic ground projection; terrain height and cover still use existing authoritative collision checks. Enemy bolts have short directional streaks and bounded impact sparks.

Player and enemy health bars show delayed orange damage loss. The reticle responds to rifle cooldown and shows reload progress at the center; active saber attacks display the combo number. When a wall compresses the spring arm into the player, the player visual hides below 1.5m and returns above 1.9m to avoid obstructing aim and flickering. Collision and health are unchanged.

Validation: 111 headless checks (including 13 new readability checks), PWA verification and clean export. Browser: visible melee ground warning, directional dodge, rifle/reload and 3-enemy victory in 15.3s at HP68, accuracy96%; no console errors/warnings. Physical mobile performance remains unverified.


## Battlefield Update - 2026-11-15

Added static industrial silhouettes, service gantries, painted lanes and launch markings outside/along the playable boundary. These use no collision or navigation bodies; scenery shadows are disabled. Cargo Yard uses a warm horizon/light and Reactor Ring a cool sky/light. Fog is reduced and affects the sky only slightly. Existing Kenney cover and all asset credits remain intact.

Gundam gait phase now follows actual horizontal speed, with subtle stride bob and travel lean. Grounded dash, landing and Zaku evade generate six-puff dust effects, capped at eight simultaneous effects with a 0.42s lifetime. Destruction layers four rising smoke puffs after sparks/flash; ordinary impacts allocate no smoke. All effects pause correctly and expire. No damage or movement speed changes.

Validation: 120 headless checks and PWA checks passed; clean Web export. Destruction cleanup regression waits for actual maximum effect lifetime. Local browser victories: Cargo Yard 27.9s/HP84, Reactor Ring 12.5s/HP84. No console warnings/errors. Physical mobile performance remains unverified.
