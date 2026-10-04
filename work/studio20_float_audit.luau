-- 20번 배치 검사 (읽기 전용): 떠 있는 파트 덩어리 찾기.
-- 앵커: 최대 변 ≥ 12 스터드(구조물) 또는 바닥면 y ≤ 0.6 (지면). 투명도 1 파트·Terrain 제외.
-- 앵커가 아닌 파트끼리 0.1 스터드 부풀린 상자로 맞닿음(GetPartBoundsInBox) → 같은 덩어리.
-- 덩어리 중 앵커에 하나도 닿지 않은 것 = 떠 있음. 결과는 로컬 수신기로 float_<TAG>.json 전송 (HttpEnabled 는 전송 동안만).
local TAG = "audit"
local HS = game:GetService("HttpService")
local parts, idx = {}, {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") and d.Transparency < 1 then table.insert(parts, d) idx[d] = #parts end
end
local N = #parts
local parent = table.create(N, 0)
for i = 1, N do parent[i] = i end
local function find(i) while parent[i] ~= i do parent[i] = parent[parent[i]] i = parent[i] end return i end
local function union(a, b) a, b = find(a), find(b) if a ~= b then parent[a] = b end end
local anchored = table.create(N, false)
for i, p in ipairs(parts) do
	local e = p.ExtentsSize
	if math.max(e.X, e.Y, e.Z) >= 12 or (p.Position.Y - e.Y / 2) <= 0.6 then anchored[i] = true end
end
local op = OverlapParams.new() op.RespectCanCollide = false op.FilterType = Enum.RaycastFilterType.Exclude
for i, p in ipairs(parts) do
	if not anchored[i] then
		op.FilterDescendantsInstances = {p}
		for _, q in ipairs(workspace:GetPartBoundsInBox(p.CFrame, p.Size + Vector3.new(0.1, 0.1, 0.1), op)) do
			local j = idx[q]
			if j then if anchored[j] then anchored[i] = true else union(i, j) end end
		end
	end
end
local clusterAnch = {}
for i = 1, N do if anchored[i] then clusterAnch[find(i)] = true end end
local groups = {}
for i = 1, N do
	local r = find(i)
	if not clusterAnch[r] then groups[r] = groups[r] or {} table.insert(groups[r], parts[i]) end
end
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude
local out = {}
for _, g in pairs(groups) do
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	local items = {}
	for _, p in ipairs(g) do
		local h = p.ExtentsSize / 2
		mn = mn:Min(p.Position - h) mx = mx:Max(p.Position + h)
		table.insert(items, {path = p:GetFullName(), name = p.Name, cls = p.ClassName, coll = p.CanCollide})
	end
	rp.FilterDescendantsInstances = g
	local c = (mn + mx) / 2
	local below = workspace:Raycast(Vector3.new(c.X, mn.Y + 0.01, c.Z), Vector3.new(0, -200, 0), rp)
	-- 가장 가까운 수평 방향 표면 (벽에 붙어야 할 물건 판별용)
	local side, sideName = 1e9, "-"
	for _, dir in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis, Vector3.yAxis}) do
		local h = workspace:Raycast(c, dir * 20, rp)
		if h then
			local half = math.abs(dir:Dot((mx - mn) / 2))
			local dd = (h.Position - c).Magnitude - half
			if dd < side then side, sideName = dd, h.Instance.Name end
		end
	end
	table.insert(out, {n = #g, c = {c.X, c.Y, c.Z}, s = {mx.X - mn.X, mx.Y - mn.Y, mx.Z - mn.Z},
		gap = below and (mn.Y - below.Position.Y) or -1, below = below and below.Instance.Name or "-",
		side = side, sideName = sideName, items = items})
end
local before = HS.HttpEnabled
HS.HttpEnabled = true
local ok, err = pcall(function()
	HS:RequestAsync({Url = "http://127.0.0.1:34999/float_" .. TAG .. ".json", Method = "POST", Body = HS:JSONEncode(out)})
end)
HS.HttpEnabled = before
assert(ok, tostring(err))
return ("clusters=%d visible=%d HttpEnabled=%s"):format(#out, N, tostring(HS.HttpEnabled))
