--!nocheck
-- 22번 건물 키트 (Surter: Days). 건물 종류마다 함수 하나, 같은 함수 + 다른 seed/크기/색 = 변형.
-- 사용: local Kit = loadstring(<이 파일>)(); Kit.build("apt_balcony", parent, CFrame, {seed=1, w=40, d=32, floors=5})
-- 좌표: 건물 원점 = 바닥 중심, 정면 = 원점 CFrame 의 LookVector 방향(-Z).
-- 면(face) 좌표: x = 바깥에서 볼 때 오른쪽, y = 위, z = 바깥쪽. 벽 바깥면 z=0, 두께는 안쪽(z<0).
-- 텍스처는 tools/buildingkit/make_textures.py 로 렌더 → upload_image. id 는 assets/textures/kit22/ids.json.
local Kit = {}
Kit.VERSION = "22.0"

Kit.TEX = {
	door_green = "rbxassetid://82404093666751",
	door_red = "rbxassetid://138864575491802",
	flowerbox_a = "rbxassetid://78543183833394",
	rail_iron = "rbxassetid://110896807818082",
	shop_broken = "rbxassetid://128521087585917",
	shop_clean = "rbxassetid://130920300520139",
	vines_a = "rbxassetid://135734921741486",
	win_boarded = "rbxassetid://70810317074575",
	win_broken = "rbxassetid://106777328177166",
	win_clean_a = "rbxassetid://117617144666761",
	win_clean_b = "rbxassetid://74512052908039",
	win_clean_c = "rbxassetid://124065815311360",
	corrugated = "rbxassetid://124124909559318",
	curtainwall_a = "rbxassetid://78458491988517",
	curtainwall_broken = "rbxassetid://123501721458881",
	curtainwall_green = "rbxassetid://122440760926354",
	garage_grey = "rbxassetid://126938453958979",
	garage_red = "rbxassetid://123768671342260",
	garage_rust = "rbxassetid://94100501315588",
	grime_streaks = "rbxassetid://81706391263079",
	soot_burn = "rbxassetid://96539978749345",
	stained_arch = "rbxassetid://132791049892670",
	stained_rose = "rbxassetid://124160286387659",
	win_modern_a = "rbxassetid://119074991572832",
	win_modern_b = "rbxassetid://135495484960261",
	win_modern_wide = "rbxassetid://133586503983649",
	win_tall_a = "rbxassetid://119827221899049",
	win_tall_b = "rbxassetid://131188232804394",
}

local M = Enum.Material
local SMOOTH = Enum.SurfaceType.Smooth
local WHITE = Color3.fromRGB(242, 238, 230)
local IRON = Color3.fromRGB(28, 28, 30)

Kit.PALETTES = {
	pink = {wall = Color3.fromRGB(228, 164, 160), trim = WHITE, base = Color3.fromRGB(150, 140, 132)},
	mint = {wall = Color3.fromRGB(166, 208, 186), trim = WHITE, base = Color3.fromRGB(138, 146, 140)},
	cream = {wall = Color3.fromRGB(238, 218, 184), trim = WHITE, base = Color3.fromRGB(156, 146, 132)},
	peach = {wall = Color3.fromRGB(242, 188, 146), trim = WHITE, base = Color3.fromRGB(150, 136, 124)},
	lavender = {wall = Color3.fromRGB(190, 174, 214), trim = WHITE, base = Color3.fromRGB(140, 136, 148)},
	butter = {wall = Color3.fromRGB(240, 224, 150), trim = WHITE, base = Color3.fromRGB(152, 146, 128)},
	sky = {wall = Color3.fromRGB(166, 200, 224), trim = WHITE, base = Color3.fromRGB(136, 142, 150)},
	coral = {wall = Color3.fromRGB(232, 140, 120), trim = WHITE, base = Color3.fromRGB(146, 132, 124)},
	brick = {wall = Color3.fromRGB(150, 78, 60), trim = Color3.fromRGB(228, 220, 204), base = Color3.fromRGB(110, 104, 98), mat = M.Brick},
	brickdark = {wall = Color3.fromRGB(110, 62, 52), trim = Color3.fromRGB(214, 206, 190), base = Color3.fromRGB(96, 92, 88), mat = M.Brick},
	stone = {wall = Color3.fromRGB(206, 196, 176), trim = Color3.fromRGB(236, 230, 216), base = Color3.fromRGB(130, 124, 116), mat = M.Limestone},
}
Kit.PASTELS = {"pink", "mint", "cream", "peach", "lavender", "butter", "sky", "coral"}

---------------------------------------------------------------- 빌더
local B = {}
B.__index = B

function Kit.newBuilder(name, params)
	local self = setmetatable({}, B)
	self.p = params or {}
	self.rng = Random.new(self.p.seed or 1)
	self.model = Instance.new("Model")
	self.model.Name = name
	self.folders = {}
	self.count = 0
	self.decay = self.p.decay or 0.35
	local palName = self.p.palette or Kit.PASTELS[self.rng:NextInteger(1, #Kit.PASTELS)]
	self.palName = palName
	self.pal = Kit.PALETTES[palName]
	self.wallMat = self.pal.mat or M.Plaster
	self.model:SetAttribute("Kit22", true)
	self.model:SetAttribute("Kit22Palette", palName)
	return self
end

function B:folder(name)
	local f = self.folders[name]
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = self.model
		self.folders[name] = f
	end
	return f
end

function B:part(folder, name, size, cf, color, mat, opt)
	local p
	if opt and opt.wedge then p = Instance.new("WedgePart") else p = Instance.new("Part") end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.Plaster
	p.TopSurface, p.BottomSurface = SMOOTH, SMOOTH
	if opt then
		if opt.shape then p.Shape = opt.shape end
		if opt.deco then p.CanCollide, p.CanTouch, p.CanQuery = false, false, false end
		if opt.noShadow then p.CastShadow = false end
		if opt.transparency then p.Transparency = opt.transparency end
	end
	p.Parent = self:folder(folder)
	self.count += 1
	return p
end

function B:decal(part, tex, face, transparency)
	local d = Instance.new("Decal")
	d.Texture = Kit.TEX[tex] or tex
	d.Face = face or Enum.NormalId.Back
	if transparency then d.Transparency = transparency end
	d.Parent = part
	return d
end

function B:chance(p) return self.rng:NextNumber() < p end
function B:pick(t) return t[self.rng:NextInteger(1, #t)] end

---------------------------------------------------------------- 면
local F = {}
F.__index = F

-- pos: 면 바닥 중심(벽 바깥면), outward: 바깥 방향 단위벡터
function B:face(pos, outward, width, height)
	local up = Vector3.yAxis
	local right = up:Cross(outward)
	return setmetatable({b = self, cf = CFrame.fromMatrix(pos, right, up, outward), w = width, h = height, openings = {}}, F)
end

function F:box(folder, name, x, y, z, sx, sy, sz, color, mat, opt)
	return self.b:part(folder, name, Vector3.new(sx, sy, sz), self.cf * CFrame.new(x, y, z), color, mat, opt)
end

-- 개구부 등록: {x0, x1, y0, y1, kind, tex, ...}
function F:open(x, y0, w, h, kind, tex, extra)
	local o = {x0 = x - w / 2, x1 = x + w / 2, y0 = y0, y1 = y0 + h, kind = kind, tex = tex}
	if extra then for k, v in pairs(extra) do o[k] = v end end
	table.insert(self.openings, o)
	return o
end

-- 벽 = 면 전체 - 개구부. 가로 띠로 나눈 뒤 같은 구간끼리 세로로 합침 (파트 수 최소화).
function F:buildWall(thickness, color, mat)
	local T = thickness or 1
	local b = self.b
	color = color or b.pal.wall
	mat = mat or b.wallMat
	local ys = {0, self.h}
	for _, o in ipairs(self.openings) do table.insert(ys, o.y0) table.insert(ys, o.y1) end
	table.sort(ys)
	local uy = {}
	for _, y in ipairs(ys) do if #uy == 0 or y - uy[#uy] > 0.01 then table.insert(uy, y) end end
	local open = {} -- key -> {x0,x1,y0,y1}
	local rects = {}
	local half = self.w / 2
	for i = 1, #uy - 1 do
		local y0, y1 = uy[i], uy[i + 1]
		local ym = (y0 + y1) / 2
		local cuts = {}
		for _, o in ipairs(self.openings) do
			if o.y0 < ym and o.y1 > ym then table.insert(cuts, {o.x0, o.x1}) end
		end
		table.sort(cuts, function(a, c) return a[1] < c[1] end)
		local solids = {}
		local x = -half
		for _, c in ipairs(cuts) do
			if c[1] - x > 0.01 then table.insert(solids, {x, c[1]}) end
			x = math.max(x, c[2])
		end
		if half - x > 0.01 then table.insert(solids, {x, half}) end
		local nextOpen = {}
		for _, s in ipairs(solids) do
			local key = string.format("%.2f|%.2f", s[1], s[2])
			local r = open[key]
			if r and math.abs(r.y1 - y0) < 0.01 then
				r.y1 = y1
			else
				r = {x0 = s[1], x1 = s[2], y0 = y0, y1 = y1}
				table.insert(rects, r)
			end
			nextOpen[key] = r
		end
		open = nextOpen
	end
	for _, r in ipairs(rects) do
		self:box("Walls", "Wall", (r.x0 + r.x1) / 2, (r.y0 + r.y1) / 2, -T / 2, r.x1 - r.x0, r.y1 - r.y0, T, color, mat)
	end
	-- 개구부 채움 (안쪽으로 들어간 텍스처 판)
	for _, o in ipairs(self.openings) do
		if o.noFill then continue end
		local w, h = o.x1 - o.x0, o.y1 - o.y0
		local depth = o.recess or 0.45
		local p = self:box("Openings", o.kind, (o.x0 + o.x1) / 2, (o.y0 + o.y1) / 2, -depth - 0.1, w, h, 0.2, Color3.fromRGB(20, 22, 26), M.SmoothPlastic)
		if o.tex then b:decal(p, o.tex, Enum.NormalId.Back) end
	end
	return rects
end

-- 단순 면: 벽 1장 + 창문 카드 (뒷면/옆면용, 파트 절약)
function F:buildFlat(thickness, color, mat)
	local T = thickness or 1
	local b = self.b
	self:box("Walls", "Wall", 0, self.h / 2, -T / 2, self.w, self.h, T, color or b.pal.wall, mat or b.wallMat)
	for _, o in ipairs(self.openings) do
		local p = self:box("Openings", o.kind, (o.x0 + o.x1) / 2, (o.y0 + o.y1) / 2, 0.04, o.x1 - o.x0, o.y1 - o.y0, 0.08, Color3.fromRGB(20, 22, 26), M.SmoothPlastic)
		if o.tex then b:decal(p, o.tex, Enum.NormalId.Back) end
	end
end

-- 가로 띠 (층 띠, 코니스 등). 양 끝을 ext 만큼 늘려 모서리를 감쌈
function F:band(y, h, depth, color, ext, mat)
	ext = ext or depth
	return self:box("Trim", "Band", 0, y + h / 2, depth / 2, self.w + 2 * ext, h, depth, color or self.b.pal.trim, mat or M.SmoothPlastic)
end

function F:windowTrim(o, style)
	local b = self.b
	local w = o.x1 - o.x0
	local cx = (o.x0 + o.x1) / 2
	local trim = b.pal.trim
	-- 창턱
	self:box("Trim", "Sill", cx, o.y0 - 0.18, 0.25, w + 0.8, 0.36, 0.5, trim, M.SmoothPlastic)
	if style == "frame" or style == "pediment" then
		self:box("Trim", "Surround", o.x0 - 0.25, (o.y0 + o.y1) / 2, 0.1, 0.5, o.y1 - o.y0, 0.2, trim, M.SmoothPlastic)
		self:box("Trim", "Surround", o.x1 + 0.25, (o.y0 + o.y1) / 2, 0.1, 0.5, o.y1 - o.y0, 0.2, trim, M.SmoothPlastic)
	end
	if style == "pediment" then
		self:box("Trim", "Hood", cx, o.y1 + 0.3, 0.3, w + 1.2, 0.6, 0.6, trim, M.SmoothPlastic)
		self:box("Trim", "HoodCap", cx, o.y1 + 0.7, 0.4, w + 1.6, 0.2, 0.8, trim, M.SmoothPlastic)
	elseif style ~= "none" then
		self:box("Trim", "Lintel", cx, o.y1 + 0.3, 0.15, w + 0.8, 0.6, 0.3, trim, M.SmoothPlastic)
	end
end

-- 창 텍스처 고르기 (낡음 정도 반영)
function B:winTex(curtains)
	local r = self.rng:NextNumber()
	if r < self.decay * 0.28 then return "win_broken" end
	if r < self.decay * 0.42 then return "win_boarded" end
	return curtains or self:pick({"win_clean_a", "win_clean_a", "win_clean_b", "win_clean_c"})
end

-- 발코니: 개구부 o 앞. 바닥판 + 난간(텍스처 3면) + 까치발
function F:balcony(cx, y, w, depth)
	local b = self.b
	depth = depth or 3.2
	self:box("Balconies", "Slab", cx, y - 0.35, depth / 2, w, 0.7, depth, b.pal.trim, M.SmoothPlastic)
	self:box("Balconies", "SlabLip", cx, y - 0.78, depth / 2 + 0.05, w + 0.2, 0.16, depth + 0.1, b.pal.trim, M.SmoothPlastic)
	local railH = 3.2
	local front = self:box("Balconies", "Railing", cx, y + railH / 2, depth - 0.15, w - 0.1, railH, 0.1, IRON, M.Metal, {transparency = 1})
	b:decal(front, "rail_iron", Enum.NormalId.Back)
	b:decal(front, "rail_iron", Enum.NormalId.Front)
	for _, sx in ipairs({-1, 1}) do
		local side = self:box("Balconies", "Railing", cx + sx * (w / 2 - 0.1), y + railH / 2, depth / 2, 0.1, railH, depth - 0.2, IRON, M.Metal, {transparency = 1})
		b:decal(side, "rail_iron", Enum.NormalId.Left)
		b:decal(side, "rail_iron", Enum.NormalId.Right)
		-- 손잡이 (진짜 파트: 실루엣)
		self:box("Balconies", "Handrail", cx + sx * (w / 2 - 0.1), y + railH - 0.1, depth / 2, 0.22, 0.2, depth - 0.1, IRON, M.Metal)
		-- 까치발
		self:box("Balconies", "Bracket", cx + sx * (w / 2 - 0.6), y - 1.3, 0.8, 0.5, 1.2, 1.6, b.pal.trim, M.SmoothPlastic)
	end
	self:box("Balconies", "Handrail", cx, y + railH - 0.1, depth - 0.15, w, 0.2, 0.22, IRON, M.Metal)
	-- 화분 몇 개 (소품 템플릿 있으면)
	if b:chance(0.5) then b:prop("Planter_small", self.cf * CFrame.new(cx + b.rng:NextNumber(-w / 3, w / 3), y, depth * 0.55)) end
end

function F:flowerbox(o)
	local b = self.b
	local w = o.x1 - o.x0 + 0.4
	local cx = (o.x0 + o.x1) / 2
	local p = self:box("Decor", "Flowerbox", cx, o.y0 + 0.55, 0.75, w, w * 1.8 / 4.4, 0.1, WHITE, M.SmoothPlastic, {transparency = 1, deco = true, noShadow = true})
	b:decal(p, "flowerbox_a", Enum.NormalId.Back)
	-- 화분 몸통은 진짜 상자 (옆에서 봐도 보이게)
	self:box("Decor", "FlowerboxBody", cx, o.y0 + 0.2, 0.55, w - 0.3, 0.75, 0.7, Color3.fromRGB(176, 104, 76), M.Wood)
end

function F:vines(x, yTop, w, h)
	local b = self.b
	local p = self:box("Decor", "Vines", x, yTop - h / 2, 0.08, w, h, 0.05, Color3.new(0, 0, 0), M.SmoothPlastic, {transparency = 1, deco = true, noShadow = true})
	b:decal(p, "vines_a", Enum.NormalId.Back)
end

-- 줄무늬 차양 (상점)
function F:awning(cx, y, w, depth, c1, c2)
	local b = self.b
	depth = depth or 4
	local drop = 2.2
	local n = math.max(4, math.floor(w / 1.6))
	local sw = w / n
	local len = math.sqrt(depth * depth + drop * drop)
	local ang = math.atan2(drop, depth)
	for i = 1, n do
		local x = cx - w / 2 + sw * (i - 0.5)
		local col = (i % 2 == 0) and c1 or c2
		local cf = self.cf * CFrame.new(x, y - drop / 2, depth / 2) * CFrame.Angles(-ang, 0, 0)
		b:part("Awnings", "Stripe", Vector3.new(sw, 0.15, len), cf, col, M.Fabric)
		-- 앞 늘어뜨림
		b:part("Awnings", "Valance", Vector3.new(sw, 0.9, 0.1), self.cf * CFrame.new(x, y - drop - 0.45, depth), col, M.Fabric)
	end
	-- 지지대
	for _, sx in ipairs({-1, 1}) do
		-- 지지대: 차양 경사를 따라 바로 아래 (수평이면 앞으로 튀어나옴)
		b:part("Awnings", "Arm", Vector3.new(0.12, 0.12, len), self.cf * CFrame.new(cx + sx * (w / 2 - 0.1), y - drop / 2 - 0.15, depth / 2) * CFrame.Angles(-ang, 0, 0), IRON, M.Metal)
	end
end

function F:sign(cx, y, w, h, text, bg, fg)
	local b = self.b
	local p = self:box("Signs", "Sign", cx, y, 0.2, w, h, 0.4, bg or Color3.fromRGB(40, 52, 48), M.SmoothPlastic)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 1
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.Fondamento
	t.TextColor3 = fg or Color3.fromRGB(240, 226, 190)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.12, 0), UDim.new(0.12, 0)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.05, 0), UDim.new(0.05, 0)
	pad.Parent = t
	t.Parent = g
	g.Parent = p
	return p
end

---------------------------------------------------------------- 소품 템플릿
-- ServerStorage.Kit22_Props 의 모델(AI 생성 메시 등)을 복제. 없으면 아무것도 안 함.
function B:prop(name, cf)
	local SS = game:GetService("ServerStorage")
	local lib = SS:FindFirstChild("Kit22_Props")
	local t = lib and lib:FindFirstChild(name)
	if not t then return nil end
	local c = t:Clone()
	c:PivotTo(cf * CFrame.Angles(0, self.rng:NextNumber(0, math.pi * 2), 0))
	-- 템플릿 피벗 = 바닥 중심으로 맞춰 둠
	c.Parent = self:folder("Props")
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then self.count += 1 end end
	return c
end

---------------------------------------------------------------- 상자형 건물 공통
-- 네 면을 만들고 { front, back, left, right } 반환. 앞/뒤는 전체 폭, 옆은 두께만큼 안쪽.
function B:shell(W, D, H, T, origin)
	T = T or 1
	origin = origin or CFrame.new()
	local function fc(pos, out) return self:face(origin * pos, origin:VectorToWorldSpace(out), 0, H) end
	local faces = {
		front = fc(Vector3.new(0, 0, -D / 2), Vector3.new(0, 0, -1)),
		back = fc(Vector3.new(0, 0, D / 2), Vector3.new(0, 0, 1)),
		left = fc(Vector3.new(-W / 2, 0, 0), Vector3.new(-1, 0, 0)),
		right = fc(Vector3.new(W / 2, 0, 0), Vector3.new(1, 0, 0)),
	}
	faces.front.w, faces.back.w = W, W
	faces.left.w, faces.right.w = D - 2 * T, D - 2 * T
	-- 지붕판
	self:part("Roof", "RoofSlab", Vector3.new(W - 2 * T, 0.8, D - 2 * T), origin * CFrame.new(0, H - 0.4, 0), Color3.fromRGB(96, 94, 92), M.Concrete)
	return faces
end

-- 지붕 위: 난간벽(파라펫) + 설비
function B:roofTop(W, D, H, opts)
	opts = opts or {}
	local O = opts.origin or CFrame.new()
	local ph = opts.parapet or 2.2
	local c = self.pal.wall
	local cap = self.pal.trim
	for _, s in ipairs({{0, -D / 2 + 0.5, W, 1}, {0, D / 2 - 0.5, W, 1}, {-W / 2 + 0.5, 0, 1, D - 2}, {W / 2 - 0.5, 0, 1, D - 2}}) do
		self:part("Roof", "Parapet", Vector3.new(s[3], ph, s[4]), O * CFrame.new(s[1], H + ph / 2, s[2]), opts.color or c, opts.mat or self.wallMat)
		self:part("Roof", "ParapetCap", Vector3.new(s[3] + 0.4, 0.3, s[4] + 0.4), O * CFrame.new(s[1], H + ph + 0.15, s[2]), cap, M.SmoothPlastic)
	end
	-- 옥상 출입구 상자
	if opts.hut ~= false and W > 20 then
		local hx, hz = self.rng:NextNumber(-W / 4, W / 4), self.rng:NextNumber(-D / 6, D / 4)
		self:part("Roof", "StairHut", Vector3.new(8, 8, 7), O * CFrame.new(hx, H + 4, hz), self.pal.base, M.Concrete)
		self:part("Roof", "StairHutTop", Vector3.new(8.6, 0.5, 7.6), O * CFrame.new(hx, H + 8.25, hz), cap, M.SmoothPlastic)
	end
	-- 실외기 / 물탱크 (템플릿)
	for i = 1, self.rng:NextInteger(1, 3) do
		self:prop("RoofAC", O * CFrame.new(self.rng:NextNumber(-W / 2 + 4, W / 2 - 4), H, self.rng:NextNumber(-D / 2 + 4, D / 2 - 4)))
	end
	if opts.tank or self:chance(0.35) then
		self:prop("WaterTank", O * CFrame.new(self.rng:NextNumber(-W / 3, W / 3), H, self.rng:NextNumber(0, D / 3)))
	end
end

-- 코니스(3단) 를 네 면에
function B:cornice(faces, H, big)
	local k = big and 1.4 or 1
	for _, f in pairs(faces) do
		f:band(H - 1.0 * k, 0.5 * k, 0.5 * k, self.pal.trim, 0.5 * k)
		f:band(H - 0.5 * k, 0.5 * k, 1.0 * k, self.pal.trim, 1.0 * k)
	end
end

-- 바닥 기단(어두운 돌)
function B:plinth(faces, h)
	for _, f in pairs(faces) do
		f:box("Trim", "Plinth", 0, h / 2, 0.15, f.w + 0.6, h, 0.3, self.pal.base, M.Concrete)
	end
end

---------------------------------------------------------------- 추가 도구 (22번 2차)
-- 파트를 모두 평행이동 (본체 옆에 날개를 붙인 뒤 전체를 가운데로)
function B:shift(dx, dz)
	for _, d in ipairs(self.model:GetDescendants()) do
		if d:IsA("BasePart") then d.CFrame = d.CFrame + Vector3.new(dx, 0, dz or 0) end
	end
end

-- 타일 텍스처 (커튼월, 골함석 등). color 로 색 입힘
function B:texture(part, tex, face, u, v, color, transparency)
	local t = Instance.new("Texture")
	t.Texture = Kit.TEX[tex] or tex
	t.Face = face or Enum.NormalId.Back
	t.StudsPerTileU, t.StudsPerTileV = u, v
	if color then t.Color3 = color end
	if transparency then t.Transparency = transparency end
	t.Parent = part
	return t
end

-- 박공지붕. center = 처마 높이의 지붕 중심 CFrame, 용마루 = center 의 X 축. W 용마루 방향 길이, D 가로 폭.
-- 양 끝 삼각 벽(박공)은 벽색 쐐기 2개씩. 반환: 지붕 높이 R
function B:gableRoof(center, W, D, opts)
	opts = opts or {}
	local pitch = math.rad(opts.pitch or 32)
	local ov = opts.overhang or 1.2
	local R = (D / 2) * math.tan(pitch)
	local roofC = opts.color or Color3.fromRGB(120, 66, 58)
	local roofM = opts.mat or M.ClayRoofTiles
	local half = D / 2 + ov
	local L = half / math.cos(pitch)
	local t = 0.6
	for _, s in ipairs({1, -1}) do
		local mid = Vector3.new(0, R - (half / 2) * math.tan(pitch) + (t / 2) / math.cos(pitch), s * half / 2)
		self:part("Roof", "RoofPlane", Vector3.new(W + 2 * ov, t, L), center * CFrame.new(mid) * CFrame.Angles(s * pitch, 0, 0), roofC, roofM)
	end
	self:part("Roof", "Ridge", Vector3.new(W + 2 * ov + 0.2, 0.5, 0.9), center * CFrame.new(0, R + 0.35, 0), roofC:Lerp(Color3.new(0, 0, 0), 0.25), roofM)
	if opts.gables ~= false then
		for _, sx in ipairs({1, -1}) do
			for _, sz in ipairs({1, -1}) do
				local cf = center * CFrame.new(sx * (W / 2 - 0.5), R / 2, sz * D / 4) * CFrame.Angles(0, sz == 1 and math.pi or 0, 0)
				self:part("Walls", "Gable", Vector3.new(1, R, D / 2), cf, opts.wallColor or self.pal.wall, opts.wallMat or self.wallMat, {wedge = true})
			end
		end
	end
	return R
end

-- 계단식 첨탑 (교회 등): cf = 바닥 중심
function B:spire(cf, w, h, color, mat)
	local steps = 6
	local y = 0
	for i = 1, steps do
		local k = 1 - (i - 1) / steps
		local sh = h / steps
		self:part("Roof", "Spire", Vector3.new(w * k, sh, w * k), cf * CFrame.new(0, y + sh / 2, 0) * CFrame.Angles(0, (i % 2) * math.pi / 4, 0), color, mat)
		y += sh
	end
	self:part("Roof", "SpireTip", Vector3.new(0.3, 4, 0.3), cf * CFrame.new(0, y + 2, 0), Color3.fromRGB(60, 60, 60), M.Metal)
end

-- 원기둥(세로). x,y0 는 면 좌표
function F:column(x, y0, h, r, z, color, mat)
	local b = self.b
	color = color or b.pal.trim
	b:part("Trim", "Column", Vector3.new(h, r * 2, r * 2), self.cf * CFrame.new(x, y0 + h / 2, z) * CFrame.Angles(0, 0, math.pi / 2), color, mat or M.SmoothPlastic, {shape = Enum.PartType.Cylinder})
	self:box("Trim", "ColumnBase", x, y0 + 0.4, z, r * 2 + 0.6, 0.8, r * 2 + 0.6, color, mat or M.SmoothPlastic)
	self:box("Trim", "ColumnCap", x, y0 + h - 0.4, z, r * 2 + 0.8, 0.8, r * 2 + 0.8, color, mat or M.SmoothPlastic)
end

-- 덧창 (창 양옆)
function F:shutters(o, color)
	local h = o.y1 - o.y0
	local w = (o.x1 - o.x0) / 2
	for _, sx in ipairs({-1, 1}) do
		local x = sx < 0 and o.x0 - w / 2 - 0.1 or o.x1 + w / 2 + 0.1
		self:box("Trim", "Shutter", x, (o.y0 + o.y1) / 2, 0.12, w, h, 0.24, color, M.WoodPlanks)
	end
end

-- 현관 포치: 바닥판 + 기둥 + 지붕판
function F:porch(cx, w, depth, h, opts)
	opts = opts or {}
	local b = self.b
	local fh = opts.floorH or 1.2
	self:box("Porch", "PorchFloor", cx, fh / 2, depth / 2, w, fh, depth, opts.floorColor or b.pal.base, M.WoodPlanks)
	local n = math.max(2, math.floor(w / 7) + 1)
	for i = 0, n - 1 do
		local x = cx - w / 2 + 0.5 + (w - 1) * i / (n - 1)
		self:box("Porch", "PorchPost", x, fh + h / 2, depth - 0.5, 0.6, h, 0.6, b.pal.trim, M.SmoothPlastic)
	end
	self:box("Porch", "PorchRoof", cx, fh + h + 0.3, depth / 2, w + 0.8, 0.6, depth + 0.8, opts.roofColor or b.pal.trim, opts.roofMat or M.SmoothPlastic)
	self:box("Porch", "PorchStep", cx + (opts.stepX or 0), fh / 4, depth + 0.6, 4, fh / 2, 1.2, opts.floorColor or b.pal.base, M.WoodPlanks)
	if opts.rail then
		local r = self:box("Porch", "PorchRail", cx, fh + 1.5, depth - 0.5, w - 1, 3, 0.1, IRON, M.Metal, {transparency = 1})
		b:decal(r, "rail_iron", Enum.NormalId.Back)
	end
end

-- 세로 돌출 간판 (호텔·극장). x = 면 위치, 양면에 세로 글자
function F:bladeSign(x, y0, h, text, bg, fg)
	local b = self.b
	local p = self:box("Signs", "BladeSign", x, y0 + h / 2, 2.2, 0.8, h, 3.6, bg or Color3.fromRGB(40, 30, 34), M.SmoothPlastic)
	local ev = Kit.SIGN_V and Kit.SIGN_V[text]
	if ev then -- 미리 구운 세로 글씨: 양옆 면에 카드
		local tw = 3.6 * 0.75
		local th = tw / ev[2]
		if th > h * 0.92 then th = h * 0.92 tw = th * ev[2] end
		for _, sx in ipairs({-1, 1}) do
			local c = Instance.new("Part")
			c.Name, c.Anchored, c.CanCollide, c.CanTouch, c.CanQuery, c.CastShadow = "SignText", true, false, false, false, false
			c.Transparency = 1
			-- 옆면(Left/Right) 데칼은 글씨가 옆으로 누움 → 카드를 90° 돌려 앞(Back) 면을 바깥으로
			c.Size = Vector3.new(tw, th, 0.02)
			c.CFrame = p.CFrame * CFrame.new(sx * 0.42, 0, 0) * CFrame.Angles(0, sx * math.pi / 2, 0)
			local d = Instance.new("Decal")
			d.Texture = ev[1]
			d.Face = Enum.NormalId.Back
			d.Color3 = fg or Color3.fromRGB(255, 196, 120)
			d.Parent = c
			c.Parent = p.Parent
			self.b.count += 1
		end
		return p
	end
	local letters = {}
	for _, cp in utf8.codes(text) do table.insert(letters, utf8.char(cp)) end -- 한글은 여러 바이트라 바이트 단위로 자르면 깨짐
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 30
		g.LightInfluence = 0
		g.Brightness = 1.4
		local lay = Instance.new("UIListLayout")
		lay.FillDirection = Enum.FillDirection.Vertical
		lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
		lay.VerticalAlignment = Enum.VerticalAlignment.Center
		lay.Parent = g
		for i, c in ipairs(letters) do
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, 0, 0.9 / #letters, 0)
			t.BackgroundTransparency = 1
			t.Text = c
			t.TextScaled = true
			t.FontFace = Font.fromEnum(Enum.Font.GothamBlack) -- 한글도 나오는 글꼴 (FredokaOne 은 한글이 "?" 로 깨짐)
			t.TextColor3 = fg or Color3.fromRGB(255, 196, 120)
			t.LayoutOrder = i
			t.Parent = g
		end
		g.Parent = p
	end
	return p
end

-- 단순 면들에 창 카드 배치 (옆/뒤)
function B:simpleFaces(faces, names, o)
	for _, n in ipairs(names) do
		local s = faces[n]
		local cnt = math.max(1, math.floor(s.w / (o.spacing or 9)))
		for fl = (o.ground and 1 or 2), o.floors do
			local y0 = fl == 1 and 0 or o.G + o.FH * (fl - 2)
			for i = 1, cnt do
				s:open(-s.w / 2 + s.w * (i - 0.5) / cnt, y0 + (o.sill or 2.8), o.ww or 4, o.wh or 6, "Window", o.tex and o.tex(self) or self:winTex())
			end
		end
		s:buildFlat(1, o.color, o.mat)
	end
end

function Kit.floorY(G, FH, fl) return fl == 1 and 0 or G + FH * (fl - 2) end

---------------------------------------------------------------- 건물 종류
Kit.TYPES = {}

-- 1. 발코니 아파트 (참고 이미지의 기본형). 4~6층, 파스텔, 위층 일부 칸에 발코니.
Kit.TYPES.apt_balcony = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(4, 6)
	local G, FH = 13, 12
	local H = G + FH * (floors - 1)
	local bays = p.bays or b.rng:NextInteger(4, 6)
	local bw = 8
	local W = p.w or bays * bw + 4
	local D = p.d or 30
	bw = (W - 4) / bays
	local faces = b:shell(W, D, H)
	local f = faces.front
	local doorBay = math.ceil(bays / 2)
	local balconyCols = {}
	for i = 1, bays do balconyCols[i] = (i % 2 == (bays % 2 == 0 and 0 or 1)) end
	local curtains = nil
	for fl = 1, floors do
		local y0 = fl == 1 and 0 or G + FH * (fl - 2)
		for i = 1, bays do
			local cx = -W / 2 + 2 + bw * (i - 0.5)
			if fl == 1 then
				if i == doorBay then
					f:open(cx, 0.6, 4.4, 9, "Door", b:pick({"door_green", "door_red"}), {recess = 0.7})
				else
					local o = f:open(cx, 3.6, 4, 6, "Window", b:winTex(curtains))
					f:windowTrim(o, "lintel")
				end
			else
				local bal = balconyCols[i] and fl >= 2
				local o = f:open(cx, y0 + (bal and 1.2 or 2.8), 4, bal and 7.4 or 6, "Window", b:winTex(curtains))
				if bal then
					f:balcony(cx, y0 + 1.0, math.min(bw - 0.6, 7))
					o.recess = 0.5
					f:windowTrim(o, "none")
					f:box("Trim", "Lintel", cx, o.y1 + 0.3, 0.15, 4.8, 0.6, 0.3, b.pal.trim, M.SmoothPlastic)
				else
					f:windowTrim(o, fl == 2 and "pediment" or "frame")
					if b:chance(0.45) then f:flowerbox(o) end
				end
			end
		end
	end
	f:buildWall(1)
	-- 문 앞 계단 + 문 위 작은 캐노피
	local dcx = -W / 2 + 2 + bw * (doorBay - 0.5)
	f:box("Trim", "Step", dcx, 0.3, 0.9, 6, 0.6, 1.8, b.pal.base, M.Concrete)
	f:box("Trim", "DoorHood", dcx, 10.4, 0.9, 6.4, 0.5, 1.8, b.pal.trim, M.SmoothPlastic)
	-- 옆/뒤: 단순 면
	for _, side in ipairs({"left", "right", "back"}) do
		local s = faces[side]
		local n = math.max(1, math.floor(s.w / 9))
		for fl = 2, floors do
			local y0 = G + FH * (fl - 2)
			for i = 1, n do
				s:open(-s.w / 2 + s.w * (i - 0.5) / n, y0 + 2.8, 4, 6, "Window", b:winTex())
			end
		end
		s:buildFlat(1)
	end
	-- 층 띠, 기단, 코니스
	for _, s in pairs(faces) do
		s:band(G - 0.5, 0.6, 0.35)
	end
	b:plinth(faces, 2.4)
	b:cornice(faces, H, false)
	b:roofTop(W, D, H)
	-- 덩굴
	if b:chance(0.4 + b.decay * 0.6) then
		local vx = -W / 2 + b.rng:NextNumber(3, W - 3)
		f:vines(vx, H - 1.2, 6, b.rng:NextNumber(10, 20))
	end
	return {W = W, D = D, H = H}
end

-- 2. 좁은 타운하우스: 3~4층, 한쪽은 2층 높이 돌출창(베이 윈도), 다른 쪽은 계단 있는 현관
Kit.TYPES.townhouse = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(3, 4)
	local FH = 12
	local G = 13
	local H = G + FH * (floors - 1)
	local W = p.w or b.rng:NextInteger(18, 22)
	local D = p.d or 28
	local faces = b:shell(W, D, H)
	local f = faces.front
	local left = b:chance(0.5) and -1 or 1
	local doorX = left * (W / 2 - 4.5)
	local bayX = -left * (W / 4)
	local bayW = W / 2 - 1
	-- 현관: 높은 기단 + 계단
	local stoop = 3
	f:open(doorX, stoop, 4.4, 9, "Door", b:pick({"door_green", "door_red"}), {recess = 0.8})
	f:box("Trim", "Stoop", doorX, stoop / 2, 1.3, 5.6, stoop, 2.6, b.pal.base, M.Concrete)
	for k = 1, 3 do
		local top = stoop * (1 - k / 4)
		f:box("Trim", "Step", doorX, top / 2, 2.6 + (k - 0.5) * 0.9, 5.6, top, 0.9, b.pal.base, M.Concrete)
	end
	f:box("Trim", "DoorHood", doorX, stoop + 9.6, 1.0, 6.2, 0.6, 2.0, b.pal.trim, M.SmoothPlastic)
	for _, sx in ipairs({-1, 1}) do
		f:box("Trim", "DoorColumn", doorX + sx * 2.8, stoop + 4.7, 0.25, 0.6, 9.4, 0.5, b.pal.trim, M.SmoothPlastic)
	end
	-- 베이 윈도 (1~2층): 앞으로 튀어나온 상자, 앞면에 창 2개
	local bayD, bayH = 2.6, G + FH - 1
	local bay = b:face(f.cf * Vector3.new(bayX, 0, bayD), f.cf.ZVector, bayW, bayH)
	for fl = 1, 2 do
		local y0 = fl == 1 and 3.6 or G + 2.8
		for k = -1, 1, 2 do
			local o = bay:open(k * bayW / 4, y0, math.min(4, bayW / 2 - 1.2), 6, "Window", b:winTex())
			bay:windowTrim(o, "lintel")
		end
	end
	bay:buildWall(1)
	for _, sx in ipairs({-1, 1}) do
		-- 베이 옆면
		f:box("Walls", "BaySide", bayX + sx * (bayW / 2 - 0.5), bayH / 2, bayD / 2, 1, bayH, bayD, b.pal.wall, b.wallMat)
	end
	f:box("Trim", "BayTop", bayX, bayH + 0.3, bayD / 2, bayW + 0.6, 0.6, bayD + 0.6, b.pal.trim, M.SmoothPlastic)
	-- 정면 나머지: 현관 위 창, 3층 이상은 창 2개
	local upperStart = 2
	for fl = upperStart, floors do
		local y0 = G + FH * (fl - 2)
		if fl >= 3 then
			for _, x in ipairs({bayX - bayW / 4, bayX + bayW / 4}) do
				local o = f:open(x, y0 + 2.8, 4, 6, "Window", b:winTex())
				f:windowTrim(o, "frame")
				if b:chance(0.5) then f:flowerbox(o) end
			end
		end
		local o = f:open(doorX, y0 + 2.8, 4, 6, "Window", b:winTex())
		f:windowTrim(o, fl == 2 and "pediment" or "frame")
	end
	f:buildWall(1)
	for _, side in ipairs({"left", "right", "back"}) do
		local s = faces[side]
		if side == "back" then
			for fl = 2, floors do
				s:open(-W / 4, G + FH * (fl - 2) + 2.8, 4, 6, "Window", b:winTex())
				s:open(W / 4, G + FH * (fl - 2) + 2.8, 4, 6, "Window", b:winTex())
			end
		end
		s:buildFlat(1)
	end
	b:plinth({front = f}, 2.4)
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	if b:chance(0.5 + b.decay * 0.5) then f:vines(doorX + left * 1.2, H - 1.4, 5, b.rng:NextNumber(8, 16)) end
	return {W = W, D = D, H = H}
end

-- 3. 모퉁이 상가 주택: 1층 상점 2~3칸(차양, 간판), 위 3~4층 창 + 화분
local SHOP_NAMES = {"CAFE", "BAKERY", "MARKET", "PHARMACY", "BOOKS", "FLOWERS", "DELI", "HARDWARE", "LAUNDRY", "DINER"}
Kit.TYPES.corner_shop = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(4, 5)
	local G, FH = 14, 12
	local H = G + FH * (floors - 1)
	local shops = p.shops or b.rng:NextInteger(2, 3)
	local sw = 13
	local W = p.w or shops * (sw + 1) + 3
	local D = p.d or 34
	local faces = b:shell(W, D, H)
	local f = faces.front
	local unit = (W - 2) / shops
	local AW = {
		{Color3.fromRGB(46, 98, 84), Color3.fromRGB(240, 234, 220)},
		{Color3.fromRGB(176, 58, 64), Color3.fromRGB(240, 234, 220)},
		{Color3.fromRGB(46, 70, 120), Color3.fromRGB(236, 230, 214)},
		{Color3.fromRGB(214, 150, 60), Color3.fromRGB(246, 238, 220)},
	}
	for i = 1, shops do
		local cx = -W / 2 + 1 + unit * (i - 0.5)
		local tex = b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean"
		f:open(cx, 1.0, unit - 2, 9.2, "Shopfront", tex, {recess = 0.6})
		local c = b:pick(AW)
		f:awning(cx, 11.2, unit - 2.4, 4, c[1], c[2])
		f:sign(cx, 12.4, unit - 3, 1.6, b:pick(SHOP_NAMES), Color3.fromRGB(34, 44, 40))
	end
	-- 위층 창
	local nW = math.max(3, math.floor(W / 8.5))
	for fl = 2, floors do
		local y0 = G + FH * (fl - 2)
		for i = 1, nW do
			local cx = -W / 2 + W * (i - 0.5) / nW
			local o = f:open(cx, y0 + 2.8, 4, 6, "Window", b:winTex())
			f:windowTrim(o, fl == floors and "frame" or "pediment")
			if b:chance(0.5) then f:flowerbox(o) end
		end
	end
	f:buildWall(1)
	-- 상점 사이 기둥(진한 색)
	for i = 0, shops do
		local x = -W / 2 + 1 + unit * i
		f:box("Trim", "ShopPier", x, 6, 0.25, 1.4, 12, 0.5, Color3.fromRGB(70, 66, 62), M.Granite)
	end
	f:box("Trim", "ShopCornice", 0, 13.4, 0.5, W + 1, 1.2, 1.0, b.pal.trim, M.SmoothPlastic)
	-- 옆면(모퉁이): 상점 1칸 + 창
	local r = faces.right
	r:open(-r.w / 2 + 9, 1.0, 11, 9.2, "Shopfront", "shop_clean", {recess = 0.6})
	for fl = 2, floors do
		local y0 = G + FH * (fl - 2)
		for i = 1, math.max(2, math.floor(r.w / 9)) do
			local o = r:open(-r.w / 2 + r.w * (i - 0.5) / math.max(2, math.floor(r.w / 9)), y0 + 2.8, 4, 6, "Window", b:winTex())
			r:windowTrim(o, "frame")
		end
	end
	r:buildWall(1)
	r:box("Trim", "ShopCornice", 0, 13.4, 0.5, r.w + 3, 1.2, 1.0, b.pal.trim, M.SmoothPlastic)
	for _, side in ipairs({"left", "back"}) do faces[side]:buildFlat(1) end
	for _, s in pairs(faces) do
		for fl = 3, floors do s:band(G + FH * (fl - 2) - 0.3, 0.5, 0.3) end
	end
	b:cornice(faces, H, true)
	b:roofTop(W, D, H)
	return {W = W, D = D, H = H}
end

-- 4. 벽돌 연립(테너먼트): 5~6층 벽돌, 흰 석재 창 상인방, 정면 비상계단
Kit.TYPES.brick_tenement = function(b)
	local p = b.p
	b.pal = Kit.PALETTES[p.palette or b:pick({"brick", "brickdark"})]
	b.wallMat = b.pal.mat
	local floors = p.floors or b.rng:NextInteger(5, 6)
	local G, FH = 13, 11.5
	local H = G + FH * (floors - 1)
	local bays = p.bays or b.rng:NextInteger(4, 5)
	local W = p.w or bays * 7.5 + 3
	local D = p.d or 32
	local bw = (W - 3) / bays
	local faces = b:shell(W, D, H)
	local f = faces.front
	local doorBay = 1
	local feBays = {bays - 1, bays} -- 비상계단 칸
	for fl = 1, floors do
		local y0 = fl == 1 and 0 or G + FH * (fl - 2)
		for i = 1, bays do
			local cx = -W / 2 + 1.5 + bw * (i - 0.5)
			if fl == 1 and i == doorBay then
				f:open(cx, 0.6, 4.4, 9, "Door", "door_green", {recess = 0.8})
			else
				local o = f:open(cx, (fl == 1 and 3.6 or y0 + 2.6), 4, 6, "Window", b:winTex())
				f:windowTrim(o, "lintel")
			end
		end
	end
	f:buildWall(1)
	-- 비상계단: 각 층 발판 + 난간 + 사다리
	local fx = -W / 2 + 1.5 + bw * (bays - 1)
	local fw = bw * 2 - 1
	for fl = 2, floors do
		local y = G + FH * (fl - 2) + 0.4
		f:box("FireEscape", "Landing", fx, y, 2.0, fw, 0.25, 4, IRON, M.DiamondPlate)
		local rail = f:box("FireEscape", "Railing", fx, y + 1.7, 3.9, fw, 3.2, 0.1, IRON, M.Metal, {transparency = 1})
		b:decal(rail, "rail_iron", Enum.NormalId.Back)
		b:decal(rail, "rail_iron", Enum.NormalId.Front)
		f:box("FireEscape", "Handrail", fx, y + 3.2, 3.9, fw, 0.18, 0.18, IRON, M.Metal)
		for _, sx in ipairs({-1, 1}) do
			f:box("FireEscape", "Post", fx + sx * fw / 2, y + 1.6, 3.9, 0.2, 3.2, 0.2, IRON, M.Metal)
		end
		if fl < floors then
			-- 위층으로 기운 계단
			local rise = FH
			local run = fw * 0.7
			local len = math.sqrt(rise * rise + run * run)
			local cf = f.cf * CFrame.new(fx, y + rise / 2, 2.2) * CFrame.Angles(0, 0, math.atan2(rise, run))
			b:part("FireEscape", "Stair", Vector3.new(len, 0.25, 1.8), cf, IRON, M.DiamondPlate)
		end
	end
	for _, side in ipairs({"left", "right", "back"}) do
		local s = faces[side]
		local n = math.max(1, math.floor(s.w / 8))
		for fl = 2, floors do
			for i = 1, n do s:open(-s.w / 2 + s.w * (i - 0.5) / n, G + FH * (fl - 2) + 2.6, 4, 6, "Window", b:winTex()) end
		end
		s:buildFlat(1)
	end
	b:plinth(faces, 3)
	for _, s in pairs(faces) do s:band(G - 0.6, 0.6, 0.4) end
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {tank = true})
	if b:chance(0.6) then f:vines(-W / 2 + b.rng:NextNumber(3, W / 2), H - 1.4, 6, b.rng:NextNumber(12, 24)) end
	return {W = W, D = D, H = H}
end

---------------------------------------------------------------- 진입점
function Kit.build(typeName, parent, cf, params)
	local fn = Kit.TYPES[typeName]
	assert(fn, "unknown type " .. tostring(typeName))
	local b = Kit.newBuilder(typeName, params)
	local info = fn(b)
	b.model:SetAttribute("Kit22Type", typeName)
	b.model:SetAttribute("Kit22Seed", b.p.seed or 1)
	if info then b.model:SetAttribute("Kit22Size", Vector3.new(info.W, info.H, info.D)) end
	b.model.WorldPivot = CFrame.new()
	b.model:PivotTo(cf)
	b.model.Parent = parent
	return b.model, b.count, info
end

-- 조명 프리셋: 참고 이미지(분홍·보라 노을). 원래 값은 Before22_<속성> 에 1회 보존.
function Kit.applyLighting(name)
	local L = game:GetService("Lighting")
	local function set(obj, prop, value)
		local key = "Before22_" .. prop
		if obj:GetAttribute(key) == nil then obj:SetAttribute(key, obj[prop]) end
		obj[prop] = value
	end
	local atm = L:FindFirstChildOfClass("Atmosphere")
	local cc = L:FindFirstChildOfClass("ColorCorrectionEffect")
	local bloom = L:FindFirstChildOfClass("BloomEffect")
	if name == "dusk" then
		-- 하늘: make_sky.py 로 만든 노을 스카이박스 (기존 Sky 없음 → 새로 추가, Added22)
		local sky = L:FindFirstChild("Kit22_Sky") or Instance.new("Sky")
		sky.Name = "Kit22_Sky"
		sky:SetAttribute("Added22", true)
		sky.SkyboxFt = "rbxassetid://75536185937589"
		sky.SkyboxLf = "rbxassetid://98395668534861"
		sky.SkyboxBk = "rbxassetid://127355836071983"
		sky.SkyboxRt = "rbxassetid://73956999315109"
		sky.SkyboxUp = "rbxassetid://90326716932073"
		sky.SkyboxDn = "rbxassetid://118004216930398"
		sky.CelestialBodiesShown = false
		sky.Parent = L
		set(L, "ClockTime", 17.55)
		set(L, "GeographicLatitude", 35)
		set(L, "Brightness", 3)
		set(L, "Ambient", Color3.fromRGB(72, 68, 74))
		set(L, "OutdoorAmbient", Color3.fromRGB(132, 126, 134))
		set(L, "ColorShift_Top", Color3.fromRGB(255, 214, 190))
		set(L, "EnvironmentDiffuseScale", 1)
		set(L, "EnvironmentSpecularScale", 1)
		set(L, "ExposureCompensation", 0.15)
		if atm then
			set(atm, "Density", 0.26)
			set(atm, "Offset", 0)
			set(atm, "Color", Color3.fromRGB(236, 196, 196))
			set(atm, "Decay", Color3.fromRGB(160, 140, 170))
			set(atm, "Glare", 0)
			set(atm, "Haze", 0.6)
		end
		if cc then
			set(cc, "Saturation", 0.05)
			set(cc, "Contrast", 0.08)
			set(cc, "Brightness", 0.02)
			set(cc, "TintColor", Color3.fromRGB(255, 250, 246))
		end
		if bloom then
			set(bloom, "Intensity", 0.5)
			set(bloom, "Size", 28)
			set(bloom, "Threshold", 1.6)
		end
	end
end
