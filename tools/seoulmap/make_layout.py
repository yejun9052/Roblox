# 강남 1단계 블록 배치 데이터: OSM(json, out geom) → 게임 좌표 JSON
# 게임 좌표: 원점 = 강남역 사거리(블록 북서 모서리), X = 테헤란로 따라 동쪽, Z = 블록 안쪽(남쪽), 1 m = 3 스터드.
# 출력: roads[{pts:[[x,z]...], w, name, cls}], buildings[{id, cx, cz, w, d, yaw(정면 방향 각, 라디안), type, floors, tier, name}], park{...}
# 사용: python3 tools/seoulmap/make_layout.py assets/source/osm/gangnam_yeoksam_20261004.json assets/source/osm/block1_layout.json
import json, math, sys

src, out = sys.argv[1], sys.argv[2]
els = json.load(open(src))["elements"]
lat0, lon0, LAT1 = 37.4900, 127.0265, 37.5015
KX = 111320 * math.cos(math.radians((lat0 + LAT1) / 2)); KY = 110540
O = (103, 387)
TH = math.radians(20.6)
S = 3.0
BW, BH = 877 * S, 585 * S          # 블록 크기 (스터드)
MARGIN = 75 * S                     # 블록 밖으로 포함할 범위 (맞은편 건물)

def tf(p):
    x = (p["lon"] - lon0) * KX - O[0]; y = (LAT1 - p["lat"]) * KY - O[1]
    return ((x * math.cos(TH) - y * math.sin(TH)) * S, (x * math.sin(TH) + y * math.cos(TH)) * S)

def in_area(x, z, m=MARGIN):
    return -m <= x <= BW + m and -m <= z <= BH + m

def in_block(x, z, pad=0):
    return -pad <= x <= BW + pad and -pad <= z <= BH + pad

# 호수공원 (블록 가운데 빈 땅) — 이 안의 건물은 지움
PARK = (740, 600, 1780, 1160)
def in_park(x, z, pad=0):
    return PARK[0] - pad <= x <= PARK[2] + pad and PARK[1] - pad <= z <= PARK[3] + pad

NAMED_W = {"테헤란로": 150, "강남대로": 150, "논현로": 105, "역삼로": 90, "언주로": 120, "봉은사로": 120, "도산대로": 150, "서초대로": 120}
CLS_W = {"trunk": 120, "primary": 90, "secondary": 60, "tertiary": 45, "unclassified": 24, "residential": 21, "living_street": 16, "service": 12, "pedestrian": 12}
roads = []
for e in els:
    t = e.get("tags", {}); g = e.get("geometry"); hw = t.get("highway")
    if not g or hw not in CLS_W: continue
    pts = [tf(p) for p in g]
    if not any(in_area(x, z, MARGIN + 60) for x, z in pts): continue
    name = t.get("name", "")
    w = NAMED_W.get(name, CLS_W[hw])
    oneway = t.get("oneway") == "yes"
    if oneway and hw in ("trunk", "primary", "secondary", "tertiary"):
        w = w / 2   # 상·하행이 따로 그려진 대로: 한쪽 차로 묶음만
    if hw == "service" and t.get("service") in ("parking_aisle", "driveway"): continue
    roads.append({"pts": [[round(x, 1), round(z, 1)] for x, z in pts], "w": w, "name": name, "cls": hw, "oneway": oneway, "lanes": t.get("lanes")})

# 도로 선분 목록 (정면 방향·간선도로 판정)
segs = []
for r in roads:
    for a, b in zip(r["pts"], r["pts"][1:]):
        segs.append((a, b, r["w"], r["name"], r["cls"]))

def seg_dist(px, pz, a, b):
    ax, az = a; bx, bz = b
    dx, dz = bx - ax, bz - az
    L2 = dx * dx + dz * dz
    t = 0 if L2 == 0 else max(0, min(1, ((px - ax) * dx + (pz - az) * dz) / L2))
    qx, qz = ax + t * dx, az + t * dz
    return math.hypot(px - qx, pz - qz)

def hull(pts):
    pts = sorted(set(pts))
    if len(pts) <= 2: return pts
    def cross(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0: lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0: up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]

def min_rect(pts):
    h = hull(pts)
    best = None
    for i in range(len(h)):
        a, b = h[i], h[(i + 1) % len(h)]
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        c, s = math.cos(-ang), math.sin(-ang)
        xs = [p[0] * c - p[1] * s for p in h]; zs = [p[0] * s + p[1] * c for p in h]
        area = (max(xs) - min(xs)) * (max(zs) - min(zs))
        if best is None or area < best[0]:
            mx, mz = (max(xs) + min(xs)) / 2, (max(zs) + min(zs)) / 2
            # 중심을 원래 좌표로
            cx = mx * math.cos(ang) - mz * math.sin(ang); cz = mx * math.sin(ang) + mz * math.cos(ang)
            best = (area, cx, cz, max(xs) - min(xs), max(zs) - min(zs), ang)
    return best

MAJOR = set(NAMED_W.keys())
def sidewalk_w(w):
    # 인도 폭 (스터드): 대로 24, 중로 14, 이면도로·골목 7, 서비스 길 0  (게임 Lua 와 같은 값)
    return 24 if w >= 90 else 14 if w >= 45 else 7 if w >= 16 else 0
buildings = []
skipped = {"park": 0, "tiny": 0, "out": 0}
for e in els:
    t = e.get("tags", {}); g = e.get("geometry")
    if "building" not in t or not g or len(g) < 3: continue
    # 지하상가·지붕만 있는 구조물은 지상 건물이 아님 (강남역 지하쇼핑센터 윤곽이 사거리에 벽으로 섰음)
    if t.get("layer", "0").startswith("-") or t.get("location") == "underground" or "지하" in t.get("name", "") or t.get("building") in ("roof", "construction"):
        skipped["under"] = skipped.get("under", 0) + 1; continue
    pts = [tf(p) for p in g]
    area, cx, cz, a, b, ang = min_rect(pts)
    if not in_area(cx, cz): skipped["out"] += 1; continue
    if in_park(cx, cz, 10): skipped["park"] += 1; continue
    if a * b < 180: skipped["tiny"] += 1; continue
    # 네 변 중 가장 가까운 도로를 보는 변 = 정면
    ux, uz = math.cos(ang), math.sin(ang)          # 변 a 방향
    vx, vz = -uz, ux                               # 변 b 방향 (법선)
    sides = [((vx, vz), a, b), ((-vx, -vz), a, b), ((ux, uz), b, a), ((-ux, -uz), b, a)]
    best = None
    for (nx, nz), wlen, dlen in sides:
        mx, mz = cx + nx * dlen / 2, cz + nz * dlen / 2
        dmin, rw, rname = 1e9, 0, ""
        for s0, s1, w, nm, cl in segs:
            dd = seg_dist(mx + nx * 3, mz + nz * 3, s0, s1) - w / 2
            if dd < dmin: dmin, rw, rname = dd, w, nm
        score = dmin - (20 if rname in MAJOR else 0)
        if best is None or score < best[0]:
            best = (score, nx, nz, wlen, dlen, dmin, rname, rw)
    _, nx, nz, W, D, dist, rname, rw = best
    # 도로에서 물리기: 각 변이 (도로 반폭 + 인도 폭 + 1) 안으로 들어와 있으면 그만큼 변을 안쪽으로 당김
    fx, fz = nx, nz                    # 정면 법선
    sx_, sz_ = -fz, fx                 # 옆 방향
    for _it in range(2):
        for (ax, az, half_n, half_t, sgn) in ((fx, fz, D / 2, W / 2, 1), (-fx, -fz, D / 2, W / 2, -1), (sx_, sz_, W / 2, D / 2, 2), (-sx_, -sz_, W / 2, D / 2, -2)):
            pen = 0
            tx, tz = -az, ax
            for k in (-1, -0.5, 0, 0.5, 1):
                px = cx + ax * half_n + tx * half_t * k * 0.95
                pz = cz + az * half_n + tz * half_t * k * 0.95
                for s0, s1, w, nm, cl in segs:
                    if abs(px - s0[0]) > 200 and abs(px - s1[0]) > 200: continue
                    need = w / 2 + sidewalk_w(w) + 1
                    d = seg_dist(px, pz, s0, s1)
                    if need - d > pen: pen = need - d
            if pen > 0:
                pen = min(pen, (D if abs(sgn) == 1 else W) - 6)
                if abs(sgn) == 1:
                    D -= pen; cx -= ax * pen / 2; cz -= az * pen / 2
                else:
                    W -= pen; cx -= ax * pen / 2; cz -= az * pen / 2
    if W < 9 or D < 9 or (cx - cx == 0 and in_park(cx, cz, 10)):
        skipped["setback"] = skipped.get("setback", 0) + 1; continue
    yaw = math.atan2(nx, -nz)   # 정면(-Z 로컬)이 (nx,nz) 를 보게 하는 Y 회전 (Roblox: LookVector = (−sin, 0, −cos)·... 빌드 쪽에서 lookAt 사용)
    lv = t.get("building:levels")
    try: lv = int(float(lv))
    except: lv = None
    bt = t.get("building"); name = t.get("name", "")
    footprint = W * D
    on_major = rname in MAJOR and dist < 40
    inside = in_block(cx, cz, 30)
    if bt == "apartments" or "아파트" in name:
        typ = "apt_modern"
    elif on_major and footprint > 2500:
        typ = "office_glass" if (lv or 0) >= 12 or footprint > 9000 else "office_mid"
    elif rw >= 45 and footprint > 900:
        typ = "shop_kr"
    elif footprint < 2600:
        typ = "villa_kr"
    else:
        typ = "shop_kr"
    if bt in ("school", "hospital", "church"): typ = "office_mid"
    floors = lv or (14 if typ == "office_glass" else 7 if typ == "office_mid" else 5 if typ == "shop_kr" else 4)
    tier = 1 if inside else 3
    buildings.append({"id": e["id"], "cx": round(cx, 1), "cz": round(cz, 1), "w": round(W, 1), "d": round(D, 1),
                      "nx": round(nx, 4), "nz": round(nz, 4), "type": typ, "floors": floors, "tier": tier, "name": name, "road": rname})

# 건물끼리 겹침 해소: 회전 사각형(OBB) 분리축 검사. 겹치면 작은 쪽을 줄이고(최대 3번), 그래도 겹치면 뺌
def corners(b):
    fx, fz = b["nx"], b["nz"]; sx, sz = -fz, fx
    hw, hd = b["w"] / 2 + 0.6, b["d"] / 2 + 0.6
    return [(b["cx"] + sx * a * hw + fx * c * hd, b["cz"] + sz * a * hw + fz * c * hd) for a, c in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
def overlap(b1, b2):
    if abs(b1["cx"] - b2["cx"]) > (b1["w"] + b1["d"] + b2["w"] + b2["d"]) / 1.4: return False
    if abs(b1["cz"] - b2["cz"]) > (b1["w"] + b1["d"] + b2["w"] + b2["d"]) / 1.4: return False
    c1, c2 = corners(b1), corners(b2)
    for poly in (c1, c2):
        for i in range(4):
            ax, az = poly[(i + 1) % 4][0] - poly[i][0], poly[(i + 1) % 4][1] - poly[i][1]
            nx_, nz_ = -az, ax
            p1 = [x * nx_ + z * nz_ for x, z in c1]; p2 = [x * nx_ + z * nz_ for x, z in c2]
            if max(p1) <= min(p2) or max(p2) <= min(p1): return False
    return True
buildings.sort(key=lambda b: -(b["w"] * b["d"]))
kept = []
dropped_ov = 0
for b in buildings:
    ok = True
    for tries in range(4):
        hit = [k for k in kept if overlap(b, k)]
        if not hit: break
        if tries == 3 or b["w"] < 10 or b["d"] < 10: ok = False; break
        b["w"] = round(b["w"] * 0.85, 1); b["d"] = round(b["d"] * 0.85, 1)
    if ok: kept.append(b)
    else: dropped_ov += 1
buildings = kept
skipped["overlap"] = dropped_ov

layout = {"origin": "강남역 사거리, 테헤란로 +X, 블록 안 +Z, 1m=3스터드", "block": [BW, BH], "park": PARK, "roads": roads, "buildings": buildings,
          "credit": "지도 데이터 © OpenStreetMap contributors (ODbL)"}
json.dump(layout, open(out, "w"), ensure_ascii=False)
from collections import Counter
print("roads", len(roads), "buildings", len(buildings), "skipped", skipped)
print(Counter(b["type"] for b in buildings), Counter(b["tier"] for b in buildings))
