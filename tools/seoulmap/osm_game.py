# 강남역~역삼역 슈퍼블록: OSM → 회전(테헤란로 수평)·축척(1 m = 3 스터드) → 게임 평면도 SVG 조각 (CSS 변수 색)
import json, math
d = json.load(open("gangnam.json")); els = d["elements"]
lat0, lon0, LAT1 = 37.4900, 127.0265, 37.5015
KX = 111320 * math.cos(math.radians((lat0 + LAT1) / 2)); KY = 110540
O = (103, 387)                      # 강남역 사거리 (미터, y 아래)
TH = math.radians(20.6)             # 테헤란로를 수평으로
S = 3.0                             # 1 m = 3 스터드
M = 90                              # 여백(m)
BW, BH = 877, 585                   # 블록(m)
def tf(p):
    x = (p["lon"] - lon0) * KX - O[0]; y = (LAT1 - p["lat"]) * KY - O[1]
    xr = x * math.cos(TH) - y * math.sin(TH); yr = x * math.sin(TH) + y * math.cos(TH)
    return ((xr + M) * S, (yr + M) * S)
W, H = (BW + 2 * M) * S, (BH + 2 * M) * S
def inside(g):
    xs = [tf(p) for p in g]
    return any(-50 <= x <= W + 50 and -50 <= y <= H + 50 for x, y in xs)
ROADW = {"trunk": 50, "primary": 50, "primary_link": 14, "secondary": 30, "tertiary": 18, "residential": 8, "living_street": 7, "service": 5, "pedestrian": 10}
out = []
def pts(g): return " ".join("%.0f,%.0f" % tf(p) for p in g)
for e in els:
    t = e.get("tags", {}); g = e.get("geometry")
    if not g or not inside(g): continue
    if t.get("leisure") in ("park", "garden", "playground", "pitch"):
        out.append('<polygon points="%s" fill="var(--green)" stroke="var(--road-edge)" stroke-width="2"/>' % pts(g))
    elif t.get("amenity") == "parking":
        out.append('<polygon points="%s" fill="var(--road)" stroke="var(--road-edge)" stroke-width="2"/>' % pts(g))
for e in els:
    t = e.get("tags", {}); g = e.get("geometry"); hw = t.get("highway")
    if not g or not inside(g) or hw not in ROADW: continue
    w = ROADW[hw] * S
    out.append('<polyline points="%s" fill="none" stroke="var(--road)" stroke-width="%.0f" stroke-linecap="round" stroke-linejoin="round"/>' % (pts(g), w))
def cls(t):
    lv = t.get("building:levels")
    try: lv = int(float(lv))
    except: lv = None
    b = t.get("building"); n = t.get("name", "")
    if b == "apartments" or "아파트" in n: return "var(--res3)"
    if b in ("commercial", "office", "retail") or (lv and lv >= 8) or any(k in n for k in ("타워", "빌딩", "센터", "프라자", "오피스텔")): return "var(--com)"
    if b in ("school", "hospital", "church", "public", "government"): return "var(--civic)"
    return "var(--res1)"
nb = 0
for e in els:
    t = e.get("tags", {}); g = e.get("geometry")
    if "building" in t and g and inside(g):
        out.append('<polygon points="%s" fill="%s" stroke="var(--road-edge)" stroke-width="1.5"/>' % (pts(g), cls(t))); nb += 1
open("gangnam_game_frag.svg", "w").write("".join(out))
print("W,H studs", round(W), round(H), "buildings", nb, "bytes", sum(len(x) for x in out))
