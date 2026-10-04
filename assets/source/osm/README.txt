gangnam_yeoksam_20261004.json — OpenStreetMap 데이터 (Overpass API, 2026-10-04 받음)
범위: 위도 37.4900~37.5015, 경도 127.0265~127.0405 (강남역~역삼역 일대). 도로·건물·공원·주차장·학교 등.
라이선스: ODbL. 게임/자료에 "지도 데이터 © OpenStreetMap contributors" 표기 필요.
받는 법: tools/seoulmap/overpass_gangnam.txt 를 overpass-api.de 에 POST (User-Agent 헤더 필요, 없으면 406).
변환: tools/seoulmap/osm_game.py — 강남역 사거리 기준, 테헤란로 수평(20.6° 회전), 1 m = 3 스터드, 블록 877×585 m.

gangnam_north_roads_20261004.json / gangnam_north_buildings_20261004.json — 강남 북부 전체 (위도 37.474~37.534, 경도 127.019~127.078, 실제 5.2×6.6 km)
 도로(주거도로 이상)·강·공원 geom / 건물 17,329채 중심점+태그. 한강 물길·선정릉 숲은 relation 이라 빠짐(개요도에선 직접 그림).
결정(2026-10-04 사용자): 맵 = 강남 북부 전체, 1 m = 3 스터드 (약 15,600×19,900 스터드, 걸어서 30분 안팎). 1단계 = 강남역~역삼역 블록.
 1단계 블록 가운데 빈 땅 = 호수공원 + 섬 연구소(히든 보스). 지하철 탈출 없음 — 한강 다리 검문소·군 헬기장·병원 옥상·고속도로(차량).
