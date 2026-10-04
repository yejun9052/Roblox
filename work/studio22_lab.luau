-- 22번 키트 시험 거리: Workspace.KitLab_22.Street (맵 서쪽 X≈-400 빈 땅). 재생성형 — Street 만 지우고 다시 만든다(맵 원본·카탈로그는 건드리지 않음).
-- 키트 소스는 로컬 수신기(127.0.0.1:34999/kit.luau)에서 받아 loadstring. HttpEnabled 는 받는 동안만 켬.
local HS = game:GetService("HttpService")
local was = HS.HttpEnabled
HS.HttpEnabled = true
local ok, src = pcall(function() return HS:GetAsync("http://127.0.0.1:34999/kit.luau", true) end)
HS.HttpEnabled = was
assert(ok, src)
local Kit = assert(loadstring(src, "kit"))()

local root = workspace:FindFirstChild("KitLab_22") or Instance.new("Folder")
root.Name = "KitLab_22"
root.Parent = workspace
-- 거리 시험장만 다시 만듦 (Catalog / PropShow 는 그대로)
for _, c in ipairs(root:GetChildren()) do
	if c.Name ~= "Catalog" and c.Name ~= "PropShow" then c:Destroy() end
end
local lab = Instance.new("Folder")
lab.Name = "Street"
lab.Parent = root
local M = Enum.Material
local function part(name, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material, p.Anchored = name, size, cf, color, mat, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = lab
	return p
end
-- 거리: X 방향 도로(폭 24), 양쪽 보도(폭 10)
local CX, CZ, LEN = -400, 300, 260
part("Ground", Vector3.new(LEN + 80, 1, 200), CFrame.new(CX, -0.5, CZ), Color3.fromRGB(110, 108, 104), M.Pavement)
part("Road", Vector3.new(LEN + 80, 0.2, 24), CFrame.new(CX, 0.1, CZ), Color3.fromRGB(58, 58, 62), M.Asphalt)
for _, s in ipairs({-1, 1}) do
	part("Sidewalk", Vector3.new(LEN + 80, 0.6, 10), CFrame.new(CX, 0.3, CZ + s * 17), Color3.fromRGB(186, 180, 170), M.Pavement)
	part("Curb", Vector3.new(LEN + 80, 0.7, 0.6), CFrame.new(CX, 0.35, CZ + s * 12.3), Color3.fromRGB(200, 196, 188), M.Concrete)
end
for i = -5, 5 do
	part("Crosswalk", Vector3.new(1.6, 0.05, 20), CFrame.new(CX + 60 + i * 3, 0.22, CZ), Color3.fromRGB(236, 234, 228), M.SmoothPlastic)
end

-- APOC = true: 아포칼립스 버전 (풍화·마른 나무·균열·잡초·잔해·폐차 많이·먼지 하늘). LOOK = "ash"(먼지) / "dark"(더 어둡게, 그을음·불탄 흔적)
local APOC = true
local LOOK = "dark"
local plan = ...
plan = plan or {
	{"apt_balcony", 11, {}}, {"corner_shop", 12, {}}, {"walkup_narrow", 13, {}}, {"townhouse", 14, {}}, {"apt_bay", 15, {}}, {"cafe_terrace", 16, {}}, {"rowhouse_gable", 17, {}},
}
local plan2 = {
	{"brick_tenement", 21, {}}, {"rowhouse_gable", 22, {}}, {"hotel", 23, {floors = 8}}, {"shop_row", 24, {shops = 3}}, {"ruin", 25, {base = "apt_balcony"}}, {"walkup_narrow", 26, {}},
}
local report = {}
local function row(list, side)
	local x = CX - LEN / 2
	for _, e in ipairs(list) do
		local params = e[3]
		params.seed = e[2]
		-- 크기 먼저 알아야 하므로 원점에 짓고 옮김
		local m, n, info = Kit.build(e[1], lab, CFrame.new(), params)
		local W, D = info.W, info.D
		local zFront = CZ + side * 22 -- 건물 정면 위치
		local cf
		-- 키트 정면 = -Z. 북쪽 줄(side=1)은 그대로 두면 도로(-Z)를 봄, 남쪽 줄은 180° 돌림
		if side == 1 then
			cf = CFrame.new(x + W / 2, 0.6, zFront + D / 2)
		else
			cf = CFrame.new(x + W / 2, 0.6, zFront - D / 2) * CFrame.Angles(0, math.pi, 0)
		end
		m:PivotTo(cf)
		if APOC then Kit.weather(m, {level = e[1] == "ruin" and 1 or 0.9, seed = e[2], groundY = 0.6, burn = LOOK == "dark" and 0.25 or 0, fade = LOOK == "dark" and 0.08 or 0}) end
		table.insert(report, ("%s seed=%d %s %.0fx%.0fx%.0f parts=%d"):format(e[1], e[2], m:GetAttribute("Kit22Palette"), W, info.H, D, n))
		x += W + 0.5
	end
end
row(plan, 1)
row(plan2, -1)
-- 거리 소품 (AI 메시 템플릿 + 키트 자연물)
local lib = game:GetService("ServerStorage"):FindFirstChild("Kit22_Props")
local R = Random.new(2222)
local function put(name, cf)
	local t = lib and lib:FindFirstChild(name)
	if not t then return end
	local c = t:Clone()
	c:PivotTo(cf)
	c.Parent = lab
	return c
end
local Y = 0.6 -- 보도 윗면
for i = 0, 8 do
	for _, s in ipairs({-1, 1}) do
		local x = CX - LEN / 2 + 10 + i * 30
		if i % 2 == 0 then
			local r = R:NextNumber()
			local state = (not APOC) and nil or (r < (LOOK == "dark" and 0.3 or 0.45) and nil or (r < 0.7 and "dry" or "dead"))
			Kit.tree(lab, CFrame.new(x, Y, CZ + s * 14), {seed = i * 10 + (s > 0 and 1 or 2), leaves = state})
		else
			local lamp = put("StreetLamp", CFrame.new(x, Y, CZ + s * 14) * CFrame.Angles(0, R:NextNumber(0, 6.28), 0))
			if APOC and lamp and R:NextNumber() < 0.4 then -- 기운 가로등
				lamp:PivotTo(lamp:GetPivot() * CFrame.Angles(math.rad(R:NextNumber(-14, 14)), 0, math.rad(R:NextNumber(-14, 14))))
			end
		end
		if R:NextNumber() < 0.3 then put("Bench", CFrame.new(x + 7, Y, CZ + s * 14.5) * CFrame.Angles(0, s > 0 and 0 or math.pi, 0)) end
		if R:NextNumber() < 0.25 then put("Hydrant", CFrame.new(x + 12, Y, CZ + s * 13.4)) end
		if R:NextNumber() < 0.5 then put(R:NextNumber() < 0.6 and "TrashPile" or "Dumpster", CFrame.new(x + R:NextNumber(-8, 8), Y, CZ + s * 20) * CFrame.Angles(0, R:NextNumber(0, 6.28), 0)) end
	end
end
if APOC then
	-- 풀숲: 연석·건물 밑·도로 균열 따라
	for i = 1, 70 do
		local s = R:NextNumber() < 0.5 and -1 or 1
		local band = R:NextNumber()
		local z = band < 0.45 and CZ + s * R:NextNumber(12.4, 13.2) or (band < 0.8 and CZ + s * R:NextNumber(20, 21.5) or CZ + R:NextNumber(-11, 11))
		local y = math.abs(z - CZ) < 12 and 0.2 or Y
		Kit.grass(lab, CFrame.new(CX - LEN / 2 + R:NextNumber(0, LEN), y, z), {seed = i, scale = R:NextNumber(0.7, 1.6)})
	end
	for i = 1, 10 do
		local s = R:NextNumber() < 0.5 and -1 or 1
		Kit.bush(lab, CFrame.new(CX - LEN / 2 + R:NextNumber(0, LEN), Y, CZ + s * R:NextNumber(19.5, 21)), {seed = i})
	end
	-- 균열: 도로와 보도
	for i = 1, 40 do
		local z = CZ + R:NextNumber(-11, 11)
		Kit.crack(lab, CFrame.new(CX - LEN / 2 + R:NextNumber(0, LEN), 0.2, z), R:NextNumber(6, 14), i)
	end
	for i = 1, 16 do
		local s = R:NextNumber() < 0.5 and -1 or 1
		Kit.crack(lab, CFrame.new(CX - LEN / 2 + R:NextNumber(0, LEN), Y, CZ + s * R:NextNumber(14, 21)), R:NextNumber(4, 8), 100 + i)
	end
	-- 잔해·쓰레기 더미
	for i = 1, 14 do
		local s = R:NextNumber() < 0.5 and -1 or 1
		local onRoad = R:NextNumber() < 0.4
		Kit.debris(lab, CFrame.new(CX - LEN / 2 + R:NextNumber(0, LEN), onRoad and 0.2 or Y, onRoad and CZ + R:NextNumber(-10, 10) or CZ + s * R:NextNumber(15, 21)), {seed = i})
	end
end
-- 폐차: 차선 위에 불규칙 (아포칼립스면 더 많이, 일부 뒤집힘)
local nCars = APOC and 13 or 7
for i = 1, nCars do
	local x = CX - LEN / 2 + R:NextNumber(10, LEN - 10)
	local lane = R:NextNumber() < 0.5 and -5 or 5
	local yaw = (lane > 0 and math.pi / 2 or -math.pi / 2) + math.rad(R:NextNumber(-35, 35))
	local name = ({"WreckCar_A", "WreckTruck", "WreckVan", "WreckJeep"})[R:NextInteger(1, 4)]
	local car = put(name, CFrame.new(x, 0.2, CZ + lane + R:NextNumber(-2, 2)) * CFrame.Angles(0, yaw, 0))
	if APOC and LOOK == "dark" and car and R:NextNumber() < 0.35 then
		Kit.scorch(lab, CFrame.new(car:GetPivot().Position.X, 0.2, car:GetPivot().Position.Z), R:NextNumber(5, 7), i) -- 불탄 차 밑 그을음
	end
	if APOC and car and R:NextNumber() < 0.2 then
		local _, sz = car:GetBoundingBox()
		car:PivotTo(car:GetPivot() * CFrame.new(0, sz.Y, 0) * CFrame.Angles(0, 0, math.pi)) -- 뒤집힘
	elseif APOC and car and R:NextNumber() < 0.25 then
		car:PivotTo(car:GetPivot() * CFrame.Angles(math.rad(R:NextNumber(-4, 4)), 0, math.rad(R:NextNumber(4, 9)))) -- 바퀴 빠져 기움
	end
end
put("BusStop", CFrame.new(CX + 40, Y, CZ - 15.5) * CFrame.Angles(0, math.pi, 0))
if APOC and LOOK == "dark" then
	-- 연기: 폐허 꼭대기 + 거리 끝 (Play 에서만 보임), 불붙은 잔해 1곳
	Kit.smoke(lab, Vector3.new(CX + 60, 40, CZ - 40), {rate = 8, size = 26})
	Kit.smoke(lab, Vector3.new(CX - LEN / 2 - 20, 6, CZ + 4), {rate = 5, size = 20})
	Kit.smoke(lab, Vector3.new(CX - 30, 1, CZ + 7), {rate = 3, size = 10, fire = 6})
	Kit.scorch(lab, CFrame.new(CX - 30, 0.2, CZ + 7), 6, 77)
end
Kit.applyLighting(APOC and LOOK or "dusk")
return table.concat(report, "\n")
