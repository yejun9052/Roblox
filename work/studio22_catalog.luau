-- 22번 키트 카탈로그: 31종을 격자로 한 채씩 지어 검사. Workspace.KitLab_22.Catalog (맵 서쪽 X -1150..-500). 재생성형.
-- 각 칸 120×120, 건물 정면은 -Z (칸 앞쪽 도로 쪽). 결과: 종류별 파트 수 / 오류.
local HS = game:GetService("HttpService")
local was = HS.HttpEnabled
HS.HttpEnabled = true
local ok, src = pcall(function() return HS:GetAsync("http://127.0.0.1:34999/kit.luau", true) end)
HS.HttpEnabled = was
assert(ok, src)
local Kit = assert(loadstring(src, "kit"))()
local lab = workspace:FindFirstChild("KitLab_22")
local old = lab:FindFirstChild("Catalog")
if old then old:Destroy() end
local cat = Instance.new("Folder")
cat.Name = "Catalog"
cat.Parent = lab
local X0, Z0, CELL, COLS = -1100, 40, 120, 6
local g = Instance.new("Part")
g.Name, g.Anchored, g.Size = "CatalogGround", true, Vector3.new(CELL * COLS + 40, 1, CELL * 6 + 40)
g.CFrame = CFrame.new(X0 + CELL * (COLS - 1) / 2, -0.5, Z0 + CELL * 2.5)
g.Material, g.Color = Enum.Material.Pavement, Color3.fromRGB(150, 146, 140)
g.Parent = cat
local seeds = ...
local report = {}
local total = 0
for i, t in ipairs(Kit.TYPE_LIST) do
	local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
	local cx, cz = X0 + col * CELL, Z0 + row * CELL
	local okb, m, n, info = pcall(Kit.build, t, cat, CFrame.new(), {seed = 100 + i, decay = 0.35})
	if okb then
		m:PivotTo(CFrame.new(cx, 0, cz))
		m.Name = ("%02d_%s"):format(i, t)
		total += n
		table.insert(report, ("%02d %-18s %3.0fx%3.0fx%3.0f parts=%d"):format(i, t, info.W, info.H, info.D, n))
	else
		table.insert(report, ("%02d %-18s ERROR %s"):format(i, t, tostring(m)))
	end
end
table.insert(report, "total parts " .. total)
return table.concat(report, "\n")
