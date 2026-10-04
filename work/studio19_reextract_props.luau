-- 19번 소품 일괄 최적화 v2 재추출: v1 은 얇은 쐐기를 두께 중앙면 삼각형 1장으로 만들어,
-- 다른 판에 반쯤 묻힌 쐐기(예: 쓰레기통 라벨 글자, 중앙면이 라벨 윗면보다 0.0075 아래)가 가려졌다.
-- v2: 얇은 쐐기도 ±두께/2 의 앞·뒤 면 2장으로 → 원래 표면 위치 그대로. 두꺼운 쐐기는 프리즘 8삼각형 (v1 과 같음).
-- 묶음/메시 배정은 v1 계획(plan_p<PHASE>.json)을 그대로 쓰고 기하·중심·크기만 다시 계산.
--   PHASE 1: 원본은 이미 ServerStorage.Props_before_19.Phase1.<gid> (폴더 안 순서 = 추출 순서)
--   PHASE 2: 원본은 Workspace 에 R19G=H* 로 표시된 쐐기 (GetDescendants 순서 = 추출 순서)
-- 출력: 로컬 수신기로 meshes_p<PHASE>_v2.txt / plan_p<PHASE>_v2.json. 맵은 수정하지 않음 (읽기 전용).
-- 실행 기록: 2026-10-03 PHASE 1, 2 를 한 번의 호출에서 차례로 실행함.
local PHASE = 1 -- 1, 2 각각 실행
local PORT = "http://127.0.0.1:34999/"
local HS = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local THIN = 0.05

local before = HS.HttpEnabled
HS.HttpEnabled = true
local ok, body = pcall(function() return HS:GetAsync(PORT .. ("plan_p%d.json"):format(PHASE)) end)
HS.HttpEnabled = before
assert(ok, "v1 계획 받기 실패: " .. tostring(body))
local plan = HS:JSONDecode(body)

local partsByGid = {}
if PHASE == 1 then
	for _, f in ipairs(SS.Props_before_19.Phase1:GetChildren()) do partsByGid[f.Name] = f:GetChildren() end
else
	for _, d in ipairs(workspace:GetDescendants()) do
		local g = d:IsA("WedgePart") and d:GetAttribute("R19G")
		if g and g:match("^H") then
			partsByGid[g] = partsByGid[g] or {}
			table.insert(partsByGid[g], d)
		end
	end
end

local function triangles(p, out)
	local s, cf = p.Size / 2, p.CFrame
	local function w(x, y, z) return cf:PointToWorldSpace(Vector3.new(x, y, z)) end
	if p.Size.X <= THIN then
		table.insert(out, {w(s.X, -s.Y, -s.Z), w(s.X, s.Y, s.Z), w(s.X, -s.Y, s.Z)})   -- +X 면
		table.insert(out, {w(-s.X, -s.Y, -s.Z), w(-s.X, -s.Y, s.Z), w(-s.X, s.Y, s.Z)}) -- -X 면
	else
		local a1, a2 = w(-s.X, -s.Y, -s.Z), w(s.X, -s.Y, -s.Z)
		local b1, b2 = w(-s.X, -s.Y, s.Z), w(s.X, -s.Y, s.Z)
		local c1, c2 = w(-s.X, s.Y, s.Z), w(s.X, s.Y, s.Z)
		for _, t in ipairs({{a1, b1, c1}, {a2, c2, b2}, {a1, a2, b2}, {a1, b2, b1}, {b1, b2, c2}, {b1, c2, c1}, {a1, c1, c2}, {a1, c2, a2}}) do
			table.insert(out, t)
		end
	end
end

-- 메시별 기준 묶음 = 계획에서 그 메시를 처음 쓰는 gid
local refGid, meshOrder = {}, {}
for _, e in ipairs(plan) do
	if not refGid[e.mesh] then refGid[e.mesh] = e.gid table.insert(meshOrder, e.mesh) end
end
-- 쐐기 순서 대응이 어긋난 묶음(2026-10-03 PHASE 2 에서 H00050, H00148)은 메시 공유 대신 고유 메시
local function rigidErr(ps, rs)
	local T = ps[1].CFrame * rs[1].CFrame:Inverse()
	local w = 0
	for i, p in ipairs(ps) do w = math.max(w, ((T * rs[i].CFrame).Position - p.Position).Magnitude) end
	return w
end
local split = {}
for _, e in ipairs(plan) do
	if rigidErr(partsByGid[e.gid], partsByGid[refGid[e.mesh]]) > 0.01 then
		e.mesh = e.mesh .. "_" .. e.gid
		refGid[e.mesh] = e.gid
		table.insert(meshOrder, e.mesh)
		table.insert(split, e.gid)
	end
end

local lines, center, size, totalTris = {}, {}, {}, 0
for _, m in ipairs(meshOrder) do
	local tris = {}
	for _, p in ipairs(partsByGid[refGid[m]]) do triangles(p, tris) end
	local keep = {}
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, t in ipairs(tris) do
		if (t[2] - t[1]):Cross(t[3] - t[1]).Magnitude > 1e-7 then
			table.insert(keep, t)
			for _, v in ipairs(t) do mn = mn:Min(v) mx = mx:Max(v) end
		end
	end
	center[m], size[m] = (mn + mx) / 2, mx - mn
	totalTris += #keep
	table.insert(lines, "M " .. m .. " " .. #keep)
	for _, t in ipairs(keep) do
		local r = {}
		for _, v in ipairs(t) do local q = v - center[m] table.insert(r, ("%.4f %.4f %.4f"):format(q.X, q.Y, q.Z)) end
		table.insert(lines, table.concat(r, " "))
	end
end

local newPlan, worst = {}, 0
for _, e in ipairs(plan) do
	local ps, rs = partsByGid[e.gid], partsByGid[refGid[e.mesh]]
	assert(ps and #ps == e.n and #rs == e.n, e.gid .. " 쐐기 수 불일치")
	local T = ps[1].CFrame * rs[1].CFrame:Inverse()
	for i, p in ipairs(ps) do worst = math.max(worst, ((T * rs[i].CFrame).Position - p.Position).Magnitude) end
	local cf = T * CFrame.new(center[e.mesh])
	local s = size[e.mesh]
	table.insert(newPlan, {gid = e.gid, mesh = e.mesh, cf = {cf:GetComponents()}, size = {s.X, s.Y, s.Z}, n = e.n, parent = e.parent})
end
assert(worst < 0.01, ("강체 대응 오차 %.4f"):format(worst))

HS.HttpEnabled = true
ok, body = pcall(function()
	HS:RequestAsync({Url = PORT .. ("meshes_p%d_v2.txt"):format(PHASE), Method = "POST", Body = table.concat(lines, "\n")})
	HS:RequestAsync({Url = PORT .. ("plan_p%d_v2.json"):format(PHASE), Method = "POST", Body = HS:JSONEncode(newPlan)})
end)
HS.HttpEnabled = before
assert(ok, "전송 실패: " .. tostring(body))
return ("PHASE=%d v2 meshes=%d units=%d tris=%d worstRigid=%.4f split=%s HttpEnabled=%s"):format(PHASE, #meshOrder, #newPlan, totalTris, worst, table.concat(split, ","), tostring(HS.HttpEnabled))
