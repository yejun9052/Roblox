# Surter: Days — 서울(강남) 맵 1단계 (진행 중)

최신 파일: `outputs/SurterDays_Gangnam_01.rbxl` (새 장소, 강남역~역삼역 블록). 22번 파일(`SurterDays_Studio_22_BuildingKit.rbxl`)은 건물 키트 시험장 보관용.

- 방향: 강남구 북부를 실제 지도(OpenStreetMap) 기반으로 1 m = 3 스터드로 짓는다. 1단계 = 강남역~역삼역 블록 + 호수공원 섬 연구소(히든 보스). 설계 페이지 `outputs/seoul_plan_v3.html`.
- 짓는 법: `work/gangnam01_build_block1.luau` 를 phase 별로 실행 (ground → park → buildings → streets → furniture → optimize → optimize_streets). 키트 `tools/buildingkit/*.luau` 는 `deploy.sh` 로 합쳐 로컬 수신기에서 loadstring.
- 작업 기록·사진: `outputs/studio_review_gangnam01/audit_log.txt` (1~6차). 성능: BasePart 약 11만, Play 60 fps (M5).
- 다음: 사용자 자전거 모델로 교체, 짙은 덩굴·옥상 잡동사니, 고층 빌딩 디테일, 튜토리얼 동선.

## 이전 기록

# Surter: Days — 건물 키트 22 (진행 중)

최신 파일: `outputs/SurterDays_Studio_22_BuildingKit.rbxl` (2026-10-04 00:51 KST 저장, 4,497,507 bytes, 헤더 인스턴스 227,242). Studio 창은 이 파일에 묶여 있음.

- 사용자 방향: 장르(좀비 생존) 유지, 스타일라이즈드 고퀄(참고 이미지) + **전 연령, 살짝 어두운 아포칼립스**. Creator Store 대신 자체 키트·AI 메시. (어린 층 대상 양산형은 별개 구상)
- 만든 것: 건물 키트 31종(`tools/buildingkit/`), 텍스처(Blender 렌더 → MCP upload_image), 스카이박스 3종(dusk/ash/dark), 가로수 `Kit.tree`(잎 카드, 마름/죽음 변형),
  풍화 `Kit.weather`, 풀숲·덤불·균열·잔해·그을음·연기, AI 소품 18종(`ServerStorage.Kit22_Props`, 폐차 반응 좋음). 조명은 "dark" 적용 중(원래 값 `Before22_*`).
- 시험장만 있음: `Workspace.KitLab_22` (Street = 아포칼립스 거리, Catalog = 31종). **실제 맵에는 아직 적용 안 함.**
- 사고: 저장이 20번 경로로 들어가 원래 20번 소실(백업 없음). 지금 `SurterDays_Studio_20_LayoutFix.rbxl` 은 22번 중간본과 같은 내용(sha 5ec443e3).
  `SurterDays_Studio_22_Apocalypse.rbxl` 은 21번과 같은 내용. 두 파일 처리(20 재구성·삭제)는 사용자 답 대기.
- 다음(내일 설명부터): ① 오늘 한 일 설명 ② 20번 복구·중복 파일 결정 ③ 실제 맵 적용 계획(부지별 종류 배정, 진입 가능·주요 건물은 유지/별도 모델링) ④ 불 꺼진 가로등.
- 상세 `outputs/studio_review_22/audit_log.txt`, 사진 같은 폴더(07·08 이 최신 분위기).

## 이전 기록

# Surter: Days — 아포칼립스 분위기 21

최신 파일: `outputs/SurterDays_Studio_21_Apocalypse.rbxl` (2026-10-03 23:08 KST 저장, 4,081,909 bytes, 헤더 인스턴스 215,133). 20번은 작업 전 백업으로 복원(sha 6f27e719 일치).

- 사용자 요청: 도로 바리케이드가 너무 많이 막는 느낌 → 막힘(플레이 구역)은 유지하되 빈도를 낮추고 자연스럽게. 무너지고 불탄 아포칼립스 분위기, 불규칙한 폐차.
- 도시 구조: 플레이 경로(활성 도로 68구간)는 한 줄, 나머지 바둑판 도로 212구간은 블록마다 콘크리트+높은 철망으로 막혀 있었음.
- 바리케이드: 경로 입구 83곳만 남기고 안쪽 113곳 제거(파트 1,372 → `ServerStorage.Barricades_before_21`). 입구는 폐차 364대·잔해·그을음으로 교체.
  보이지 않는 차단면(높이 24, 양옆 담장까지)으로 막힘 유지 — Play 에서 처음엔 폐차 위 점프·보도 틈 우회로 뚫려 보정함.
- 거리: 경로 폐차 50(가운데 차선 비움)·막힌 도로 폐차 130, 잿더미 471, 외벽 그을음 106, 보도 잔해 더미 41, 연기 26·불타는 차 3, 기운 가로등 5.
- 조명: 먼지·연기 낀 색감(대기 밀도/헤이즈↑, 채도 -0.3, 따뜻한 틴트). 원래 값 `Before21_*` 속성.
- 검증: 경로 차선 12,240칸 겹침 0, Play 경로 66/68(나머지 2는 기존 탈출 게이트 경사로 구역), 바리케이드 정면 10/10·가장자리 11/12 막힘(나머지 1은 맵 외곽선 밖), B16·B13 정문 진입 OK.
  연기는 편집 화면 캡처에 안 찍혀 Play 에서 눈으로 확인 필요. 상세 `outputs/studio_review_21/audit_log.txt`.
- 파트: 새 `Workspace.Apocalypse_21` 10,922 (충돌 5,933) → Workspace BasePart 약 118,400 (20번 108,856).
- 스크립트(적용 완료, 재실행 금지): `work/studio21_barricade_store.luau`(1회), `studio21_build_barricades.luau`·`studio21_build_streets.luau`(재생성형), `studio21_blocker_extend.luau`(요약본), `studio21_lighting.luau`.
- 남은 일: 실제 플레이 화면에서 연기 확인, 무너진 건물(외곽 실루엣) 보강, 폐차를 메시로 바꿔 파트 수 줄이기. Orca 조작 없음.

## 이전 기록

# Surter: Days — 맵 배치 수정 20

최신 파일: `outputs/SurterDays_Studio_20_LayoutFix.rbxl` (2026-10-03 22:07 KST 저장, 3,797,691 bytes, 헤더 인스턴스 203,280 = 19번 +36). 19번은 `outputs/SurterDays_Studio_19_PropOptimize.rbxl` 그대로 보존.

- 사용자 요청: 맵 전체의 어색한 배치 — 병원 침대가 벽에서 떨어져 방 가운데, 계단 난간 공중 부양 등 — 를 고치기.
- 병원: 계단 난간 기둥 36개를 디딤판 위로 내리고 동쪽에 36개 추가, 연속 손잡이 4개를 계단 경사로, 계단 구멍 난간 12개를 바닥 위로.
  병동 위쪽 줄 병상 12곳(452파트)을 180° 돌려 칸막이벽에 머리판 밀착. 18번에서 "뒤에 벽 없음"으로 남겼던 그 12곳.
- 진입 가능 건물 1층: 방 가운데 줄지어 있던 선반·책상·소파 57건을 가장 가까운 벽으로(책상 9건은 90° 회전). 뒷면이 문/개구부·겹침·문 2 스터드 이내면 유지.
- 떠 있는 물건: 외곽 건물 창틀 1,068·조명 14 를 면에 붙이고, 도로 잔해·상자·판자 106 을 바닥으로. 농구 골대 2개(기둥 관통·림 부양) 정리.
- 검증: 겹침 검사, 바닥 접점, Play 보행(병원 계단 9/9, 병동 17/17, 가구 앞 60/65 — 실패는 상자 위로 올라섬 등 통행 막힘 아님). 상세 `outputs/studio_review_20/audit_log.txt`.
- 이동 파트 2,662 (CFrameBefore20 속성으로 원위치 가능), 추가 36 (Added20). 삭제 없음. BasePart 108,856.
- 스크립트(적용 완료, 재실행 금지): `work/studio20_hospital_fix.luau`, `studio20_furniture_to_wall.luau`, `studio20_furniture_to_wall_pass2.luau`, `studio20_float_fix.luau`. 읽기 전용 검사: `studio20_float_audit.luau`.
- 남은 일: 외곽 폐허 배경 잔해, 2층 이상 실내(대부분 비어 있음), 확장 구역 실내 세부, 0.17 스터드 길가 소품 간격. Orca 조작 없음.

## 이전 기록

# Surter: Days — 반복 소품 최적화 19

최신 파일: `outputs/SurterDays_Studio_19_PropOptimize.rbxl` (2026-10-03 20:50 KST 저장, 3,779,463 bytes, 헤더 인스턴스 203,244). (드럼통 파일럿만 반영된 18:47 저장본은 `SurterDays_Studio_19_PropOptimize_barrelpilot.rbxl`로 보존). 18번은 git 원본 그대로.

- 목표: 메시를 작은 삼각형 쐐기(WedgePart)로 분해해 만든 소품을 MeshPart로 교체해 파트 수를 줄임. 모양·위치는 그대로.
- 결과: Workspace BasePart 190,004 → 108,820 (−43%). 작은 쐐기 62,945 + 드럼통 20,352 → 1,499 남음(12개 미만 묶음 + 병원 벤치 140).
  - 드럼통 24개: 854파트 → MeshPart 3 + 원통 Part 3. (barrel_detail_v2.fbx)
  - 1차 비충돌 장식(쓰레기통·상자 끈/라벨·호스·볼트 등): 쐐기 32,015 → MeshPart 459 (메시 157종).
  - 2차 충돌 소품(타이어·공구판·간이침대·소파·공구 등): 쐐기 29,431 → MeshPart 158 (메시 116종), CanCollide true, Default(15개 Precise).
- 원본은 모두 `ServerStorage.Props_before_19` (Barrel_<id>, Phase1/Phase2.<gid>)에 보관, 각 파트 `OriginalParent19` 속성. 삭제 없음.
- 방법: Studio에서 쐐기 묶음(같은 Parent+Name, 외형별)을 추출해 로컬 수신기(HTTP, 전송 동안만 HttpEnabled)로 받음 → Blender 헤드리스로 FBX → 사용자가 Import Queue로 가져옴 → 교체 스크립트. 모양이 같은 소품은 메시 공유.
- 주의점(다음 작업에 그대로 적용):
  - Import Queue는 모델 전체를 균일 배율로 줄이고 Y축 180° 회전 → Size 직접 지정 + 180° 보정. 축 배율이 같은지만 검사.
  - 얇은 쐐기는 앞·뒤 면 2장으로(중앙면 1장이면 판에 반쯤 묻힌 글자가 사라짐 — 쓰레기통 "PAPER"→"P-PEP" 사례).
  - 원통 Shape Part는 메시에 넣지 말 것. 같은 이름 형제 모델이 있으면 경로+이름 묶음이 섞임(병원 벤치 14개 사례 → 복귀).
- 검증: 교체 전후 같은 카메라 사진(쓰레기통·라벨·상자·타이어·소파·드럼통) 일치. 2차 충돌: 레이 17,808개 중 1.1% 통과(얇은 면 가장자리), 설 수 있는 칸 비교, Play 보행 B14/B16/B01 왕복 성공, 정면 보행 막힘 확인, 타이어 더미는 원본과 같이 위로 올라섬.
- 남은 일: 작은 쐐기 1,499개(작은 묶음)·병원 벤치는 유지. 타이어 윗면 조명 반사가 조금 다름. 저사양 성능 실측은 아직.
- 스크립트(모두 적용 완료, 재실행 금지): `work/studio19_extract_barrel.luau`(읽기), `studio19_replace_barrel.luau`, `studio19_fix_barrel_cylinders.luau`, `studio19_extract_props.luau`, `studio19_replace_props.luau`(v1, 이후 v2로 대체), `studio19_reextract_props.luau`, `studio19_replace_props_v2.luau`. Blender: `tools/blender/build_barrel_fbx.py`, `tools/blender/build_props_fbx.py`. 데이터: `assets/source/`, FBX: `assets/fbx/`.
- 검증 기록/사진: `outputs/studio_review_19/` (audit_log.txt). Orca 조작 없음.

## 이전 기록

# Surter: Days — 병원 가구 벽 접점 수정 18

최신 파일: `outputs/SurterDays_Studio_18_HospitalFit.rbxl`. 2026-09-15 22:42:40 KST 저장 확인, 3,295,018 bytes. 17번 원본 보존. Studio는 편집 모드로 열려 있음.

- 사용자 요청: 병원에서 벽과 떨어져 있는 가구를 하나씩 찾아 수정.
- 병상 38곳 중 26곳을 기존 칸막이 벽으로 이동. 관련 수액대·모니터 받침·커튼·의자도 함께 이동. 앞쪽 독립형 병상 12곳은 뒤에 벽이 없어 유지. 협탁 26, 선반 13, 수납장 8, 안내판 27, 작업대/조작대/손 소독기/배터리 추가 보정. 총 이동 부품 1,390개.
- `Furniture_fit_18.Item_audit`에 119개 작업/유지 기록. 개별 부품 `CFrameBefore18`에 최초 좌표 보존. 협탁 기록의 Before는 병상 이동 후 추가 밀착 직전 좌표.
- 벽 뒷면 111개, 통로 216개, 바퀴 152개, 기존 바닥 44+44개 및 천장 33개 검사 실패 0. 추가 지지부 174개 실패 0.
- 실제 Play 기본 45/45 + 변경 병실 주변 37/37, 총 82/82 정상 걷기 통과. 시작 위치만 시험용 이동. 이후 기하 변경 없음.
- 사진/검증: `outputs/studio_review_18/` 및 `병원_가구_점검표.md` (119행). 개체 목록 `items119.txt`.
- `work/studio18_hospital_fit.luau` 적용 완료, 재실행 금지. 감사/보행 스크립트는 게임 자동 실행 코드로 설치하지 않음.
- 전체 도시 품질 완성/성능 검증 아님. Orca 조작 없음.

## 이전 기록

# Surter: Days — 재개 검증 및 학교 세부 수정 17

최신 작업 파일: `outputs/SurterDays_Studio_17_Campus.rbxl`. 이전 16번 보존. Studio는 편집 상태로 열어 둠.

- 16번 맵 실제 Play 보행: 주거 3, 상업 3, 병원 진입로 5, 동부 공공 3개 구간, 총 14/14 통과(2026-09-15 21:58). 구역 시작점만 순간이동 후 각 구간은 Humanoid 보행. 전체 도시/저사양 성능 검증은 아님.
- 학교 가장자리 잔디에 벤치+쓰레기통 3곳 추가. 첫 후보는 기존 보행로와 간섭해 실패 후 원복 확인. 조사 후 X=1250의 빈 구역에 적용 성공. 기존 통로/출입문 유지.
- 운동장 전광판의 빈 뒷면에 학교 안내 추가. 공중에 떠 있던 기존 서문 글자(투명 표면)를 잔디 가장자리 지주형 간판으로 이동하고 실물 뒷판·지지대 추가. 원래 CFrame을 해당 부품 속성에 보존.
- `Campus_quality_17`: 최종 새 부품 52개, 지면 접점 17개 독립 재검사 실패 0, 신규 충돌 부품 0. 가구는 장식용이며 실제 앉기 기능 없음. 추가 후 Play 재시험은 하지 않았고 기하/화면 검사로 확인.
- `work/studio17_campus.luau`, `work/studio17_gate_sign.luau` 이미 적용. 재실행 금지. 기존 16번 외벽 추가 마감 수치 `MainWallFinish=314` 확인.
- 검증/사진: `outputs/studio_review_17/play14_pass.jpg`, `play_audit.txt`, `campus_audit.txt`, `final_audit.jpg`, `campus_final.jpg`. 전체 맵 세부 리모델링 및 성능 검증은 계속 필요. Orca 조작 없음.

## 이전 기록 — 도시 전역 품질 수정 16

최신 작업 파일: `outputs/SurterDays_Studio_16_CityQuality.rbxl`. 기존 15번 보존.

- 도시 전역 재질/색감 정리: 653개 그룹, 외벽 요소 11,798개, 창문 4,814개, 프레임 12,872개, 도로 표면 363개, 지붕 마감 190개. 이 수치는 개별 건물 수가 아니라 부품/그룹 수다.
- 옥상 서비스 키트 115곳, 도로 보수 표시/배수 장식 포함 새 부품 2,111개. 지지부 높이 115개 검사 실패 0, 신규 충돌 부품 0. 기존 충돌 형상 유지.
- 안개 밀도/조명/색보정 조정. 건물별 원래 Color/Material/Reflectance와 환경 설정은 속성으로 보존. 추가 외벽 마감 `studio16_facade_finish.luau`도 적용했으며 정확한 추가 개수는 재개 시 확인 필요.
- 식재 후보 검사에서는 빈 공간을 확보하지 못해 실제 새 식재 0개. 빈 작업 모델만 남음.
- 사용자가 잠시 중단 요청. Play를 시작했으나 `studio16_playtest.luau`는 실행하지 않았으며 보행 검증 미완료. 이후 사용자 요청으로 Play 중지, 저장 및 Studio 종료 처리. 전체 품질 완료/출시 준비 완료가 아님.
- 작업 자료: `work/studio16_city_quality.luau`, `city16_zones.luau`, `studio16_courtyards.luau`, `studio16_facade_finish.luau`. 이미 적용됨. `studio16_playtest.luau`는 미실행 테스트안이며 게임 자동 실행 스크립트로 설치하지 않음.
- 기존 병원/경찰서 개선 유지. Orca 조작 없음. 다음 재개 시 구역별 보행과 성능 검증부터 진행.

## 이전 기록 — 병원 진입부 15

최신 작업 파일: `outputs/SurterDays_Studio_15_Approach.rbxl` (2026-09-15). 이전 14번 보존.

- 병원 정문과 기존 경계 개구부에 맞춘 횡단보도·정지선, 응급실 보행 진입 표시, 배수구 4곳, 점검 덮개 2곳, 표지판 2개, 벽 쪽 쓰레기통 2개. `Approach_detail_15` 안에 81개 부품.
- 실제 지면 높이를 raycast로 확인해 바닥 표시 배치. 첫 시도는 경계 구조물 위에 촉각 표시가 놓이는 것을 검사에서 감지해 실패했고 Studio가 원복함. 촉각 표시는 제외하고 보정 적용 성공. 중간 작업 보관 모델은 생성하지 않음.
- 기하 검증: 지지부 접점 4개, 보행/차도 충돌 검사 36개, 실패 0. 최종 항공 화면에서 횡단보도와 정문 연결 확인. 이번 Play 보행 재시험은 하지 않음.
- `work/studio15_approach.luau`: 적용 작업과 검사. 이미 적용됨, 재실행 방지 있음.
- `outputs/studio_review_15/audit_log.txt`, `approach_final.jpg`: 검사 기록과 실제 Studio 사진.
- 이번 범위는 병원 진입부. 나머지 주요시설/도시 전체 디테일 및 성능 검수는 후속 작업. Orca 조작 없음.

## 이전 기록 — 외관 디테일 14

최신 작업 파일: `outputs/SurterDays_Studio_14_Exterior.rbxl` (2026-09-15).

- 13번 병원 수정본을 Studio에서 열어 병원 외관을 개선. 기존 13번 보존.
- `Exterior_quality_14`: 옥상 설비 받침, 팬 가드, 덕트·지지대·정비 통로 표시. 현관 벤치 두 개, 안전 볼라드, 캐노피 고정 조명, 안내판. 기존 정적 구급차 두 대에 범퍼·그릴·램프·문·미러 추가. 총 195개 직접 하위 부품.
- 접점 높이 19개 및 정면/가로 통로 충돌 검사 18개 실패 0. 눈높이 화면 검수에서 안내판이 창문 하부와 겹쳐 아래로 이동하고 추가 검사 통과.
- 이번에는 Play 보행 시험을 새로 실행하지 않았다. 병원 내부는 13번 검증 상태 그대로이며, 새 외부 형상은 기하 검사와 Studio 화면으로 확인했다. 저사양 성능과 도시 전체 검수는 미완료.
- 자료: `work/studio14_exterior.luau` (이미 적용, 재실행 방지). 증거와 사진: `outputs/studio_review_14/audit_log.txt`, `entrance_final.jpg`.
- 이번 수정 범위는 병원 외관. 다른 주요 시설과 전체 도로의 후속 디테일은 남아 있다. 파괴 장식/게임 로직/외부 에셋 설치 없음. Orca 조작 없음.

## 이전 기록 — 병원 품질 개선 13

최신 작업 파일: `outputs/SurterDays_Studio_13_Hospital.rbxl`

2026-09-14 21:50:21 KST에 Studio Save As 완료. 3,222,542 bytes. Studio 제목과 디스크 파일 확인. 이전 12번 파일은 3,215,976 bytes / 21:06:14 그대로 보존했다.

## 13번 반영 및 검증

- 약국: 조제대와 벽 쪽 수납장, 단말기·처방전 트레이·약병 배치. 기존 선반을 뒤 벽으로 이동해 통로 확보.
- 검사실: 공중에 떠 있던 작업대를 바닥 지지 수납장으로 교체. 현미경, 싱크대, 분석기, 검체 소품 추가. 실 이름 표지 수정.
- 영상검사실: 검사 침대가 검사실 벽을 침범하지 않도록 이동. 장비 받침과 조작대·의자 추가, 안내판 방향 수정.
- 2층과 3층 간호 데스크: 높이 조정, 단말기 두 자리와 의자, 벽 쪽 문서 수납장. 병동 약품 선반을 벽 쪽으로 이동.
- 겹친 실내 조명 18개와 케이스를 보관 처리. 현재 활성 조명 33개. 천장 안내판 지지봉과 발전기 접지 보정.
- 새 모델: `workspace.Surter_Remodel_10.Surter_Medical_Centre.Clinical_quality_13`. 대체 객체: `ServerStorage.Hospital_before_13`.
- 검사: 바닥 접점 44개, 천장 장착 33개, 통로 폭/높이 검사 216개 — 실패 0.
- 실제 Play 클라이언트 정상 보행: 약국·검사실·영상검사실·두 계단·3층 병동·간호 데스크까지 45/45 구간 통과. 이후 형상 변경 없음. 촬영 후 카메라는 Custom으로 복원.
- 자료: `work/studio13_hospital.luau`, `work/studio13_audit.luau`, `work/studio13_playtest.luau`. 작업/시험용으로만 실행했으며 자동 실행 게임 스크립트로 설치하지 않음.
- 사진과 증거: `outputs/studio_review_13/`의 `laboratory_final.jpg`, `pharmacy_final.jpg`, `nurse_station_final.jpg`, `audit_log.txt`, `playtest_log.txt`, `playtest.jpg`.
- 병원 이번 개선분을 완료했다. 전체 도시 아트 완성과 저사양 성능, 파밍/NPC/탈출 로직은 별도 작업이다. Orca 조작 없음.

저장 검증 후 Roblox Studio를 정상 종료했고 창 목록에서 종료 확인했다. PC와 다른 앱은 종료하지 않았다.

## 이전 기록 — 병원 품질 개선 12

최신 작업 파일: `outputs/SurterDays_Studio_12_Hospital.rbxl`

2026-09-14 21:06:14 KST에 Roblox Studio에서 저장 확인. 3,215,976 bytes.
원본은 이전 작업 폴더의 `SurterDays_Studio_11_Police.rbxl`이며 수정하지 않았다.
현재 폴더로 Save As 한 뒤 Studio 편집 모드에서 병원 내부를 수정했다.

## 반영 내용

- 병원 조명 51개를 천장 하부에 맞추고 고정 케이스 추가. 병실 조명 24개에 방향성 그림자를 사용하고 보조광을 줄임.
- 병상 38개: 바닥에 맞춘 바퀴, 프레임 연결부, 모니터 받침, 독서등이 붙은 지지형 헤드보드, 수액대 바닥 받침 추가. 모니터 화면을 침대 쪽으로 회전.
- 커튼 레일 천장 지지대와 걸이 추가. 환기구 천장 높이 수정. 병실 보조 의자 지지부 72개 접지 수정.
- 접수 공간: 진료 구역 구분 벽, 9 studs 입구, 안내판, 직원용 책상 두 자리, 낮은 안내 테이블, 모니터 받침·키보드·의자·서류·벽 쪽 수납장.
- 대기 공간: 창가 6석과 측면 2석, 잡지 테이블. 중앙 통로를 비움.
- 대체된 객체 131개는 `ServerStorage.Hospital_before_12`에 보관. 새 모델은 `workspace.Surter_Remodel_10.Surter_Medical_Centre.Interior_quality_12`.
- 경찰서 11, 운동장, 나머지 도시 유지. Orca 사용/조작 없음.

## 검증

- Studio 출력: 가구 다리 44개, 침대 바퀴 152개, 천장 케이스 51개, 통로 몸체 높이/폭 검사 117개 — 실패 0.
- 실제 Play 클라이언트에서 정상 Humanoid 걷기로 19/19 구간 통과. 입구 → 접수대 옆 → 진료실 입구 → 대기 공간 → 중앙 복도 → 계단 → 위층 병실.
- Play 이후 화면 방향, 비충돌 의자 높이, 조명만 보정. 의자 지지부 72개 접지 확인. 해당 시각 보정 후 Play 재실행은 하지 않음.
- 실제 사진: `outputs/studio_review_12/reception_final.jpg`, `ward_final.jpg`, `waiting_final.jpg`.
- 증거: `audit.jpg`, `playtest.jpg`, `playtest_log.txt`, `final_save_log.txt`.

## 다음 작업과 한계

병원 전체의 최종 아트 완성이나 도시 전체 품질 검수를 완료한 것은 아니다. 약국·검사실·간호 스테이션과 다른 주요시설의 가구 배치/장착 상태, 3층 동선, 플레이 성능을 후속 검수해야 한다. 파밍/NPC/좀비/탈출 로직을 새로 구현하지 않았다. 조명 그림자 성능은 낮은 사양 기기에서 별도 확인 필요.

다음에도 기존 건물 한 곳씩 실제 눈높이 화면과 보행 검사로 품질을 올릴 것. 파괴 장식은 이후 단계. Orca는 건드리지 말 것.

## 작업 자료

- `work/studio12_hospital.luau`: 주 개선 작업. 재실행 방지 있음.
- `work/studio12_finish_audit.luau`: 화면 검수 후 보정과 검사. 일부 상대 이동이 있으므로 재실행 금지.
- `work/studio12_visual_finish.luau`: 모니터 방향, 의자 접지, 병실 그림자. 재실행 방지 있음.
- `work/studio12_audit_readonly.luau`: 주요 접지/통로 검사 추출본.
- `work/studio12_playtest.luau`: Play 클라이언트 일회성 보행 검사. 게임에 자동 실행 스크립트로 설치하지 않음.
