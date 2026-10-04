-- 19번 소품 일괄 최적화 v2 교체. studio19_reextract_props.luau 의 v2 계획(plan_p<PHASE>_v2.json)과
-- Import Queue 로 가져온 props19_p<PHASE>_v2 모델을 사용.
-- PHASE 1: 원본은 이미 ServerStorage.Props_before_19.Phase1 에 있음. v1 MeshPart(R19G=G*, 저장 전 이번 세션 생성물)를 v2 로 바꿈.
-- PHASE 2: Workspace 의 R19G=H* 쐐기를 MeshPart 로 바꾸고 원본은 Props_before_19.Phase2.<gid> 로 이동 (OriginalParent19 속성).
--   CanCollide true, CollisionFidelity Default. 교체 전후 같은 레이캐스트 격자로 충돌 형상 비교, 차이가 큰 묶음은
--   PreciseConvexDecomposition 으로 올려 재검사. 결과는 반환 문자열로.
-- 가져오기 보정: Y축 180°, Size 는 계획값 직접 지정 (Import Queue 가 균일 배율로 줄여 넣음), DoubleSided.
-- 재실행 방지: PHASE 1 은 R19V2 속성 MeshPart 가 있으면, PHASE 2 는 Phase2 폴더가 있으면 중단.
local PHASE = 1 -- 1, 2 순서로 각각 1회
local PORT = "http://127.0.0.1:34999/"
local HS = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local FLIP = CFrame.Angles(0, math.pi, 0)
local store = SS.Props_before_19

local before = HS.HttpEnabled
HS.HttpEnabled = true
local ok, body = pcall(function() return HS:GetAsync(PORT .. ("plan_p%d_v2.json"):format(PHASE)) end)
HS.HttpEnabled = before
assert(ok, "계획 받기 실패: " .. tostring(body))
local plan = HS:JSONDecode(body)

local tmplModel = workspace:FindFirstChild("props19_p" .. PHASE .. "_v2")
assert(tmplModel, "가져온 모델 props19_p" .. PHASE .. "_v2 없음")

-- 원본 쐐기
local wedges = {}
if PHASE == 1 then
	for _, f in ipairs(store.Phase1:GetChildren()) do wedges[f.Name] = f:GetChildren() end
else
	assert(not store:FindFirstChild("Phase2"), "이미 적용됨: Phase2")
	for _, d in ipairs(workspace:GetDescendants()) do
		local g = d:IsA("WedgePart") and d:GetAttribute("R19G")
		if g and g:match("^H") then wedges[g] = wedges[g] or {} table.insert(wedges[g], d) end
	end
end
-- PHASE 1 의 v1 MeshPart
local v1 = {}
if PHASE == 1 then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("MeshPart") then
			local g = d:GetAttribute("R19G")
			if d:GetAttribute("R19V2") and g and g:match("^G") then error("이미 v2 적용됨: " .. d:GetFullName()) end
			if g and g:match("^G") then v1[g] = d end
		end
	end
end

-- 사전 검사
local worstAxis = 0
for _, e in ipairs(plan) do
	assert(wedges[e.gid] and #wedges[e.gid] == e.n, e.gid .. " 쐐기 수 불일치")
	if PHASE == 1 then assert(v1[e.gid], e.gid .. " v1 MeshPart 없음") end
	local t = tmplModel:FindFirstChild(e.mesh)
	assert(t and t:IsA("MeshPart"), "템플릿 없음 " .. e.mesh)
	local ms, rs = t.MeshSize, {}
	for i, a in ipairs({"X", "Y", "Z"}) do
		if e.size[i] > 0.02 and ms[a] > 0 then table.insert(rs, e.size[i] / ms[a]) end
	end
	for i = 2, #rs do worstAxis = math.max(worstAxis, math.abs(rs[i] / rs[1] - 1)) end
end
assert(worstAxis < 0.01, ("템플릿 축 배율 불일치 %.4f"):format(worstAxis))

-- 충돌 비교용 레이캐스트 격자 (묶음 bbox 를 0.3 넓혀 위→아래 8×8, 수평 X/Z 방향 3높이×8)
local function probe(e, include)
	local cf = CFrame.new(table.unpack(e.cf))
	local h = Vector3.new(e.size[1], e.size[2], e.size[3]) / 2 + Vector3.new(0.3, 0.3, 0.3)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = include
	local res = {}
	local function cast(o, d)
		local r = workspace:Raycast(o, d, rp)
		table.insert(res, r and (r.Position - o).Magnitude or -1)
	end
	for i = 0, 7 do
		for j = 0, 7 do
			local u, v = -h.X + (i + 0.5) * h.X / 4, -h.Z + (j + 0.5) * h.Z / 4
			cast(cf:PointToWorldSpace(Vector3.new(u, h.Y, v)), cf:VectorToWorldSpace(Vector3.new(0, -2 * h.Y, 0)))
		end
	end
	for k = 0, 2 do
		local y = -h.Y + (k + 0.5) * h.Y * 2 / 3
		for i = 0, 7 do
			local u = -h.X + (i + 0.5) * h.X / 4
			cast(cf:PointToWorldSpace(Vector3.new(u, y, -h.Z)), cf:VectorToWorldSpace(Vector3.new(0, 0, 2 * h.Z)))
			local v = -h.Z + (i + 0.5) * h.Z / 4
			cast(cf:PointToWorldSpace(Vector3.new(-h.X, y, v)), cf:VectorToWorldSpace(Vector3.new(2 * h.X, 0, 0)))
		end
	end
	return res
end
local function mismatch(a, b)
	local bad = 0
	for i = 1, #a do
		if (a[i] < 0) ~= (b[i] < 0) or (a[i] >= 0 and math.abs(a[i] - b[i]) > 0.25) then bad += 1 end
	end
	return bad / #a
end

local base = {}
if PHASE == 2 then
	for _, e in ipairs(plan) do base[e.gid] = probe(e, wedges[e.gid]) end
end

local phaseFolder
if PHASE == 2 then
	phaseFolder = Instance.new("Folder")
	phaseFolder.Name = "Phase2"
	phaseFolder.Parent = store
end

local made, moved, meshOf = 0, 0, {}
for _, e in ipairs(plan) do
	local ws = wedges[e.gid]
	local src = ws[1]
	local parent = PHASE == 1 and v1[e.gid].Parent or src.Parent
	local mp = tmplModel[e.mesh]:Clone()
	mp.Name = src.Name .. "_mesh19"
	mp.Size = Vector3.new(math.max(e.size[1], 0.001), math.max(e.size[2], 0.001), math.max(e.size[3], 0.001))
	mp.CFrame = CFrame.new(table.unpack(e.cf)) * FLIP
	mp.DoubleSided = true
	mp.Anchored = true
	mp.Material, mp.MaterialVariant, mp.Color = src.Material, src.MaterialVariant, src.Color
	mp.Reflectance, mp.Transparency = src.Reflectance, src.Transparency
	mp.CastShadow, mp.CanQuery, mp.CanTouch = src.CastShadow, src.CanQuery, src.CanTouch
	if PHASE == 1 then
		mp.CanCollide = false
		pcall(function() mp.CollisionFidelity = Enum.CollisionFidelity.Box end)
	else
		mp.CanCollide = true
		mp.CollisionFidelity = Enum.CollisionFidelity.Default
	end
	mp:SetAttribute("R19G", e.gid)
	mp:SetAttribute("R19V2", true)
	mp.Parent = parent
	meshOf[e.gid] = mp
	made += 1
	if PHASE == 1 then
		v1[e.gid]:Destroy()
	else
		local keep = Instance.new("Folder")
		keep.Name = e.gid
		keep:SetAttribute("OriginalParent19", parent:GetFullName())
		keep.Parent = phaseFolder
		for _, w in ipairs(ws) do
			w:SetAttribute("OriginalParent19", parent:GetFullName())
			w.Parent = keep
			moved += 1
		end
	end
end

-- 충돌 비교 (PHASE 2)
local report = {}
if PHASE == 2 then
	local worst, upgraded = {}, 0
	for _, e in ipairs(plan) do
		local m = mismatch(base[e.gid], probe(e, {meshOf[e.gid]}))
		if m > 0.10 then
			meshOf[e.gid].CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			upgraded += 1
			m = mismatch(base[e.gid], probe(e, {meshOf[e.gid]}))
		end
		table.insert(worst, {gid = e.gid, m = m, name = meshOf[e.gid].Name})
	end
	table.sort(worst, function(a, b) return a.m > b.m end)
	table.insert(report, "Precise 로 올림=" .. upgraded)
	for i = 1, math.min(12, #worst) do table.insert(report, ("  %s %.0f%% %s"):format(worst[i].gid, worst[i].m * 100, worst[i].name)) end
end

-- 템플릿 정리: v2 는 ServerStorage 로, 이번 세션 v1 템플릿(미사용)은 제거
tmplModel.Name = "Props_19_mesh_templates_p" .. PHASE .. "_v2"
tmplModel.Parent = SS
local oldT = SS:FindFirstChild("Props_19_mesh_templates_p" .. PHASE) or workspace:FindFirstChild("props19_p" .. PHASE)
if oldT then oldT:Destroy() end
return ("PHASE=%d v2 meshparts=%d moved=%d axis=%.4f HttpEnabled=%s\n"):format(PHASE, made, moved, worstAxis, tostring(HS.HttpEnabled)) .. table.concat(report, "\n")
