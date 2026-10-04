-- 20번 배치 수정 2차 (studio20_furniture_to_wall.luau 이후): 1차에서 남은 가구를 90° 회전 후 벽에 붙임.
-- 1차와 같은 조건. 회전 축 = 가구 묶음 AABB 중심(수직). 옮긴 파트 CFrameBefore20.
-- 원래 설명: 진입 가능 건물(Active/Bxx/Bxx_yy_Enterable) 1층의 선반·소파·책상을 가장 가까운 벽에 붙임.
-- 가구 = 서로 맞닿은 비구조 파트 덩어리 (선반 위 물건, 책상 위 기기, 라벨 등 함께 이동). 종류는 덩어리 안 이름으로 판정.
-- 이동: 짧은 축 방향 평행이동만(회전 없음), 벽과 0.05 간격. 소파는 등받이(Couch back) 쪽 벽으로만.
-- 조건: 뒷면 6개 레이가 모두 벽(문 제외)에 닿음, 이동 후 다른 파트와 겹침 없음(처음부터 닿아 있던 바닥류 제외), 문에서 2 스터드 이상.
-- 옮긴 파트에 CFrameBefore20 속성. DRY=true 면 계획만 반환. 재실행 방지: 덩어리에 CFrameBefore20 이 있으면 건너뜀.
local DRY = true -- 2026-10-03 DRY=false 로 1회 적용 (책상 9건)
local FLOOR_Y = 1.0
local GAP = 0.05

local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return p.Position, Vector3.new(
		math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z,
		math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z)
end
local STRUCT = {"wall", "partition", "pillar", "column", "pier", "jamb", "door", "threshold", "lintel", "window", "glaz", "glass",
	"sill", "mullion", "floor", "ceiling", "roof", "slab", "ground", "stair", "tread", "step", "ramp", "beam", "band", "frame", "skirting", "trim"}
local function isStruct(p)
	local n = p.Name:lower()
	for _, k in ipairs(STRUCT) do if n:find(k, 1, true) then return true end end
	local _, h = aabb(p)
	return math.max(h.X, h.Z) * 2 >= 12 or h.Y * 2 >= 8
end
local function isDoor(p) local n = p.Name:lower() return n:find("door", 1, true) ~= nil end

local plans, skipped = {}, {}
local moved = 0
for _, f in ipairs(workspace.SurterDays:GetChildren()) do
	if f.Name:match("^Active/B%d+/B%d+_%d+_Enterable$") then
		-- 건물 범위
		local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("BasePart") then local c, h = aabb(d) if c.Y + h.Y > 0 then mn = mn:Min(c - h) mx = mx:Max(c + h) end end
		end
		-- 1층 비구조 파트
		local cand, idx = {}, {}
		for _, d in ipairs(workspace:GetPartBoundsInBox(CFrame.new((mn + mx) / 2), mx - mn)) do
			if d.Transparency < 1 and not isStruct(d) then
				local c, h = aabb(d)
				if c.Y - h.Y > FLOOR_Y - 0.3 and c.Y + h.Y < FLOOR_Y + 9 then table.insert(cand, d) idx[d] = #cand end
			end
		end
		-- 맞닿음 묶기
		local par = {}
		for i = 1, #cand do par[i] = i end
		local function find(i) while par[i] ~= i do par[i] = par[par[i]] i = par[i] end return i end
		local op = OverlapParams.new() op.RespectCanCollide = false op.FilterType = Enum.RaycastFilterType.Exclude
		for i, p in ipairs(cand) do
			op.FilterDescendantsInstances = {p}
			for _, q in ipairs(workspace:GetPartBoundsInBox(p.CFrame, p.Size + Vector3.new(0.06, 0.06, 0.06), op)) do
				local j = idx[q]
				if j then local a, b = find(i), find(j) if a ~= b then par[a] = b end end
			end
		end
		local groups = {}
		for i, p in ipairs(cand) do local r = find(i) groups[r] = groups[r] or {} table.insert(groups[r], p) end
		-- 레이캐스트: 벽 판정용 (가구 후보 전부 제외)
		local rpWall = RaycastParams.new() rpWall.FilterType = Enum.RaycastFilterType.Exclude rpWall.FilterDescendantsInstances = cand
		for _, g in pairs(groups) do
			local kind
			local backPart
			for _, p in ipairs(g) do
				local n = p.Name
				if n:match("^Shelf upright") then kind = kind or "shelf" end
				if n:match("^Couch back") then kind = "couch" backPart = p end
				if n:match("^Couch base") and not kind then kind = "couch" end
				if n:match("^Desk top") then kind = kind or "desk" end
			end
			local already = false
			for _, p in ipairs(g) do if p:GetAttribute("CFrameBefore20") then already = true end end
			if kind and not already then
				local gmn, gmx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
				for _, p in ipairs(g) do local c, h = aabb(p) gmn = gmn:Min(c - h) gmx = gmx:Max(c + h) end
				local gc0 = (gmn + gmx) / 2
				-- 회전 전 이미 어느 벽이든 1.5 스터드 이내면 건너뜀
				local nearAny = false
				for _, dir in ipairs({Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis}) do
					local h = workspace:Raycast(Vector3.new(gc0.X, FLOOR_Y + 1.5, gc0.Z), dir * 60, rpWall)
					if h and (h.Position - Vector3.new(gc0.X, FLOOR_Y + 1.5, gc0.Z)):Dot(dir) - math.abs(dir:Dot((gmx - gmn) / 2)) < 1.5 then nearAny = true end
				end
				if nearAny then table.insert(skipped, ("%s 이미 벽 근처"):format(f.Name:match("B%d+_%d+"))) continue end
				-- 90° 회전 (원래 CFrame 저장 후)
				local orig = {}
				for _, p in ipairs(g) do orig[p] = p.CFrame end
				local pivot = CFrame.new(gc0)
				local rot = pivot * CFrame.Angles(0, math.pi / 2, 0) * pivot:Inverse()
				for _, p in ipairs(g) do p.CFrame = rot * p.CFrame end
				gmn, gmx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
				for _, p in ipairs(g) do local c, h = aabb(p) gmn = gmn:Min(c - h) gmx = gmx:Max(c + h) end
				local gc, gs = (gmn + gmx) / 2, gmx - gmn
				local shortAxis = gs.X < gs.Z and "X" or "Z"
				local dirs = shortAxis == "X" and {Vector3.xAxis, -Vector3.xAxis} or {Vector3.zAxis, -Vector3.zAxis}
				-- 거리
				local function wallDist(dir)
					local half = math.abs(dir:Dot(gs / 2))
					local best = nil
					for _, hgt in ipairs({1.5, 4}) do
						local h = workspace:Raycast(Vector3.new(gc.X, FLOOR_Y + hgt, gc.Z), dir * 60, rpWall)
						if not h or isDoor(h.Instance) then return nil end
						local d = (h.Position - Vector3.new(gc.X, FLOOR_Y + hgt, gc.Z)):Dot(dir) - half
						best = best and math.min(best, d) or d
					end
					return best
				end
				local opts = {}
				for _, dir in ipairs(dirs) do
					local d = wallDist(dir)
					if d then
						local ok = true
						if kind == "couch" and backPart then
							ok = (backPart.Position - gc):Dot(dir) > 0 -- 등받이가 그 방향
						end
						if ok then table.insert(opts, {dir = dir, d = d}) end
					end
				end
				table.sort(opts, function(a, b) return a.d < b.d end)
				local chosen, reason = nil, "벽 없음"
				for _, o in ipairs(opts) do
					if o.d < 1.0 then chosen, reason = nil, "이미 벽 근처" break end
					local move = o.dir * (o.d - GAP)
					-- 뒷면 커버리지
					local cover = true
					local along = shortAxis == "X" and Vector3.zAxis or Vector3.xAxis
					local halfLong = math.abs(along:Dot(gs / 2)) - 0.3
					for _, t in ipairs({-1, 0, 1}) do
						for _, hgt in ipairs({1.2, 3}) do
							local o0 = gc + move + along * (t * halfLong)
							o0 = Vector3.new(o0.X, FLOOR_Y + hgt, o0.Z)
							local h = workspace:Raycast(o0, o.dir * (math.abs(o.dir:Dot(gs / 2)) + 0.5), rpWall)
							if not h or isDoor(h.Instance) then cover = false end
						end
					end
					if not cover then reason = "뒷면이 문/개구부" continue end
					-- 문 근처
					local nearDoor = false
					local opD = OverlapParams.new() opD.FilterType = Enum.RaycastFilterType.Exclude opD.FilterDescendantsInstances = g
					for _, q in ipairs(workspace:GetPartBoundsInBox(CFrame.new(gc + move), gs + Vector3.new(4, 0, 4), opD)) do
						if isDoor(q) then nearDoor = true break end
					end
					if nearDoor then reason = "문 근처" continue end
					-- 겹침 (원래 자리에서 이미 닿던 것 제외)
					local pre = {}
					for _, p in ipairs(g) do local cfr = p.CFrame p.CFrame = orig[p] for _, q in ipairs(workspace:GetPartsInPart(p, opD)) do pre[q] = true end p.CFrame = cfr end
					local clash = nil
					for _, p in ipairs(g) do
						local cf0 = p.CFrame
						p.CFrame = cf0 + move
						for _, q in ipairs(workspace:GetPartsInPart(p, opD)) do
							if not pre[q] then clash = q.Name break end
						end
						p.CFrame = cf0
						if clash then break end
					end
					if clash then reason = "겹침: " .. clash continue end
					chosen = {move = move, d = o.d}
					break
				end
				local label = ("%s %s @(%.0f,%.0f) %d파트"):format(f.Name:match("B%d+_%d+"), kind, gc.X, gc.Z, #g)
				if chosen then
					table.insert(plans, ("%s → 90° 회전 + %.1f 스터드 이동"):format(label, chosen.move.Magnitude))
					for _, p in ipairs(g) do
						if DRY then p.CFrame = orig[p] else
							p:SetAttribute("CFrameBefore20", orig[p])
							p.CFrame = p.CFrame + chosen.move
							moved += 1
						end
					end
				else
					for _, p in ipairs(g) do p.CFrame = orig[p] end
					table.insert(skipped, label .. " 유지: " .. reason)
				end
			end
		end
	end
end
return ("%s 이동 %d건 (파트 %d) / 유지 %d건\n"):format(DRY and "[계획]" or "[적용]", #plans, moved, #skipped) .. table.concat(plans, "\n") .. "\n-- 유지:\n" .. table.concat(skipped, "\n")
