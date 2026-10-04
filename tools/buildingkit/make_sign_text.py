# 간판 글씨 이미지: 흰 글씨 + 투명 배경 (Roblox Decal.Color3 로 색 입힘). 가로(h) / 세로 한 글자씩(v).
# 실행: Blender --background --factory-startup --python tools/buildingkit/make_sign_text.py
# 입력 assets/source/sign_texts.json, 출력 assets/textures/kit22/signs/<h|v>_<번호>.png + index.json (글자, 파일, 가로세로비)
import bpy, json, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "textures", "kit22", "signs")
os.makedirs(OUT, exist_ok=True)
data = json.load(open(os.path.join(ROOT, "assets", "source", "sign_texts.json")))
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FALLBACK = "/System/Library/Fonts/Supplemental/AppleGothic.ttf"

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "FLAT"
sc.display.shading.color_type = "SINGLE"
sc.display.shading.single_color = (1, 1, 1)
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.display.render_aa = "32"
try:
    font = bpy.data.fonts.load(FONT)
except Exception as e:
    print("ttc 실패, 대체", e)
    font = bpy.data.fonts.load(FALLBACK)
cd = bpy.data.cameras.new("Cam")
cd.type = "ORTHO"
cam = bpy.data.objects.new("Cam", cd)
sc.collection.objects.link(cam)
sc.camera = cam
index = []
def render(text, kind, i):
    cu = bpy.data.curves.new("T", "FONT")
    cu.body = text if kind == "h" else "\n".join(list(text))
    cu.font = font
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.space_line = 0.95
    cu.offset = 0.035  # 획을 굵게 (간판 글씨)
    ob = bpy.data.objects.new("T", cu)
    sc.collection.objects.link(ob)
    bpy.context.view_layer.update()
    # 실제 모양 경계 (메시로 바꿔서)
    dg = bpy.context.evaluated_depsgraph_get()
    me = ob.evaluated_get(dg).to_mesh()
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    ob.evaluated_get(dg).to_mesh_clear()
    pad = 0.08 * (y1 - y0 if kind == "h" else x1 - x0)
    w, h = (x1 - x0) + 2 * pad, (y1 - y0) + 2 * pad
    cam.location = ((x0 + x1) / 2, (y0 + y1) / 2, 10)
    cam.rotation_euler = (0, 0, 0)
    cd.ortho_scale = max(w, h)
    PX = 160 if kind == "h" else 120  # 글자 높이(가로형) / 글자 폭(세로형) 기준 픽셀
    if kind == "h":
        rh = PX; rw = int(PX * w / h)
    else:
        rw = PX; rh = int(PX * h / w)
    k = min(1.0, 1024 / max(rw, rh))
    sc.render.resolution_x, sc.render.resolution_y = max(8, int(rw * k)), max(8, int(rh * k))
    name = "%s_%02d" % (kind, i)
    sc.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(ob)
    index.append({"text": text, "kind": kind, "file": name + ".png", "aspect": round(w / h, 3)})
for i, t in enumerate(data["h"]): render(t, "h", i)
for i, t in enumerate(data["v"]): render(t, "v", i)
json.dump(index, open(os.path.join(OUT, "index.json"), "w"), ensure_ascii=False, indent=1)
print("WROTE", len(index))
