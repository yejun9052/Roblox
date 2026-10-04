"""19번 소품 일괄 최적화: work/studio19_extract_props.luau 가 보낸 삼각형 목록 → 메시 여러 개를 담은 FBX.

실행 (저장소 루트에서):
  /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/blender/build_props_fbx.py -- <phase>
입력:  assets/source/props19_p<phase>_meshes.txt   ("M <이름> <삼각형수>" 다음 줄마다 x y z ×3, 메시 bbox 중심 기준 Roblox 좌표)
출력:  assets/fbx/props19_p<phase>.fbx               (객체 이름 = 메시 이름)
좌표:  Roblox (x, y, z) -> Blender (x, -z, y). barrel 과 같은 내보내기 설정 → Studio Import Queue 에서 cm 단위·Y축 180° 로 들어온다.
UV:   면 법선 주축 기준 박스 투영, 4 스터드 = 1 타일 (MeshPart 재질 텍스처용).
"""
import os
import sys
import bpy
import bmesh

phase = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "1"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "source", f"props19_p{phase}_meshes.txt")
OUT = os.path.join(ROOT, "assets", "fbx", f"props19_p{phase}.fbx")
TILE = 4.0


def conv(x, y, z):
    return (x, -z, y)


def parse():
    meshes, cur = [], None
    for ln in open(SRC):
        t = ln.split()
        if not t:
            continue
        if t[0] == "M":
            cur = (t[1], [])
            meshes.append(cur)
        else:
            v = list(map(float, t))
            cur[1].append((conv(*v[0:3]), conv(*v[3:6]), conv(*v[6:9])))
    return meshes


def build(name, tris):
    bm = bmesh.new()
    for tri in tris:
        vs = [bm.verts.new(p) for p in tri]
        try:
            bm.faces.new(vs)
        except ValueError:
            pass
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][ax]
        for lp in f.loops:
            co = lp.vert.co
            lp[uv].uv = (co[a] / TILE, co[b] / TILE)
    me = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob, len(me.polygons)


bpy.ops.wm.read_factory_settings(use_empty=True)
objs, total = [], 0
for name, tris in parse():
    ob, n = build(name, tris)
    objs.append(ob)
    total += n
for ob in objs:
    ob.select_set(True)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, object_types={'MESH'},
                         apply_unit_scale=True, global_scale=1.0,
                         axis_forward='-Z', axis_up='Y', mesh_smooth_type='FACE')
print("PROPS19", "meshes", len(objs), "tris", total, "->", OUT)
