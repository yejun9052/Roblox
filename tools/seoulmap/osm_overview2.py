# 강남 북부 전체 개요도 → 페이지용 SVG 조각(클래스 색, 다크모드 대응). 단위 m, 북쪽 위.
import json, math
lat0, lat1, lon0, lon1 = 37.474, 37.534, 127.019, 127.078
KX = 111320 * math.cos(math.radians((lat0 + lat1) / 2)); KY = 110540
def xy(lat, lon): return ((lon - lon0) * KX, (lat1 - lat) * KY)
W, H = (lon1 - lon0) * KX, (lat1 - lat0) * KY
d = json.load(open("gangnam_big.json"))["elements"]
b = json.load(open("gangnam_bld_centers.json"))["elements"]
P = []
def pl(g): return " ".join("%.0f,%.0f" % xy(p["lat"], p["lon"]) for p in g)
# 한강: 강 중심선을 굵게 (실제 폭 약 1 km)
for e in d:
    t = e.get("tags", {}); g = e.get("geometry")
    if g and t.get("waterway") == "river" and t.get("name") == "한강":
        P.append('<polyline class="wl" points="%s" stroke-width="900"/>' % pl(g))
for e in d:
    t = e.get("tags", {}); g = e.get("geometry")
    if not g: continue
    if t.get("leisure") in ("park", "garden", "stadium") or t.get("landuse") in ("grass", "forest", "cemetery") or t.get("natural") == "wood":
        P.append('<polygon class="pk" points="%s"/>' % pl(g))
P.append('<ellipse class="pk" cx="2539" cy="2617" rx="378" ry="273"/>')  # 선정릉 숲 (관계형 데이터라 직접)
for e in d:
    t = e.get("tags", {}); g = e.get("geometry")
    if not g: continue
    if t.get("natural") == "water": P.append('<polygon class="wa" points="%s"/>' % pl(g))
    elif t.get("waterway") in ("river", "stream") and t.get("name") != "한강":
        P.append('<polyline class="wl" points="%s" stroke-width="%d"/>' % (pl(g), 90 if t.get("name") == "탄천" else 45))
RW = {"motorway": 34, "trunk": 34, "primary": 26, "secondary": 18, "tertiary": 13, "motorway_link": 10, "trunk_link": 10, "primary_link": 9, "residential": 5, "unclassified": 5, "living_street": 4}
for cls in ("residential", "unclassified", "living_street", "tertiary", "secondary", "primary_link", "trunk_link", "motorway_link", "primary", "trunk", "motorway"):
    for e in d:
        t = e.get("tags", {}); g = e.get("geometry")
        if g and t.get("highway") == cls:
            P.append('<polyline class="%s" points="%s" stroke-width="%d"/>' % ("rb" if RW[cls] >= 18 else "rs", pl(g), RW[cls]))
def col(t):
    bt = t.get("building"); n = t.get("name", "")
    if bt == "apartments" or "아파트" in n: return "ba"
    if bt in ("commercial", "office", "retail", "hotel") or any(k in n for k in ("타워", "빌딩", "센터", "프라자")): return "bc"
    if bt in ("school", "church", "kindergarten", "public", "hospital"): return "bp"
    return "br"
for e in b:
    c = e.get("center")
    if not c: continue
    x, y = xy(c["lat"], c["lon"])
    P.append('<rect class="%s" x="%.0f" y="%.0f" width="10" height="10"/>' % (col(e.get("tags", {})), x - 5, y - 5))
open("overview_frag.svg", "w").write("".join(P))
print(round(W), round(H), sum(len(p) for p in P))
