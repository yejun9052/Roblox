-- 강남 01: 1단계 블록(강남역~역삼역) 짓기. 데이터 = assets/source/osm/block1_layout.json (tools/seoulmap/make_layout.py).
-- 재생성형: Workspace.Gangnam.Block1 (건물) / Workspace.Gangnam.Ground1 (지면·도로) 를 지우고 다시 만듦. 다른 것은 건드리지 않음.
-- 호출: f(phase, from, to) — phase "ground" = 지면·도로, "buildings" = 건물 from..to 번째 (MCP 시간 제한 때문에 나눠서)
local phase, from, to = ...
local HS = game:GetService("HttpService")
local was = HS.HttpEnabled
HS.HttpEnabled = true
local ok1, kitSrc = pcall(function() return HS:GetAsync("http://127.0.0.1:34999/kit.luau", true) end)
local ok2, laySrc = pcall(function() return HS:GetAsync("http://127.0.0.1:34999/block1_layout.json", true) end)
HS.HttpEnabled = was
assert(ok1 and ok2, "수신기에서 받기 실패")
local Kit = assert(loadstring(kitSrc, "kit"))()
local L = HS:JSONDecode(laySrc)
local M = Enum.Material

local root = workspace:FindFirstChild("Gangnam") or Instance.new("Folder")
root.Name = "Gangnam"
root.Parent = workspace
root:SetAttribute("Credit", L.credit)

local function part(parent, name, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material, p.Anchored = name, size, cf, color, mat, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

if phase == "ground" then
	local g = root:FindFirstChild("Ground1")
	if g then g:Destroy() end
	g = Instance.new("Folder")
	g.Name = "Ground1"
	g.Parent = root
	-- 기본 Baseplate 는 치움 (ServerStorage 에 보관)
	local bp = workspace:FindFirstChild("Baseplate")
	if bp then bp.Parent = game:GetService("ServerStorage") end
	local BW, BH = L.block[1], L.block[2]
	local MG = 260
	local x0, z0, x1, z1 = -MG, -MG, BW + MG, BH + MG
	local pk = L.park
	local GROUND = Color3.fromRGB(70, 68, 66)
	-- 지면 = 공원 자리를 뺀 4장 (공원은 지형으로)
	local function slab(ax, az, bx, bz)
		if bx - ax > 1 and bz - az > 1 then
			part(g, "Ground", Vector3.new(bx - ax, 2, bz - az), CFrame.new((ax + bx) / 2, -1, (az + bz) / 2), GROUND, M.Pavement)
		end
	end
	slab(x0, z0, x1, pk[2])
	slab(x0, pk[4], x1, z1)
	slab(x0, pk[2], pk[1], pk[4])
	slab(pk[3], pk[2], x1, pk[4])
	-- 도로: 선분마다 아스팔트 판 + 꺾이는 점에 원판
	local ASPH = Color3.fromRGB(52, 52, 56)
	local nseg = 0
	for _, r in ipairs(L.roads) do
		local w = r.w
		local y = (w >= 90 and 0.12 or w >= 40 and 0.1 or 0.08)
		for i = 1, #r.pts - 1 do
			local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
			local b = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
			local len = (b - a).Magnitude
			if len > 0.5 then
				local mid = (a + b) / 2
				part(g, "Road", Vector3.new(w, 0.2, len), CFrame.lookAt(mid + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)), ASPH, M.Asphalt)
				nseg += 1
			end
			if i > 1 then
				part(g, "RoadJoint", Vector3.new(0.2, w, w), CFrame.new(a.X, y, a.Z) * CFrame.Angles(0, 0, math.pi / 2), ASPH, M.Asphalt).Shape = Enum.PartType.Cylinder
			end
		end
	end
	-- 차선 표시 ------------------------------------------------------------
	local DASH = "rbxassetid://116000494183574"   -- 흰 점선 15/39 (텍스처 V = 파트 길이 방향)
	local ZEBRA = "rbxassetid://70955332995599"   -- 횡단보도 줄무늬 (U = 파트 폭 방향)
	local YEL, WHT = Color3.fromRGB(214, 170, 40), Color3.fromRGB(226, 224, 216)
	local mk = Instance.new("Folder") mk.Name = "Markings" mk.Parent = g
	-- 교차로 끝점: 다른 이름 도로의 선분이 끝점 근처를 지나면 그 도로 폭 반환
	local allSegs = {}
	for ri, r in ipairs(L.roads) do
		for i = 1, #r.pts - 1 do table.insert(allSegs, {ri, Vector3.new(r.pts[i][1], 0, r.pts[i][2]), Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2]), r.w, r.name}) end
	end
	local function crossW(ri, p)
		local best = 0
		for _, sg in ipairs(allSegs) do
			if sg[1] ~= ri and (sg[5] == "" or sg[5] ~= L.roads[ri].name) then
				local a, b = sg[2], sg[3]
				local ab = b - a
				local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
				if (p - (a + ab * t)).Magnitude < sg[4] / 2 + 2 then best = math.max(best, sg[4]) end
			end
		end
		return best
	end
	local function flat(name, w, len, cf, color, tex, tu, tv)
		local p = part(mk, name, Vector3.new(w, 0.04, len), cf, color, M.SmoothPlastic)
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		if tex then
			p.Transparency = 1
			local t = Instance.new("Texture")
			t.Texture, t.Face = tex, Enum.NormalId.Top
			t.StudsPerTileU, t.StudsPerTileV = tu, tv
			t.Color3 = color
			t.Parent = p
		end
		return p
	end
	local nMark, nCross = 0, 0
	for ri, r in ipairs(L.roads) do
		local w = r.w
		if w >= 40 and #r.pts >= 2 then
			local y = 0.3 -- 도로 윗면(최대 0.22)보다 위
			-- 끝점이 교차로면 그만큼 선을 짧게 하고 횡단보도·정지선
			local p0 = Vector3.new(r.pts[1][1], 0, r.pts[1][2])
			local pn = Vector3.new(r.pts[#r.pts][1], 0, r.pts[#r.pts][2])
			local cw0, cwn = crossW(ri, p0), crossW(ri, pn)
			local trim0 = cw0 > 0 and (cw0 / 2 + 22) or 0
			local trimN = cwn > 0 and (cwn / 2 + 22) or 0
			-- 누적 길이
			local cum = {0}
			for i = 2, #r.pts do
				cum[i] = cum[i - 1] + (Vector3.new(r.pts[i][1], 0, r.pts[i][2]) - Vector3.new(r.pts[i - 1][1], 0, r.pts[i - 1][2])).Magnitude
			end
			local total = cum[#r.pts]
			local lanes
			local offsets, yellow = {}, {}
			if r.oneway then
				lanes = math.max(1, math.floor((w - 2) / 12))
				local lw = (w - 2) / lanes
				for k = 1, lanes - 1 do table.insert(offsets, -w / 2 + 1 + lw * k) end
				table.insert(yellow, -w / 2 + 1.2) -- 중앙분리 쪽(진행 방향 왼쪽 = -side)
			else
				lanes = math.max(1, math.floor((w / 2 - 1) / 12))
				local lw = (w / 2 - 1) / lanes
				for k = 1, lanes - 1 do table.insert(offsets, lw * k) table.insert(offsets, -lw * k) end
				table.insert(yellow, -0.6) table.insert(yellow, 0.6)
			end
			for i = 1, #r.pts - 1 do
				local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
				local b = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
				local len = (b - a).Magnitude
				-- 이 선분에서 표시할 구간 [s0, s1] (전체 기준 trim 반영)
				local s0 = math.max(0, trim0 - cum[i])
				local s1 = math.min(len, (total - trimN) - cum[i])
				if s1 - s0 > 4 then
					local dir = (b - a).Unit
					local side = Vector3.new(-dir.Z, 0, dir.X)
					local mid = a + dir * ((s0 + s1) / 2)
					local L2 = s1 - s0
					local base = CFrame.lookAt(mid + Vector3.new(0, y, 0), mid + Vector3.new(0, y, 0) + dir)
					for _, off in ipairs(offsets) do
						flat("LaneDash", 0.5, L2, base * CFrame.new(off, 0, 0), WHT, DASH, 0.5, 39)
						nMark += 1
					end
					for _, off in ipairs(yellow) do
						flat("CenterLine", 0.45, L2, base * CFrame.new(off, 0, 0), YEL)
						nMark += 1
					end
				end
			end
			-- 횡단보도 + 정지선 (교차로 끝)
			for _, e in ipairs({{p0, Vector3.new(r.pts[2][1], 0, r.pts[2][2]), cw0}, {pn, Vector3.new(r.pts[#r.pts - 1][1], 0, r.pts[#r.pts - 1][2]), cwn}}) do
				if e[3] > 0 then
					local dir = (e[2] - e[1]).Unit
					local c = e[1] + dir * (e[3] / 2 + 8)
					local cf = CFrame.lookAt(c + Vector3.new(0, y, 0), c + Vector3.new(0, y, 0) + dir)
					flat("Crosswalk", w - 4, 10, cf, WHT, ZEBRA, 3, 10)
					flat("StopLine", r.oneway and (w - 4) or (w / 2 - 2), 0.9, cf * CFrame.new(r.oneway and 0 or (w / 4), 0, -8), WHT)
					nCross += 1
				end
			end
		end
	end
	-- 이면도로(16~40): 노란 실선 하나
	for _, r in ipairs(L.roads) do
		if r.w >= 16 and r.w < 40 then
			for i = 1, #r.pts - 1 do
				local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
				local b = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
				local len = (b - a).Magnitude
				if len > 10 then
					local mid = (a + b) / 2
					flat("CenterLine", 0.4, len - 6, CFrame.lookAt(mid + Vector3.new(0, 0.26, 0), b + Vector3.new(0, 0.26, 0)), YEL)
					nMark += 1
				end
			end
		end
	end
	nseg = nseg .. (" / 차선 %d, 횡단보도 %d"):format(nMark, nCross)
	-- 인도 = 도로를 뺀 땅 전체를 0.7 올린 판 (260 타일마다 CSG 로 도로 모양을 뺌). 공원 자리는 비움
	local GS = game:GetService("GeometryService")
	local walkF = Instance.new("Folder") walkF.Name = "Walk" walkF.Parent = g
	local roadParts = {}
	for _, d in ipairs(g:GetChildren()) do if d.Name == "Road" or d.Name == "RoadJoint" then table.insert(roadParts, d) end end
	local opR = OverlapParams.new() opR.FilterType = Enum.RaycastFilterType.Include opR.FilterDescendantsInstances = roadParts
	local TILE, WH = 260, 0.7
	local WALKC = Color3.fromRGB(150, 144, 136)
	local nTile, nFail = 0, 0
	for tx = x0, x1 - 1, TILE do
		for tz = z0, z1 - 1, TILE do
			local sx, sz = math.min(TILE, x1 - tx), math.min(TILE, z1 - tz)
			local tile = Instance.new("Part")
			tile.Anchored = true
			tile.Size = Vector3.new(sx, WH, sz)
			tile.CFrame = CFrame.new(tx + sx / 2, WH / 2, tz + sz / 2)
			tile.Material, tile.Color = M.Pavement, WALKC
			local cutters = {}
			for _, p in ipairs(workspace:GetPartBoundsInBox(tile.CFrame, tile.Size + Vector3.new(2, 6, 2), opR)) do
				local c = p:Clone()
				if c.Shape == Enum.PartType.Cylinder then c.Size = Vector3.new(6, p.Size.Y, p.Size.Z)
				else c.Size = Vector3.new(p.Size.X, 6, p.Size.Z) end
				table.insert(cutters, c)
			end
			-- 공원 자리
			local ix0, iz0 = math.max(tx, pk[1]), math.max(tz, pk[2])
			local ix1, iz1 = math.min(tx + sx, pk[3]), math.min(tz + sz, pk[4])
			if ix1 > ix0 and iz1 > iz0 then
				local c = Instance.new("Part") c.Size = Vector3.new(ix1 - ix0, 6, iz1 - iz0) c.CFrame = CFrame.new((ix0 + ix1) / 2, 0, (iz0 + iz1) / 2)
				table.insert(cutters, c)
			end
			if #cutters == 0 then
				tile.Name = "Walk" tile.Parent = walkF nTile += 1
			else
				local ok, res = pcall(function() return GS:SubtractAsync(tile, cutters, {CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition}) end)
				if ok then
					for _, r in ipairs(res) do r.Name = "Walk" r.Anchored = true r.Parent = walkF nTile += 1 end
				else
					nFail += 1
				end
				tile:Destroy()
			end
			for _, c in ipairs(cutters) do c:Destroy() end
		end
	end
	nseg = nseg .. (" / 인도 판 %d (실패 %d)"):format(nTile, nFail)
	return ("지면·도로: 도로 %d개, 선분 %s"):format(#L.roads, tostring(nseg))
end


if phase == "park" then
	-- 호수공원 + 섬 연구소 (지형). 공원 사각형 L.park = {x0, z0, x1, z1}
	local T = workspace.Terrain
	local pk = L.park
	local x0, z0, x1, z1 = pk[1], pk[2], pk[3], pk[4]
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local old = root:FindFirstChild("Park1")
	if old then old:Destroy() end
	local pf = Instance.new("Folder")
	pf.Name = "Park1"
	pf.Parent = root
	-- 지형 초기화 후 잔디 바닥 (지면 높이 0 에 맞춤: 윗면 y=0)
	T:Clear() -- 지형은 공원에만 씀. Air 채우기로는 물이 안 지워짐(이전 호수가 남았음)
	T:FillBlock(CFrame.new(cx, -6, cz), Vector3.new(x1 - x0, 12, z1 - z0), Enum.Material.Grass)
	-- 공원 테두리: 산책로 (흙)
	for _, s in ipairs({{cx, z0 + 6, x1 - x0, 12}, {cx, z1 - 6, x1 - x0, 12}, {x0 + 6, cz, 12, z1 - z0}, {x1 - 6, cz, 12, z1 - z0}}) do
		T:FillBlock(CFrame.new(s[1], -1, s[2]), Vector3.new(s[3], 2, s[4]), Enum.Material.Ground)
	end
	-- 호수: 타원 (가로 반지름 RX, 세로 RZ) 을 원기둥 여러 개로 파고 물 채움
	local RX, RZ = (x1 - x0) * 0.30, (z1 - z0) * 0.27
	local lx, lz = cx + 20, cz + 10
	local DEPTH = 16
	local step = 10
	for x = lx - RX, lx + RX, step do
		for z = lz - RZ, lz + RZ, step do
			local u, v = (x - lx) / RX, (z - lz) / RZ
			local d = u * u + v * v
			-- 가장자리 출렁임
			local wob = 1 + 0.08 * math.sin(math.atan2(v, u) * 5) + 0.05 * math.sin(math.atan2(v, u) * 3 + 1)
			if d < wob * wob then
				local depth = DEPTH * math.min(1, (1 - math.sqrt(d) / wob) * 3 + 0.25)
				-- 물은 빈칸(Air)에만 채워짐 → 먼저 비우고 채움
				T:FillBlock(CFrame.new(x, -depth / 2 - 0.5, z), Vector3.new(step + 2, depth + 1, step + 2), Enum.Material.Air)
				T:FillBlock(CFrame.new(x, -depth / 2 - 0.5, z), Vector3.new(step + 2, depth + 1, step + 2), Enum.Material.Water)
				T:FillBlock(CFrame.new(x, -depth - 2, z), Vector3.new(step + 2, 3, step + 2), Enum.Material.Mud)
			end
		end
	end
	-- 공원 안을 지나던 도로 조각 치움 (빈 땅을 가로지르던 OSM 길)
	local g1 = root:FindFirstChild("Ground1")
	local cleared = 0
	if g1 then
		for _, r in ipairs(g1:GetDescendants()) do
			local p = r:IsA("BasePart") and r.Position
			if p and r.Name ~= "Ground" and p.X > x0 + 8 and p.X < x1 - 8 and p.Z > z0 + 8 and p.Z < z1 - 8 then
				r:Destroy() cleared += 1
			end
		end
	end
	-- 섬 (가운데) : 바위 + 잔디
	local IR = 70
	T:FillCylinder(CFrame.new(lx, -8, lz), 16, IR, Enum.Material.Rock)
	T:FillCylinder(CFrame.new(lx, 0.5, lz), 2, IR - 6, Enum.Material.Grass)
	-- 연구소 (섬 위): 콘크리트 2층 + 철조망 + 안테나 + 경고 표지
	local lab = Instance.new("Model")
	lab.Name = "IslandLab"
	lab:SetAttribute("HiddenBoss", true)
	lab.Parent = pf
	local C = Color3.fromRGB(176, 178, 176)
	local function lp(name, size, cf, col, mat, shape)
		local p = part(lab, name, size, cf, col, mat)
		if shape then p.Shape = shape end
		return p
	end
	local LW, LD, LH = 64, 44, 26
	lp("LabBody", Vector3.new(LW, LH, LD), CFrame.new(lx, 1.5 + LH / 2, lz), C, M.Concrete)
	lp("LabRoofEdge", Vector3.new(LW + 2, 1.5, LD + 2), CFrame.new(lx, 1.5 + LH + 0.75, lz), Color3.fromRGB(120, 122, 124), M.Concrete)
	lp("LabStripe", Vector3.new(LW + 0.4, 2, LD + 0.4), CFrame.new(lx, 1.5 + 12, lz), Color3.fromRGB(40, 110, 150), M.SmoothPlastic)
	lp("Dome", Vector3.new(22, 22, 22), CFrame.new(lx + 14, 1.5 + LH, lz), Color3.fromRGB(200, 204, 206), M.Metal, Enum.PartType.Ball)
	lp("Antenna", Vector3.new(0.8, 24, 0.8), CFrame.new(lx - 22, 1.5 + LH + 12, lz - 12), Color3.fromRGB(80, 80, 84), M.Metal)
	-- 창 (어둡게 깨짐)
	local fz = lz - LD / 2 - 0.1
	for i = 0, 4 do
		for k = 0, 1 do
			local w = lp("LabWindow", Vector3.new(7, 4, 0.2), CFrame.new(lx - 24 + i * 12, 1.5 + 6 + k * 11, fz), Color3.fromRGB(16, 18, 20), M.SmoothPlastic)
			local d = Instance.new("Decal") d.Texture = Kit.TEX.curtainwall_broken d.Face = Enum.NormalId.Front d.Parent = w
		end
	end
	-- 정문 + 경고 표지
	lp("LabDoor", Vector3.new(10, 10, 0.4), CFrame.new(lx, 1.5 + 5, fz - 0.1), Color3.fromRGB(60, 64, 68), M.DiamondPlate)
	local sign = lp("LabSign", Vector3.new(16, 3, 0.3), CFrame.new(lx, 1.5 + 13, fz - 0.3), Color3.fromRGB(230, 200, 40), M.SmoothPlastic)
	local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 30
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.TextScaled = true
	t.FontFace = Font.fromEnum(Enum.Font.GothamBlack) t.Text = "⚠ 생물안전 4등급 · 출입금지" t.TextColor3 = Color3.fromRGB(20, 20, 20) t.Parent = g g.Parent = sign
	-- 철조망 펜스 (섬 둘레)
	local n = 28
	for i = 0, n - 1 do
		local a0, a1 = i / n * math.pi * 2, (i + 1) / n * math.pi * 2
		local p0 = Vector3.new(lx + math.cos(a0) * (IR - 10), 0, lz + math.sin(a0) * (IR - 10))
		local p1 = Vector3.new(lx + math.cos(a1) * (IR - 10), 0, lz + math.sin(a1) * (IR - 10))
		if i % 7 ~= 3 then -- 군데군데 뚫림
			local mid = (p0 + p1) / 2
			local f = lp("Fence", Vector3.new(0.2, 7, (p1 - p0).Magnitude), CFrame.lookAt(mid + Vector3.new(0, 4.5, 0), p1 + Vector3.new(0, 4.5, 0)), Color3.fromRGB(60, 62, 66), M.Metal)
			f.Transparency = 1
			local d1 = Instance.new("Texture") d1.Texture = Kit.TEX.rail_iron d1.Face = Enum.NormalId.Left d1.StudsPerTileU, d1.StudsPerTileV = 8, 7 d1.Parent = f
			local d2 = d1:Clone() d2.Face = Enum.NormalId.Right d2.Parent = f
		end
		lp("FencePost", Vector3.new(0.5, 8, 0.5), CFrame.new(p0.X, 5, p0.Z), Color3.fromRGB(60, 62, 66), M.Metal)
	end
	-- 끊어진 다리: 남쪽 기슭 → 섬, 가운데 구간 빠짐
	local shoreZ = lz + RZ + 8
	local bz0, bz1 = lz + IR - 4, shoreZ
	local len = bz1 - bz0
	local segs = 6
	for i = 0, segs - 1 do
		if i ~= 2 and i ~= 3 then
			local zz = bz0 + len * (i + 0.5) / segs
			local tilt = (i == 1 and math.rad(-14)) or (i == 4 and math.rad(12)) or 0
			local dy = (i == 1 or i == 4) and -2.5 or 0
			lp("Bridge", Vector3.new(12, 1.2, len / segs), CFrame.new(lx, 2 + dy, zz) * CFrame.Angles(tilt, 0, 0), Color3.fromRGB(150, 146, 140), M.Concrete)
		end
		lp("BridgePier", Vector3.new(2, 14, 2), CFrame.new(lx - 5, -5, bz0 + len * i / segs), Color3.fromRGB(130, 128, 124), M.Concrete)
		lp("BridgePier", Vector3.new(2, 14, 2), CFrame.new(lx + 5, -5, bz0 + len * i / segs), Color3.fromRGB(130, 128, 124), M.Concrete)
	end
	-- 산책로 (지형 Pavement 띠, 잔디와 같은 높이) -------------------------------
	T:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(150, 140, 126))
	T:SetMaterialColor(Enum.Material.LeafyGrass, Color3.fromRGB(96, 110, 52))
	local paths = {} -- {a, b, w}
	local function path(a, b, w)
		local d = b - a
		local len = d.Magnitude
		if len < 1 then return end
		-- 지형 칸(4 스터드) 하나를 통째로: 얇으면 기존 잔디가 이김
		local cf = CFrame.lookAt((a + b) / 2 + Vector3.new(0, -2, 0), (a + b) / 2 + Vector3.new(0, -2, 0) + d)
		T:FillBlock(cf, Vector3.new(w, 4, len + w * 0.6), Enum.Material.Pavement)
		table.insert(paths, {a, b, w})
	end
	local function nearPath(x, z, pad)
		local p = Vector3.new(x, 0, z)
		for _, q in ipairs(paths) do
			local a, b = q[1], q[2]
			local ab = b - a
			local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
			if (p - (a + ab * t)).Magnitude < q[3] / 2 + pad then return true end
		end
		return false
	end
	-- 호수 둘레길 (타원)
	local RING = 1.2
	local NR = 40
	local ring = {}
	for i = 0, NR - 1 do
		local a = i / NR * math.pi * 2
		local wob = 1 + 0.08 * math.sin(a * 5) + 0.05 * math.sin(a * 3 + 1)
		ring[i] = Vector3.new(lx + math.cos(a) * RX * RING * wob, 0, lz + math.sin(a) * RZ * RING * wob)
	end
	for i = 0, NR - 1 do path(ring[i], ring[(i + 1) % NR], 12) end
	-- 입구 6곳 → 둘레길 (가장 가까운 점까지, 살짝 굽게)
	local gates = {Vector3.new(cx, 0, z0 + 2), Vector3.new(cx, 0, z1 - 2), Vector3.new(x0 + 2, 0, cz), Vector3.new(x1 - 2, 0, cz), Vector3.new(x0 + 2, 0, z0 + 2), Vector3.new(x1 - 2, 0, z1 - 2)}
	local rngP = Random.new(77)
	for _, gp in ipairs(gates) do
		local best, bd = nil, 1e9
		for i = 0, NR - 1 do local d = (ring[i] - gp).Magnitude if d < bd then best, bd = ring[i], d end end
		local mid = (gp + best) / 2 + Vector3.new(rngP:NextNumber(-30, 30), 0, rngP:NextNumber(-20, 20))
		path(gp, mid, 10) path(mid, best, 10)
	end
	-- 북쪽 입구 광장
	local plaza = Vector3.new(cx - 160, 0, z0 + 70)
	T:FillCylinder(CFrame.new(plaza + Vector3.new(0, -2, 0)), 4, 38, Enum.Material.Pavement)
	table.insert(paths, {plaza, plaza, 76})
	-- 정자 (광장 옆): 기둥 4 + 마루 + 기와 지붕(쐐기 4)
	local jz = Instance.new("Model") jz.Name = "Pavilion" jz.Parent = pf
	local jc = Vector3.new(cx + 200, 0, z0 + 80)
	local WOOD, ROOF = Color3.fromRGB(110, 72, 44), Color3.fromRGB(58, 60, 64)
	part(jz, "Deck", Vector3.new(22, 1.5, 22), CFrame.new(jc + Vector3.new(0, 0.75, 0)), WOOD, M.WoodPlanks)
	for _, o in ipairs({{-9, -9}, {9, -9}, {9, 9}, {-9, 9}}) do
		part(jz, "Post", Vector3.new(1.2, 11, 1.2), CFrame.new(jc + Vector3.new(o[1], 7, o[2])), WOOD, M.Wood)
	end
	part(jz, "Beam", Vector3.new(21, 1, 21), CFrame.new(jc + Vector3.new(0, 12.5, 0)), Color3.fromRGB(140, 60, 50), M.Wood)
	for k = 0, 3 do
		local rot = CFrame.Angles(0, k * math.pi / 2, 0)
		part(jz, "RoofTile", Vector3.new(28, 6, 14), CFrame.new(jc + Vector3.new(0, 16, 0)) * rot * CFrame.new(0, 0, 7) * CFrame.Angles(0, math.pi, 0), ROOF, M.Slate).Parent = jz
	end
	for _, d in ipairs(jz:GetChildren()) do if d.Name == "RoofTile" then local w2 = Instance.new("WedgePart") w2.Size, w2.CFrame, w2.Color, w2.Material, w2.Anchored, w2.Name = d.Size, d.CFrame, d.Color, d.Material, true, d.Name w2.Parent = jz d:Destroy() end end
	table.insert(paths, {jc, jc, 30})
	-- 놀이터: 모래 바닥 + 미끄럼틀 + 그네 + 정글짐 (녹슨 색)
	local pg = Instance.new("Model") pg.Name = "Playground" pg.Parent = pf
	local pc = Vector3.new(cx + 330, 0, z1 - 90)
	T:FillCylinder(CFrame.new(pc + Vector3.new(0, -2, 0)), 4, 34, Enum.Material.Sand)
	local RUST, BLUE, YELW = Color3.fromRGB(150, 80, 50), Color3.fromRGB(60, 96, 140), Color3.fromRGB(196, 160, 60)
	part(pg, "SlideTower", Vector3.new(6, 8, 6), CFrame.new(pc + Vector3.new(-12, 4, 0)), BLUE, M.Metal)
	part(pg, "SlideRoof", Vector3.new(7, 0.6, 7), CFrame.new(pc + Vector3.new(-12, 11, 0)), RUST, M.Metal)
	part(pg, "Slide", Vector3.new(4, 0.5, 13), CFrame.new(pc + Vector3.new(-12, 4.4, 9.5)) * CFrame.Angles(math.rad(-34), 0, 0), YELW, M.SmoothPlastic)
	for _, x in ipairs({6, 18}) do
		part(pg, "SwingPost", Vector3.new(0.6, 10, 0.6), CFrame.new(pc + Vector3.new(x, 5, -6)) * CFrame.Angles(0, 0, math.rad(x == 6 and 10 or -10)), RUST, M.Metal)
	end
	part(pg, "SwingBar", Vector3.new(14, 0.5, 0.5), CFrame.new(pc + Vector3.new(12, 10, -6)), RUST, M.Metal)
	for _, x in ipairs({9.5, 14.5}) do
		part(pg, "SwingSeat", Vector3.new(2.6, 0.3, 1.2), CFrame.new(pc + Vector3.new(x, 2.4, -6)) * CFrame.Angles(math.rad(x == 14.5 and 25 or 0), 0, 0), Color3.fromRGB(40, 40, 44), M.Rubber)
		local ch = part(pg, "SwingChain", Vector3.new(0.15, 7.5, 0.15), CFrame.new(pc + Vector3.new(x, 6.2, -6)), Color3.fromRGB(90, 90, 90), M.Metal)
		ch.CanCollide = false
	end
	for gx = 0, 2 do for gz = 0, 2 do
		part(pg, "JungleGym", Vector3.new(0.4, 6, 0.4), CFrame.new(pc + Vector3.new(4 + gx * 4, 3, 10 + gz * 4)), BLUE, M.Metal)
	end end
	for gy = 2, 6, 4 do
		part(pg, "JungleBar", Vector3.new(8.4, 0.4, 0.4), CFrame.new(pc + Vector3.new(8, gy, 14)), BLUE, M.Metal)
		part(pg, "JungleBar", Vector3.new(0.4, 0.4, 8.4), CFrame.new(pc + Vector3.new(8, gy, 14)), BLUE, M.Metal)
	end
	table.insert(paths, {pc, pc, 70})
	-- 호숫가 나무 데크 (남서쪽 물가 따라)
	local deck = Instance.new("Model") deck.Name = "Boardwalk" deck.Parent = pf
	for i = 22, 30 do
		local a0, a1 = i / NR * math.pi * 2, (i + 1) / NR * math.pi * 2
		local p0 = Vector3.new(lx + math.cos(a0) * RX * 0.98, 0, lz + math.sin(a0) * RZ * 0.98)
		local p1 = Vector3.new(lx + math.cos(a1) * RX * 0.98, 0, lz + math.sin(a1) * RZ * 0.98)
		local mid = (p0 + p1) / 2
		local broken = rngP:NextNumber() < 0.15
		if not broken then
			part(deck, "Deck", Vector3.new(9, 0.8, (p1 - p0).Magnitude + 0.5), CFrame.lookAt(mid + Vector3.new(0, 1.2, 0), p1 + Vector3.new(0, 1.2, 0)), WOOD, M.WoodPlanks)
		end
		part(deck, "DeckPost", Vector3.new(0.8, 6, 0.8), CFrame.new(p0 + Vector3.new(0, -1.5, 0)), WOOD, M.Wood)
	end
	-- 웃자란 풀밭 (LeafyGrass 반점) — 둘레길·광장·놀이터 밖
	local placedOver = 0
	for i = 1, 90 do
		local x, z = rngP:NextNumber(x0 + 30, x1 - 30), rngP:NextNumber(z0 + 30, z1 - 30)
		local u, v = (x - lx) / RX, (z - lz) / RZ
		if u * u + v * v > 1.6 and not nearPath(x, z, 20) then
			T:FillCylinder(CFrame.new(x, -2, z), 4, rngP:NextNumber(16, 34), Enum.Material.LeafyGrass)
			for k = 1, 6 do Kit.grass(pf, CFrame.new(x + rngP:NextNumber(-14, 14), 0, z + rngP:NextNumber(-14, 14)), {seed = 900 + i * 10 + k, scale = rngP:NextNumber(1.2, 2.0)}) end
			placedOver += 1
		end
	end
	-- 나무: 길 밖, 호수 밖, 숲처럼 군데군데 모이게
	local rng = Random.new(1111)
	local placed = 0
	local groves = {}
	for g2 = 1, 9 do table.insert(groves, Vector3.new(rng:NextNumber(x0 + 40, x1 - 40), 0, rng:NextNumber(z0 + 40, z1 - 40))) end
	for i = 1, 320 do
		local gc = groves[rng:NextInteger(1, #groves)]
		local x, z = gc.X + rng:NextNumber(-70, 70), gc.Z + rng:NextNumber(-55, 55)
		if i % 4 == 0 then x, z = rng:NextNumber(x0 + 14, x1 - 14), rng:NextNumber(z0 + 14, z1 - 14) end
		local u, v = (x - lx) / RX, (z - lz) / RZ
		if x > x0 + 10 and x < x1 - 10 and z > z0 + 10 and z < z1 - 10 and u * u + v * v > 1.5 and not nearPath(x, z, 9) then
			local r = rng:NextNumber()
			Kit.tree(pf, CFrame.new(x, 0, z), {seed = i, planter = false, leaves = r < 0.35 and nil or (r < 0.7 and "dry" or "dead"), height = rng:NextNumber(20, 30), radius = rng:NextNumber(7, 10)})
			placed += 1
		end
	end
	-- 둘레길 벤치·가로등 (길 바깥쪽 가장자리, 일부 쓰러짐)
	local lib = game.ServerStorage:FindFirstChild("Kit22_Props")
	for i = 0, NR - 1, 2 do
		local p = ring[i]
		local out = (p - Vector3.new(lx, 0, lz)).Unit
		local pos = p + out * 8
		local nm = (i % 4 == 0) and "Bench" or "StreetLamp"
		if lib and lib:FindFirstChild(nm) then
			local c = lib[nm]:Clone()
			c:PivotTo(CFrame.lookAt(pos, pos - out))
			if nm == "StreetLamp" and rng:NextNumber() < 0.3 then c:PivotTo(c:GetPivot() * CFrame.Angles(math.rad(rng:NextNumber(15, 40)), 0, 0)) end
			c.Parent = pf
		end
	end
	return ("호수공원: 나무 %d, 길 %d, 웃자란 풀밭 %d, 호수 %dx%d, 공원 안 도로 조각 %d 치움"):format(placed, #paths, placedOver, math.floor(RX * 2), math.floor(RZ * 2), cleared)
end


if phase == "streets" then
	-- 거리: 모든 도로 인도+연석, 가로수·가로등(일부 쓰러짐·꺾임), 골목 전봇대+전선(일부 기욺), 폐차(정체·추돌·역주행·인도 위·전복), 잔해
	local old = root:FindFirstChild("Streets1")
	if old then old:Destroy() end
	local sf = Instance.new("Folder") sf.Name = "Streets1" sf.Parent = root
	local walk = Instance.new("Folder") walk.Name = "Sidewalks" walk.Parent = sf
	local green = Instance.new("Folder") green.Name = "Trees" green.Parent = sf
	local poles = Instance.new("Folder") poles.Name = "Poles" poles.Parent = sf
	local cars = Instance.new("Folder") cars.Name = "Wrecks" cars.Parent = sf
	local junk = Instance.new("Folder") junk.Name = "Debris" junk.Parent = sf
	local rng = Random.new(4040)
	local lib = game:GetService("ServerStorage"):FindFirstChild("Kit22_Props")
	local function put(parent, name, cf)
		local t = lib and lib:FindFirstChild(name)
		if not t then return nil end
		local c = t:Clone()
		c:PivotTo(cf)
		c.Parent = parent
		return c
	end
	local pk = L.park
	local function inPark(x, z, pad) pad = pad or 0 return x > pk[1] - pad and x < pk[3] + pad and z > pk[2] - pad and z < pk[4] + pad end
	local blk = root:FindFirstChild("Block1")
	local g1 = root:FindFirstChild("Ground1")
	local opB = OverlapParams.new() opB.FilterType = Enum.RaycastFilterType.Include opB.FilterDescendantsInstances = {blk}
	local opR = OverlapParams.new() opR.FilterType = Enum.RaycastFilterType.Include opR.FilterDescendantsInstances = {g1}
	local function freeOfBuildings(cf, size) return #workspace:GetPartBoundsInBox(cf, size, opB) == 0 end
	local function onRoad(cf, size)
		for _, p in ipairs(workspace:GetPartBoundsInBox(cf, size, opR)) do
			if p.Name == "Road" or p.Name == "RoadJoint" then return true end
		end
		return false
	end
	local function sidewalkW(w) return w >= 90 and 24 or w >= 45 and 14 or w >= 16 and 7 or 0 end -- make_layout.py 와 같은 값
	local major = {}
	for _, r in ipairs(L.roads) do
		if r.w >= 45 then
			for i = 1, #r.pts - 1 do table.insert(major, {Vector3.new(r.pts[i][1], 0, r.pts[i][2]), Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2]), r.w}) end
		end
	end
	local function nearMajor(p, pad)
		for _, m in ipairs(major) do
			local a, b = m[1], m[2]
			local ab = b - a
			local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
			if (p - (a + ab * t)).Magnitude < m[3] / 2 + pad then return true end
		end
		return false
	end
	-- 차 겹침 방지 격자
	local occ = {}
	local function key(x, z) return math.floor(x / 8) .. "," .. math.floor(z / 8) end
	local function freeCar(p, r)
		for dx = -1, 1 do for dz = -1, 1 do
			local list = occ[key(p.X + dx * 8, p.Z + dz * 8)]
			if list then for _, q in ipairs(list) do if (q - p).Magnitude < r then return false end end end
		end end
		return true
	end
	local function markCar(p) local k = key(p.X, p.Z) occ[k] = occ[k] or {} table.insert(occ[k], p) end
	-- 로블록스풍 차 (사용자 요청: 사실적인 차 대신 단순하고 깔끔한 로블록스 느낌). 경찰차는 드물게
	-- 사용자 요청(3차): 검은색·흰색 승용차만 (택시·경찰차·픽업·버스 없음), 덜 빼곡하게
	local CARS = {"RbxSedanBlack", "RbxSedanBlack", "RbxSedanWhite", "RbxSedanWhite", "RbxSUVBlack", "RbxHatch"}
	do -- 아직 없는 차종은 빼고
		local ok = {}
		for _, n in ipairs(CARS) do if lib and lib:FindFirstChild(n) then table.insert(ok, n) end end
		CARS = ok
	end
	local nCar = 0
	-- yaw: 진행 방향 dir 을 보게. pose: "ok" / "tilt" / "side" / "flip"
	local function wreck(pos, dir, jitterDeg, surfaceY)
		if inPark(pos.X, pos.Z, 6) then return nil end -- 공원(호수) 안에는 차 없음
		if not freeCar(pos, 9) then return nil end
		if not freeOfBuildings(CFrame.new(pos.X, 3, pos.Z), Vector3.new(7, 5, 7)) then return nil end
		local yaw = math.atan2(-dir.X, -dir.Z) + math.rad(rng:NextNumber(-jitterDeg, jitterDeg))
		local c = put(cars, CARS[rng:NextInteger(1, #CARS)], CFrame.new(pos.X, surfaceY or 0.2, pos.Z) * CFrame.Angles(0, yaw, 0))
		if not c then return nil end
		local r = rng:NextNumber()
		local _, sz = c:GetBoundingBox()
		if r < 0.07 then -- 전복
			c:PivotTo(c:GetPivot() * CFrame.new(0, sz.Y, 0) * CFrame.Angles(0, 0, math.pi))
			Kit.scorch(junk, CFrame.new(pos.X, 0.2, pos.Z), 6, nCar)
		elseif r < 0.12 then -- 옆으로 누움
			c:PivotTo(c:GetPivot() * CFrame.new(0, sz.X / 2, 0) * CFrame.Angles(0, 0, math.pi / 2 * (rng:NextNumber() < 0.5 and 1 or -1)))
		elseif r < 0.30 then -- 바퀴 빠져 기움
			c:PivotTo(c:GetPivot() * CFrame.Angles(math.rad(rng:NextNumber(-5, 5)), 0, math.rad(rng:NextNumber(4, 10) * (rng:NextNumber() < 0.5 and 1 or -1))))
		end
		if rng:NextNumber() < 0.12 then Kit.scorch(junk, CFrame.new(pos.X, 0.2, pos.Z), rng:NextNumber(5, 7), nCar + 7) end
		markCar(pos)
		nCar += 1
		return c
	end
	local FENCE = Color3.fromRGB(214, 212, 204)
	local fences = Instance.new("Folder") fences.Name = "Fences" fences.Parent = sf
	local rpWalk = RaycastParams.new() rpWalk.FilterType = Enum.RaycastFilterType.Include rpWalk.FilterDescendantsInstances = {g1}
	local nWalk, nTree, nLamp, nPole, nFallen, nFence = 0, 0, 0, 0, 0, 0
	for ri, r in ipairs(L.roads) do
		local w = r.w
		local swW = sidewalkW(w)
		local mode = rng:NextNumber() -- 도로마다 차 밀도: 정체 / 띄엄띄엄 / 거의 없음
		local density = mode < 0.3 and 0.38 or (mode < 0.8 and 0.14 or 0.03)
		for i = 1, #r.pts - 1 do
			local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
			local b = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
			local seg = b - a
			local len = seg.Magnitude
			if len > 4 and not inPark(a.X, a.Z, 6) then
				local dir = seg.Unit
				local side = Vector3.new(-dir.Z, 0, dir.X)
				-- 인도(올린 땅) 위: 가로수·가로등·쓰레기 + 대로변 방호 울타리. 인도 판 위인지 레이로 확인
				local function onWalk(p)
					local hit = workspace:Raycast(p + Vector3.new(0, 5, 0), Vector3.new(0, -8, 0), rpWalk)
					return hit and hit.Instance.Name == "Walk" and hit.Position.Y > 0.5
				end
				if w >= 16 then
					local step = 18
					local n = math.max(1, math.floor(len / step))
					for k = 0, n - 1 do
						local mid = a + dir * (len * (k + 0.5) / n)
						for _, sgn in ipairs({-1, 1}) do
							local toRoad = -side * sgn
							local tpos = mid + side * sgn * (w / 2 + 3.2)
							if onWalk(tpos) and freeOfBuildings(CFrame.new(tpos.X, 8, tpos.Z), Vector3.new(4, 14, 4)) then
								local slot = (w >= 40) and (k % 3 == 1) or (k % 6 == 2 and rng:NextNumber() < 0.5)
								if slot then
									if rng:NextNumber() < 0.6 then
										local rr = rng:NextNumber()
										local t = Kit.tree(green, CFrame.new(tpos.X, 0.7, tpos.Z), {seed = ri * 100 + i * 7 + k, leaves = rr < 0.3 and nil or (rr < 0.7 and "dry" or "dead"), height = rng:NextNumber(18, 24)})
										nTree += 1
										if rng:NextNumber() < 0.2 then
											local fall = (rng:NextNumber() < 0.8 and toRoad or -toRoad) + dir * rng:NextNumber(-0.4, 0.4)
											local axis = Vector3.yAxis:Cross(fall.Unit).Unit
											t:PivotTo(CFrame.new(tpos.X, 0.9, tpos.Z) * CFrame.fromAxisAngle(axis, math.rad(rng:NextNumber(72, 86))) * (t:GetPivot() - t:GetPivot().Position))
											for _, d in ipairs(t:GetChildren()) do if d.Name:match("^Planter") or d.Name == "Soil" then d:Destroy() end end
											nFallen += 1
										end
									else
										local lamp = put(green, "StreetLamp", CFrame.new(tpos.X, 0.7, tpos.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
										nLamp += 1
										local q = rng:NextNumber()
										if lamp and q < 0.12 then
											local axis = Vector3.yAxis:Cross((toRoad + dir * rng:NextNumber(-0.6, 0.6)).Unit).Unit
											lamp:PivotTo(CFrame.new(tpos.X, 0.9, tpos.Z) * CFrame.fromAxisAngle(axis, math.rad(rng:NextNumber(78, 88))))
											nFallen += 1
										elseif lamp and q < 0.4 then
											local axis = Vector3.yAxis:Cross((toRoad + dir * rng:NextNumber(-1, 1)).Unit).Unit
											lamp:PivotTo(lamp:GetPivot() * CFrame.fromAxisAngle(axis, math.rad(rng:NextNumber(14, 38))))
										end
									end
								elseif k % 4 == 3 and rng:NextNumber() < 0.35 then
									local ppos = mid + side * sgn * (w / 2 + rng:NextNumber(4, 9)) + dir * rng:NextNumber(-5, 5)
									if onWalk(ppos) and freeOfBuildings(CFrame.new(ppos.X, 3, ppos.Z), Vector3.new(5, 5, 5)) then
										local nm = ({"TrashPile", "TrashPile", "Dumpster", "ShoppingCart"})[rng:NextInteger(1, 4)]
										put(junk, nm, CFrame.new(ppos.X, 0.7, ppos.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
									end
								end
							end
						end
					end
				end
				-- 보행자 방호 울타리 (대로·중로 연석 따라 구간구간, 일부 휘거나 빠짐)
				if w >= 40 then
					for _, sgn in ipairs({-1, 1}) do
						local on = rng:NextNumber() < 0.5
						local t = 0
						while t < len - 8 do
							if rng:NextNumber() < 0.12 then on = not on end
							local c = a + dir * (t + 4) + side * sgn * (w / 2 + 1.0)
							if on and onWalk(c) and onWalk(c + dir * 3.5) and onWalk(c - dir * 3.5) and freeOfBuildings(CFrame.new(c.X, 2, c.Z), Vector3.new(1, 3, 8)) then
								local q = rng:NextNumber()
								if q > 0.06 then -- 6% 는 패널 빠짐
									local cf = CFrame.lookAt(Vector3.new(c.X, 0.7, c.Z), Vector3.new(c.X, 0.7, c.Z) + dir)
									if q < 0.16 then cf = cf * CFrame.Angles(math.rad(rng:NextNumber(-35, 35)), 0, math.rad(rng:NextNumber(-10, 10))) end -- 휨
									local panel = part(fences, "FencePanel", Vector3.new(0.12, 3.0, 8), cf * CFrame.new(0, 1.9, 0), FENCE, M.Metal)
									panel.Transparency = 1
									for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
										local tx = Instance.new("Texture") tx.Texture = Kit.TEX.rail_iron tx.Face = face
										tx.StudsPerTileU, tx.StudsPerTileV = 8, 3.2 tx.Color3 = FENCE tx.Parent = panel
									end
									part(fences, "FenceRail", Vector3.new(0.25, 0.25, 8), cf * CFrame.new(0, 3.45, 0), FENCE, M.Metal)
									part(fences, "FencePost", Vector3.new(0.35, 3.6, 0.35), cf * CFrame.new(0, 1.8, -4), FENCE, M.Metal)
									nFence += 1
								end
							end
							t += 8
						end
					end
				end
				-- 골목 전봇대 + 전선
				if w <= 24 then
					local n = math.max(1, math.floor(len / 40))
					local prev = nil
					for k = 0, n do
						local pos = a + dir * (len * k / n) + side * (w / 2 + 1.6)
						local onWalkHere = workspace:Raycast(Vector3.new(pos.X, 5, pos.Z), Vector3.new(0, -8, 0), rpWalk)
						if not inPark(pos.X, pos.Z, 6) and not nearMajor(Vector3.new(pos.X, 0, pos.Z), 26) and onWalkHere and onWalkHere.Instance.Name == "Walk"
							and not onRoad(CFrame.new(pos.X, 0, pos.Z), Vector3.new(2.5, 2, 2.5)) and freeOfBuildings(CFrame.new(pos.X, 10, pos.Z), Vector3.new(1, 18, 1)) then
							local lean = rng:NextNumber() < 0.08
							local base = CFrame.new(pos.X, 0.7, pos.Z)
							local tilt = lean and CFrame.fromAxisAngle(Vector3.yAxis:Cross((-side + dir * rng:NextNumber(-0.5, 0.5)).Unit).Unit, math.rad(rng:NextNumber(14, 26))) or CFrame.new()
							local top = base * tilt
							local pole = part(poles, "UtilityPole", Vector3.new(22, 1.1, 1.1), top * CFrame.new(0, 11, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 148, 142), M.Concrete)
							pole.Shape = Enum.PartType.Cylinder
							local armPos = (top * CFrame.new(0, 20, 0)).Position
							part(poles, "CrossArm", Vector3.new(0.4, 0.4, 5), CFrame.lookAt(armPos, armPos + side), Color3.fromRGB(90, 90, 94), M.Metal)
							if rng:NextNumber() < 0.25 then
								local tr = part(poles, "Transformer", Vector3.new(2.6, 1.8, 1.8), top * CFrame.new(0, 16.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 114, 116), M.Metal)
								tr.Shape = Enum.PartType.Cylinder
							end
							nPole += 1
							if prev and not lean then
								for wi, off in ipairs({-1.8, 0, 1.8}) do
									local p0 = prev + side * off + Vector3.new(0, 20.6 - wi * 0.25, 0)
									local p1 = pos + side * off + Vector3.new(0, 20.6 - wi * 0.25, 0)
									local m = (p0 + p1) / 2 + Vector3.new(0, -1.6 - wi * 0.3, 0)
									for _, pair in ipairs({{p0, m}, {m, p1}}) do
										local wl = part(poles, "Wire", Vector3.new(0.12, 0.12, (pair[2] - pair[1]).Magnitude), CFrame.lookAt((pair[1] + pair[2]) / 2, pair[2]), Color3.fromRGB(24, 24, 26), M.SmoothPlastic)
										wl.CanCollide, wl.CanQuery, wl.CanTouch, wl.CastShadow = false, false, false, false
									end
								end
							elseif lean and rng:NextNumber() < 0.7 then
								-- 끊어져 늘어진 전선 (기운 전봇대 끝에서 땅으로)
								for wi = 1, 2 do
									local p0 = armPos + side * (wi == 1 and -1.8 or 1.8)
									local p1 = Vector3.new(pos.X, 0.4, pos.Z) + dir * rng:NextNumber(-14, 14) - side * rng:NextNumber(2, 8)
									local wl = part(poles, "Wire", Vector3.new(0.12, 0.12, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), Color3.fromRGB(24, 24, 26), M.SmoothPlastic)
									wl.CanCollide, wl.CanQuery, wl.CanTouch, wl.CastShadow = false, false, false, false
								end
							end
							prev = (not lean) and pos or nil
						else
							prev = nil
						end
					end
				end
				-- 폐차 ----------------------------------------------------------
				if w >= 40 then
					-- 차로 안쪽: 정체 구간은 줄지어(조금씩 비뚤게), 나머지는 띄엄띄엄 제멋대로
					local lanes = {}
					if r.oneway then
						local n = math.max(1, math.floor((w - 2) / 12))
						for k = 1, n do table.insert(lanes, {off = -w / 2 + 1 + (w - 2) * (k - 0.5) / n, d = dir}) end
					else
						local n = math.max(1, math.floor((w / 2 - 1) / 12))
						for k = 1, n do
							table.insert(lanes, {off = (w / 2 - 1) * (k - 0.5) / n, d = dir})
							table.insert(lanes, {off = -(w / 2 - 1) * (k - 0.5) / n, d = -dir})
						end
					end
					-- 차가 지나갈 길: 차로 하나는 거의 비워 둠 (양방향이면 방향마다 하나)
					local freeLane = {}
					if r.oneway then freeLane[rng:NextInteger(1, #lanes)] = true
					else freeLane[rng:NextInteger(1, math.max(1, #lanes / 2)) * 2 - 1] = true freeLane[rng:NextInteger(1, math.max(1, #lanes / 2)) * 2] = true end
					for li, ln in ipairs(lanes) do
						local laneDensity = freeLane[li] and density * 0.08 or density
						local t = rng:NextNumber(0, 12)
						while t < len do
							local jam = density > 0.5
							if rng:NextNumber() < laneDensity then
								local pos = a + dir * t + side * (ln.off + rng:NextNumber(-2.5, 2.5))
								local d = ln.d
								local jit = jam and 18 or 55
								if rng:NextNumber() < 0.06 then d = -d end                     -- 역주행
								if rng:NextNumber() < 0.07 then d = side * (rng:NextNumber() < 0.5 and 1 or -1) jit = 25 end -- 가로로 멈춤
								wreck(pos, d, jit)
							end
							t += jam and rng:NextNumber(15, 24) or rng:NextNumber(28, 80)
						end
					end
					-- 인도로 올라간 차
					if swW > 0 and rng:NextNumber() < 0.25 then
						local sgn = rng:NextNumber() < 0.5 and -1 or 1
						local pos = a + dir * rng:NextNumber(0, len) + side * sgn * (w / 2 + swW * 0.4)
						if freeOfBuildings(CFrame.new(pos.X, 3, pos.Z), Vector3.new(12, 5, 14)) then
							wreck(pos, (dir + side * sgn * rng:NextNumber(0.3, 1.2)).Unit, 20, 0.9)
						end
					end
					-- 균열
					for k = 1, math.floor(len / 50) do
						local pos = a + dir * rng:NextNumber(0, len) + side * rng:NextNumber(-w / 2 + 3, w / 2 - 3)
						Kit.crack(junk, CFrame.new(pos.X, 0.33, pos.Z), rng:NextNumber(8, 16), ri * 97 + k)
					end
				elseif w >= 16 then
					-- 골목: 한쪽에 세워둔 채 버려진 차
					local t = rng:NextNumber(5, 40)
					while t < len - 5 do
						if rng:NextNumber() < 0.45 then
							local sgn = rng:NextNumber() < 0.5 and -1 or 1
							wreck(a + dir * t + side * sgn * (w / 2 - 4), dir * (rng:NextNumber() < 0.5 and 1 or -1), 12)
						end
						t += rng:NextNumber(25, 60)
					end
				end
				for k = 1, math.floor(len / 40) do
					local pos = a + dir * rng:NextNumber(0, len) + side * (rng:NextNumber() < 0.5 and -1 or 1) * (w / 2 - rng:NextNumber(0.5, 2))
					Kit.grass(junk, CFrame.new(pos.X, 0.2, pos.Z), {seed = ri * 1000 + i * 10 + k, scale = rng:NextNumber(0.7, 1.4)})
				end
				if rng:NextNumber() < 0.25 then
					local pos = a + dir * rng:NextNumber(0, len) + side * rng:NextNumber(-w / 3, w / 3)
					Kit.debris(junk, CFrame.new(pos.X, 0.2, pos.Z), {seed = ri * 31 + i})
				end
			end
		end
	end
	-- 건물 사이 빈 틈 → 쓰레기 쌓인 골목 / 철망 친 골목 -------------------------------
	-- 도로를 따라 인도 바로 뒤를 6 스터드 간격으로 훑어서, 건물이 없는 구간(폭 6~45)이 양옆에 건물을 끼고 있으면 "틈"
	local alleyF = Instance.new("Folder") alleyF.Name = "Alleys" alleyF.Parent = sf
	local CHAIN = Kit.TEX.chainlink
	local BINC = {Color3.fromRGB(40, 90, 170), Color3.fromRGB(190, 50, 40), Color3.fromRGB(40, 130, 70), Color3.fromRGB(60, 60, 64), Color3.fromRGB(150, 110, 60)}
	local nGapTrash, nGapFence = 0, 0
	local function bin(pos, rngx)
		local r = rngx:NextNumber(1.0, 1.6)
		local h = rngx:NextNumber(1.6, 2.6)
		local c = part(alleyF, "Bucket", Vector3.new(h, r * 2, r * 2), CFrame.new(pos + Vector3.new(0, 0.7 + h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), BINC[rngx:NextInteger(1, #BINC)], M.SmoothPlastic)
		c.Shape = Enum.PartType.Cylinder
	end
	local function box3(pos, rngx)
		local sz = Vector3.new(rngx:NextNumber(1.5, 3), rngx:NextNumber(1.2, 2.4), rngx:NextNumber(1.5, 3))
		part(alleyF, "Box", sz, CFrame.new(pos + Vector3.new(0, 0.7 + sz.Y / 2, 0)) * CFrame.Angles(0, rngx:NextNumber(0, 6.28), 0), Color3.fromRGB(150, 116, 76), M.Cardboard)
	end
	for ri, r in ipairs(L.roads) do
		if r.w >= 16 then
			local swW = sidewalkW(r.w)
			for i = 1, #r.pts - 1 do
				local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
				local b2 = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
				local len = (b2 - a).Magnitude
				if len > 30 and not inPark(a.X, a.Z, 20) and not inPark(b2.X, b2.Z, 20) then
					local dir = (b2 - a).Unit
					local side = Vector3.new(-dir.Z, 0, dir.X)
					for _, sgn in ipairs({-1, 1}) do
						local inward = side * sgn
						local step = 6
						local n = math.floor(len / step)
						local hits = {}
						for k = 0, n do
							local p = a + dir * (k * step) + inward * (r.w / 2 + swW + 8)
							hits[k] = not freeOfBuildings(CFrame.lookAt(p + Vector3.new(0, 6, 0), p + Vector3.new(0, 6, 0) + inward), Vector3.new(4, 8, 12))
						end
						local k = 1
						while k < n do
							if not hits[k] and hits[k - 1] then
								local k2 = k
								while k2 <= n and not hits[k2] do k2 += 1 end
								local gw = (k2 - k) * step
								if k2 <= n and gw >= 6 and gw <= 45 then
									local cAlong = (k + k2 - 1) / 2 * step
									local mouth = a + dir * cAlong + inward * (r.w / 2 + swW + 0.6)
									local deep = mouth + inward * 14
									-- 교차로(안쪽으로 다른 도로) 는 제외
									if not onRoad(CFrame.new(deep.X, 0, deep.Z), Vector3.new(4, 2, 10)) then
										local rr = Random.new(ri * 7919 + i * 31 + k)
										if rr:NextNumber() < 0.45 then
											-- 철망 + 기둥 (+ 가끔 휜 패널·문틈)
											local fcf = CFrame.lookAt(mouth + Vector3.new(0, 0.7, 0), mouth + Vector3.new(0, 0.7, 0) + dir)
											local fw = gw + 1
											local panel = part(alleyF, "ChainFence", Vector3.new(0.1, 8, fw), fcf * CFrame.new(0, 4, 0), Color3.fromRGB(160, 160, 158), M.Metal)
											panel.Transparency = 1
											if rr:NextNumber() < 0.3 then panel.CFrame *= CFrame.Angles(0, 0, math.rad(rr:NextNumber(-14, 14))) end
											for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
												local t = Instance.new("Texture") t.Texture = CHAIN t.Face = face t.StudsPerTileU, t.StudsPerTileV = 3, 3 t.Parent = panel
											end
											for q = 0, math.max(1, math.floor(fw / 8)) do
												local px = -fw / 2 + fw * q / math.max(1, math.floor(fw / 8))
												part(alleyF, "FencePost", Vector3.new(0.4, 8.6, 0.4), fcf * CFrame.new(0, 4.3, px), Color3.fromRGB(110, 110, 112), M.Metal)
											end
											part(alleyF, "FenceTop", Vector3.new(0.25, 0.25, fw), fcf * CFrame.new(0, 8.1, 0), Color3.fromRGB(110, 110, 112), M.Metal)
											-- 철조망 (위쪽 가시철사 느낌: 꼬인 선 2줄)
											for _, oy in ipairs({8.7, 9.2}) do
												local bw = part(alleyF, "Barbed", Vector3.new(0.12, 0.12, fw), fcf * CFrame.new(0, oy, 0) * CFrame.Angles(math.rad(rr:NextNumber(-3, 3)), 0, 0), Color3.fromRGB(70, 70, 70), M.Metal)
												bw.CanCollide = false
											end
											-- 철망 뒤에 쓰레기 조금
											for q = 1, rr:NextInteger(1, 3) do
												local tp = mouth + inward * rr:NextNumber(3, 10) + dir * rr:NextNumber(-gw / 3, gw / 3)
												put(alleyF, "TrashPile", CFrame.new(tp.X, 0.7, tp.Z) * CFrame.Angles(0, rr:NextNumber(0, 6.28), 0))
											end
											nGapFence += 1
										else
											-- 쓰레기 쌓인 골목: 대형 쓰레기통, 봉투 더미, 양동이·박스, 판자, 종이
											local depthMax = 18
											for q = 1, rr:NextInteger(4, 8) do
												local tp = mouth + inward * rr:NextNumber(1, depthMax) + dir * rr:NextNumber(-gw / 2 + 2, gw / 2 - 2)
												local kind = rr:NextNumber()
												if kind < 0.35 then put(alleyF, "TrashPile", CFrame.new(tp.X, 0.7, tp.Z) * CFrame.Angles(0, rr:NextNumber(0, 6.28), 0))
												elseif kind < 0.5 then put(alleyF, "Dumpster", CFrame.lookAt(Vector3.new(tp.X, 0.7, tp.Z), Vector3.new(tp.X, 0.7, tp.Z) - inward) * CFrame.Angles(0, rr:NextNumber(-0.3, 0.3), 0))
												elseif kind < 0.75 then bin(tp, rr)
												else box3(tp, rr) end
											end
											Kit.debris(alleyF, CFrame.new(mouth.X + inward.X * 6, 0.7, mouth.Z + inward.Z * 6), {seed = ri * 13 + k, count = rr:NextInteger(3, 6), spread = math.min(4, gw / 3)})
											for q = 1, 3 do
												local gp = mouth + inward * rr:NextNumber(0, depthMax) + dir * (rr:NextNumber() < 0.5 and -1 or 1) * (gw / 2 - 0.8)
												Kit.grass(alleyF, CFrame.new(gp.X, 0.7, gp.Z), {seed = ri * 101 + q + k, scale = rr:NextNumber(0.8, 1.4)})
											end
											nGapTrash += 1
										end
									end
								end
								k = k2
							else
								k += 1
							end
						end
					end
				end
			end
		end
	end
	-- 빈 골목 채우기: 골목·이면도로 양쪽 인도 안쪽(건물 쪽)에 잔해·쓰레기·식물·자전거 무더기 ----------------
	local fillF = Instance.new("Folder") fillF.Name = "AlleyFill" fillF.Parent = sf
	local nFill = {rubble = 0, trash = 0, plant = 0, bike = 0, road = 0}
	for ri, r in ipairs(L.roads) do
		if r.w >= 16 then
			local swW = sidewalkW(r.w)
			local alley = r.w <= 24
			local p = alley and 0.32 or 0.12
			for i = 1, #r.pts - 1 do
				local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
				local b2 = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
				local len = (b2 - a).Magnitude
				if len > 12 and not inPark(a.X, a.Z, 10) and not inPark(b2.X, b2.Z, 10) then
					local dir = (b2 - a).Unit
					local side = Vector3.new(-dir.Z, 0, dir.X)
					local rr = Random.new(ri * 104729 + i)
					local t = rr:NextNumber(3, 9)
					while t < len - 4 do
						for _, sgn in ipairs({-1, 1}) do
							if rr:NextNumber() < p then
								local inward = side * sgn
								local pos = a + dir * t + inward * (r.w / 2 + swW - 1.6)
								local cf = CFrame.lookAt(Vector3.new(pos.X, 0.7, pos.Z), Vector3.new(pos.X, 0.7, pos.Z) + dir)
								local hit = workspace:Raycast(Vector3.new(pos.X, 5, pos.Z), Vector3.new(0, -8, 0), rpWalk)
								if hit and hit.Instance.Name == "Walk" and freeOfBuildings(cf * CFrame.new(0, 3, 0), Vector3.new(3, 4, 5)) then
									local q = rr:NextNumber()
									local seed = ri * 1000 + i * 37 + math.floor(t)
									if q < 0.32 then Kit.rubbleMix(fillF, cf, {seed = seed, spread = 2.2}) nFill.rubble += 1
									elseif q < 0.58 then
										for k = 1, rr:NextInteger(1, 3) do
											local o = cf * CFrame.new(rr:NextNumber(-1.5, 1.5), 0, rr:NextNumber(-3, 3))
											local nm = ({"TrashPile", "TrashPile", "Dumpster", "ShoppingCart"})[rr:NextInteger(1, 4)]
											put(fillF, nm, o * CFrame.Angles(0, rr:NextNumber(0, 6.28), 0))
										end
										nFill.trash += 1
									elseif q < 0.86 then Kit.plantSpot(fillF, cf, {seed = seed}) nFill.plant += 1
									else Kit.bikeLoose(fillF, cf, {seed = seed}) nFill.bike += 1 end
								end
							end
						end
						t += rr:NextNumber(7, 11)
					end
					-- 골목 도로 위: 유리 조각·철판 몇 개
					if alley and rr:NextNumber() < 0.5 then
						local pos = a + dir * rr:NextNumber(0, len) + side * rr:NextNumber(-r.w / 3, r.w / 3)
						Kit.rubbleMix(fillF, CFrame.new(pos.X, 0.2, pos.Z), {seed = ri * 7 + i, spread = 1.6})
						nFill.road += 1
					end
				end
			end
		end
	end
	-- 강남역 사거리 연쇄 추돌 더미 (원점 근처, 아무 방향)
	for k = 1, 12 do
		local pos = Vector3.new(rng:NextNumber(-70, 90), 0, rng:NextNumber(-70, 90))
		local a = rng:NextNumber(0, math.pi * 2)
		wreck(pos, Vector3.new(math.cos(a), 0, math.sin(a)), 180)
	end
	-- 사거리: 뒤집혀 불탄 검은 SUV (버스는 색 때문에 뺌)
	local flip = put(cars, "RbxSUVBlack", CFrame.new(60, 0.2, 30) * CFrame.Angles(0, 0.6, 0))
	if flip then local _, fsz = flip:GetBoundingBox() flip:PivotTo(flip:GetPivot() * CFrame.new(0, fsz.Y, 0) * CFrame.Angles(0, 0, math.pi)) Kit.scorch(junk, CFrame.new(60, 0.2, 30), 8, 999) end
	Kit.smoke(sf, Vector3.new(60, 4, 30), {rate = 6, size = 24, fire = 8})
	-- 불타는 차 몇 곳
	for k = 1, 6 do
		local c = cars:GetChildren()[rng:NextInteger(1, #cars:GetChildren())]
		if c then Kit.smoke(sf, c:GetPivot().Position + Vector3.new(0, 3, 0), {rate = 4, size = 16, fire = rng:NextNumber() < 0.5 and 5 or nil}) end
	end
	return ("거리: 나무 %d, 가로등 %d, 쓰러짐 %d, 울타리 %d, 전봇대 %d, 폐차 %d, 틈 골목 쓰레기 %d / 철망 %d, 골목 채움 잔해 %d 쓰레기 %d 식물 %d 자전거 %d 도로잔해 %d"):format(nTree, nLamp, nFallen, nFence, nPole, nCar, nGapTrash, nGapFence, nFill.rubble, nFill.trash, nFill.plant, nFill.bike, nFill.road)
end



if phase == "furniture" then
	-- 골목 가로시설 (참고 사진 느낌): 맨홀·빗물받이·볼라드·방호벽·시멘트 블록·벽 부착물·바깥 철계단·카페 테라스·덩굴
	local sf = root:FindFirstChild("Streets1")
	local old = sf:FindFirstChild("Furniture") if old then old:Destroy() end
	local ff = Instance.new("Folder") ff.Name = "Furniture" ff.Parent = sf
	local blk = root:FindFirstChild("Block1")
	local g1 = root:FindFirstChild("Ground1")
	local pk = L.park
	local function inPark(x, z, pad) pad = pad or 0 return x > pk[1] - pad and x < pk[3] + pad and z > pk[2] - pad and z < pk[4] + pad end
	local opB = OverlapParams.new() opB.FilterType = Enum.RaycastFilterType.Include opB.FilterDescendantsInstances = {blk}
	local function free(cf, size) return #workspace:GetPartBoundsInBox(cf, size, opB) == 0 end
	local rpW = RaycastParams.new() rpW.FilterType = Enum.RaycastFilterType.Include rpW.FilterDescendantsInstances = {g1}
	local function walkAt(p) local h = workspace:Raycast(Vector3.new(p.X, 5, p.Z), Vector3.new(0, -8, 0), rpW) return h and h.Instance.Name == "Walk" end
	local rng = Random.new(6060)
	local cnt = {manhole = 0, drain = 0, bollard = 0, barrier = 0, blocks = 0, wall = 0, stair = 0, cafe = 0, vines = 0}
	-- 1) 도로: 맨홀·빗물받이·방호벽·시멘트 블록, 인도: 볼라드 줄
	for ri, r in ipairs(L.roads) do
		local w = r.w
		if w >= 16 then
			for i = 1, #r.pts - 1 do
				local a = Vector3.new(r.pts[i][1], 0, r.pts[i][2])
				local b2 = Vector3.new(r.pts[i + 1][1], 0, r.pts[i + 1][2])
				local len = (b2 - a).Magnitude
				if len > 20 and not inPark(a.X, a.Z, 20) and not inPark(b2.X, b2.Z, 20) then
					local dir = (b2 - a).Unit
					local side = Vector3.new(-dir.Z, 0, dir.X)
					local yaw = CFrame.lookAt(Vector3.zero, dir)
					local t = rng:NextNumber(10, 60)
					while t < len - 5 do
						local pos = a + dir * t
						local q = rng:NextNumber()
						if q < 0.35 then
							local mp = pos + side * rng:NextNumber(-w / 3, w / 3)
							Kit.manhole(ff, CFrame.new(mp.X, 0.22, mp.Z) * yaw, rng) cnt.manhole += 1
						elseif q < 0.6 then
							local sgn = rng:NextNumber() < 0.5 and -1 or 1
							local dp = pos + side * sgn * (w / 2 - 0.9)
							Kit.drainGrate(ff, CFrame.new(dp.X, 0.22, dp.Z) * yaw) cnt.drain += 1
						elseif q < 0.75 then
							-- 방호벽 1~3개 (길을 반쯤 막음) + 시멘트 블록
							local sgn = rng:NextNumber() < 0.5 and -1 or 1
							for k = 1, rng:NextInteger(1, 3) do
								local bp = pos + side * sgn * (w / 2 - 3 - (k - 1) * 4.5) + dir * rng:NextNumber(-1.5, 1.5)
								Kit.jersey(ff, CFrame.new(bp.X, 0.2, bp.Z) * CFrame.lookAt(Vector3.zero, side) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0), rng)
								cnt.barrier += 1
							end
							if rng:NextNumber() < 0.6 then
								local cp = pos + side * sgn * (w / 2 - 2) + dir * rng:NextNumber(3, 6)
								Kit.cinderBlocks(ff, CFrame.new(cp.X, 0.2, cp.Z), rng) cnt.blocks += 1
							end
						elseif q < 0.9 then
							-- 볼라드 줄 (인도 연석 쪽)
							local sgn = rng:NextNumber() < 0.5 and -1 or 1
							local n = rng:NextInteger(3, 5)
							for k = 1, n do
								local bp = pos + dir * ((k - (n + 1) / 2) * 3) + side * sgn * (w / 2 + 1.4)
								if walkAt(bp) and free(CFrame.new(bp.X, 2, bp.Z), Vector3.new(1, 3, 1)) and rng:NextNumber() > 0.12 then
									Kit.bollard(ff, CFrame.new(bp.X, 0.7, bp.Z), rng) cnt.bollard += 1
								end
							end
						else
							local sgn = rng:NextNumber() < 0.5 and -1 or 1
							local cp = pos + side * sgn * (w / 2 + rng:NextNumber(2, 5))
							if walkAt(cp) and free(CFrame.new(cp.X, 2, cp.Z), Vector3.new(4, 3, 4)) then Kit.cinderBlocks(ff, CFrame.new(cp.X, 0.7, cp.Z), rng) cnt.blocks += 1 end
						end
						t += rng:NextNumber(35, 80)
					end
				end
			end
		end
	end
	-- 2) 건물 벽: 계량기·우편함·소화기함·벽보·가스관, 덩굴, 바깥 철계단, 카페 테라스
	local function wallCF(m, side, along)
		local sz = m:GetAttribute("Kit22Size")
		if not sz then return nil end
		local W, D = sz.X, sz.Z
		local pv = m:GetPivot()
		if side == "front" then return pv * CFrame.new(along * W / 2, 0, -D / 2), W
		elseif side == "back" then return pv * CFrame.new(along * W / 2, 0, D / 2) * CFrame.Angles(0, math.pi, 0), W
		elseif side == "right" then return pv * CFrame.new(W / 2, 0, along * D / 2) * CFrame.Angles(0, -math.pi / 2, 0), D
		else return pv * CFrame.new(-W / 2, 0, along * D / 2) * CFrame.Angles(0, math.pi / 2, 0), D end
	end
	local rpB = RaycastParams.new() rpB.FilterType = Enum.RaycastFilterType.Include rpB.FilterDescendantsInstances = {blk}
	for _, m in ipairs(blk:GetChildren()) do
		local typ = m:GetAttribute("Kit22Type")
		if typ == "villa_kr" or typ == "shop_kr" or typ == "box_simple" then
			for _, side in ipairs({"left", "right", "back", "front"}) do
				local along = rng:NextNumber(-0.6, 0.6)
				local cf, span = wallCF(m, side, along)
				if cf then
					-- 벽 표면 찾기: 바깥 6 스터드에서 안쪽으로 레이
					local look = cf.LookVector
					local hit = workspace:Raycast(cf.Position + look * 6 + Vector3.new(0, 5, 0), -look * 8, rpB)
					if hit then
						local wcf = CFrame.lookAt(Vector3.new(hit.Position.X, cf.Position.Y, hit.Position.Z), Vector3.new(hit.Position.X, cf.Position.Y, hit.Position.Z) + look)
						local outside = wcf * CFrame.new(0, 3, -3)
						if free(outside, Vector3.new(4, 4, 3)) then
							if side ~= "front" or typ == "box_simple" then
								if rng:NextNumber() < 0.6 then Kit.wallStuff(ff, wcf, rng) cnt.wall += 1 end
							end
							if rng:NextNumber() < 0.35 then
								Kit.wallVines(ff, wcf * CFrame.new(rng:NextNumber(-span / 4, span / 4), 0, 0), rng:NextNumber(12, 26), rng:NextNumber(5, 9), rng)
								cnt.vines += 1
							end
							-- 빌라 옆벽 바깥 철계단 (2층까지)
							if typ == "villa_kr" and (side == "left" or side == "right") and rng:NextNumber() < 0.25 then
								local sc = wcf * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.pi / 2, 0)
								if free(sc * CFrame.new(0, 6, -6), Vector3.new(3, 10, 14)) then
									Kit.outdoorStair(ff, sc * CFrame.new(0, 0, 6), 10, rng) cnt.stair += 1
								end
							end
						end
					end
				end
			end
			-- 상가 앞 카페 테라스
			if typ == "shop_kr" and rng:NextNumber() < 0.3 then
				local cf = wallCF(m, "front", 0)
				local tc = cf * CFrame.new(rng:NextNumber(-4, 4), 0, -7)
				if walkAt(tc.Position) and free(tc * CFrame.new(0, 1.3, 0), Vector3.new(11, 1.8, 5)) then Kit.cafeTerrace(ff, tc, rng) cnt.cafe += 1 end
			end
		end
	end
	local parts = 0 for _, d in ipairs(ff:GetDescendants()) do if d:IsA("BasePart") then parts += 1 end end
	return ("가로시설: 맨홀 %d, 빗물받이 %d, 볼라드 %d, 방호벽 %d, 블록 %d, 벽 부착물 %d, 덩굴 %d, 철계단 %d, 카페 %d (파트 %d)"):format(
		cnt.manhole, cnt.drain, cnt.bollard, cnt.barrier, cnt.blocks, cnt.wall, cnt.vines, cnt.stair, cnt.cafe, parts)
end

if phase == "optimize" or phase == "optimize_streets" then
	-- 성능: 같은 모델 안의 "맨 파트"(자식 없음·불투명·MeshPart 아님)를 CSG 로 합침.
	--   구조(충돌 필요: 벽·기둥·바닥·지붕 등 큰 것) → 합친 1개, 정밀 충돌
	--   장식(작은 것·창틀·실외기·잔해 등) → 합친 1개, 충돌·조회·터치 끔
	-- 2층 이상 창 카드(데칼)는 합칠 수 없어서 충돌·그림자만 끔. 다시 짓기(buildings/streets)하면 원래대로 돌아감.
	local GS = game:GetService("GeometryService")
	local STRUCT = {Wall = true, Soffit = true, Pillar = true, ParkingFloor = true, RoofSlab = true, Parapet = true, StairHut = true, Gable = true, RoofPlane = true,
		Slab = true, Column = true, Deck = true, Ramp = true, Tower = true, BellTower = true, StairTower = true, GroundSlab = true, Dock = true, Stoop = true, Step = true, BaySide = true, OrielSide = true}
	local function plain(p)
		return p:IsA("BasePart") and not p:IsA("MeshPart") and not p:IsA("UnionOperation") and #p:GetChildren() == 0 and p.Transparency < 0.05
			and (not p:IsA("Part") or p.Shape ~= Enum.PartType.Ball)
	end
	local function merge(list, parent, name, collide)
		if #list < 2 then return 0 end
		local ok, res = pcall(function()
			return GS:UnionAsync(list[1], {table.unpack(list, 2)}, {SplitApart = false,
				CollisionFidelity = collide and Enum.CollisionFidelity.PreciseConvexDecomposition or Enum.CollisionFidelity.Box})
		end)
		if not ok or not res[1] then return -1 end
		local u = res[1]
		u.Name = name
		u.Anchored = true
		u.UsePartColor = false
		if not collide then u.CanCollide, u.CanQuery, u.CanTouch = false, false, false end
		u.Parent = parent
		for _, p in ipairs(list) do p:Destroy() end
		return #list - 1
	end
	local saved, failed, n = 0, 0, 0
	if phase == "optimize" then
		local blk = root:FindFirstChild("Block1")
		local models = blk:GetChildren()
		from = from or 1
		to = math.min(to or #models, #models)
		for i = from, to do
			local m = models[i]
			if m:IsA("Model") and not m:GetAttribute("Optimized") then
				local base = m:GetPivot().Position.Y
				local A, B = {}, {}
				for _, p in ipairs(m:GetDescendants()) do
					-- 소품(복제된 Model: 차·나무·자전거 등)은 건드리지 않음
					local owner = p:FindFirstAncestorWhichIsA("Model")
					if owner == m and plain(p) then
						local big = math.max(p.Size.X, p.Size.Y, p.Size.Z) >= 6
						if p.CanCollide and (STRUCT[p.Name] or big) then table.insert(A, p) else table.insert(B, p) end
					elseif owner == m and p:IsA("BasePart") and p.Parent and p.Parent.Name == "Openings" and p.Position.Y - base > 9 then
						p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
					end
				end
				for _, pair in ipairs({{A, "MergedStructure", true}, {B, "MergedDetail", false}}) do
					local r = merge(pair[1], m, pair[2], pair[3])
					if r < 0 then failed += 1 else saved += r end
				end
				m:SetAttribute("Optimized", true)
				n += 1
			end
		end
		return ("최적화 건물 %d~%d: %d채, 파트 %d 개 줄임, 실패 %d"):format(from, to, n, saved, failed)
	else
		-- 거리: 잔해·식물·거치대·잔해 더미 모델, 나무(가지·화단), 틈 골목은 모델 단위 / 폴더 직속 파트는 근처끼리 묶음
		local sf = root:FindFirstChild("Streets1")
		local pf = root:FindFirstChild("Park1")
		for _, holder in ipairs({sf, pf}) do
			for _, m in ipairs(holder:GetDescendants()) do
				if m:IsA("Model") and not m:GetAttribute("Optimized") and (m.Name == "RubbleMix" or m.Name == "Plants" or m.Name == "BikeRack" or m.Name == "Debris22" or m.Name == "Tree22" or m.Name == "Bush22"
					or m.Name == "Manhole" or m.Name == "Drain" or m.Name == "Bollard" or m.Name == "Barrier" or m.Name == "CinderBlocks" or m.Name == "WallStuff"
					or m.Name == "OutdoorStair" or m.Name == "CafeTerrace") then
					local L = {}
					for _, p in ipairs(m:GetChildren()) do if plain(p) then table.insert(L, p) end end
					local solid = m.Name == "Tree22" or m.Name == "Barrier" or m.Name == "Bollard" or m.Name == "OutdoorStair" or m.Name == "CinderBlocks"
					local r = merge(L, m, "Merged", solid)
					if r < 0 then failed += 1 else saved += r end
					m:SetAttribute("Optimized", true)
					n += 1
				end
			end
		end
		-- 폴더 직속 작은 파트(울타리·전봇대 부품·연석·골목 잡동사니): 40 스터드 칸마다 묶음
		for _, fname in ipairs({"Fences", "Poles", "Alleys", "Debris", "AlleyFill", "Wrecks"}) do
			local f = sf:FindFirstChild(fname)
			if f then
				local cells = {}
				for _, p in ipairs(f:GetChildren()) do
					if plain(p) then
						local k = math.floor(p.Position.X / 40) .. "," .. math.floor(p.Position.Z / 40) .. "," .. tostring(p.CanCollide)
						cells[k] = cells[k] or {}
						table.insert(cells[k], p)
					end
				end
				for k, L in pairs(cells) do
					local collide = k:sub(-4) == "true"
					local r = merge(L, f, "Merged" .. fname, collide)
					if r < 0 then failed += 1 else saved += r end
				end
			end
		end
		return ("최적화 거리: 모델 %d, 파트 %d 개 줄임, 실패 %d"):format(n, saved, failed)
	end
end

if phase == "buildings" then
	local blk = root:FindFirstChild("Block1")
	if not blk then
		blk = Instance.new("Folder")
		blk.Name = "Block1"
		blk.Parent = root
	end
	from = from or 1
	to = math.min(to or #L.buildings, #L.buildings)
	if from == 1 then blk:ClearAllChildren() end
	local CAP = {villa_kr = 5, shop_kr = 7, office_mid = 12, office_glass = 30, apt_modern = 15}
	local made, parts, failed = 0, 0, {}
	for i = from, to do
		local e = L.buildings[i]
		local typ = e.type
		local params = {seed = e.id % 1000003, w = e.w, d = e.d, decay = 0.6}
		if e.tier == 3 then
			params.office = (typ == "office_glass" or typ == "office_mid")
			params.floors = math.clamp(e.floors, 2, 30)
			typ = "box_simple"
		else
			params.floors = math.clamp(e.floors, 2, CAP[typ] or 8)
		end
		local okb, m, n = pcall(Kit.build, typ, blk, CFrame.new(), params)
		if okb then
			local c = Vector3.new(e.cx, 0.7, e.cz) -- 인도 판(0.7) 위에
			m:PivotTo(CFrame.lookAt(c, c + Vector3.new(e.nx, 0, e.nz)))
			m.Name = ("%s_%d"):format(typ, e.id)
			m:SetAttribute("OsmId", e.id)
			if e.name ~= "" then m:SetAttribute("OsmName", e.name) end
			if e.tier == 1 then Kit.weather(m, {level = 0.8, seed = e.id % 9973, groundY = 0.7, burn = 0.2}) end
			made += 1
			parts += n
		else
			table.insert(failed, ("%d %s: %s"):format(e.id, typ, tostring(m)))
		end
	end
	Kit.applyLighting("dark")
	return ("건물 %d~%d: 지음 %d, 파트 약 %d, 실패 %d\n%s"):format(from, to, made, parts, #failed, table.concat(failed, "\n", 1, math.min(#failed, 8)))
end
return "phase 를 'ground' 또는 'buildings' 로"
