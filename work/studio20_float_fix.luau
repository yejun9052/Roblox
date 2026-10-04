-- 20번 배치 수정: 떠 있는 덩어리(studio20_float_audit.luau 와 같은 판정, 월드 AABB 보정)를 이름 규칙으로 고침.
--   DROP: 아래 바닥까지 내림 (0.05 < 거리 < 15, 받는 면 법선 Y > 0.7)
--   SNAP: 가장 가까운 벽/천장 면까지 수평 또는 위로 이동 (0.03 < 거리 < 1.2)
-- 이동 후 다른 파트와 겹치면(이동 전부터 닿던 것 제외) 건너뜀. 옮긴 파트 CFrameBefore20 속성. DRY=true 면 계획만.
local DRY = true -- 2026-10-03 DRY=false 로 1회 적용
local DROP = {"^Waste bin", "^Service barrel", "^Collapsed rubble", "^Loot supply package", "^Stored barricade plank", "^Supply crate"}
local SNAP = {"warm door light", "bulkhead", "_Silhouette_%d+_frame$", "^Ceiling luminaire"}

local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return p.Position, Vector3.new(
		math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
		math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z)
end
local function matchAny(name, pats)
	for _, p in ipairs(pats) do if name:find(p) then return true end end
	return false
end

-- 떠 있는 덩어리 찾기
local parts, idx = {}, {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsA("Terrain") and d.Transparency < 1 then table.insert(parts, d) idx[d] = #parts end
end
local N = #parts
local par = table.create(N, 0)
for i = 1, N do par[i] = i end
local function find(i) while par[i] ~= i do par[i] = par[par[i]] i = par[i] end return i end
local anchored = table.create(N, false)
for i, p in ipairs(parts) do
	local c, h = aabb(p)
	if math.max(p.Size.X, p.Size.Y, p.Size.Z) >= 12 or (c.Y - h.Y) <= 0.6 then anchored[i] = true end
end
local op = OverlapParams.new() op.RespectCanCollide = false op.FilterType = Enum.RaycastFilterType.Exclude
for i, p in ipairs(parts) do
	if not anchored[i] then
		op.FilterDescendantsInstances = {p}
		for _, q in ipairs(workspace:GetPartBoundsInBox(p.CFrame, p.Size + Vector3.new(0.1, 0.1, 0.1), op)) do
			local j = idx[q]
			if j then if anchored[j] then anchored[i] = true else local a, b = find(i), find(j) if a ~= b then par[a] = b end end end
		end
	end
end
local ca = {}
for i = 1, N do if anchored[i] then ca[find(i)] = true end end
local groups = {}
for i = 1, N do local r = find(i) if not ca[r] then groups[r] = groups[r] or {} table.insert(groups[r], parts[i]) end end

local function overlapOK(g, move)
	local opD = OverlapParams.new() opD.FilterType = Enum.RaycastFilterType.Exclude opD.FilterDescendantsInstances = g
	local pre = {}
	for _, p in ipairs(g) do for _, q in ipairs(workspace:GetPartsInPart(p, opD)) do pre[q] = true end end
	-- 0.01 만큼 덜 움직인 자리에서 검사 (닿기만 하는 받침면은 겹침으로 안 셈)
	local m = move.Magnitude > 0.02 and move - move.Unit * 0.01 or move
	for _, p in ipairs(g) do
		local cf0 = p.CFrame
		p.CFrame = cf0 + m
		local hit
		for _, q in ipairs(workspace:GetPartsInPart(p, opD)) do if not pre[q] then hit = q.Name break end end
		p.CFrame = cf0
		if hit then return false, hit end
	end
	return true
end

local log, stats = {}, {drop = 0, snap = 0, skip = 0, parts = 0}
for _, g in pairs(groups) do
	local name = g[1].Name
	local mode = matchAny(name, DROP) and "drop" or (matchAny(name, SNAP) and "snap") or nil
	local already = false
	for _, p in ipairs(g) do if p:GetAttribute("CFrameBefore20") then already = true end end
	if mode and not already then
		local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
		for _, p in ipairs(g) do local c, h = aabb(p) mn = mn:Min(c - h) mx = mx:Max(c + h) end
		local c, half = (mn + mx) / 2, (mx - mn) / 2
		local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = g
		local move, why = nil, "조건 밖"
		if mode == "drop" then
			local best = nil
			for _, o in ipairs({Vector3.new(0, 0, 0), Vector3.new(half.X * 0.8, 0, half.Z * 0.8), Vector3.new(-half.X * 0.8, 0, half.Z * 0.8), Vector3.new(half.X * 0.8, 0, -half.Z * 0.8), Vector3.new(-half.X * 0.8, 0, -half.Z * 0.8)}) do
				local h = workspace:Raycast(Vector3.new(c.X + o.X, mn.Y + 0.01, c.Z + o.Z), Vector3.new(0, -20, 0), rp)
				if h and h.Normal.Y > 0.7 then local d = mn.Y - h.Position.Y if not best or d < best then best = d end end
			end
			if best and best > 0.05 and best < 15 then move = Vector3.new(0, -best, 0) end
		else
			local best, bdir = nil, nil
			for _, dir in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis, Vector3.yAxis}) do
				local hl = math.abs(dir:Dot(half))
				local h = workspace:Raycast(c, dir * (hl + 2), rp)
				if h then local d = (h.Position - c):Dot(dir) - hl if d > 0.03 and d < 1.2 and (not best or d < best) then best, bdir = d, dir end end
			end
			if best then move = bdir * best end
		end
		if move then
			local ok, clash = overlapOK(g, move)
			if not ok then move, why = nil, "겹침 " .. clash end
		end
		if move then
			stats[mode] += 1
			stats.parts += #g
			if #log < 40 then table.insert(log, ("%s %s @(%.0f,%.0f,%.0f) %.2f"):format(mode, name:sub(1, 40), c.X, c.Y, c.Z, move.Magnitude)) end
			if not DRY then
				for _, p in ipairs(g) do p:SetAttribute("CFrameBefore20", p.CFrame) p.CFrame = p.CFrame + move end
			end
		else
			stats.skip += 1
			if #log < 60 then table.insert(log, ("skip %s %s: %s"):format(mode, name:sub(1, 40), why)) end
		end
	end
end
return ("%s drop=%d snap=%d skip=%d parts=%d (떠 있는 덩어리 전체 %d)\n"):format(DRY and "[계획]" or "[적용]", stats.drop, stats.snap, stats.skip, stats.parts, (function() local n = 0 for _ in pairs(groups) do n += 1 end return n end)()) .. table.concat(log, "\n")
