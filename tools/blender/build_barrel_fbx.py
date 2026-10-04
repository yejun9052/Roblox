"""19번 드럼통 장식 메시 생성 + FBX 내보내기.

실행 (저장소 루트에서):
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/blender/build_barrel_fbx.py
입력:  assets/source/barrel_014016_tris.txt  (work/studio19_extract_barrel.luau 출력)
출력:  assets/fbx/barrel_detail_v2.fbx  (Barrel_steel / Barrel_plate / Barrel_faded 3개 메시)
좌표:  Roblox (x, y, z) -> Blender (x, -z, y). 1 Blender 단위 = 1 스터드. 원점 = 드럼통 바닥 중심.
주의: 2026-10-03 MCP 세션은 전체를 한 메시로 정리한 뒤 재질별로 분리했다(tris 792/92/36).
이 스크립트는 재질별로 바로 정리하므로 삼각형 수가 조금 다를 수 있다. 2026-10-03 v2 로 헤드리스 실행함.
"""
import os
import bpy
import bmesh

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "assets", "source", "barrel_014016_tris.txt")
OUT = os.path.join(ROOT, "assets", "fbx", "barrel_detail_v2.fbx")
# v2: plate 의 B 1개(뚜껑 원판)와 steel 의 B 2개(볼트 와셔)는 원본이 Shape=Cylinder Part 라
# 박스로 넣으면 사각 판이 튀어나온다. 이 셋은 메시에서 빼고 원본 Part 를 그대로 둔다. faded 의 B 3개는 실제 Block.
SKIP_BOX = {"plate", "steel"}
MATS = ["steel", "plate", "faded"]
COLORS = {"steel": (0.25, 0.25, 0.25, 1), "plate": (0.35, 0.38, 0.2, 1), "faded": (0.6, 0.45, 0.25, 1)}
BOX_QUADS = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]


def conv(x, y, z):
    return (x, -z, y)


def build_per_material():
    lines = open(SRC).read().strip().split("\n")
    meshes = {m: bmesh.new() for m in MATS}
    for ln in lines[1:]:
        t = ln.split()
        kind, m = t[0], t[1]
        nums = list(map(float, t[2:]))
        if kind == "B" and m in SKIP_BOX:
            continue
        bm = meshes[m]
        vs = [bm.verts.new(conv(*nums[i:i + 3])) for i in range(0, len(nums), 3)]
        try:
            if kind == "W":
                bm.faces.new(vs)
            else:
                for q in BOX_QUADS:
                    bm.faces.new([vs[i] for i in q])
        except ValueError:
            pass  # 퇴화 삼각형
    objs = []
    col = bpy.data.collections.get("Props_19") or bpy.data.collections.new("Props_19")
    if col.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(col)
    for m, bm in meshes.items():
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.003)
        bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0005)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        name = "Barrel_" + m
        me = bpy.data.meshes.new(name + "_mesh")
        bm.to_mesh(me)
        bm.free()
        mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        mat.diffuse_color = COLORS[m]
        me.materials.append(mat)
        old = bpy.data.objects.get(name)
        if old:
            bpy.data.objects.remove(old, do_unlink=True)
        ob = bpy.data.objects.new(name, me)
        col.objects.link(ob)
        objs.append(ob)
        print(name, "tris", sum(len(p.vertices) - 2 for p in me.polygons), "dims", tuple(round(d, 3) for d in ob.dimensions))
    return objs


def export(objs):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, object_types={'MESH'},
                             apply_unit_scale=True, global_scale=1.0,
                             axis_forward='-Z', axis_up='Y', mesh_smooth_type='FACE')
    print("exported", OUT)


export(build_per_material())
