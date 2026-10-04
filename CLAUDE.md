# Surter: Days — Claude Code 작업 지침

Roblox 좀비 생존·익스트랙션 게임의 도시 맵 저장소. 맵 이력은 `SESSION.md`, 저장소 소개는 `README.md`.

## 반드시 지킬 것

- **이 저장소(`~/projects/Roblox`) 밖의 파일은 절대 건드리지 않는다.** (사용자 지시)
- 이전 번호의 `.rbxl`은 덮어쓰지 않는다. 새 작업은 번호를 올린 새 파일로 남긴다. 최신 원본은 `outputs/SurterDays_Studio_21_Apocalypse.rbxl` (2026-10-03, 미커밋, 아포칼립스 분위기). 22번(건물 키트) 진행 중 `SurterDays_Studio_22_BuildingKit.rbxl` (2026-10-04 00:51, Studio 창이 이 파일에 묶임). **원래 20번은 2026-10-04 저장 사고로 소실**(현재 20번 파일 = 22번 중간본). 사용자에게 저장을 부탁하기 전에 창이 묶인 파일을 `.keep` 으로 복사해 둘 것. 20번(배치)·19번(소품 최적화)·드럼통 중간본 보존. 18번은 git a836712 그대로.
- `work/` 의 12~21번 편집 스크립트는 이미 맵에 적용됨. 재실행 금지, 게임 자동 실행 스크립트로 설치 금지.
- 기존 객체는 삭제하지 말고 `ServerStorage.<이름>_before_<번호>` 로 옮겨 되돌릴 수 있게 한다 (12~18번과 같은 방식).
- Orca 앱은 건드리지 않는다.
- 설치, 설정 파일 수정, 저장소 밖 쓰기, git push 전에는 사용자 확인을 받는다.

## 환경 (2026-10-03 기준)

- MacBook Air M5, macOS. Roblox Studio(`/Applications/RobloxStudio.app`), Blender 5.2.2 LTS(`/Applications/Blender.app`).
- Roblox Studio **내장 MCP** 사용 (구 `studio-rust-mcp-server`는 2026-04 종료). Studio에서 Assistant → … → Manage MCP Servers → "Enable Studio as MCP server" 켜져 있음. 실행 파일: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`. 코드 실행 도구 이름은 `execute_luau` (`run_code` 아님).
  - Claude Code 등록 예: `claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` (문법은 `claude mcp add --help`로 확인할 것)
  - `execute_luau`는 플러그인 권한이라 일부 속성(예: `Lighting.Technology`)은 읽기 불가.
- Blender: Blender Lab 공식 MCP 애드온(`bl_ext.lab_blender_org.mcp`, localhost:9876) 설치됨. Claude Desktop 커넥터로 연결해 사용했다. Claude Code에서 같은 서버를 쓸 수 있는지는 확인하지 않았다. 대안: `Blender --background --python <script>` 로 헤드리스 실행.
- macOS 파일 열기/저장 창(Studio의 Save to File As, Import)은 자동화가 안 된다. 2026-10-03에 Save As 창에서 이름 입력이 반영되지 않아 18번이 두 번 덮어써졌고, 두 번 모두 `git restore` 로 복원했다.

## 완료: 19번 반복 소품 최적화 (2026-10-03, 상세·수치는 SESSION.md, outputs/studio_review_19/audit_log.txt)

- Workspace BasePart 190,004 → 108,820. 작은 WedgePart 묶음을 MeshPart 로 교체, 원본은 `ServerStorage.Props_before_19` 에 보관.
- 메시 교체 절차 (다른 소품에도 재사용):
  1. Studio 에서 대상 파트 기하를 추출 → 로컬 수신기로 전송. 수신기: scratchpad 의 간단한 Python HTTP 서버(127.0.0.1:34999, POST 저장/GET 제공).
     플러그인 HTTP 는 `HttpService.HttpEnabled` 가 필요 → 전송 동안만 true, 끝나면 원래 값(false) 복구. MCP 출력으로 큰 데이터를 받지 말 것.
  2. `tools/blender/build_props_fbx.py` (헤드리스) 로 FBX. 객체 이름 = 메시 이름.
  3. 사용자가 Home → Import → Import Queue(📂)로 FBX 선택 → Start Import → Assets 에서 맵에 넣기. 파일 창은 자동화 불가.
     `AssetService:CreateAssetAsync` 는 MCP 실행 환경에서 막혀 있음.
  4. Import Queue 결과: 모델 전체가 **균일 배율로 축소**(barrel 은 ×100, props 는 ×0.0227 등 매번 다름)·**Y축 180° 회전**.
     → MeshPart Size 를 계획값으로 직접 지정 + `CFrame.Angles(0, math.pi, 0)`. 사전 검사는 축별 배율이 같은지만.
  5. 교체 후 같은 카메라 `screen_capture` 비교, 충돌 소품은 레이캐스트·설 수 있는 칸(GetPartsInPart) 비교 + Play 보행.
- 기하 주의: 얇은 쐐기(두께 0.025)는 앞·뒤 면 2장으로 (중앙면 1장이면 판에 반쯤 묻힌 글자가 사라짐). `Shape=Cylinder` Part 는 메시에 넣지 말 것.
  같은 이름 형제 모델(예: 병원 Creator_Benches 14개)은 경로+이름 묶음이 섞이므로 제외.
- 맵은 StreamingEnabled — Play 클라이언트에는 주변 파트만 있음. 전체 조회는 Server/Edit 데이터모델에서.
- 저장: ⌘S 가 안 먹힐 때가 있음 → macOS 메뉴 File → Save to File. 저장 후 mtime/크기/헤더 인스턴스 수 확인.

## 완료: 20번 배치 수정 (2026-10-03, 상세 SESSION.md, outputs/studio_review_20/audit_log.txt)

- 병원 계단 난간·손잡이, 병동 위쪽 줄 병상 12곳, 진입 가능 건물 1층 선반·책상·소파 57건 벽으로, 떠 있는 창틀·조명·잔해 정리, 농구 골대.
- 옮긴 파트는 `CFrameBefore20`(병원은 `SizeBefore20` 도) 속성, 새 파트는 `Added20` 속성.
- 배치 작업 요령:
  - **`ExtentsSize` 는 월드 AABB 가 아니다**(파트 자체 좌표 크기). 월드 범위는 CFrame 축 절댓값으로 직접 계산 (`studio20_*.luau` 의 `aabb()`).
  - 평면도: Studio 에서 파트 AABB 를 로컬 수신기로 보내고 SVG 로 그려 `qlmanage -t -s 2400` 으로 PNG 변환 (matplotlib 없음, 설치 안 함).
  - 큰 결과는 MCP 출력(10만 자에서 잘림) 대신 로컬 수신기로.
  - Studio 창이 가려져 있으면 `screen_capture` 가 멈춤 → 사용자에게 창을 앞으로 띄워 달라고 요청.
  - Play 는 StreamingEnabled: 클라이언트에는 주변만 있으므로 대상 계산은 Server/Edit 에서 하고 클라이언트는 보행만.

## 완료: 21번 아포칼립스 분위기 (2026-10-03, 상세 SESSION.md, outputs/studio_review_21/audit_log.txt)

- 새 요소는 모두 `Workspace.Apocalypse_21` (Barricades / Streets). 치운 차단벽은 `ServerStorage.Barricades_before_21`, 조명 원래 값 `Before21_*`, 기운 가로등 `CFrameBefore21`.
- 플레이 구역 경계 = 입구 바리케이드의 보이지 않는 차단면(`Barricade_blocker_21`, 높이 24). 폐차를 옮기거나 지울 때 차단면은 남길 것.
- `studio21_build_barricades.luau`·`studio21_build_streets.luau` 는 폴더를 지우고 다시 만드는 재생성형이지만, 이후 수동 보정(차단면 폭·연기)이 있으므로 그냥 재실행하지 말 것.
- MCP screen_capture 는 파티클(연기)을 찍지 못함.

## 진행 중: 22번 건물 키트 (2026-10-03~, 상세 outputs/studio_review_22/audit_log.txt)

- 방향(사용자): 장르 유지, 질감은 참고 이미지(스타일라이즈드 도시) 수준, **전 연령·살짝 어두운 아포칼립스**(깨끗한 파스텔 노을은 폐도시에 안 어울림). Creator Store 모델은 쓰지 않음(악성 코드 우려). 건물 종류를 함수로(약 30종) 만들어 변형 재사용, 주요 건물은 따로 모델링.
- 키트: `tools/buildingkit/kit.luau` + `kit_types2.luau` + `kit_nature.luau`(Kit.tree) + `kit_apoc.luau`(조명 ash/dark, Kit.weather, grass/bush/crack/debris/scorch/smoke) → `sh tools/buildingkit/deploy.sh <scratchpad>/inbox` 로 합쳐 수신기에 올리고, execute_luau 에서 `loadstring(HttpService:GetAsync(url, true))()`.
  `Kit.build(type, parent, CFrame, {seed, decay, w, d, floors ...})` → Model, 파트 수, {W,D,H}. 정면 = -Z, 원점 = 바닥 중심. 종류 목록 `Kit.TYPE_LIST`.
- 텍스처: `tools/buildingkit/make_textures.py`(Blender Cycles 헤드리스, 균일광으로 알베도+틈새 그늘) → scratchpad inbox 에 복사 → MCP `upload_image`(http://127.0.0.1:34999/<파일>) → id 를 `assets/textures/kit22/ids.json` 과 `Kit.TEX` 에.
  수신기 GET 은 쿼리스트링을 지원하지 않음(`?x` 붙이면 "alive" 반환). HttpService GetAsync 는 nocache=true.
- 소품: MCP `generate_mesh`(AI, 스크립트 없음) → `ServerStorage.Kit22_Props.<이름>`, 피벗 = 바닥 중심. 생성물은 -150° 돌아가 있어 회전 0 으로. 연속 요청은 2~5건씩(8건이면 Too Many Requests).
  `generate_material` 은 Studio 내부 오류로 안 됨.
- 스카이박스 면: Ft=-Z, Lf=+X, Bk=+Z, Rt=-X, Up(이미지 위=+X, 오른쪽=-Z). `tools/buildingkit/make_sky.py`.
- 조명: `Kit.applyLighting("dusk")` 원래 값 `Before22_*`, Sky 는 새로 추가(`Lighting.Kit22_Sky`, Added22). `Lighting.Technology` 는 MCP 로 못 바꿈 → 사용자가 Future 로.
- 시험장 `Workspace.KitLab_22` (Street: `work/studio22_lab.luau`, Catalog: `work/studio22_catalog.luau`, 둘 다 재생성형·맵 원본 무관). 맵에 적용할 때는 새 폴더 + 기존 건물은 `ServerStorage.<이름>_before_22` 로.

## 결정: 서울(강남) 맵 (2026-10-04, 설계 페이지 https://claude.ai/artifact/BbFBbUYMd4hx2szfv2SYGW · 사본 outputs/seoul_plan_v3.html)

- 기존 맵은 보관하고 **강남구 북부(한강~양재천, 강남대로~탄천)** 를 실제 지도(OpenStreetMap, ODbL 출처 표기) 기반으로 새로 짓는다. 1 m = 3 스터드 → 약 15,600 × 19,900 스터드, 걸어서 30분 안팎(차 필수). 게임에선 테헤란로가 수평이 되게 약 21° 회전.
- 1단계 = 강남역~역삼역 블록(2,630 × 1,755 스터드). 가운데 빈 땅 = 호수공원 + 섬 연구소(히든 보스, 끊어진 다리). 북동 대형 건물 = 대학병원(옥상 헬기 탈출).
- 탈출: 한강 다리 검문소(성수·영동대교 남단), 군 임시 헬기장(삼성동 컨벤션센터 광장), 병원 옥상, 양재 방면 고속도로(차량). **지하철 탈출 없음.**
- 첫 접속 = 튜토리얼: 1단계 블록에서 차 고치기(배터리·연료) → 강남대로 남쪽 → 고속도로 → 쉘터. 고친 차는 쉘터 차고에 남아 이후 출격에 사용(잃을 수 있음). 쉘터 위치(맵 밖 별도 장소 / 맵 안)는 미정.
- Creator Store·공식 템플릿 안 씀. 건물은 키트 자동 배치(OSM 건물 자리), 디테일 3등급(핵심 / 대로변 / 안쪽 단순 상자+창 텍스처) + 스트리밍.
- 실제 상호·상표는 게임 안에서 바꿔 쓴다(코엑스 → 컨벤션센터 등). 데이터·스크립트: `assets/source/osm/`, `tools/seoulmap/`.

### 다음 후보

- 21번 연기 Play 확인, 폐차를 메시로(파트 1만 감소 가능), 남은 작은 쐐기 1,499개, 저사양 성능 실측(18 vs 21 비교), 2층 이상 실내(대부분 비어 있음), 외곽 폐허 배경 잔해, 확장 구역 실내 세부.

### 알려진 빈 그룹 (아직 손대지 않음)

`SurterDays` 아래 `Active/B25/B25_01_*`, `B25_02_*`, `Active/B26/*`, `Polish/Hospital*` 등 하위 0개 폴더가 있다. 이전 작업에서 옮기고 남은 것으로 보이나 확인 전.
