---------------------------------------------------------------- 아포칼립스 처리 (22번): 조명 "ash", 건물 풍화, 마른/죽은 나무. kit_nature 뒤에 붙임 (deploy.sh)
Kit.TEX.leaf_dry = "rbxassetid://99422996624136"
Kit.TEX.cracks_a = "rbxassetid://129213499712776"
Kit.TEX.cracks_b = "rbxassetid://119516747924839"
Kit.TEX.moss_a = "rbxassetid://91693137169854"

local MA = Enum.Material
local DUST = Color3.fromRGB(128, 116, 100)

-- 아포칼립스 조명 프리셋. ash = 먼지 낀 황회색, dark = 더 어둡고 연기 낀 저녁(전 연령, 살짝 어둡게).
-- 원래 값 Before22_* (applyLighting 과 같은 키, 처음 값만 보존)
local SKIES = {
	ash = {"rbxassetid://71032454728518", "rbxassetid://109068506775271", "rbxassetid://106495962700568", "rbxassetid://115825428131953", "rbxassetid://131657876808887", "rbxassetid://120425767798440"},
	dark = {"rbxassetid://108300500978973", "rbxassetid://73376371036161", "rbxassetid://99245241615075", "rbxassetid://120739427629480", "rbxassetid://89494462052338", "rbxassetid://87858578934704"},
}
local LOOKS = {
	ash = {clock = 16.9, bright = 2.4, amb = {78, 72, 66}, out = {128, 118, 104}, shift = {255, 206, 160}, expo = 0.1,
		atm = {0.36, 0.1, {198, 172, 140}, {122, 106, 92}, 0.2, 2.0}, cc = {-0.12, 0.12, 0, {255, 242, 224}}, bloom = {0.3, 24, 1.8}},
	-- "살짝 더 어둡게": 처음 값(밝기 2.0·노출 -0.1)은 길바닥이 새까매져 너무 어두웠음 → 중간으로
	dark = {clock = 17.3, bright = 2.5, amb = {72, 68, 66}, out = {116, 108, 100}, shift = {255, 180, 120}, expo = 0.05,
		atm = {0.38, 0.05, {164, 148, 130}, {100, 90, 84}, 0.15, 2.3}, cc = {-0.2, 0.14, 0, {248, 236, 222}}, bloom = {0.35, 24, 1.6}},
}
local baseApply = Kit.applyLighting
function Kit.applyLighting(name)
	local look = LOOKS[name]
	if not look then return baseApply(name) end
	local L = game:GetService("Lighting")
	local function set(obj, prop, value)
		local key = "Before22_" .. prop
		if obj:GetAttribute(key) == nil then obj:SetAttribute(key, obj[prop]) end
		obj[prop] = value
	end
	local function rgb(t) return Color3.fromRGB(t[1], t[2], t[3]) end
	local sky = L:FindFirstChild("Kit22_Sky") or Instance.new("Sky")
	sky.Name = "Kit22_Sky"
	sky:SetAttribute("Added22", true)
	local ids = SKIES[name]
	sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxBk, sky.SkyboxRt, sky.SkyboxUp, sky.SkyboxDn = ids[1], ids[2], ids[3], ids[4], ids[5], ids[6]
	sky.CelestialBodiesShown = false
	sky.Parent = L
	set(L, "ClockTime", look.clock)
	set(L, "GeographicLatitude", 35)
	set(L, "Brightness", look.bright)
	set(L, "Ambient", rgb(look.amb))
	set(L, "OutdoorAmbient", rgb(look.out))
	set(L, "ColorShift_Top", rgb(look.shift))
	set(L, "ExposureCompensation", look.expo)
	local atm = L:FindFirstChildOfClass("Atmosphere")
	local cc = L:FindFirstChildOfClass("ColorCorrectionEffect")
	local bloom = L:FindFirstChildOfClass("BloomEffect")
	if atm then
		set(atm, "Density", look.atm[1]) set(atm, "Offset", look.atm[2]) set(atm, "Color", rgb(look.atm[3]))
		set(atm, "Decay", rgb(look.atm[4])) set(atm, "Glare", look.atm[5]) set(atm, "Haze", look.atm[6])
	end
	if cc then
		set(cc, "Saturation", look.cc[1]) set(cc, "Contrast", look.cc[2]) set(cc, "Brightness", look.cc[3]) set(cc, "TintColor", rgb(look.cc[4]))
	end
	if bloom then set(bloom, "Intensity", look.bloom[1]) set(bloom, "Size", look.bloom[2]) set(bloom, "Threshold", look.bloom[3]) end
end

local function aabbY(p)
	local cf, s = p.CFrame, p.Size / 2
	local hy = math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z
	return p.Position.Y - hy, p.Position.Y + hy
end

-- 건물 풍화. model = Kit.build 결과(배치 후). level 0~1
function Kit.weather(model, opts)
	opts = opts or {}
	local level = opts.level or 0.8
	local rng = Random.new(opts.seed or 7)
	local groundY = opts.groundY or model:GetPivot().Position.Y
	local function folder(n) return model:FindFirstChild(n) end
	-- 1. 색 바램 (먼지색 쪽으로)
	for _, fn in ipairs({"Walls", "Trim", "Balconies", "Awnings", "Signs", "Porch", "Roof"}) do
		local f = folder(fn)
		if f then
			for _, p in ipairs(f:GetDescendants()) do
				if p:IsA("BasePart") and p.Transparency < 1 then p.Color = p.Color:Lerp(DUST, 0.16 + 0.16 * level + (opts.fade or 0)) end
			end
		end
	end
	local deco = folder("Decor") or Instance.new("Folder")
	deco.Name = "Decor"
	deco.Parent = model
	-- 2. 벽: 빗물 때 텍스처 + 바닥 이끼 띠 + 덩굴
	local walls = folder("Walls")
	if walls then
		for _, w in ipairs(walls:GetChildren()) do
			if w:IsA("Part") and w.Name == "Wall" and w.Size.X >= 3 and w.Size.Y >= 3 then
				local t = Instance.new("Texture")
				t.Texture = Kit.TEX.grime_streaks
				t.Face = Enum.NormalId.Back
				t.StudsPerTileU, t.StudsPerTileV = 16, 16
				t.OffsetStudsU, t.OffsetStudsV = rng:NextNumber(0, 16), rng:NextNumber(0, 16)
				t.Transparency = 1 - math.min(0.95, 0.35 + 0.6 * level)
				t.Parent = w
				if rng:NextNumber() < (opts.burn or 0) then
					local sb = Instance.new("Texture")
					sb.Texture = Kit.TEX.soot_burn
					sb.Face = Enum.NormalId.Back
					sb.StudsPerTileU, sb.StudsPerTileV = 14, 14
					sb.OffsetStudsU, sb.OffsetStudsV = rng:NextNumber(0, 14), rng:NextNumber(0, 14)
					sb.Transparency = 0.15
					sb.Parent = w
				end
				local bot, top = aabbY(w)
				if bot - groundY < 1.5 and w.Size.X >= 4 then
					local mh = math.min(w.Size.Y, 3 + 3 * level)
					local c = Instance.new("Part")
					c.Name, c.Anchored, c.CanCollide, c.CanTouch, c.CanQuery, c.CastShadow = "Moss", true, false, false, false, false
					c.Transparency = 1
					c.Size = Vector3.new(w.Size.X, mh, 0.05)
					c.CFrame = w.CFrame * CFrame.new(0, -w.Size.Y / 2 + mh / 2, w.Size.Z / 2 + 0.04)
					local mt = Instance.new("Texture")
					mt.Texture = Kit.TEX.moss_a
					mt.Face = Enum.NormalId.Back
					mt.StudsPerTileU, mt.StudsPerTileV = 12, mh
					mt.OffsetStudsU = rng:NextNumber(0, 12)
					mt.Transparency = 0.3
					mt.Parent = c
					c.Parent = deco
				end
				if w.Size.Y >= 12 and w.Size.X >= 5 and rng:NextNumber() < 0.25 * level then
					local vh = math.min(w.Size.Y - 1, rng:NextNumber(10, 22))
					local vw = math.min(w.Size.X, rng:NextNumber(5, 8))
					local v = Instance.new("Part")
					v.Name, v.Anchored, v.CanCollide, v.CanTouch, v.CanQuery, v.CastShadow = "Vines", true, false, false, false, false
					v.Transparency = 1
					v.Size = Vector3.new(vw, vh, 0.05)
					v.CFrame = w.CFrame * CFrame.new(rng:NextNumber(-(w.Size.X - vw) / 2, (w.Size.X - vw) / 2), w.Size.Y / 2 - vh / 2, w.Size.Z / 2 + 0.07)
					local d = Instance.new("Decal")
					d.Texture = Kit.TEX.vines_a
					d.Face = Enum.NormalId.Back
					d.Parent = v
					v.Parent = deco
				end
			end
		end
	end
	-- 3. 창: 깨짐/판자 더 늘림
	local op = folder("Openings")
	if op then
		for _, o in ipairs(op:GetChildren()) do
			local d = o:FindFirstChildOfClass("Decal")
			local tx = d and d.Texture or ""
			local western = tx == Kit.TEX.win_clean_a or tx == Kit.TEX.win_clean_b or tx == Kit.TEX.win_clean_c or tx == Kit.TEX.win_tall_a or tx == Kit.TEX.win_tall_b
			if d and o.Name == "Window" and Kit.TEX.win_kr_broken and not western then
				local q = rng:NextNumber()
				if q < 0.22 * level then d.Texture = Kit.TEX.win_kr_broken
				elseif q < 0.42 * level and Kit.TEX.win_kr_boarded then
					d.Texture = rng:NextNumber() < 0.5 and Kit.TEX.win_kr_boarded or Kit.TEX.win_kr_boarded_b
				elseif q < 0.52 * level and Kit.boardWindow then
					Kit.boardWindow(o, rng) -- 바깥에 진짜 판자
				end
			elseif d and o.Name == "Window" and western then
				local r = rng:NextNumber()
				if r < 0.30 * level then d.Texture = Kit.TEX.win_broken
				elseif r < 0.45 * level then d.Texture = Kit.TEX.win_boarded end
			elseif d and (o.Name == "Shopfront" or o.Name == "Lobby") and rng:NextNumber() < 0.6 * level then
				d.Texture = Kit.TEX.shop_broken
			end
		end
	end
	-- 4. 차양 찢김, 간판 기울어짐, 난간 일부 떨어짐
	local aw = folder("Awnings")
	if aw then
		for _, p in ipairs(aw:GetChildren()) do
			if (p.Name == "Stripe" or p.Name == "Valance") and rng:NextNumber() < 0.3 * level then p:Destroy() end
		end
	end
	local sg = folder("Signs")
	if sg then
		for _, p in ipairs(sg:GetChildren()) do
			if p.Name == "Sign" and rng:NextNumber() < 0.5 * level then
				p.CFrame = p.CFrame * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12)))
			end
		end
	end
	local bal = folder("Balconies")
	if bal then
		for _, p in ipairs(bal:GetChildren()) do
			if (p.Name == "Railing" or p.Name == "GlassRail") and rng:NextNumber() < 0.18 * level then p:Destroy() end
		end
	end
	model:SetAttribute("Kit22Weather", level)
end

-- 마른/죽은 나무: Kit.tree 에 leaves = "dry" (갈색 잎 듬성) / "dead" (잎 없음, 잔가지 더)
local baseTree = Kit.tree
function Kit.tree(parent, cf, opts)
	opts = opts or {}
	if opts.leaves ~= "dry" and opts.leaves ~= "dead" then return baseTree(parent, cf, opts) end
	local dead = opts.leaves == "dead"
	local o2 = table.clone(opts)
	o2.leaves = 1
	o2.cards = dead and 0 or 14
	local m = baseTree(parent, cf, o2)
	local rng = Random.new((opts.seed or 1) + 999)
	for _, p in ipairs(m:GetChildren()) do
		if p.Name == "CanopyFill" then
			if dead then p:Destroy() else p.Color = Color3.fromRGB(120, 104, 60) p.Size = p.Size * 0.7 end
		elseif p.Name == "LeafCard" then
			for _, d in ipairs(p:GetChildren()) do if d:IsA("Decal") then d.Texture = Kit.TEX.leaf_dry end end
		elseif p.Name == "Limb" then
			p.Color = Color3.fromRGB(78, 70, 62)
		end
	end
	if dead then
		-- 잔가지: 가지 끝에서 2~3개씩
		local limbs = {}
		for _, p in ipairs(m:GetChildren()) do if p.Name == "Limb" and p.Size.Y < 1 then table.insert(limbs, p) end end
		for _, l in ipairs(limbs) do
			local tip = l.Position + l.CFrame.RightVector * l.Size.X / 2
			for k = 1, rng:NextInteger(2, 3) do
				local dir = (l.CFrame.RightVector + Vector3.new(rng:NextNumber(-0.8, 0.8), rng:NextNumber(0.1, 0.7), rng:NextNumber(-0.8, 0.8))).Unit
				local len = rng:NextNumber(2.5, 4.5)
				local p = Instance.new("Part")
				p.Name, p.Anchored, p.Shape, p.Material, p.Color = "Twig", true, Enum.PartType.Cylinder, MA.Wood, Color3.fromRGB(78, 70, 62)
				p.Size = Vector3.new(len, 0.36, 0.36)
				p.CFrame = CFrame.lookAt(tip + dir * len / 2, tip + dir * len) * CFrame.Angles(0, math.pi / 2, 0)
				p.Parent = m
			end
		end
	end
	m:SetAttribute("Kit22TreeState", opts.leaves)
	return m
end

---------------------------------------------------------------- 거리 장식: 풀숲, 덤불, 균열, 잔해
Kit.TEX.grass_a = "rbxassetid://73322792937819"
Kit.TEX.grass_dry = "rbxassetid://118483344397654"

local function card(parent, name, size, cf, tex, faces)
	local c = Instance.new("Part")
	c.Name, c.Anchored, c.CanCollide, c.CanTouch, c.CanQuery, c.CastShadow = name, true, false, false, false, false
	c.Transparency = 1
	c.Size = size
	c.CFrame = cf
	for _, f in ipairs(faces or {Enum.NormalId.Front, Enum.NormalId.Back}) do
		local d = Instance.new("Decal")
		d.Texture = Kit.TEX[tex] or tex
		d.Face = f
		d.Parent = c
	end
	c.Parent = parent
	return c
end

-- 풀숲: 교차 카드 3장 (바닥 중심 cf)
function Kit.grass(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local k = opts.scale or rng:NextNumber(0.8, 1.5)
	local tex = opts.dry and "grass_dry" or (rng:NextNumber() < 0.3 and "grass_dry" or "grass_a")
	local m = Instance.new("Model")
	m.Name = "Grass22"
	local w, h = 2.4 * k, 2.0 * k
	local yaw = rng:NextNumber(0, math.pi)
	for i = 0, 2 do
		card(m, "GrassCard", Vector3.new(w, h, 0.05), cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, yaw + i * math.pi / 3, 0), tex)
	end
	m.Parent = parent
	return m
end

-- 덤불: 잎 카드 반구 + 채움 구
function Kit.bush(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local R = opts.radius or rng:NextNumber(2.2, 3.6)
	local m = Instance.new("Model")
	m.Name = "Bush22"
	local fill = Instance.new("Part")
	fill.Name, fill.Anchored, fill.Shape, fill.Material = "BushFill", true, Enum.PartType.Ball, Enum.Material.Grass
	fill.Color = Color3.fromRGB(86, 124, 56)
	fill.Size = Vector3.new(R * 1.5, R * 1.1, R * 1.5)
	fill.CFrame = cf * CFrame.new(0, R * 0.45, 0)
	fill.Parent = m
	local tex = {"leaf_a", "leaf_b", "leaf_c"}
	for i = 0, 9 do
		local th = i / 10 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local y = rng:NextNumber(0.2, 0.9)
		local pos = (cf * CFrame.new(math.cos(th) * R * 0.6, R * y, math.sin(th) * R * 0.6)).Position
		local look = CFrame.lookAt(pos, pos + Vector3.new(math.cos(th), 0.3, math.sin(th)))
		local s = R * rng:NextNumber(0.9, 1.2)
		local t = tex[rng:NextInteger(1, 3)]
		card(m, "BushCard", Vector3.new(s, s, 0.05), look, t)
		card(m, "BushCard", Vector3.new(s, s, 0.05), look * CFrame.Angles(0, math.pi / 2, 0), t)
	end
	m.Parent = parent
	return m
end

-- 균열: 바닥에 붙는 납작 카드 (윗면 데칼)
function Kit.crack(parent, cf, size, seed)
	local rng = Random.new(seed or 1)
	return card(parent, "Crack", Vector3.new(size, 0.02, size), cf * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
		rng:NextNumber() < 0.5 and "cracks_a" or "cracks_b", {Enum.NormalId.Top})
end

-- 잔해 더미: 콘크리트 덩어리 + 판자 + 종이
function Kit.debris(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local m = Instance.new("Model")
	m.Name = "Debris22"
	local n = opts.count or rng:NextInteger(5, 9)
	local spread = opts.spread or 3
	local cols = {Color3.fromRGB(150, 146, 140), Color3.fromRGB(120, 116, 110), Color3.fromRGB(176, 160, 140)}
	for i = 1, n do
		local s = rng:NextNumber(0.6, 2.2)
		local p = Instance.new("Part")
		p.Name, p.Anchored = "Rubble", true
		p.Size = Vector3.new(s * rng:NextNumber(0.8, 1.5), s * rng:NextNumber(0.4, 0.8), s)
		p.CFrame = cf * CFrame.new(rng:NextNumber(-spread, spread), s * 0.22, rng:NextNumber(-spread, spread)) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5))
		p.Color = cols[rng:NextInteger(1, 3)]
		p.Material = rng:NextNumber() < 0.5 and Enum.Material.Concrete or Enum.Material.Slate
		p.Parent = m
	end
	for i = 1, rng:NextInteger(1, 3) do
		local p = Instance.new("Part")
		p.Name, p.Anchored = "Plank", true
		p.Size = Vector3.new(0.3, 0.15, rng:NextNumber(3, 6))
		p.CFrame = cf * CFrame.new(rng:NextNumber(-spread, spread), 0.3, rng:NextNumber(-spread, spread)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), 0)
		p.Color, p.Material = Color3.fromRGB(110, 86, 60), Enum.Material.WoodPlanks
		p.Parent = m
	end
	for i = 1, rng:NextInteger(2, 5) do
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.CanQuery = "Paper", true, false, false
		p.Size = Vector3.new(0.7, 0.03, 0.9)
		p.CFrame = cf * CFrame.new(rng:NextNumber(-spread * 2, spread * 2), 0.05, rng:NextNumber(-spread * 2, spread * 2)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		p.Color, p.Material = Color3.fromRGB(226, 220, 204), Enum.Material.SmoothPlastic
		p.Parent = m
	end
	m.Parent = parent
	return m
end

-- 불탄 자국: 바닥 그을음 원판 (탄 차 밑 등)
function Kit.scorch(parent, cf, radius, seed)
	local rng = Random.new(seed or 1)
	for i = 1, rng:NextInteger(2, 3) do
		local r = radius * rng:NextNumber(0.5, 1)
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = "Scorch", true, false, false, false, false
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.04, r * 2, r * 2)
		p.CFrame = cf * CFrame.new(rng:NextNumber(-1, 1) * radius * 0.3, 0.03 + i * 0.006, rng:NextNumber(-1, 1) * radius * 0.3) * CFrame.Angles(0, 0, math.pi / 2)
		p.Color, p.Material = Color3.fromRGB(22, 20, 19), Enum.Material.Slate
		p.Transparency = rng:NextNumber(0.2, 0.45)
		p.Parent = parent
	end
end

-- 연기 기둥 / 불 (Play 화면에서만 보임: screen_capture 는 파티클을 못 찍음)
function Kit.smoke(parent, pos, opts)
	opts = opts or {}
	local a = Instance.new("Part")
	a.Name, a.Anchored, a.CanCollide, a.CanTouch, a.CanQuery, a.Transparency = "SmokeSource", true, false, false, false, 1
	a.Size = Vector3.new(2, 1, 2)
	a.CFrame = CFrame.new(pos)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(40, 38, 36), Color3.fromRGB(110, 104, 98))
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.7, 0.75), NumberSequenceKeypoint.new(1, 1)})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, opts.size or 18)})
	e.Lifetime = NumberRange.new(7, 11)
	e.Rate = opts.rate or 6
	e.Speed = NumberRange.new(5, 8)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(2, 1, 0.5)
	e.RotSpeed = NumberRange.new(-20, 20)
	e.Rotation = NumberRange.new(0, 360)
	e.LightInfluence = 1
	e.Parent = a
	if opts.fire then
		local f = Instance.new("Fire")
		f.Size, f.Heat = opts.fire, 8
		f.Color, f.SecondaryColor = Color3.fromRGB(255, 120, 40), Color3.fromRGB(255, 200, 80)
		f.Parent = a
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = Color3.fromRGB(255, 140, 60), 18, 2
		l.Parent = a
	end
	a.Parent = parent
	return a
end

---------------------------------------------------------------- 골목 채우기 (4차): 섞인 잔해, 식물(화분·스티로폼 텃밭), 자전거 거치대
local function P(parent, name, size, cf, color, mat, opt)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material, p.Anchored = name, size, cf, color, mat, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if opt then
		if opt.deco then p.CanCollide, p.CanTouch, p.CanQuery = false, false, false end
		if opt.shape then p.Shape = opt.shape end
		if opt.transparency then p.Transparency = opt.transparency end
		if opt.noShadow then p.CastShadow = false end
	end
	p.Parent = parent
	return p
end
Kit.P = P

-- 섞인 잔해: 콘크리트 덩어리·벽돌·유리 조각·휜 철판·철근·판자 (cf = 바닥 중심)
function Kit.rubbleMix(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local sp = opts.spread or 3
	local m = Instance.new("Model") m.Name = "RubbleMix" m.Parent = parent
	local function at(dx, dz, y) return cf * CFrame.new(dx, y, dz) end
	for i = 1, rng:NextInteger(2, 5) do -- 콘크리트
		local s = rng:NextNumber(0.7, 2.2)
		P(m, "Concrete", Vector3.new(s * rng:NextNumber(0.8, 1.6), s * rng:NextNumber(0.35, 0.8), s), at(rng:NextNumber(-sp, sp), rng:NextNumber(-sp, sp), s * 0.2) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5)),
			({Color3.fromRGB(150, 146, 140), Color3.fromRGB(120, 116, 110), Color3.fromRGB(170, 164, 152)})[rng:NextInteger(1, 3)], Enum.Material.Concrete)
	end
	for i = 1, rng:NextInteger(0, 4) do -- 벽돌
		P(m, "Brick", Vector3.new(1.1, 0.45, 0.55), at(rng:NextNumber(-sp, sp), rng:NextNumber(-sp, sp), 0.25) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)),
			Color3.fromRGB(140 + rng:NextInteger(-20, 20), 70, 52), Enum.Material.Brick)
	end
	for i = 1, rng:NextInteger(2, 7) do -- 유리 조각 (얇은 쐐기, 반짝임)
		local g = Instance.new("WedgePart")
		g.Name, g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = "GlassShard", true, false, false, false, false
		g.Size = Vector3.new(0.05, rng:NextNumber(0.4, 1.4), rng:NextNumber(0.4, 1.6))
		g.CFrame = at(rng:NextNumber(-sp * 1.3, sp * 1.3), rng:NextNumber(-sp * 1.3, sp * 1.3), 0.06) * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.pi / 2 + rng:NextNumber(-0.15, 0.15))
		g.Color = Color3.fromRGB(170, 196, 204)
		g.Material = Enum.Material.Glass
		g.Transparency = 0.35
		g.Reflectance = 0.25
		g.Parent = m
	end
	if rng:NextNumber() < 0.6 then -- 휜 철판 (기대거나 누움)
		local lean = rng:NextNumber() < 0.5
		local w, h = rng:NextNumber(2.5, 5), rng:NextNumber(2, 4)
		P(m, "MetalSheet", Vector3.new(w, 0.12, h), at(rng:NextNumber(-sp, sp), rng:NextNumber(-sp, sp), lean and h * 0.35 or 0.15)
			* CFrame.Angles(lean and math.rad(rng:NextNumber(50, 70)) or rng:NextNumber(-0.15, 0.15), rng:NextNumber(0, 6.28), rng:NextNumber(-0.2, 0.2)),
			({Color3.fromRGB(120, 90, 70), Color3.fromRGB(110, 116, 120), Color3.fromRGB(140, 100, 70)})[rng:NextInteger(1, 3)], Enum.Material.CorrodedMetal)
	end
	for i = 1, rng:NextInteger(0, 3) do -- 철근
		P(m, "Rebar", Vector3.new(0.15, 0.15, rng:NextNumber(3, 6)), at(rng:NextNumber(-sp, sp), rng:NextNumber(-sp, sp), 0.3) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), 0),
			Color3.fromRGB(110, 70, 50), Enum.Material.CorrodedMetal, {deco = true})
	end
	if rng:NextNumber() < 0.5 then
		P(m, "Plank", Vector3.new(0.35, 0.15, rng:NextNumber(3, 6)), at(rng:NextNumber(-sp, sp), rng:NextNumber(-sp, sp), 0.25) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), 0),
			Color3.fromRGB(110, 86, 60), Enum.Material.WoodPlanks)
	end
	return m
end

-- 식물: 화분 / 스티로폼 텃밭 상자 / 풀 (cf = 바닥 중심)
function Kit.plantSpot(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local lib = game:GetService("ServerStorage"):FindFirstChild("Kit22_Props")
	local m = Instance.new("Model") m.Name = "Plants" m.Parent = parent
	local kind = rng:NextNumber()
	if kind < 0.45 then
		-- 스티로폼 텃밭 (흰 상자 + 풀 카드), 1~3개 나란히
		for i = 1, rng:NextInteger(1, 3) do
			local c = cf * CFrame.new((i - 1) * 2.9 - 2.9, 0, rng:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, rng:NextNumber(-0.15, 0.15), 0)
			P(m, "StyroBox", Vector3.new(2.7, 1.2, 1.8), c * CFrame.new(0, 0.6, 0), Color3.fromRGB(232, 232, 226):Lerp(Color3.fromRGB(150, 140, 120), rng:NextNumber(0, 0.4)), Enum.Material.SmoothPlastic)
			P(m, "Soil", Vector3.new(2.5, 0.1, 1.6), c * CFrame.new(0, 1.18, 0), Color3.fromRGB(70, 54, 40), Enum.Material.Ground, {deco = true})
			Kit.grass(m, c * CFrame.new(0, 1.2, 0), {seed = (opts.seed or 1) * 7 + i, scale = rng:NextNumber(0.5, 0.8), dry = rng:NextNumber() < 0.5})
		end
	elseif kind < 0.8 then
		-- 화분 1~4개 (AI 화분 + 큰 화분)
		for i = 1, rng:NextInteger(1, 4) do
			local nm = (rng:NextNumber() < 0.5 and lib and lib:FindFirstChild("PotBig")) and "PotBig" or "Planter_small"
			local t = lib and lib:FindFirstChild(nm)
			if t then
				local c = t:Clone()
				c:PivotTo(cf * CFrame.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-1, 1)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
				if rng:NextNumber() < 0.2 then c:PivotTo(c:GetPivot() * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.pi / 2, 0, 0)) end -- 넘어진 화분
				c.Parent = m
			end
		end
	else
		-- 틈새 덤불·풀
		Kit.bush(m, cf, {seed = opts.seed, radius = rng:NextNumber(1.6, 2.6)})
		for i = 1, 3 do Kit.grass(m, cf * CFrame.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-2, 2)), {seed = (opts.seed or 1) + i, scale = rng:NextNumber(0.8, 1.5)}) end
	end
	return m
end

-- 자전거 거치대: cf = 거치대 중심(바닥), 길이 방향 = cf 의 X. n 칸, 자전거는 cf 의 -Z(앞)로 머리
function Kit.bikeRack(parent, cf, n, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local lib = game:GetService("ServerStorage"):FindFirstChild("Kit22_Props")
	local m = Instance.new("Model") m.Name = "BikeRack" m.Parent = parent
	local MET = Color3.fromRGB(150, 152, 156)
	local gap = 2.2
	local L = n * gap
	P(m, "RackBase", Vector3.new(L + 0.6, 0.2, 0.5), cf * CFrame.new(0, 0.1, 0), MET, Enum.Material.Metal)
	for i = 0, n do
		local x = -L / 2 + i * gap
		-- 거꾸로 U 자: 기둥 2 + 위 가로대
		P(m, "RackLeg", Vector3.new(0.15, 2.6, 0.15), cf * CFrame.new(x, 1.3, -0.9), MET, Enum.Material.Metal)
		P(m, "RackLeg", Vector3.new(0.15, 2.6, 0.15), cf * CFrame.new(x, 1.3, 0.9), MET, Enum.Material.Metal)
		P(m, "RackTop", Vector3.new(0.15, 0.15, 1.95), cf * CFrame.new(x, 2.6, 0), MET, Enum.Material.Metal)
	end
	if opts.roof then
		P(m, "RackRoof", Vector3.new(L + 1.5, 0.2, 4.5), cf * CFrame.new(0, 6.2, 1) * CFrame.Angles(math.rad(-6), 0, 0), Color3.fromRGB(80, 110, 130), Enum.Material.Plastic)
		for _, x in ipairs({-L / 2 - 0.5, L / 2 + 0.5}) do P(m, "RackPost", Vector3.new(0.3, 6.2, 0.3), cf * CFrame.new(x, 3.1, 2.8), MET, Enum.Material.Metal) end
	end
	local bike = lib and lib:FindFirstChild("Bicycle")
	if bike then
		for i = 1, n do
			if rng:NextNumber() < (opts.fill or 0.6) then
				local c = bike:Clone()
				local x = -L / 2 + (i - 0.5) * gap
				local base = cf * CFrame.new(x, 0, -0.5) * CFrame.Angles(0, math.rad(rng:NextNumber(-8, 8)), 0)
				if rng:NextNumber() < 0.2 then -- 쓰러진 자전거
					base = cf * CFrame.new(x, 0.5, -2.5) * CFrame.Angles(0, rng:NextNumber(-0.6, 0.6), math.pi / 2)
				end
				c:PivotTo(base)
				c.Parent = m
			end
		end
	end
	return m
end

-- 자전거·스쿠터 하나 (기대거나 쓰러짐)
function Kit.bikeLoose(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local lib = game:GetService("ServerStorage"):FindFirstChild("Kit22_Props")
	local nm = rng:NextNumber() < 0.6 and "Bicycle" or "Scooter"
	local t = lib and lib:FindFirstChild(nm)
	if not t then return end
	local c = t:Clone()
	if rng:NextNumber() < 0.45 then
		c:PivotTo(cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.pi / 2))
	else
		c:PivotTo(cf * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(-12, 12))))
	end
	c.Parent = parent
	return c
end
