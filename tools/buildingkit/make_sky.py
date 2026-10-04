# 22번 스카이박스: 분홍·보라 노을 + 솜구름. Blender 내장 파이썬(numpy) 으로 6면 PNG.
# 실행: Blender --background --factory-startup --python tools/buildingkit/make_sky.py -- [이름(기본 dusk)]
# Roblox 면 방향 (2026-10-03 색 시험으로 확인): Ft=-Z(오른쪽 +X), Lf=+X(오른쪽 +Z), Bk=+Z(오른쪽 -X), Rt=-X(오른쪽 -Z),
#   Up=+Y(이미지 위쪽 = +X, 오른쪽 = -Z). Dn 은 균일색.
import bpy, os, sys, math
import numpy as np

NAME = (sys.argv[sys.argv.index("--") + 1:] or ["dusk"])[0] if "--" in sys.argv else "dusk"
OUT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "textures", "kit22", "sky"))
os.makedirs(OUT, exist_ok=True)
N = 1024
SUN = np.array([-0.973, 0.115, 0.199])
SUN /= np.linalg.norm(SUN)

rng = np.random.default_rng(22)
G = 256
LAT = rng.random((G, G)).astype(np.float32)


def vnoise(x, y):
    xi = np.floor(x).astype(np.int64)
    yi = np.floor(y).astype(np.int64)
    xf = x - xi
    yf = y - yi
    u = xf * xf * (3 - 2 * xf)
    v = yf * yf * (3 - 2 * yf)
    a = LAT[xi % G, yi % G]
    b = LAT[(xi + 1) % G, yi % G]
    c = LAT[xi % G, (yi + 1) % G]
    d = LAT[(xi + 1) % G, (yi + 1) % G]
    return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v


def fbm(x, y, oct=6):
    s = np.zeros_like(x)
    amp, f, tot = 0.5, 1.0, 0.0
    for _ in range(oct):
        s += amp * vnoise(x * f, y * f)
        tot += amp
        amp *= 0.5
        f *= 2.03
    return s / tot


def lerp(a, b, t):
    return a + (b - a) * t[..., None]


def c(r, g, b):
    return np.array([r, g, b], dtype=np.float32) / 255.0


# 프리셋: dusk = 분홍·보라 노을(참고 이미지), ash = 먼지·연기 낀 탁한 하늘(아포칼립스)
PRESETS = {
    "dusk": dict(h=[(255, 196, 168), (246, 170, 186), (196, 158, 214), (118, 120, 196)], glow=(255, 200, 150), glowk=1.0,
                 thr=0.47, cdark=(170, 140, 196), clit=(255, 214, 210), cover=0.92, below=(226, 176, 176)),
    "dark": dict(h=[(168, 120, 84), (128, 112, 100), (98, 96, 96), (64, 68, 76)], glow=(255, 140, 70), glowk=0.45,
                 thr=0.30, cdark=(62, 58, 58), clit=(160, 124, 96), cover=0.97, below=(96, 88, 80)),
    "ash": dict(h=[(222, 178, 128), (196, 170, 140), (160, 152, 144), (112, 116, 122)], glow=(255, 170, 90), glowk=0.7,
                thr=0.36, cdark=(104, 96, 92), clit=(214, 180, 146), cover=0.95, below=(150, 136, 120)),
}
P = PRESETS[NAME]


def sky_color(d):
    y = d[..., 1]
    h = np.clip(y, -1, 1)
    # 높이별 그라데이션 (지평선 → 위)
    t1 = np.clip(h / 0.08, 0, 1)
    t2 = np.clip((h - 0.08) / 0.25, 0, 1)
    t3 = np.clip((h - 0.33) / 0.67, 0, 1)
    col = lerp(np.broadcast_to(c(*P["h"][0]), d.shape), np.broadcast_to(c(*P["h"][1]), d.shape), t1)
    col = lerp(col, np.broadcast_to(c(*P["h"][2]), d.shape), t2)
    col = lerp(col, np.broadcast_to(c(*P["h"][3]), d.shape), t3)
    # 해 쪽 빛무리
    sd = np.clip((d * SUN).sum(-1), 0, 1)
    glow = (sd ** 10 * 0.32 + sd ** 120 * 0.5 + sd ** 900 * 0.8) * P["glowk"]
    col = col + glow[..., None] * c(*P["glow"])
    # 구름 (y>0 평면 투영)
    yy = np.maximum(y, 0.04)
    px = d[..., 0] / yy * 0.9
    pz = d[..., 2] / yy * 0.9
    n = fbm(px * 0.9 + 37.0, pz * 0.9 + 11.0)
    n2 = fbm(px * 2.6 + 5.0, pz * 2.6 + 91.0, 4)
    dens = np.clip((n * 0.8 + n2 * 0.3 - P["thr"]) * 3.2, 0, 1)
    fade = np.clip((y - 0.02) / 0.22, 0, 1) * np.clip(1 - (y - 0.55) / 0.45, 0.25, 1)
    dens = dens * fade
    # 구름 색: 해 쪽은 밝은 분홍·주황, 반대쪽은 라벤더 그늘
    lit = np.clip(n2 * 1.4 - 0.2, 0, 1) * 0.6 + sd[..., None][..., 0] * 0.4
    ccol = lerp(np.broadcast_to(c(*P["cdark"]), d.shape), np.broadcast_to(c(*P["clit"]), d.shape), np.clip(lit, 0, 1))
    ccol = ccol + (sd ** 4)[..., None] * c(60, 30, 0)
    col = lerp(col, ccol, dens * P["cover"])
    # 지평선 아래
    below = np.clip(-h / 0.05, 0, 1)
    col = lerp(col, np.broadcast_to(c(*P["below"]), d.shape), below)
    return np.clip(col, 0, 1)


def face_dirs(face):
    a = (np.arange(N) + 0.5) / N * 2 - 1
    u, v = np.meshgrid(a, -a)  # u: 왼→오, v: 위가 +1 (행 0 = 위)
    one = np.ones_like(u)
    if face == "Ft":
        d = np.stack([u, v, -one], -1)
    elif face == "Lf":
        d = np.stack([one, v, u], -1)
    elif face == "Bk":
        d = np.stack([-u, v, one], -1)
    elif face == "Rt":
        d = np.stack([-one, v, -u], -1)
    elif face == "Up":
        d = np.stack([v, one, -u], -1)
    else:
        d = np.stack([u, -one, v], -1)
    return d / np.linalg.norm(d, axis=-1, keepdims=True)


def save(path, rgb):
    h, w = rgb.shape[:2]
    img = bpy.data.images.new("s", w, h)
    # Blender 픽셀은 아래 행부터
    px = np.concatenate([rgb[::-1], np.ones((h, w, 1), dtype=np.float32)], axis=2).ravel()
    img.pixels = px
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


for face in ["Ft", "Lf", "Bk", "Rt", "Up", "Dn"]:
    if face == "Dn":
        rgb = np.broadcast_to(c(*P["below"]), (64, 64, 3)).copy()
    else:
        rgb = sky_color(face_dirs(face)).astype(np.float32)
    p = os.path.join(OUT, "%s_%s.png" % (NAME, face))
    save(p, rgb)
    print("WROTE", p)
