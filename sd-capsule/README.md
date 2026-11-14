# Capsule Sortie — 1차 팬게임 데모

Godot 4.7.2 standard / GDScript / WebGL 2.0 Compatibility / single-thread Web export.
실제 무료 SD RX78 모델을 조작해 자쿠 3기를 격파하는 싱글플레이 데모입니다. 비공식 팬 프로젝트이며 원작 게임의 코드·데이터를 사용하지 않습니다.

## 실행 및 조작

배포 주소: https://yum-sy.github.io/sd-capsule-fighter-demo/

- Enter 또는 화면 터치: 시작/재도전
- WASD 이동, Space 점프/길게 공중 부스터, Shift 방향 대시
- 좌클릭/F: 선택 무장 사용, 우클릭/V: 사벨
- R 재장전, Tab 표적 전환, Q/E 무장 전환
- 화면 상단 **마우스 잠금** 버튼: 자유 시점. 지원하지 않으면 화면 드래그
- Esc 일시정지, M 음소거, L 저사양, T 터치 UI 표시
- 터치: 왼쪽 이동, 오른쪽 공격·부스터·대시·재장전·무장·표적 버튼, 나머지 영역 시점 드래그

화면 위에 조작 UI를 겹치며 별도 조작 패널로 게임 화면을 줄이지 않습니다. 가로 화면을 사용하세요. 모바일 브라우저에서 세로 화면이면 가로 회전 안내가 표시됩니다.

## 구현

- 실제 SD 건담/자쿠 GLB 확보 및 Godot 변환. 플레이어 높이/방향 보정, 자쿠 메쉬 재질별 병합, 자동 LOD
- 건담 분리 부품의 강체 관절 걷기·점프 자세 및 사벨 시각 효과. 스킨 리깅/모션 캡처 애니메이션은 아님
- 3인칭 SpringArm 카메라, 충돌, 이동·점프·부스터·방향 대시, 부스터 소진/재충전
- 시야·거리·가림을 고려한 자동 타겟팅과 수동 전환
- 라이플: 6발, 피해 25, 간격 0.28초, 재장전 1.6초, 빈 탄창 자동 재장전
- 사벨: 3타 콤보 25/30/45, 거리 3.4m, 각도/벽 판정, 마지막 타격 넉백
- 자쿠: HP 100, 추적/횡이동/거리 유지/피격 회피, 발사 예고 후 물리 탄환 공격
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
| 실행용 메쉬 | 13, 부품 유지 | 24, 재질별 병합 |

건담은 내려받은 파일 자체가 흰색 단일 재질입니다. 총·방패·머리·팔다리는 이름 있는 독립 메쉬입니다. 자쿠는 일반 group/Material 노드 위주이며 실행용 병합본은 별도 관절화하지 않았습니다. 원본 GLB 보존, 자쿠 선분 프리미티브 39개는 실행용에서 제외했습니다.

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
python3 sd-capsule/tools/build_web.py --godot "$GODOT_BIN"
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

2026-11-14 개발 환경 기준:

- headless 전투 13개 + 확장 14개 = 27개 통과
- 라이플 명중/쿨다운/재장전, 벽 가림/관통 방지, 범위, 승리 및 중복 격파 방지
- 사벨 3타/넉백, HP/무적, 대시/부스터 소진·회복, 동시 멀티터치 명령, AI 이동/회피, 패배
- 브라우저: 라이플 3기 격파 승리, 탄약을 쓰지 않은 사벨 1기 격파, 적에게 피격/패배, Q 무장 전환, 공중 부스터, 재도전
- 1280×720에서 관측 FPS 대체로 110~120, 평균 표시 107~119. 전체 기기 성능 보장이 아님
- 844×390 가로 화면에서 플로팅 터치 UI/전체 3D 화면 확인. 실제 스마트폰 터치·GPU 측정 아님
- HTTP 서버 중단(접속 실패 확인) 후 캐시에서 새로고침 및 3기 격파 완료
- 검증 시 브라우저 오류 로그 없음

**남은 실기기 검증:** iPhone/iPad Safari 설치·가로 잠금 동작, Android 설치·동시 터치, 목표 모바일 30FPS의 장시간 실측. 저사양 모드는 내부 3D 해상도 65%와 LOD 임계값을 사용합니다. 이 항목은 실제 기기 없이 달성했다고 표시하지 않습니다.

## 수동 인수 테스트

1. 공개 HTTPS 주소를 열고 오프라인 준비 완료 확인. 사격과 사벨로 각각 적을 격파
2. 이동·시점·공격 동시 터치, 점프 후 부스터 고갈, 대시, 무장/표적 전환
3. 피격·패배/승리 후 재시작, 앱 전환 후 일시정지 유지
4. 홈 화면 설치 → 앱 종료 → 비행기 모드에서 재실행
5. 저사양/기본 설정으로 5분 전투, FPS/발열/입력 누락 기록
