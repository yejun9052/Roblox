# OSM(json, out geom) → SVG 평면도. 미터 좌표(경위도 국지 투영), 북쪽 위.
import json, math, sys
src, out = sys.argv[1], sys.argv[2]
d = json.load(open(src))
els = d["elements"]
lat0, lon0 = 37.4900, 127.0265
LAT1 = 37.5015
KX = 111320 * math.cos(math.radians((lat0 + LAT1) / 2))
KY = 110540
def xy(p):
    return ((p["lon"] - lon0) * KX, (LAT1 - p["lat"]) * KY)
W = (127.0405 - lon0) * KX
H = (LAT1 - lat0) * KY
ROADW = {"trunk": 40, "primary": 40, "primary_link": 14, "secondary": 25, "tertiary": 16, "residential": 7, "living_street": 6,
         "service": 4, "footway": 0, "pedestrian": 8, "busway": 0, "steps": 0, "cycleway": 0, "path": 0, "platform": 0}
parts = []
def poly(e, fill, stroke="#9a968e", sw=0.6, op=1):
    g = e.get("geometry")
    if not g: return
    pts = " ".join("%.1f,%.1f" % xy(p) for p in g)
    parts.append('<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" opacity="%s"/>' % (pts, fill, stroke, sw, op))
# 바탕: 공원/녹지
for e in els:
    t = e.get("tags", {})
    if t.get("leisure") in ("park", "garden", "playground", "pitch"):
        poly(e, "#b9d8a8", "#8fb07f")
    elif t.get("amenity") == "school":
        poly(e, "#d8c3a0", "#a8946e", op=0.8)
    elif t.get("amenity") == "parking":
        poly(e, "#dcdad4", "#b0aca4")
# 도로
for e in els:
    t = e.get("tags", {})
    hw = t.get("highway")
    if hw and ROADW.get(hw, 0) > 0 and e.get("geometry"):
        pts = " ".join("%.1f,%.1f" % xy(p) for p in e["geometry"])
        parts.append('<polyline points="%s" fill="none" stroke="#cfccc5" stroke-width="%d" stroke-linecap="round" stroke-linejoin="round"/>' % (pts, ROADW[hw]))
# 건물
def bcolor(t):
    lv = t.get("building:levels")
    try: lv = int(float(lv))
    except: lv = None
    b = t.get("building")
    n = t.get("name", "")
    if b in ("apartments",) or "아파트" in n: return "#f0c98a"
    if b in ("commercial", "office", "retail") or (lv and lv >= 8) or any(k in n for k in ("타워", "빌딩", "센터", "프라자", "오피스텔")): return "#f2b8b5"
    if b in ("school", "hospital", "church", "public", "government"): return "#c9d7e8"
    return "#f6e7a6"
for e in els:
    t = e.get("tags", {})
    if "building" in t:
        poly(e, bcolor(t), "#8d897f", 0.5)
svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %.0f %.0f" width="%.0f" height="%.0f"><rect width="100%%" height="100%%" fill="#f3f1ec"/>%s</svg>' % (W, H, W, H, "".join(parts))
open(out, "w").write(svg)
print("W,H meters", round(W), round(H))
