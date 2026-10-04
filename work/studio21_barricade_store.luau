-- 21번 A: 막힌 도로 차단벽 정리 (1회 실행).
-- 막힌 도로(Roads/Reserved/*) 구간 중 끝점이 활성 도로에서 16 스터드 이내 = 입구(gate), 나머지 = 안쪽(inner).
-- 두 종류 모두 차단벽 파트(Concrete closure, Closure amber stripe, Fence obstruction)를
-- ServerStorage.Barricades_before_21.<폴더명> 으로 옮김 (OriginalParent21 속성). Collapsed rubble 은 그대로 둠.
-- gate 폴더에는 Gate21=true, Center21(지면 중심), Cross21(가로 방향 단위벡터), Span21(원래 펜스 폭) 속성 기록 → B 단계가 사용.
-- 재실행 방지: Barricades_before_21 이 있으면 중단.
local SS = game:GetService("ServerStorage")
local SD = workspace.SurterDays
assert(not SS:FindFirstChild("Barricades_before_21"), "이미 적용됨")

local function aabb(p)
	local cf, s = p.CFrame, p.Size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return p.Position, Vector3.new(math.abs(r.X) * s.X + math.abs(u.X) * s.Y + math.abs(l.X) * s.Z,
		math.abs(r.Y) * s.X + math.abs(u.Y) * s.Y + math.abs(l.Y) * s.Z, math.abs(r.Z) * s.X + math.abs(u.Z) * s.Y + math.abs(l.Z) * s.Z)
end
local active = {}
for _, f in ipairs(SD:GetChildren()) do
	if f.Name:match("^Roads/Active/") then
		for _, d in ipairs(f:GetChildren()) do
			if d:IsA("BasePart") and d.Name:match("^Road surface") then local c, h = aabb(d) table.insert(active, {c = c, h = h}) end
		end
	end
end
local function nearActive(p, tol)
	for _, a in ipairs(active) do
		if math.max(0, math.abs(p.X - a.c.X) - a.h.X) <= tol and math.max(0, math.abs(p.Z - a.c.Z) - a.h.Z) <= tol then return true end
	end
	return false
end

local store = Instance.new("Folder")
store.Name = "Barricades_before_21"
store.Parent = SS
local nGate, nInner, nParts = 0, 0, 0
for _, f in ipairs(SD:GetChildren()) do
	if f.Name:match("^Roads/Reserved/") then
		local road, fence
		local closure = {}
		for _, d in ipairs(f:GetChildren()) do
			if d:IsA("BasePart") then
				if d.Name:match("^Road surface") then road = d end
				if d.Name:match("^Fence obstruction") then fence = d end
				if d.Name:match("^Concrete closure") or d.Name:match("^Fence obstruction") or d.Name:match("^Closure amber stripe") then table.insert(closure, d) end
			end
		end
		if road and #closure > 0 then
			local c, h = aabb(road)
			local axis = h.X > h.Z and Vector3.xAxis or Vector3.zAxis
			local half = math.max(h.X, h.Z)
			local isGate = nearActive(c + axis * half, 16) or nearActive(c - axis * half, 16)
			local keep = Instance.new("Folder")
			keep.Name = f.Name
			keep:SetAttribute("OriginalParent21", f:GetFullName())
			if isGate then
				-- 차단 중심/폭: 펜스 기준, 없으면 콘크리트 블록 범위
				local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
				for _, d in ipairs(fence and {fence} or closure) do local cc, hh = aabb(d) mn = mn:Min(cc - hh) mx = mx:Max(cc + hh) end
				local cross = axis == Vector3.xAxis and Vector3.zAxis or Vector3.xAxis
				local span = math.abs(cross:Dot(mx - mn))
				local ctr = (mn + mx) / 2
				keep:SetAttribute("Gate21", true)
				keep:SetAttribute("Center21", Vector3.new(ctr.X, c.Y + h.Y, ctr.Z))
				keep:SetAttribute("Cross21", cross)
				keep:SetAttribute("Span21", span)
				keep:SetAttribute("RoadWidth21", 2 * math.abs(cross:Dot(h)))
				nGate += 1
			else
				nInner += 1
			end
			keep.Parent = store
			for _, d in ipairs(closure) do
				d:SetAttribute("OriginalParent21", f:GetFullName())
				d.Parent = keep
				nParts += 1
			end
		end
	end
end
return ("gate=%d inner=%d 옮긴 파트=%d"):format(nGate, nInner, nParts)
