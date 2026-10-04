# 22번 건물 키트 텍스처: Blender 헤드리스(Cycles)로 창문/문/난간 등을 3D 로 만들어 정면 직교 렌더 → PNG.
# 실행: /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python tools/buildingkit/make_textures.py -- [이름 ...]
# 출력: assets/textures/kit22/<이름>.png  (1 단위 = 1 스터드, 텍스처는 개구부 전체를 덮음)
import bpy, bmesh, math, os, random, sys

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "textures", "kit22")
OUT = os.path.abspath(OUT)
os.makedirs(OUT, exist_ok=True)
PX_PER_STUD = 112
ONLY = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    return sc


def world_sky(sc, strength=1.0):
    # 게임 안에서 다시 조명되므로 텍스처는 균일광(알베도 + 틈새 그늘)으로 굽는다
    w = bpy.data.worlds.new("Flat")
    sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (1, 1, 1, 1)
    bg.inputs[1].default_value = 0.9 * strength
    return
    w = bpy.data.worlds.new("Sky")
    sc.world = w
    w.use_nodes = True
    nt = w.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    bg = nt.nodes.new("ShaderNodeBackground")
    out = nt.nodes.new("ShaderNodeOutputWorld")
    nt.links.new(tc.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], bg.inputs[0])
    nt.links.new(bg.outputs[0], out.inputs[0])
    cr = ramp.color_ramp
    cr.elements[0].position = 0.0
    cr.elements[0].color = (0.30, 0.26, 0.28, 1)   # 지면 반사
    cr.elements[1].position = 1.0
    cr.elements[1].color = (0.35, 0.45, 0.75, 1)   # 하늘 위
    e = cr.elements.new(0.5)
    e.color = (1.0, 0.62, 0.55, 1)                 # 지평선 분홍
    e = cr.elements.new(0.62)
    e.color = (0.72, 0.58, 0.85, 1)                # 보라
    bg.inputs[1].default_value = strength


def sun(rot=(math.radians(35), math.radians(-15), math.radians(-20)), energy=1.0, color=(1.0, 1.0, 1.0)):
    d = bpy.data.lights.new("Sun", "SUN")
    d.energy = energy
    d.color = color
    d.angle = math.radians(8)
    o = bpy.data.objects.new("Sun", d)
    o.rotation_euler = rot
    bpy.context.scene.collection.objects.link(o)


def mat(name, color, rough=0.5, metal=0.0, emit=None, emit_str=0.0, alpha=1.0, transmission=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if transmission:
        b.inputs["Transmission Weight"].default_value = transmission
        b.inputs["IOR"].default_value = 1.45
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = emit_str
    if alpha < 1:
        b.inputs["Alpha"].default_value = alpha
    return m


def glass_mat(name, tint=(0.07, 0.11, 0.19), alpha=0.42, streak=0.6):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*tint, 1)
    b.inputs["Roughness"].default_value = 0.1
    b.inputs["Alpha"].default_value = alpha
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs[0])
    add = nt.nodes.new("ShaderNodeMath")
    add.operation = "ADD"
    nt.links.new(sep.outputs["X"], add.inputs[0])
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = 0.8
    nt.links.new(sep.outputs["Z"], mul.inputs[0])
    nt.links.new(mul.outputs[0], add.inputs[1])
    sc_ = nt.nodes.new("ShaderNodeMath")
    sc_.operation = "MULTIPLY"
    sc_.inputs[1].default_value = 0.22
    nt.links.new(add.outputs[0], sc_.inputs[0])
    fr = nt.nodes.new("ShaderNodeMath")
    fr.operation = "FRACT"
    nt.links.new(sc_.outputs[0], fr.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(fr.outputs[0], ramp.inputs[0])
    cr = ramp.color_ramp
    cr.interpolation = "EASE"
    cr.elements[0].position = 0.0
    cr.elements[0].color = (0.0, 0.0, 0.0, 1)
    cr.elements[1].position = 0.18
    cr.elements[1].color = (0.0, 0.0, 0.0, 1)
    for pos, v in ((0.22, 1.0), (0.30, 0.15), (0.34, 0.7), (0.40, 0.0)):
        e = cr.elements.new(pos)
        e.color = (v, v, v, 1)
    # 반사색: 위는 연보라, 아래는 분홍 (참고 이미지 노을)
    sky = nt.nodes.new("ShaderNodeMix")
    sky.data_type = "RGBA"
    nt.links.new(sep.outputs["Z"], sky.inputs[0])
    sky.inputs[6].default_value = (1.0, 0.78, 0.80, 1)
    sky.inputs[7].default_value = (0.78, 0.82, 1.0, 1)
    em = nt.nodes.new("ShaderNodeMath")
    em.operation = "MULTIPLY"
    em.inputs[1].default_value = streak
    nt.links.new(ramp.outputs[0], em.inputs[0])
    nt.links.new(sky.outputs[2], b.inputs["Emission Color"])
    nt.links.new(em.outputs[0], b.inputs["Emission Strength"])
    return m


_JIT = [0]


def box(name, cx, cy, cz, sx, sy, sz, material, bevel=0.03):
    # 같은 깊이에 겹친 앞면은 Cycles 에서 검은 얼룩이 생김 → 상자마다 아주 조금씩 앞뒤로 어긋나게
    _JIT[0] += 1
    cz += (_JIT[0] % 7) * 0.0015
    # 좌표: x 가로, y 세로(위), z 앞쪽(카메라 방향). Blender 에서는 (x, -z, y) 대신 (x, z_front→-y) 로 둔다.
    bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, -cz, cy))
    o = bpy.context.active_object
    o.name = name
    o.scale = (sx, sz, sy)
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        md = o.modifiers.new("bev", "BEVEL")
        md.width = bevel
        md.segments = 2
    o.data.materials.append(material)
    return o


def cyl(name, cx, cy, cz, r, length, axis, material, verts=16):
    rot = {"x": (0, math.radians(90), 0), "y": (0, 0, 0), "z": (math.radians(90), 0, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=length, location=(cx, -cz, cy), rotation=rot)
    o = bpy.context.active_object
    o.name = name
    bpy.ops.object.shade_smooth()
    o.data.materials.append(material)
    return o


def camera(w, h):
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("Cam")
    cd.type = "ORTHO"
    cd.ortho_scale = max(w, h)
    cam = bpy.data.objects.new("Cam", cd)
    cam.location = (0, -20, h / 2)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.resolution_x = int(round(w * PX_PER_STUD))
    sc.render.resolution_y = int(round(h * PX_PER_STUD))
    # 큰 쪽 기준 512~1024 사이로
    m = max(sc.render.resolution_x, sc.render.resolution_y)
    if m > 1024:
        k = 1024 / m
        sc.render.resolution_x = int(sc.render.resolution_x * k)
        sc.render.resolution_y = int(sc.render.resolution_y * k)


def render(name):
    sc = bpy.context.scene
    sc.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("WROTE", sc.render.filepath, sc.render.resolution_x, sc.render.resolution_y)


def curtain(name, x0, x1, y0, y1, z, color, folds=7, amp=0.06):
    # 주름진 커튼: 세로 주름 사인파 평면
    m = mat(name + "_m", color, rough=0.9)
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    nx, ny = 24, 2
    vs = []
    for j in range(ny + 1):
        row = []
        for i in range(nx + 1):
            t = i / nx
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * j / ny
            zz = z + amp * math.sin(t * folds * 2 * math.pi)
            row.append(bm.verts.new((x, -zz, y)))
        vs.append(row)
    for j in range(ny):
        for i in range(nx):
            bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
    bm.to_mesh(me)
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    for p in o.data.polygons:
        p.use_smooth = True
    o.data.materials.append(m)
    return o


# ---------- 창문 ----------
def window(name, W=4.0, H=6.0, curtain_color=(0.93, 0.86, 0.78), state="clean", frame_color=(0.92, 0.91, 0.88), seed=1):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    fr = mat("frame", frame_color, rough=0.45)
    glass = glass_mat("glass")
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    woods = [mat("wood%d" % i, c, rough=0.85) for i, c in enumerate([(0.30, 0.22, 0.15), (0.26, 0.20, 0.14), (0.36, 0.28, 0.19)])]
    # 안쪽 어둠 (개구부 뒤)
    box("Back", 0, H / 2, -1.6, W, H, 0.1, interior, bevel=0)
    # 개구부 안쪽 벽면(측면 그림자): 위/좌/우 리빌
    reveal = mat("reveal", (0.78, 0.76, 0.72), rough=0.8)
    # 리빌(개구부 안쪽 면)은 Roblox 쪽 벽 두께가 만든다 → 텍스처는 창틀이 가장자리까지
    fz = -0.35  # 창틀 앞면 깊이
    t = 0.3
    box("FrameL", -W / 2 + t / 2, H / 2, fz, t, H + 0.2, 0.25, fr, bevel=0.02)
    box("FrameR", W / 2 - t / 2, H / 2, fz, t, H + 0.2, 0.25, fr, bevel=0.02)
    box("FrameT", 0, H - t / 2, fz + 0.012, W - 2 * t + 0.01, t, 0.25, fr, bevel=0.02)
    box("FrameB", 0, t / 2 + 0.02, fz + 0.012, W - 2 * t + 0.01, t + 0.05, 0.3, fr)
    transom = H * 0.76
    box("Transom", 0, transom, fz, W - 0.3, 0.16, 0.22, fr)
    box("Mullion", 0, transom / 2 + 0.1, fz, 0.16, transom - 0.2, 0.22, fr)
    # 창짝 테두리(살짝 앞)
    for sx in (-1, 1):
        cxs = sx * (W / 4 - 0.02)
        sw = W / 2 - 0.45
        box("SashT", cxs, transom - 0.16, fz + 0.04, sw, 0.1, 0.12, fr, bevel=0.02)
        box("SashB", cxs, 0.42, fz + 0.04, sw, 0.12, 0.12, fr, bevel=0.02)
        box("SashBar", cxs, transom * 0.55, fz + 0.04, sw, 0.07, 0.08, fr, bevel=0.015)
    gz = fz - 0.05
    if state in ("clean", "boarded"):
        box("Glass", 0, H / 2, gz, W - 0.3, H - 0.3, 0.02, glass, bevel=0)
        # 커튼 (반쯤 걷힘)
        cm_l = rnd.uniform(0.3, 0.45)
        cm_r = rnd.uniform(0.25, 0.42)
        curtain("CurL", -W / 2 + 0.2, -W / 2 + 0.2 + W * cm_l, 0.4, transom - 0.1, gz - 0.35, curtain_color)
        curtain("CurR", W / 2 - 0.2 - W * cm_r, W / 2 - 0.2, 0.4, transom - 0.1, gz - 0.35, curtain_color)
        curtain("CurTop", -W / 2 + 0.2, W / 2 - 0.2, transom + 0.05, H - 0.2, gz - 0.3, curtain_color, folds=10, amp=0.03)
    if state == "broken":
        # 유리 대부분 깨짐: 테두리에 남은 파편 (삼각형)
        shard = mat("shard", (0.25, 0.32, 0.42), rough=0.03)
        for k in range(22):
            side = rnd.choice(["L", "R", "T", "B", "M"])
            x = {"L": -W / 2 + 0.38, "R": W / 2 - 0.38, "M": rnd.choice([-0.16, 0.16])}.get(side, rnd.uniform(-W / 2 + 0.4, W / 2 - 0.4))
            y = {"T": transom - 0.2, "B": 0.5}.get(side, rnd.uniform(0.6, transom - 0.3))
            s = rnd.uniform(0.12, 0.38)
            bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=s, depth=0.02, location=(x, -gz, y),
                                            rotation=(math.radians(90), 0, rnd.uniform(0, 6.28)))
            bpy.context.active_object.scale = (rnd.uniform(0.4, 1.0), rnd.uniform(0.8, 1.6), 1)
            bpy.context.active_object.data.materials.append(shard)
        # 찢어진 커튼 한쪽만
        curtain("CurL", -W / 2 + 0.2, -W / 2 + 0.2 + W * 0.22, 1.2, transom - 0.1, gz - 0.5, (0.45, 0.42, 0.38))
        box("TransomGlass", 0, (transom + H) / 2, gz, W - 0.3, H - transom - 0.3, 0.02, glass, bevel=0)
    if state == "boarded":
        for k in range(3):
            y = H * (0.25 + 0.25 * k) + rnd.uniform(-0.3, 0.3)
            o = box("Board%d" % k, rnd.uniform(-0.2, 0.2), y, 0.05 + 0.13 * k, W + 0.4, 0.55, 0.12, woods[k % 3], bevel=0.02)
            o.rotation_euler = (0, math.radians(rnd.uniform(-12, 12)), 0)
            for sx in (-1, 1):
                cyl("Nail", sx * (W / 2 - 0.15), y, 0.13, 0.04, 0.05, "z", mat("nail", (0.2, 0.2, 0.2), metal=1))
    camera(W, H)
    render(name)


# ---------- 문 ----------
def door(name, W=4.0, H=8.0, color=(0.30, 0.42, 0.36), seed=2):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    paint = mat("paint", color, rough=0.5)
    fr = mat("frame", (0.92, 0.91, 0.88), rough=0.45)
    glass = glass_mat("glass")
    brass = mat("brass", (0.85, 0.65, 0.3), rough=0.3, metal=1)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    box("Back", 0, H / 2, -1.6, W, H, 0.1, interior, bevel=0)
    tH = H * 0.2
    dH = H - tH
    box("FrameL", -W / 2 + 0.15, H / 2, -0.3, 0.3, H, 0.3, fr)
    box("FrameR", W / 2 - 0.15, H / 2, -0.3, 0.3, H, 0.3, fr)
    box("FrameT", 0, H - 0.15, -0.3, W, 0.3, 0.3, fr)
    box("TransomBar", 0, dH, -0.3, W, 0.25, 0.3, fr)
    box("TransomGlass", 0, dH + tH / 2, -0.4, W - 0.4, tH - 0.3, 0.02, glass, bevel=0)
    # 문짝 2장
    for sx in (-1, 1):
        cx = sx * (W / 4 - 0.07)
        lw = W / 2 - 0.3
        box("Leaf", cx, dH / 2, -0.45, lw, dH - 0.1, 0.12, paint, bevel=0.02)
        # 패널 몰딩
        for (py, ph) in ((dH * 0.68, dH * 0.42), (dH * 0.2, dH * 0.26)):
            box("PanelTop", cx, py + ph / 2, -0.37, lw - 0.5, 0.08, 0.06, paint, bevel=0.02)
            box("PanelBot", cx, py - ph / 2, -0.37, lw - 0.5, 0.08, 0.06, paint, bevel=0.02)
            box("PanelL", cx - lw / 2 + 0.25, py, -0.37, 0.08, ph, 0.06, paint, bevel=0.02)
            box("PanelR", cx + lw / 2 - 0.25, py, -0.37, 0.08, ph, 0.06, paint, bevel=0.02)
        # 위쪽 패널은 유리
        box("LeafGlass", cx, dH * 0.68, -0.39, lw - 0.6, dH * 0.40, 0.02, glass, bevel=0)
        cyl("Knob", sx * 0.35, dH * 0.47, -0.3, 0.09, 0.15, "z", brass)
    camera(W, H)
    render(name)


# ---------- 상점 정면 ----------
def shopfront(name, W=12.0, H=9.0, color=(0.16, 0.22, 0.20), state="clean", seed=3):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    paint = mat("paint", color, rough=0.45)
    glass = glass_mat("glass", alpha=0.45)
    interior = mat("interior", (0.07, 0.065, 0.06), rough=0.9)
    shelf = mat("shelf", (0.55, 0.45, 0.35), rough=0.8)
    box("Back", 0, H / 2, -3.0, W, H, 0.1, interior, bevel=0)
    # 안쪽 선반 실루엣
    for k in range(3):
        box("Shelf", rnd.uniform(-W / 3, W / 3), 1.5 + k * 1.6, -2.4, rnd.uniform(2, 4), 0.15, 0.6, shelf, bevel=0)
    dW = 3.2
    dx = W / 2 - dW / 2 - 0.6 if rnd.random() < 0.5 else -(W / 2 - dW / 2 - 0.6)
    # 하부 벽(킥플레이트)
    box("Kick", 0, 0.6, -0.25, W, 1.2, 0.3, paint)
    box("Head", 0, H - 0.6, -0.25, W, 1.2, 0.35, paint)
    box("PostL", -W / 2 + 0.2, H / 2, -0.25, 0.4, H, 0.35, paint)
    box("PostR", W / 2 - 0.2, H / 2, -0.25, 0.4, H, 0.35, paint)
    box("TransomBar", 0, H * 0.72, -0.25, W, 0.22, 0.3, paint)
    # 진열창 세로 멀리언
    n = 3
    for k in range(1, n):
        x = -W / 2 + W * k / n
        if abs(x - dx) > dW / 2 + 0.3:
            box("Mull", x, H / 2, -0.25, 0.18, H, 0.28, paint)
    box("DoorPostL", dx - dW / 2, H * 0.36, -0.25, 0.22, H * 0.72, 0.3, paint)
    box("DoorPostR", dx + dW / 2, H * 0.36, -0.25, 0.22, H * 0.72, 0.3, paint)
    box("DoorKickBlank", dx, 0.6, -0.2, dW - 0.2, 1.2, 0.2, interior, bevel=0)
    box("DoorRail", dx, 1.0, -0.3, dW - 0.4, 0.3, 0.12, paint, bevel=0.02)
    box("DoorBar", dx, 3.4, -0.3, dW - 0.6, 0.12, 0.15, mat("steel", (0.75, 0.75, 0.75), rough=0.25, metal=1), bevel=0.02)
    if state == "clean":
        box("Glass", 0, H / 2, -0.35, W - 0.4, H - 0.4, 0.02, glass, bevel=0)
    else:
        shard = mat("shard", (0.25, 0.32, 0.42), rough=0.03)
        box("TopGlass", 0, H * 0.86, -0.35, W - 0.4, H * 0.24, 0.02, glass, bevel=0)
        for k in range(16):
            x = rnd.uniform(-W / 2 + 0.6, W / 2 - 0.6)
            y = rnd.choice([1.4, H * 0.7 - 0.2])
            bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=rnd.uniform(0.3, 0.9), depth=0.02, location=(x, 0.35, y),
                                            rotation=(math.radians(90), 0, rnd.uniform(0, 6.28)))
            bpy.context.active_object.data.materials.append(shard)
    camera(W, H)
    render(name)


# ---------- 난간 (알파) ----------
def railing(name, W=8.0, H=3.2):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    sc.render.film_transparent = True
    iron = mat("iron", (0.06, 0.06, 0.07), rough=0.35, metal=0.6)
    box("Top", 0, H - 0.1, 0, W, 0.2, 0.25, iron, bevel=0.04)
    box("Bot", 0, 0.25, 0, W, 0.14, 0.14, iron, bevel=0.02)
    box("Mid", 0, H - 0.55, 0, W, 0.08, 0.08, iron, bevel=0.01)
    n = int(W / 0.42)
    for i in range(n + 1):
        x = -W / 2 + 0.1 + (W - 0.2) * i / n
        cyl("Bal", x, (H - 0.1 + 0.25) / 2, 0, 0.045, H - 0.35, "y", iron, verts=8)
    # 위쪽 고리 장식
    for i in range(n):
        x = -W / 2 + 0.1 + (W - 0.2) * (i + 0.5) / n
        bpy.ops.mesh.primitive_torus_add(major_radius=0.18, minor_radius=0.03, location=(x, 0, H - 0.33),
                                         rotation=(math.radians(90), 0, 0))
        bpy.context.active_object.data.materials.append(iron)
    camera(W, H)
    render(name)


# ---------- 덩굴 오버레이 (알파) ----------
def vines(name, W=6.0, H=12.0, seed=7, density=1.0):
    sc = reset()
    world_sky(sc, 1.2)
    sun(energy=3.6)
    sc.render.film_transparent = True
    rnd = random.Random(seed)
    leafm = [mat("leaf%d" % i, c, rough=0.6) for i, c in enumerate([(0.16, 0.35, 0.12), (0.22, 0.45, 0.15), (0.12, 0.28, 0.10), (0.30, 0.50, 0.18)])]
    stem = mat("stem", (0.25, 0.18, 0.10), rough=0.8)
    # 위에서 늘어지는 줄기 여러 개
    for s in range(int(7 * density)):
        x = rnd.uniform(-W / 2 + 0.3, W / 2 - 0.3)
        length = rnd.uniform(H * 0.35, H * 0.95)
        y = H
        steps = int(length / 0.35)
        for k in range(steps):
            y -= 0.35
            x += rnd.uniform(-0.12, 0.12)
            for _ in range(2):
                r = rnd.uniform(0.18, 0.32) * (1 - 0.4 * k / steps)
                bpy.ops.mesh.primitive_circle_add(vertices=6, radius=r, fill_type="TRIFAN",
                                                  location=(x + rnd.uniform(-0.3, 0.3), -rnd.uniform(0, 0.3), y + rnd.uniform(-0.15, 0.15)),
                                                  rotation=(math.radians(90) + rnd.uniform(-0.4, 0.4), rnd.uniform(-0.4, 0.4), rnd.uniform(0, 6.28)))
                o = bpy.context.active_object
                o.scale = (1, 0.65, 1)
                o.data.materials.append(rnd.choice(leafm))
    # 윗부분 무성한 덩어리
    for k in range(int(140 * density)):
        bpy.ops.mesh.primitive_circle_add(vertices=6, radius=rnd.uniform(0.2, 0.36), fill_type="TRIFAN",
                                          location=(rnd.uniform(-W / 2, W / 2), -rnd.uniform(0, 0.4), H - abs(rnd.gauss(0, 0.9))),
                                          rotation=(math.radians(90) + rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), rnd.uniform(0, 6.28)))
        o = bpy.context.active_object
        o.scale = (1, 0.65, 1)
        o.data.materials.append(rnd.choice(leafm))
    camera(W, H)
    render(name)


# ---------- 화분 상자 (창 아래, 알파) ----------
def flowerbox(name, W=4.4, H=1.8, seed=11):
    sc = reset()
    world_sky(sc, 1.2)
    sun(energy=3.6)
    sc.render.film_transparent = True
    rnd = random.Random(seed)
    boxm = mat("planter", (0.55, 0.32, 0.22), rough=0.7)
    box("Planter", 0, 0.4, 0.3, W - 0.2, 0.8, 0.8, boxm)
    leafm = [mat("leaf%d" % i, c, rough=0.6) for i, c in enumerate([(0.18, 0.40, 0.14), (0.25, 0.50, 0.16), (0.14, 0.32, 0.11)])]
    flm = [mat("fl%d" % i, c, rough=0.5) for i, c in enumerate([(0.95, 0.45, 0.60), (1.0, 0.85, 0.3), (0.95, 0.95, 0.95), (0.85, 0.3, 0.35)])]
    for k in range(70):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=rnd.uniform(0.12, 0.22),
                                              location=(rnd.uniform(-W / 2 + 0.2, W / 2 - 0.2), -rnd.uniform(0.0, 0.6), rnd.uniform(0.75, 1.5)))
        bpy.context.active_object.data.materials.append(rnd.choice(leafm))
    for k in range(18):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=rnd.uniform(0.08, 0.13),
                                              location=(rnd.uniform(-W / 2 + 0.3, W / 2 - 0.3), -rnd.uniform(0.3, 0.7), rnd.uniform(1.0, 1.65)))
        bpy.context.active_object.data.materials.append(rnd.choice(flm))
    camera(W, H)
    render(name)


# ---------- 현대식 창 (어두운 알루미늄 틀, 블라인드) ----------
def window_modern(name, W=4.0, H=6.0, blinds=0.45, seed=21, frame_color=(0.16, 0.16, 0.17)):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    fr = mat("frame", frame_color, rough=0.35, metal=0.6)
    glass = glass_mat("glass", alpha=0.38)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    slat = mat("slat", (0.85, 0.84, 0.80), rough=0.6)
    box("Back", 0, H / 2, -1.6, W, H, 0.1, interior, bevel=0)
    t = 0.18
    fz = -0.3
    box("FrameL", -W / 2 + t / 2, H / 2, fz, t, H + 0.2, 0.2, fr, bevel=0.01)
    box("FrameR", W / 2 - t / 2, H / 2, fz, t, H + 0.2, 0.2, fr, bevel=0.01)
    box("FrameT", 0, H - t / 2, fz + 0.01, W - 2 * t + 0.01, t, 0.2, fr, bevel=0.01)
    box("FrameB", 0, t / 2, fz + 0.01, W - 2 * t + 0.01, t, 0.2, fr, bevel=0.01)
    mx = rnd.choice([-W * 0.18, W * 0.18, 0])
    box("Mull", mx, H / 2, fz, 0.12, H - 0.2, 0.18, fr, bevel=0.01)
    box("Glass", 0, H / 2, fz - 0.06, W - 0.2, H - 0.2, 0.02, glass, bevel=0)
    # 블라인드: 위에서 일정 비율까지
    bl = H * blinds * rnd.uniform(0.6, 1.4)
    y = H - 0.25
    while y > H - bl:
        box("Slat", 0, y, fz - 0.3, W - 0.3, 0.09, 0.02, slat, bevel=0)
        y -= 0.16
    camera(W, H)
    render(name)


# ---------- 커튼월 타일 (사무용 빌딩, 층 1칸) ----------
def curtainwall(name, W=8.0, H=12.0, tint=(0.07, 0.11, 0.19), seed=31, broken=False):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    fr = mat("frame", (0.62, 0.64, 0.66), rough=0.3, metal=0.8)
    glass = glass_mat("glass", tint=tint, alpha=0.5, streak=0.7)
    spand = mat("spandrel", (0.20, 0.22, 0.25), rough=0.4, metal=0.3)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    ceil = mat("ceil", (0.75, 0.75, 0.72), rough=0.9)
    box("Back", 0, H / 2, -3, W, H, 0.1, interior, bevel=0)
    sp = 2.6
    box("Spandrel", 0, sp / 2, -0.15, W, sp, 0.2, spand, bevel=0.01)
    box("Ceiling", 0, H - 0.4, -1.5, W, 0.1, 3, ceil, bevel=0)
    for k in range(3):
        box("Light", rnd.uniform(-W / 3, W / 3), H - 0.5, -1.5, 1.6, 0.05, 0.4, mat("lamp", (1, 1, 1), emit=(1, 0.95, 0.85), emit_str=0.6), bevel=0)
    n = 4
    for i in range(n + 1):
        x = -W / 2 + W * i / n
        box("Mull", x, H / 2, 0, 0.16 if 0 < i < n else 0.3, H, 0.3, fr, bevel=0.02)
    box("Transom", 0, sp, 0, W, 0.18, 0.3, fr, bevel=0.02)
    box("Top", 0, H - 0.1, 0, W, 0.2, 0.3, fr, bevel=0.02)
    if not broken:
        box("Glass", 0, (sp + H) / 2, -0.08, W, H - sp, 0.02, glass, bevel=0)
    else:
        for i in range(n):
            if rnd.random() < 0.5:
                box("Glass", -W / 2 + W * (i + 0.5) / n, (sp + H) / 2, -0.08, W / n, H - sp, 0.02, glass, bevel=0)
    camera(W, H)
    render(name)


# ---------- 셔터 (차고/창고) ----------
def garage(name, W=10.0, H=10.0, color=(0.62, 0.64, 0.66), dirty=0.0, seed=41, windows=False):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    fr = mat("frame", (0.25, 0.25, 0.26), rough=0.4, metal=0.6)
    box("FrameL", -W / 2 + 0.2, H / 2, 0, 0.4, H, 0.4, fr)
    box("FrameR", W / 2 - 0.2, H / 2, 0, 0.4, H, 0.4, fr)
    box("FrameT", 0, H - 0.4, 0.01, W - 0.8, 0.8, 0.4, fr)
    y = 0.0
    k = 0
    while y < H - 0.8:
        c = color
        if dirty > 0:
            f = 1 - dirty * rnd.uniform(0.0, 0.35)
            c = (color[0] * f, color[1] * f * 0.97, color[2] * f * 0.93)
        sl = mat("slat%d" % k, c, rough=0.45, metal=0.5)
        box("Slat", 0, y + 0.27, -0.2 + (k % 2) * 0.03, W - 0.8, 0.5, 0.15, sl, bevel=0.06)
        y += 0.55
        k += 1
    if windows:
        gl = glass_mat("glass", alpha=0.6)
        for i in range(4):
            box("Win", -W / 2 + 0.4 + (W - 0.8) * (i + 0.5) / 4, H * 0.62, -0.1, (W - 0.8) / 4 - 0.6, 1.1, 0.05, gl, bevel=0)
    box("Handle", 0, 0.7, -0.05, 1.2, 0.15, 0.15, fr)
    camera(W, H)
    render(name)


# ---------- 렌더 후 알파 마스크 (아치/원) ----------
def mask(name, shape):
    import numpy as np
    pth = os.path.join(OUT, name + ".png")
    im = bpy.data.images.load(pth)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    yy, xx = np.mgrid[0:h, 0:w]
    x = (xx + 0.5) / w * 2 - 1
    y = (yy + 0.5) / h  # 0 아래, 1 위
    if shape == "arch":
        r = 1.0
        cy = 1 - (w / h)  # 반원 중심 높이(정규화)
        inside = (y <= cy) | ((x * x + ((y - cy) * h / w) ** 2) <= 1.0)
    else:
        inside = (x * x + (y * 2 - 1) ** 2) <= 1.0
    a[..., 3] = np.where(inside, a[..., 3], 0)
    im.pixels = a.ravel()
    im.save()
    print("MASKED", pth)


def stained(name, W=4.0, H=9.0, seed=51, shape="arch"):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    lead = mat("lead", (0.12, 0.12, 0.13), rough=0.5, metal=0.5)
    stone = mat("stone", (0.85, 0.82, 0.76), rough=0.8)
    cols = [(0.30, 0.05, 0.06), (0.05, 0.10, 0.30), (0.45, 0.30, 0.05), (0.08, 0.20, 0.10), (0.22, 0.08, 0.26), (0.10, 0.10, 0.18)]
    gm = [mat("sg%d" % i, c, rough=0.15) for i, c in enumerate(cols)]
    n = 6
    for i in range(n):
        for j in range(int(n * H / W)):
            x = -W / 2 + W * (i + 0.5) / n
            y = H * (j + 0.5) / int(n * H / W)
            box("Pane", x, y, -0.1, W / n, H / int(n * H / W), 0.02, rnd.choice(gm), bevel=0)
    for i in range(n + 1):
        box("LeadV", -W / 2 + W * i / n, H / 2, 0, 0.06, H, 0.05, lead, bevel=0)
    for j in range(int(n * H / W) + 1):
        box("LeadH", 0, H * j / int(n * H / W), 0, W, 0.06, 0.05, lead, bevel=0)
    if shape == "circle":
        # 돌 테두리 링
        bpy.ops.mesh.primitive_torus_add(major_radius=W / 2 - 0.25, minor_radius=0.25, location=(0, -0.05, H / 2),
                                         rotation=(math.radians(90), 0, 0))
        bpy.context.active_object.data.materials.append(stone)
        bpy.ops.mesh.primitive_torus_add(major_radius=W / 5, minor_radius=0.15, location=(0, -0.05, H / 2),
                                         rotation=(math.radians(90), 0, 0))
        bpy.context.active_object.data.materials.append(stone)
    camera(W, H)
    render(name)
    mask(name, shape)


# ---------- 그을음/얼룩 오버레이 (알파, 위에서 흘러내림) ----------
def grime(name, W=16.0, H=16.0, seed=61, soot=False):
    import numpy as np
    rng = np.random.default_rng(seed)
    w, h = 512, 512
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    a = np.zeros((h, w), dtype=np.float32)
    for k in range(40 if not soot else 26):
        cx = rng.uniform(0, w)
        width = rng.uniform(6, 40) * (1.8 if soot else 1)
        top = rng.uniform(0.75, 1.0) * h if not soot else rng.uniform(0.2, 0.7) * h
        length = rng.uniform(0.15, 0.7) * h
        wob = np.sin(yy / rng.uniform(20, 60) + rng.uniform(0, 6)) * rng.uniform(1, 6)
        dx = np.abs(xx - cx - wob) / width
        t = (top - yy) / length  # 0 시작점 → 1 끝 (아래로)
        if soot:
            t = (yy - (top - length)) / length  # 불탄 자국: 창 위로 번짐
        streak = np.clip(1 - dx, 0, 1) ** 1.5 * np.clip(1 - np.abs(t * 2 - 1), 0, 1)
        a = np.maximum(a, streak * rng.uniform(0.25, 0.6 if not soot else 0.85))
    col = np.array([0.10, 0.09, 0.08] if soot else [0.24, 0.21, 0.18], dtype=np.float32)
    rgba = np.concatenate([np.broadcast_to(col, (h, w, 3)), a[..., None]], axis=2)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = rgba[::-1].ravel()  # 위쪽 행이 위로
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()
    print("WROTE", img.filepath_raw)


# ---------- 잎 뭉치 (알파, 나무 캐노피 카드용) ----------
def leafclump(name, seed=71, base=(0.20, 0.42, 0.14), spread=0.10, n=420):
    sc = reset()
    w = bpy.data.worlds.new("Flat")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.82, 1.0, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    sun(rot=(math.radians(-40), math.radians(-20), 0), energy=3.0, color=(1.0, 0.95, 0.85))
    sc.render.film_transparent = True
    sc.cycles.samples = 64
    rnd = random.Random(seed)
    # 높이별 색: 위쪽 잎은 밝고 노란 기, 아래쪽은 어둡고 푸른 기 (참고 이미지의 햇빛 받은 캐노피)
    mats = []
    for lv in range(5):
        row = []
        t = lv / 4.0
        for i in range(3):
            k = rnd.uniform(-spread, spread)
            bright = 0.55 + 0.75 * t
            c = (min(1, (base[0] + k * 0.8) * bright + 0.06 * t), min(1, (base[1] + k) * bright + 0.05 * t), max(0, (base[2] + k * 0.6) * (0.75 + 0.3 * t)))
            m = mat("leaf%d_%d" % (lv, i), c, rough=0.5)
            m.node_tree.nodes["Principled BSDF"].inputs["Subsurface Weight"].default_value = 0.15
            row.append(m)
        mats.append(row)
    # 잎 하나 = 끝이 뾰족한 타원 (8각 원을 늘림), 가운데 잎맥은 생략
    for i in range(n):
        # 반구 + 아래쪽은 덜 채움 (뭉치 실루엣)
        while True:
            x, y, z = rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)
            if x * x + y * y + z * z <= 1 and (z > -0.55 or rnd.random() < 0.3):
                break
        r = rnd.uniform(0.085, 0.13)
        bpy.ops.mesh.primitive_circle_add(vertices=8, radius=r, fill_type="TRIFAN", location=(x * 0.95, y * 0.6, z * 0.88 + 1.0),
                                          rotation=(math.radians(90) + rnd.uniform(-0.9, 0.9), rnd.uniform(-0.9, 0.9), rnd.uniform(0, 6.28)))
        o = bpy.context.active_object
        o.scale = (0.55, 1.0, 1)
        lv = max(0, min(4, int((z + 1) / 2 * 5 + rnd.uniform(-0.6, 0.6))))
        o.data.materials.append(rnd.choice(mats[lv]))
    camera(2.1, 2.1)
    bpy.context.scene.camera.location = (0, -20, 1.0)
    sc.render.resolution_x = sc.render.resolution_y = 512
    render(name)

# ---------- 아포칼립스: 아스팔트 균열 / 벽 이끼 (numpy, 알파) ----------
def _save_rgba(name, rgba):
    h, w = rgba.shape[:2]
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels = rgba[::-1].astype("float32").ravel()
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()
    print("WROTE", img.filepath_raw)


def cracks(name, seed=81, n=6):
    import numpy as np
    rng = np.random.default_rng(seed)
    S = 512
    a = np.zeros((S, S), dtype=np.float32)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)

    def line(x0, y0, x1, y1, w):
        # 선분까지 거리 → 부드러운 선
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy + 1e-6
        t = np.clip(((xx - x0) * dx + (yy - y0) * dy) / L2, 0, 1)
        d = np.hypot(xx - (x0 + t * dx), yy - (y0 + t * dy))
        return np.clip(1 - (d - w) / 1.2, 0, 1)

    def walk(x, y, ang, steps, w, depth):
        nonlocal a
        for i in range(steps):
            ang += rng.normal(0, 0.35)
            L = rng.uniform(8, 18)
            nx, ny = x + np.cos(ang) * L, y + np.sin(ang) * L
            a = np.maximum(a, line(x, y, nx, ny, w))
            if depth < 2 and rng.random() < 0.18:
                walk(nx, ny, ang + rng.choice([-1, 1]) * rng.uniform(0.6, 1.2), int(steps * 0.5), max(0.6, w * 0.6), depth + 1)
            x, y = nx, ny
            w = max(0.5, w * 0.97)
            if not (0 <= x < S and 0 <= y < S):
                break

    for k in range(n):
        walk(S / 2 + rng.uniform(-60, 60), S / 2 + rng.uniform(-60, 60), rng.uniform(0, 6.28), 22, 2.2, 0)
    col = np.array([0.08, 0.075, 0.07], dtype=np.float32)
    rgba = np.concatenate([np.broadcast_to(col, (S, S, 3)), (a * 0.9)[..., None]], axis=2)
    _save_rgba(name, rgba)


def moss(name, seed=91):
    import numpy as np
    rng = np.random.default_rng(seed)
    S = 512
    G = 64
    lat = rng.random((G + 1, G + 1)).astype(np.float32)

    def vnoise(x, y, f):
        x, y = x * f, y * f
        xi, yi = np.floor(x).astype(int) % G, np.floor(y).astype(int) % G
        xf, yf = x - np.floor(x), y - np.floor(y)
        u, v = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
        a00, a10, a01, a11 = lat[xi, yi], lat[(xi + 1) % G, yi], lat[xi, (yi + 1) % G], lat[(xi + 1) % G, (yi + 1) % G]
        return (a00 * (1 - u) + a10 * u) * (1 - v) + (a01 * (1 - u) + a11 * u) * v

    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32) / S
    n = vnoise(xx, yy, 6) * 0.55 + vnoise(xx, yy, 18) * 0.3 + vnoise(xx, yy, 48) * 0.15
    grad = 1 - yy  # 아래(행 끝)로 갈수록 진함 → 행 0 = 위
    grad = yy
    alpha = np.clip((n - 0.62 + grad * 0.55) * 3.0, 0, 1) * 0.92
    g = vnoise(xx, yy, 30)[..., None]
    col = np.concatenate([0.20 + 0.10 * g, 0.32 + 0.14 * g, 0.12 + 0.05 * g], axis=2)
    rgba = np.concatenate([col, alpha[..., None]], axis=2)
    _save_rgba(name, rgba)


# ---------- 풀 덤불 (알파, 교차 카드용): 가늘고 휜 풀잎 ----------
def grass(name, seed=101, n=140, dry=0.25):
    sc = reset()
    w = bpy.data.worlds.new("Flat")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.8, 0.85, 1.0, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.7
    sun(rot=(math.radians(-50), math.radians(-20), 0), energy=2.6)
    sc.render.film_transparent = True
    rnd = random.Random(seed)
    greens = [mat("g%d" % i, c, rough=0.6) for i, c in enumerate([(0.22, 0.45, 0.10), (0.30, 0.52, 0.12), (0.18, 0.38, 0.09), (0.36, 0.55, 0.14)])]
    drys = [mat("d%d" % i, c, rough=0.7) for i, c in enumerate([(0.55, 0.48, 0.22), (0.62, 0.55, 0.28)])]
    for i in range(n):
        x0 = rnd.gauss(0, 0.45)
        h = rnd.uniform(0.6, 1.9) * (1 - min(0.6, abs(x0) * 0.5))
        bend = rnd.uniform(-0.5, 0.5)
        wid = rnd.uniform(0.035, 0.06)
        me = bpy.data.meshes.new("blade")
        bm = bmesh.new()
        segs = 6
        prev = None
        for k in range(segs + 1):
            t = k / segs
            x = x0 + bend * t * t
            y = h * t
            ww = wid * (1 - t)
            a = bm.verts.new((x - ww, rnd.uniform(-0.02, 0.02), y))
            b = bm.verts.new((x + ww, 0, y))
            if prev:
                bm.faces.new((prev[0], prev[1], b, a))
            prev = (a, b)
        bm.to_mesh(me)
        o = bpy.data.objects.new("blade", me)
        o.location = (0, -rnd.uniform(-0.3, 0.3), 0)
        bpy.context.scene.collection.objects.link(o)
        o.data.materials.append(rnd.choice(drys) if rnd.random() < dry else rnd.choice(greens))
    camera(2.4, 2.0)
    bpy.context.scene.camera.location = (0, -20, 1.0)
    sc.render.resolution_x, sc.render.resolution_y = 614, 512
    render(name)


# ---------- 한국식 창: 은색 알루미늄 미닫이 새시 (+ 방범창) ----------
def window_kr(name, W=4.0, H=4.5, bars=True, seed=111, cur_color=(0.85, 0.82, 0.76), broken=False):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    alu = mat("alu", (0.70, 0.71, 0.72), rough=0.35, metal=0.8)
    glass = glass_mat("glass", tint=(0.10, 0.11, 0.12), alpha=0.6, streak=0.12)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    bar = mat("bar", (0.62, 0.62, 0.64), rough=0.4, metal=0.9)
    box("Back", 0, H / 2, -1.6, W, H, 0.1, interior, bevel=0)
    t = 0.2
    fz = -0.3
    box("FrameL", -W / 2 + t / 2, H / 2, fz, t, H + 0.2, 0.2, alu, bevel=0.01)
    box("FrameR", W / 2 - t / 2, H / 2, fz, t, H + 0.2, 0.2, alu, bevel=0.01)
    box("FrameT", 0, H - t / 2, fz + 0.01, W - 2 * t + 0.01, t, 0.2, alu, bevel=0.01)
    box("FrameB", 0, t / 2, fz + 0.01, W - 2 * t + 0.01, t, 0.2, alu, bevel=0.01)
    # 미닫이 두 짝 (한쪽이 조금 열림)
    shift = rnd.uniform(0, 0.6)
    for k, (cx, z) in enumerate(((-W / 4 + shift * 0.5, fz - 0.05), (W / 4, fz - 0.12))):
        sw = W / 2 + 0.05
        box("SashL", cx - sw / 2 + 0.06, H / 2, z, 0.12, H - 0.35, 0.06, alu, bevel=0.005)
        box("SashR", cx + sw / 2 - 0.06, H / 2, z, 0.12, H - 0.35, 0.06, alu, bevel=0.005)
        box("SashT", cx, H - 0.24, z, sw, 0.1, 0.06, alu, bevel=0.005)
        box("SashB", cx, 0.24, z, sw, 0.1, 0.06, alu, bevel=0.005)
        if not broken:
            box("Glass", cx, H / 2, z - 0.03, sw - 0.15, H - 0.45, 0.02, glass, bevel=0)
        else:
            shard = mat("shard%d" % k, (0.25, 0.32, 0.42), rough=0.03)
            for j in range(5):
                bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=rnd.uniform(0.15, 0.4), depth=0.02,
                                                location=(cx + rnd.choice([-1, 1]) * (sw / 2 - 0.3), -(z - 0.03), rnd.uniform(0.5, H - 0.5)),
                                                rotation=(math.radians(90), 0, rnd.uniform(0, 6.28)))
                bpy.context.active_object.data.materials.append(shard)
    curtain("Cur", -W / 2 + 0.25, -W / 2 + 0.25 + W * rnd.uniform(0.25, 0.5), 0.3, H - 0.3, fz - 0.5, cur_color, folds=6)
    if bars:
        n = int(W / 0.32)
        for i in range(n + 1):
            x = -W / 2 + 0.15 + (W - 0.3) * i / n
            cyl("Bar", x, H / 2, 0.15, 0.035, H - 0.1, "y", bar, verts=8)
        for y in (0.35, H / 2, H - 0.35):
            box("BarH", 0, y, 0.18, W - 0.1, 0.07, 0.05, bar, bevel=0)
    camera(W, H)
    render(name)


# ---------- 3등급(먼 건물)용 외벽 타일: 벽(중립 회색, Texture.Color3 로 색) + 창 1개 ----------
def facade_tile(name, W=10.0, H=9.0, ww=4.6, wh=4.6, seed=121, office=False):
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    wall = mat("wall", (0.80, 0.80, 0.80), rough=0.9)
    alu = mat("alu", (0.72, 0.73, 0.74), rough=0.35, metal=0.8)
    glass = glass_mat("glass", tint=(0.10, 0.11, 0.12), alpha=0.6, streak=0.12)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    if office:
        ww, wh = W - 0.8, H - 2.2
    cy = H * 0.52
    # 벽 = 창 구멍 둘레 4장
    box("WallT", 0, (cy + wh / 2 + H) / 2, 0, W, H - (cy + wh / 2), 0.4, wall, bevel=0)
    box("WallB", 0, (cy - wh / 2) / 2, 0, W, cy - wh / 2, 0.4, wall, bevel=0)
    box("WallL", -(ww / 2 + W / 2) / 2 - 0.0, cy, 0, (W - ww) / 2, wh, 0.4, wall, bevel=0)
    box("WallR", (ww / 2 + W / 2) / 2, cy, 0, (W - ww) / 2, wh, 0.4, wall, bevel=0)
    box("Back", 0, cy, -1.5, ww, wh, 0.1, interior, bevel=0)
    box("Frame", 0, cy, -0.35, ww, wh, 0.05, alu, bevel=0)
    box("Glass", 0, cy, -0.3, ww - 0.3, wh - 0.3, 0.02, glass, bevel=0)
    box("Mull", 0, cy, -0.28, 0.12, wh - 0.3, 0.06, alu, bevel=0)
    box("Sill", 0, cy - wh / 2 - 0.1, 0.15, ww + 0.4, 0.2, 0.3, wall, bevel=0.02)
    camera(W, H)
    render(name)


# ---------- 렌더 후 처리: 먼지 낀 유리 / 때 (번들거림 줄이기) ----------
def grimeify(name, amount=0.55, seed=1):
    import numpy as np
    pth = os.path.join(OUT, name + ".png")
    im = bpy.data.images.load(pth)
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
    rng = np.random.default_rng(seed)
    G = 32
    lat = rng.random((G + 1, G + 1)).astype(np.float32)
    def vn(f):
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        x, y = xx / w * f, yy / h * f
        xi, yi = np.floor(x).astype(int) % G, np.floor(y).astype(int) % G
        xf, yf = x - np.floor(x), y - np.floor(y)
        u, v = xf * xf * (3 - 2 * xf), yf * yf * (3 - 2 * yf)
        return (lat[yi, xi] * (1 - u) + lat[yi, (xi + 1) % G] * u) * (1 - v) + (lat[(yi + 1) % G, xi] * (1 - u) + lat[(yi + 1) % G, (xi + 1) % G] * u) * v
    n = vn(5) * 0.6 + vn(17) * 0.4
    rgb = a[..., :3]
    lum = rgb.mean(-1, keepdims=True)
    # 밝은 반사 줄무늬 눌러주기 + 채도 낮추기
    rgb = np.where(lum > 0.45, rgb * (0.55 + 0.45 * (1 - amount)), rgb)
    rgb = rgb * (1 - 0.35 * amount) + lum * 0.35 * amount
    # 갈색 먼지 얼룩 (아래쪽 진하게: 픽셀 행 0 = 아래)
    yy = np.mgrid[0:h, 0:w][0].astype(np.float32) / h
    dirt = np.clip((n - 0.45) * 2.2 + (1 - yy) * 0.35, 0, 1)[..., None] * amount
    rgb = rgb * (1 - dirt * 0.55) + np.array([0.30, 0.26, 0.21], dtype=np.float32) * dirt * 0.55
    a[..., :3] = np.clip(rgb, 0, 1)
    im.pixels = a.ravel()
    im.save()
    print("GRIMED", pth)

def boarded_kr(name, W=4.0, H=4.5, seed=131):
    # 한국식 창 + 판자 못질 (창틀 보이게 판자 3~4장 엇갈림)
    sc = reset()
    world_sky(sc, 1.0)
    sun()
    rnd = random.Random(seed)
    alu = mat("alu", (0.66, 0.67, 0.68), rough=0.4, metal=0.7)
    interior = mat("interior", (0.05, 0.05, 0.06), rough=0.9)
    woods = [mat("wood%d" % i, c, rough=0.9) for i, c in enumerate([(0.36, 0.27, 0.18), (0.30, 0.23, 0.16), (0.44, 0.34, 0.22), (0.26, 0.21, 0.16)])]
    nail = mat("nail", (0.18, 0.18, 0.18), metal=1)
    box("Back", 0, H / 2, -1.6, W, H, 0.1, interior, bevel=0)
    t = 0.2
    box("FrameL", -W / 2 + t / 2, H / 2, -0.3, t, H + 0.2, 0.2, alu, bevel=0.01)
    box("FrameR", W / 2 - t / 2, H / 2, -0.3, t, H + 0.2, 0.2, alu, bevel=0.01)
    box("FrameT", 0, H - t / 2, -0.29, W - 2 * t, t, 0.2, alu, bevel=0.01)
    box("FrameB", 0, t / 2, -0.29, W - 2 * t, t, 0.2, alu, bevel=0.01)
    n = rnd.randint(3, 5)
    for k in range(n):
        y = H * (k + 0.6) / (n + 0.2) + rnd.uniform(-0.25, 0.25)
        o = box("Board%d" % k, rnd.uniform(-0.15, 0.15), y, 0.02 + 0.09 * k, W + rnd.uniform(0.1, 0.5), rnd.uniform(0.45, 0.7), 0.1, woods[k % 4], bevel=0.02)
        o.rotation_euler = (0, math.radians(rnd.uniform(-10, 10)), 0)
        for sx in (-1, 1):
            cyl("Nail", sx * (W / 2 - 0.2), y, 0.08 + 0.09 * k, 0.04, 0.05, "z", nail)
    camera(W, H)
    render(name)

def chainlink(name, seed=141):
    # 철망(다이아몬드) 알파 타일 — numpy 로 직접. 4×4 스터드 한 장
    import numpy as np
    S = 256
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    cell = S / 6
    u = ((xx + yy) % cell) / cell
    v = ((xx - yy) % cell) / cell
    d = np.minimum(np.minimum(u, 1 - u), np.minimum(v, 1 - v)) * cell
    a = np.clip(1.6 - d, 0, 1)
    col = np.array([0.62, 0.63, 0.62], dtype=np.float32)
    rgba = np.concatenate([np.broadcast_to(col, (S, S, 3)), a[..., None]], axis=2)
    _save_rgba(name, rgba)

JOBS = {
    "win_clean_a": lambda: window("win_clean_a", curtain_color=(0.93, 0.86, 0.78), seed=1),
    "win_clean_b": lambda: window("win_clean_b", curtain_color=(0.86, 0.62, 0.66), seed=2),
    "win_clean_c": lambda: window("win_clean_c", curtain_color=(0.62, 0.72, 0.80), seed=3),
    "win_broken": lambda: window("win_broken", state="broken", seed=4),
    "win_boarded": lambda: window("win_boarded", state="boarded", seed=5),
    "door_green": lambda: door("door_green", color=(0.22, 0.36, 0.30)),
    "door_red": lambda: door("door_red", color=(0.50, 0.16, 0.14)),
    "shop_clean": lambda: (shopfront("shop_clean", seed=3), grimeify("shop_clean", 0.55, 99)),
    "shop_broken": lambda: shopfront("shop_broken", state="broken", seed=6),
    "rail_iron": lambda: railing("rail_iron"),
    "vines_a": lambda: vines("vines_a", seed=7),
    "flowerbox_a": lambda: flowerbox("flowerbox_a"),
    "win_tall_a": lambda: window("win_tall_a", H=7.5, curtain_color=(0.93, 0.86, 0.78), seed=8),
    "win_tall_b": lambda: window("win_tall_b", H=7.5, curtain_color=(0.86, 0.62, 0.66), seed=9),
    "win_modern_a": lambda: (window_modern("win_modern_a", seed=21), grimeify("win_modern_a", 0.55, 86)),
    "win_modern_b": lambda: (window_modern("win_modern_b", blinds=0.2, seed=22), grimeify("win_modern_b", 0.55, 40)),
    "win_modern_wide": lambda: (window_modern("win_modern_wide", W=8.0, H=6.0, seed=23), grimeify("win_modern_wide", 0.55, 52)),
    "curtainwall_a": lambda: (curtainwall("curtainwall_a", seed=31), grimeify("curtainwall_a", 0.55, 14)),
    "curtainwall_green": lambda: (curtainwall("curtainwall_green", tint=(0.06, 0.16, 0.15), seed=32), grimeify("curtainwall_green", 0.55, 56)),
    "curtainwall_broken": lambda: curtainwall("curtainwall_broken", seed=33, broken=True),
    "garage_grey": lambda: garage("garage_grey", seed=41),
    "garage_rust": lambda: garage("garage_rust", color=(0.55, 0.38, 0.28), dirty=1.0, seed=42),
    "garage_red": lambda: garage("garage_red", W=12, H=12, color=(0.62, 0.12, 0.10), seed=43, windows=True),
    "stained_arch": lambda: stained("stained_arch"),
    "stained_rose": lambda: stained("stained_rose", W=8.0, H=8.0, seed=52, shape="circle"),
    "grime_streaks": lambda: grime("grime_streaks"),
    "soot_burn": lambda: grime("soot_burn", seed=62, soot=True),
    "leaf_a": lambda: leafclump("leaf_a", seed=71, base=(0.22, 0.50, 0.10)),
    "leaf_b": lambda: leafclump("leaf_b", seed=72, base=(0.30, 0.56, 0.10)),
    "leaf_c": lambda: leafclump("leaf_c", seed=73, base=(0.16, 0.40, 0.10)),
    "leaf_dry": lambda: leafclump("leaf_dry", seed=74, base=(0.42, 0.34, 0.12), n=260),
    "cracks_a": lambda: cracks("cracks_a", seed=85, n=3),
    "cracks_b": lambda: cracks("cracks_b", seed=82, n=4),
    "moss_a": lambda: moss("moss_a"),
    "grass_a": lambda: grass("grass_a", seed=101),
    "grass_dry": lambda: grass("grass_dry", seed=102, dry=0.7),
    "win_kr_bars": lambda: (window_kr("win_kr_bars", seed=111), grimeify("win_kr_bars", 0.6, 1)),
    "win_kr_boarded": lambda: (boarded_kr("win_kr_boarded"), grimeify("win_kr_boarded", 0.4, 9)),
    "win_kr_boarded_b": lambda: (boarded_kr("win_kr_boarded_b", seed=132), grimeify("win_kr_boarded_b", 0.4, 10)),
    "chainlink": lambda: chainlink("chainlink"),
    "win_kr_bars_b": lambda: (window_kr("win_kr_bars_b", seed=112, cur_color=(0.70, 0.78, 0.82)), grimeify("win_kr_bars_b", 0.6, 2)),
    "win_kr_plain": lambda: (window_kr("win_kr_plain", bars=False, seed=113), grimeify("win_kr_plain", 0.65, 3)),
    "facade_kr_tile": lambda: (facade_tile("facade_kr_tile"), grimeify("facade_kr_tile", 0.6, 4)),
    "facade_office_tile": lambda: (facade_tile("facade_office_tile", W=8.0, H=10.0, office=True), grimeify("facade_office_tile", 0.6, 6)),
    "win_kr_broken": lambda: window_kr("win_kr_broken", seed=115, cur_color=(0.45, 0.42, 0.38), broken=True),
    "win_kr_wide": lambda: (window_kr("win_kr_wide", W=8.0, H=5.0, bars=False, seed=114, cur_color=(0.88, 0.80, 0.74)), grimeify("win_kr_wide", 0.65, 5)),
}
for k, f in JOBS.items():
    if not ONLY or k in ONLY:
        f()
