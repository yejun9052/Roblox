-- 21번 C: 거리 분위기 (폐차·잿더미·외벽 그을음·잔해·연기/불·기운 가로등). 다시 실행하면 Streets 폴더를 지우고 새로 만듦.
-- 가로등은 CFrameBefore21 속성으로 원위치 보존(재실행 시 먼저 원위치 복원 후 다시 기울임).
-- 플레이 경로(Roads/Active) 폐차: 연석 쪽, 가운데 9 스터드 차선 비움, 기존 충돌 파트와 겹치면 취소.
local SEED = 2122
local RNG = Random.new(SEED)
local SD = workspace.SurterDays
local root = workspace:FindFirstChild("Apocalypse_21") or Instance.new("Folder")
root.Name = "Apocalypse_21"
root.Parent = workspace
local old = root:FindFirstChild("Streets")
if old then old:Destroy() end
local F = Instance.new("Folder") F.Name = "Streets" F.Parent = root
local function sub(n) local f = Instance.new("Folder") f.Name = n f.Parent = F return f end
local WRECK_A, WRECK_R, ASH, BURN, DEBRIS = sub("Wrecks_route"), sub("Wrecks_reserved"), sub("Ash"), sub("FacadeBurn"), sub("Debris")

local PALETTE = {
	{Color3.fromRGB(34, 31, 29), Enum.Material.Slate}, {Color3.fromRGB(44, 40, 37), Enum.Material.Metal}, {Color3.fromRGB(28, 28, 30), Enum.Material.Slate},
	{Color3.fromRGB(52, 50, 48), Enum.Material.Metal}, {Color3.fromRGB(38, 34, 31), Enum.Material.CorrodedMetal},
	{Color3.fromRGB(62, 42, 30), Enum.Material.CorrodedMetal}, {Color3.fromRGB(66, 72, 76), Enum.Material.Metal}, {Color3.fromRGB(84, 40, 34), Enum.Material.Metal},
	{Color3.fromRGB(150, 146, 136), Enum.Material.Metal}}
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
local function aabbOf(parts)
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(parts) do
		local s, c = p.Size / 2, p.CFrame
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			local w = c:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)) mn = mn:Min(w) mx = mx:Max(w)
		end end end
	end
	return mn, mx
end
local function buildCar(parent, kind)
	local m = Instance.new("Model")
	m.Name = "Wreck_" .. kind
	local pal = PALETTE[RNG:NextInteger(1, #PALETTE)]
	local body, bmat = pal[1], pal[2]
	local van = kind == "van"
	local L, W, H = van and 9.2 or 8.2, van and 4.2 or 3.9, van and 2.7 or 1.35
	local clear, wheels = 0.5, 0
	for _, s in ipairs({{1, 1}, {1, -1}, {-1, 1}, {-1, -1}}) do
		if RNG:NextNumber() > 0.3 then
			wheels += 1
			part(m, "Wheel", Vector3.new(0.55, 1.0, 1.0), CFrame.new(s[1] * (L / 2 - 1.4), 0.5, s[2] * (W / 2 - 0.05)) * CFrame.Angles(0, math.pi / 2, 0),
				Color3.fromRGB(18, 18, 18), Enum.Material.Slate, Enum.PartType.Cylinder)
		end
	end
	if wheels < 3 then clear = 0.15 end
	part(m, "Body", Vector3.new(L, H, W), CFrame.new(0, clear + H / 2, 0), body, bmat)
	part(m, "Bumper", Vector3.new(0.3, 0.45, W + 0.1), CFrame.new(L / 2 + 0.1, clear + 0.35, 0), DARK, Enum.Material.Slate)
	part(m, "Bumper", Vector3.new(0.3, 0.45, W + 0.1), CFrame.new(-L / 2 - 0.1, clear + 0.35, 0), DARK, Enum.Material.Slate)
	if van then
		deco(part(m, "WindowsBurnt", Vector3.new(L * 0.28, 1.0, W + 0.04), CFrame.new(L * 0.34, clear + H * 0.72, 0), DARK, Enum.Material.Slate))
	else
		local cabL, cabH = 2.6, RNG:NextNumber() < 0.25 and 0.75 or 1.2
		local y0 = clear + H
		part(m, "Cabin", Vector3.new(cabL, cabH, W - 0.5), CFrame.new(-0.5, y0 + cabH / 2, 0), body, bmat)
		deco(part(m, "WindowsBurnt", Vector3.new(cabL + 0.06, cabH * 0.6, W - 0.44), CFrame.new(-0.5, y0 + cabH * 0.5, 0), DARK, Enum.Material.Slate))
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
	deco(part(m, "RustPatch", Vector3.new(L * RNG:NextNumber(0.2, 0.4), H * 0.6, 0.04), CFrame.new(RNG:NextNumber(-1.5, 1.5), clear + H * 0.5, W / 2 + 0.02),
		Color3.fromRGB(70, 42, 28), Enum.Material.CorrodedMetal))
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
local function place(m, cf)
	local ps = {}
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = cf * p.CFrame table.insert(ps, p) end end
	local mn = aabbOf(ps)
	local dy = groundY(cf.Position) - mn.Y
	for _, p in ipairs(ps) do p.CFrame = p.CFrame + Vector3.new(0, dy, 0) end
	return ps
end
local IGNORE = {"Road surface", "Curb", "Sidewalk", "lane", "Lot apron", "Scorch", "Ash", "Crack", "dash", "stripe", "Manhole", "joint", "vent", "dark"}
local function blocked(ps)
	local op = OverlapParams.new() op.FilterType = Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances = {root}
	for _, p in ipairs(ps) do
		for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
			local ok = false
			for _, k in ipairs(IGNORE) do if q.Name:find(k) then ok = true break end end
			if not ok and q.CanCollide and q.Transparency < 1 then return q.Name end
			if not ok and q.Size.Magnitude > 3 then return q.Name end
		end
	end
	return nil
end
local function scorch(parent, pos, radius, name)
	local gy = groundY(pos)
	for i = 1, RNG:NextInteger(2, 4) do
		local r = radius * RNG:NextNumber(0.45, 1.0)
		local off = Vector3.new(RNG:NextNumber(-1, 1), 0, RNG:NextNumber(-1, 1)) * radius * 0.45
		local p = deco(part(parent, name or "Scorch", Vector3.new(0.04, r * 2, r * 2), CFrame.new(pos.X + off.X, gy + 0.02 + i * 0.005, pos.Z + off.Z) * CFrame.Angles(0, 0, math.pi / 2),
			name == "Ash" and Color3.fromRGB(64, 62, 58) or DARK, Enum.Material.Slate, Enum.PartType.Cylinder))
		p.Transparency = RNG:NextNumber(0.2, 0.45)
	end
end
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local function smoke(p, dense)
	-- 부착점은 회전 없이 차체 월드 꼭대기에 (뒤집힌 차도 연기가 위로). 화면 캡처에는 파티클이 안 찍혀 Play 에서 확인 필요.
	local a = Instance.new("Attachment") a.Name = "Smoke21" a.Parent = p
	local cf, s = p.CFrame, p.Size / 2
	local topY = -math.huge
	for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		topY = math.max(topY, cf:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)).Y)
	end end end
	a.WorldCFrame = CFrame.new(p.Position.X, topY + 0.1, p.Position.Z)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE
	e.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 54, 50)), ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 136, 128))})
	e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(0.4, dense and 12 or 9), NumberSequenceKeypoint.new(1, dense and 24 or 18)})
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.6, 0.55), NumberSequenceKeypoint.new(1, 1)})
	e.Lifetime = NumberRange.new(12, 18)
	e.Rate = dense and 8 or 5
	e.Speed = NumberRange.new(4, 6)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(1.4, 0.4, 0.6)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-15, 15)
	e.LightInfluence = 0.5
	e.Parent = a
end

-- 도로 구간
local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return p.Position, Vector3.new(math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z, math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z)
end
local roads = {}
for _, f in ipairs(SD:GetChildren()) do
	if f.Name:match("^Roads/") then
		for _, d in ipairs(f:GetChildren()) do
			if d:IsA("BasePart") and d.Name:match("^Road surface") then
				local c, h = aabb(d)
				local axis = h.X > h.Z and Vector3.xAxis or Vector3.zAxis
				table.insert(roads, {c = Vector3.new(c.X, c.Y + h.Y, c.Z), axis = axis, cross = axis == Vector3.xAxis and Vector3.zAxis or Vector3.xAxis,
					len = 2 * math.max(h.X, h.Z), w = 2 * math.min(h.X, h.Z), active = f.Name:match("^Roads/Active/") ~= nil})
			end
		end
	end
end
local gates = {}
for _, s in ipairs(root.Barricades:GetChildren()) do
	local b = s:FindFirstChild("Barricade_blocker_21")
	if b then table.insert(gates, b.Position) end
end
local function nearGate(p, r) for _, g in ipairs(gates) do if (Vector3.new(g.X, 0, g.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude < r then return true end end return false end

local stats = {route = 0, reserved = 0, rejected = 0, ash = 0, burn = 0, debris = 0, smoke = 0, fire = 0}
local smokeCands = {}
for _, rd in ipairs(roads) do
	local yawBase = math.atan2(-rd.axis.Z, rd.axis.X)
	local tries = rd.active and math.floor(rd.len / 40) or math.floor(rd.len / 45)
	for _ = 1, tries do
		if RNG:NextNumber() < (rd.active and 0.7 or 0.4) then
			local t = RNG:NextNumber(-0.36, 0.36) * rd.len
			local side = RNG:NextNumber() < 0.5 and 1 or -1
			local r = RNG:NextNumber()
			local kind = r < 0.18 and "van" or "sedan"
			local lat, yaw, tilt
			if rd.active then
				lat = side * (rd.w / 2 - 2.5 - RNG:NextNumber(0, 0.7))
				yaw = yawBase + math.rad(RNG:NextNumber(-20, 20)) + (RNG:NextNumber() < 0.5 and math.pi or 0)
				tilt = CFrame.Angles(math.rad(RNG:NextNumber(-3, 3)), 0, math.rad(RNG:NextNumber(-3, 3)))
				if r > 0.92 then tilt = CFrame.Angles(math.pi / 2 * side, 0, 0) end
			else
				lat = RNG:NextNumber(-rd.w / 2 + 2.5, rd.w / 2 - 2.5)
				yaw = yawBase + math.rad(RNG:NextNumber(-70, 70))
				tilt = CFrame.Angles(math.rad(RNG:NextNumber(-4, 4)), 0, math.rad(RNG:NextNumber(-4, 4)))
				if r > 0.85 then tilt = CFrame.Angles(math.pi, 0, 0) elseif r > 0.75 then tilt = CFrame.Angles(math.pi / 2 * side, 0, 0) end
			end
			local pos = rd.c + rd.axis * t + rd.cross * lat
			if not nearGate(pos, 14) then
				local m = buildCar(rd.active and WRECK_A or WRECK_R, kind)
				local ps = place(m, CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * tilt)
				local ok = blocked(ps) == nil
				if ok and rd.active then
					-- 가운데 차선 확보: 차의 가로 범위가 도로 중심에서 4.5 이상 떨어져야 함
					local mn, mx = aabbOf(ps)
					local a, b = (mn - rd.c):Dot(rd.cross), (mx - rd.c):Dot(rd.cross)
					if math.min(math.abs(a), math.abs(b)) < 4.5 or (a < 0) ~= (b < 0) then ok = false end
				end
				if ok then
					scorch(rd.active and WRECK_A or WRECK_R, pos, RNG:NextNumber(3, 5))
					if rd.active then stats.route += 1 table.insert(smokeCands, m) else stats.reserved += 1 if RNG:NextNumber() < 0.08 then table.insert(smokeCands, m) end end
				else
					m:Destroy() stats.rejected += 1
				end
			end
		end
	end
	-- 잿더미: 도로 위 불규칙
	for _ = 1, math.floor(rd.len / 35) do
		if RNG:NextNumber() < 0.55 then
			local pos = rd.c + rd.axis * RNG:NextNumber(-0.45, 0.45) * rd.len + rd.cross * RNG:NextNumber(-0.4, 0.4) * rd.w
			scorch(ASH, pos, RNG:NextNumber(2, 6), RNG:NextNumber() < 0.5 and "Ash" or "Scorch")
			stats.ash += 1
		end
	end
	-- 외벽 그을음 + 잔해 더미: 도로 양쪽 건물
	if rd.active or RNG:NextNumber() < 0.5 then
		for _ = 1, math.floor(rd.len / 30) do
			local side = RNG:NextNumber() < 0.5 and 1 or -1
			local base = rd.c + rd.axis * RNG:NextNumber(-0.42, 0.42) * rd.len
			local o = Vector3.new(base.X, base.Y + RNG:NextNumber(5, 16), base.Z)
			local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = {root}
			local h = workspace:Raycast(o, rd.cross * side * 45, rp)
			if h and math.abs(h.Normal.Y) < 0.2 and h.Instance.Size.Y >= 6 then
				local n = h.Instance.Name:lower()
				local bad = n:find("fence") or n:find("screen") or n:find("rail") or n:find("retaining") or n:find("sign") or n:find("glass") or n:find("window") or n:find("lamp") or n:find("blocker")
				if not bad and RNG:NextNumber() < 0.6 then
					-- 아래가 진하고 위로 번지는 그을음 3장
					local look = h.Position + h.Normal
					for i = 1, 3 do
						local w, ht = RNG:NextNumber(2.5, 4.5) * (1 + i * 0.35), RNG:NextNumber(3, 5) * (1 + i * 0.3)
						local c = h.Position + h.Normal * (0.03 + i * 0.012) + Vector3.new(0, ht * 0.4 + i * 0.8, 0)
						local p = deco(part(BURN, "FacadeBurn", Vector3.new(w, ht, 0.04), CFrame.lookAt(c, c + h.Normal), DARK, Enum.Material.Slate))
						p.Transparency = 0.25 + i * 0.17
					end
					stats.burn += 1
				end
				-- 건물 바닥 쪽 잔해 더미 (보도 위)
				if RNG:NextNumber() < 0.35 then
					local g = workspace:Raycast(Vector3.new(h.Position.X, base.Y + 2, h.Position.Z) + h.Normal * 1.8, Vector3.new(0, -6, 0), rp)
					if g then
						local pile = Instance.new("Folder") pile.Name = "RubblePile" pile.Parent = DEBRIS
						local ps = {}
						for _ = 1, RNG:NextInteger(5, 9) do
							local s = RNG:NextNumber(0.6, 2.2)
							local along = rd.axis * RNG:NextNumber(-2.5, 2.5)
							local c = g.Position + along + h.Normal * RNG:NextNumber(0, 1.8)
							table.insert(ps, part(pile, "Rubble", Vector3.new(s * RNG:NextNumber(0.9, 1.7), s * RNG:NextNumber(0.4, 0.9), s),
								CFrame.new(c + Vector3.new(0, s * 0.22, 0)) * CFrame.Angles(RNG:NextNumber(-0.6, 0.6), RNG:NextNumber(0, 6.28), RNG:NextNumber(-0.6, 0.6)),
								({Color3.fromRGB(96, 92, 86), Color3.fromRGB(74, 70, 64), Color3.fromRGB(58, 54, 50), Color3.fromRGB(110, 70, 58)})[RNG:NextInteger(1, 4)],
								({Enum.Material.Concrete, Enum.Material.Slate, Enum.Material.Brick})[RNG:NextInteger(1, 3)]))
						end
						if rd.active and blocked(ps) then pile:Destroy() else stats.debris += 1 end
					end
				end
			end
		end
	end
end
-- 연기/불: 경로 폐차 일부
for i, m in ipairs(smokeCands) do
	if i % 4 == 1 and stats.smoke < 22 then
		local body = m:FindFirstChild("Body")
		if body then
			smoke(body, stats.smoke % 3 == 0)
			stats.smoke += 1
			if stats.fire < 4 and stats.smoke % 5 == 0 then
				local f = Instance.new("Fire") f.Size = 4 f.Heat = 7 f.Color = Color3.fromRGB(236, 120, 40) f.SecondaryColor = Color3.fromRGB(60, 30, 20) f.Parent = body
				local l = Instance.new("PointLight") l.Color = Color3.fromRGB(255, 140, 60) l.Brightness = 1.6 l.Range = 16 l.Parent = body
				stats.fire += 1
			end
		end
	end
end
-- 바리케이드에도 연기 몇 개
local bi = 0
for _, s in ipairs(root.Barricades:GetChildren()) do
	bi += 1
	if bi % 9 == 0 then
		local m = s:FindFirstChildWhichIsA("Model")
		local body = m and m:FindFirstChild("Body")
		if body then smoke(body, false) stats.smoke += 1 end
	end
end
-- 가로등 기울이기 (경로 26개 중 5개)
local lamps = {}
for _, f in ipairs(SD:GetChildren()) do
	if f.Name:match("^Roads/Active/") then
		for _, d in ipairs(f:GetDescendants()) do if d:IsA("BasePart") and d.Name:match("^Streetlamp post") then table.insert(lamps, d) end end
	end
end
table.sort(lamps, function(a, b) return a:GetFullName() .. a.Position.X < b:GetFullName() .. b.Position.X end)
local tilted = 0
for i, post in ipairs(lamps) do
	if i % 5 == 2 then
		local top = post.Position + Vector3.new(0, post.Size.Y / 2, 0)
		local base = post.Position - Vector3.new(0, post.Size.Y / 2, 0)
		local grp = {post}
		for _, q in ipairs(workspace:GetPartBoundsInRadius(top, 7)) do
			if q ~= post and (q.Name:match("^Streetlamp arm") or q.Name:match("bulkhead") or q.Name:match("arm_brace") or q.Name:match("service_screw")) then table.insert(grp, q) end
		end
		local ang = math.rad(RNG:NextNumber(12, 20)) * (RNG:NextNumber() < 0.5 and 1 or -1)
		local axis = RNG:NextNumber() < 0.5 and "X" or "Z"
		local rot = CFrame.new(base) * (axis == "X" and CFrame.Angles(ang, 0, 0) or CFrame.Angles(0, 0, ang)) * CFrame.new(-base)
		for _, q in ipairs(grp) do
			local orig = q:GetAttribute("CFrameBefore21")
			if not orig then q:SetAttribute("CFrameBefore21", q.CFrame) orig = q.CFrame end
			q.CFrame = rot * orig
		end
		tilted += 1
	end
end
local np = 0
for _, d in ipairs(F:GetDescendants()) do if d:IsA("BasePart") then np += 1 end end
return ("경로 폐차 %d, 막힌 도로 폐차 %d, 취소 %d, 잿더미 %d, 외벽 그을음 %d, 잔해 더미 %d, 연기 %d, 불 %d, 기운 가로등 %d, 파트 %d"):format(
	stats.route, stats.reserved, stats.rejected, stats.ash, stats.burn, stats.debris, stats.smoke, stats.fire, tilted, np)
