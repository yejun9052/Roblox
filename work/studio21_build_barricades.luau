-- 21번 B: 입구 차단벽 자리에 폐차 바리케이드 생성 (studio21_barricade_store.luau 이후). 다시 실행하면 지우고 새로 만듦.
-- 데이터: ServerStorage.Barricades_before_21.<폴더>.Gate21/Center21/Cross21/Span21.
-- 결과: Workspace.Apocalypse_21.Barricades.<도로>. 차량 폭 7.5 당 1대(비스듬히, 일부 뒤집힘/옆으로 누움) + 잔해 + 그을음 + 보이지 않는 차단면.
-- 차단면: 원래 펜스와 같은 폭, 높이 24, Transparency 1, CanCollide true, CanQuery false (플레이 구역 유지).
local SS = game:GetService("ServerStorage")
local SEED = 2121
local RNG = Random.new(SEED)

local root = workspace:FindFirstChild("Apocalypse_21") or Instance.new("Folder")
root.Name = "Apocalypse_21"
root.Parent = workspace
local old = root:FindFirstChild("Barricades")
if old then old:Destroy() end
local folder = Instance.new("Folder")
folder.Name = "Barricades"
folder.Parent = root

-- 차체 색·재질: 불탄 숯빛 위주, 녹·바랜 도색 일부
local PALETTE = {
	{Color3.fromRGB(34, 31, 29), Enum.Material.Slate}, {Color3.fromRGB(44, 40, 37), Enum.Material.Metal}, {Color3.fromRGB(28, 28, 30), Enum.Material.Slate},
	{Color3.fromRGB(52, 50, 48), Enum.Material.Metal}, {Color3.fromRGB(38, 34, 31), Enum.Material.CorrodedMetal},
	{Color3.fromRGB(72, 46, 32), Enum.Material.CorrodedMetal}, {Color3.fromRGB(66, 72, 76), Enum.Material.Metal}, {Color3.fromRGB(84, 40, 34), Enum.Material.Metal}}
local DARK = Color3.fromRGB(20, 18, 17)
local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = mat or Enum.Material.CorrodedMetal
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function deco(p) p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = false, false, false, false return p end

-- 차량: 원점 = 지면 중심, 길이 X 방향
local function buildCar(parent, kind)
	local m = Instance.new("Model")
	m.Name = "Wreck_" .. kind
	local pal = PALETTE[RNG:NextInteger(1, #PALETTE)]
	local body, bmat = pal[1], pal[2]
	local van = kind == "van"
	local L, W, H = van and 9.2 or 8.2, van and 4.2 or 3.9, van and 2.7 or 1.35
	local clear = 0.5
	local wheels = 0
	for _, s in ipairs({{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do
		if RNG:NextNumber() > 0.3 then
			wheels += 1
			part(m, "Wheel", Vector3.new(0.55, 1.0, 1.0), CFrame.new(s[1] * (L / 2 - 1.4), 0.5, s[2] * (W / 2 - 0.05)) * CFrame.Angles(0, math.pi / 2, 0),
				Color3.fromRGB(18, 18, 18), Enum.Material.Slate, Enum.PartType.Cylinder)
		end
	end
	if wheels < 3 then clear = 0.15 end -- 바퀴 빠짐 → 주저앉음
	part(m, "Body", Vector3.new(L, H, W), CFrame.new(0, clear + H / 2, 0), body, bmat)
	part(m, "Bumper", Vector3.new(0.3, 0.45, W + 0.1), CFrame.new(L / 2 + 0.1, clear + 0.35, 0), DARK, Enum.Material.Slate)
	part(m, "Bumper", Vector3.new(0.3, 0.45, W + 0.1), CFrame.new(-L / 2 - 0.1, clear + 0.35, 0), DARK, Enum.Material.Slate)
	if van then
		deco(part(m, "WindowsBurnt", Vector3.new(L * 0.28, 1.0, W + 0.04), CFrame.new(L * 0.34, clear + H * 0.72, 0), DARK, Enum.Material.Slate))
	else
		-- 객실: 가운데 블록 + 앞유리/뒷유리 쐐기(타서 검게). 일부는 지붕 내려앉음
		local cabL, cabH = 2.6, RNG:NextNumber() < 0.25 and 0.75 or 1.2
		local y0 = clear + H
		part(m, "Cabin", Vector3.new(cabL, cabH, W - 0.5), CFrame.new(-0.5, y0 + cabH / 2, 0), body, bmat)
		deco(part(m, "WindowsBurnt", Vector3.new(cabL + 0.06, cabH * 0.6, W - 0.44), CFrame.new(-0.5, y0 + cabH * 0.5, 0), DARK, Enum.Material.Slate))
		-- WedgePart 의 높은 쪽(+Z)이 객실을 향하도록 회전
		local fw = Instance.new("WedgePart")
		fw.Name, fw.Anchored, fw.Material, fw.Color = "Windshield", true, Enum.Material.Slate, DARK
		fw.Size = Vector3.new(W - 0.5, cabH, 1.3)
		fw.CFrame = CFrame.new(-0.5 + cabL / 2 + 0.65, y0 + cabH / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0)
		fw.Parent = m
		local rw = fw:Clone()
		rw.Name = "RearWindow"
		rw.Size = Vector3.new(W - 0.5, cabH, 0.9)
		rw.CFrame = CFrame.new(-0.5 - cabL / 2 - 0.45, y0 + cabH / 2, 0) * CFrame.Angles(0, math.pi / 2, 0)
		rw.Parent = m
	end
	deco(part(m, "HoodScorch", Vector3.new(L * 0.3, 0.05, W - 0.4), CFrame.new(L * 0.32, clear + H + 0.026, 0), DARK, Enum.Material.Slate))
	-- 녹 얼룩
	deco(part(m, "RustPatch", Vector3.new(L * RNG:NextNumber(0.2, 0.4), H * 0.6, 0.04), CFrame.new(RNG:NextNumber(-1.5, 1.5), clear + H * 0.5, W / 2 + 0.02),
		Color3.fromRGB(110, 62, 36), Enum.Material.CorrodedMetal))
	m.Parent = parent
	return m
end
local rpGround = RaycastParams.new()
rpGround.FilterType = Enum.RaycastFilterType.Exclude
rpGround.FilterDescendantsInstances = {root}
local function groundY(p)
	local h = workspace:Raycast(Vector3.new(p.X, p.Y + 6, p.Z), Vector3.new(0, -14, 0), rpGround)
	return h and h.Position.Y or p.Y
end
-- 모델을 cf(지면점·방향)로 옮기고 바닥을 지면에 붙임
local function place(m, cf)
	local minY = math.huge
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CFrame = cf * p.CFrame
			local s, c = p.Size / 2, p.CFrame
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				minY = math.min(minY, c:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)).Y)
			end end end
		end
	end
	local dy = groundY(cf.Position) - minY
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = p.CFrame + Vector3.new(0, dy, 0) end end
end
local function scorch(parent, pos, radius)
	local gy = groundY(pos)
	for i = 1, RNG:NextInteger(2, 4) do
		local r = radius * RNG:NextNumber(0.45, 1.0)
		local off = Vector3.new(RNG:NextNumber(-1, 1), 0, RNG:NextNumber(-1, 1)) * radius * 0.45
		local p = deco(part(parent, "Scorch", Vector3.new(0.04, r * 2, r * 2), CFrame.new(pos.X + off.X, gy + 0.02 + i * 0.005, pos.Z + off.Z) * CFrame.Angles(0, 0, math.pi / 2),
			DARK, Enum.Material.Slate, Enum.PartType.Cylinder))
		p.Transparency = RNG:NextNumber(0.15, 0.4)
	end
end
local function rubble(parent, pos, n, spread)
	for i = 1, n do
		local s = RNG:NextNumber(0.8, 2.6)
		local c = pos + Vector3.new(RNG:NextNumber(-spread.X, spread.X), 0, RNG:NextNumber(-spread.Z, spread.Z))
		local p = part(parent, "Rubble", Vector3.new(s * RNG:NextNumber(0.8, 1.6), s * RNG:NextNumber(0.4, 0.9), s),
			CFrame.new(c.X, groundY(c) + s * 0.25, c.Z) * CFrame.Angles(RNG:NextNumber(-0.5, 0.5), RNG:NextNumber(0, math.pi * 2), RNG:NextNumber(-0.5, 0.5)),
			({Color3.fromRGB(88, 86, 80), Color3.fromRGB(70, 66, 60), Color3.fromRGB(54, 50, 46)})[RNG:NextInteger(1, 3)],
			({Enum.Material.Concrete, Enum.Material.Slate, Enum.Material.Cobblestone})[RNG:NextInteger(1, 3)])
	end
end

local made, cars = 0, 0
for _, g in ipairs(SS.Barricades_before_21:GetChildren()) do
	if g:GetAttribute("Gate21") then
		local c, cross, span = g:GetAttribute("Center21"), g:GetAttribute("Cross21"), g:GetAttribute("Span21")
		local along = Vector3.new(cross.Z, 0, cross.X)
		local site = Instance.new("Folder")
		site.Name = g.Name:match("R%d+") or g.Name
		site.Parent = folder
		local n = math.ceil(span / 7.5) -- 촘촘히 (틈이 보이면 보이지 않는 벽이 어색함)
		local step = span / n
		for i = 1, n do
			local off = -span / 2 + step * (i - 0.5)
			local pos = c + cross * off + along * RNG:NextNumber(-1.6, 1.6)
			local r = RNG:NextNumber()
			local kind = r < 0.2 and "van" or "sedan"
			local m = buildCar(site, kind)
			local yaw = math.atan2(-cross.Z, cross.X) + math.rad(RNG:NextNumber(-25, 25))
			local tilt = CFrame.Angles(math.rad(RNG:NextNumber(-4, 4)), 0, math.rad(RNG:NextNumber(-3, 3)))
			if r > 0.8 then tilt = CFrame.Angles(math.pi, 0, 0) m.Name ..= "_overturned"
			elseif r > 0.68 then tilt = CFrame.Angles(math.pi / 2 * (RNG:NextNumber() < 0.5 and 1 or -1), 0, 0) m.Name ..= "_onside" end
			place(m, CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * tilt)
			scorch(site, pos, RNG:NextNumber(3, 5))
			cars += 1
		end
		rubble(site, c, 12, Vector3.new(math.abs(cross.X) * span / 2 + math.abs(along.X) * 2.2, 0, math.abs(cross.Z) * span / 2 + math.abs(along.Z) * 2.2))
		local b = Instance.new("Part")
		b.Name = "Barricade_blocker_21"
		b.Size = Vector3.new(span, 24, 1.2) -- 10 이면 폐차 지붕에서 점프해 넘어감 (Play 시험) → 24
		b.CFrame = CFrame.lookAt(c + Vector3.new(0, 12, 0), c + Vector3.new(0, 12, 0) + along)
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, true, false, false, false
		b.Transparency = 1
		b.Parent = site
		made += 1
	end
end
local np = 0
for _, d in ipairs(folder:GetDescendants()) do if d:IsA("BasePart") then np += 1 end end
return ("바리케이드 %d곳, 차량 %d대, 파트 %d"):format(made, cars, np)
