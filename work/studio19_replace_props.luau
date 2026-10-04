-- 19번 소품 일괄 최적화: studio19_extract_props.luau 가 R19G 로 표시한 쐐기 묶음을 MeshPart 로 교체.
-- 전제: assets/fbx/props19_p<PHASE>.fbx 를 Import Queue 로 가져와 Workspace 에 모델(자식 MeshPart 이름 = 메시 이름)이 있음.
--       배치 계획은 로컬 수신기(127.0.0.1:34999)에서 plan_p<PHASE>.json 을 GET (= assets/source/props19_p<PHASE>_plan.json).
-- 원본 쐐기는 ServerStorage.Props_before_19.Phase<PHASE>.<gid> 로 이동 (삭제 안 함), 각 파트 OriginalParent19 속성.
-- 메시: 가져오기 Y축 180° 보정, Size 는 계획값 직접 지정, DoubleSided, 외형/Query/Touch/그림자는 원본 첫 쐐기 값.
-- 충돌: PHASE 1 = CanCollide false. PHASE 2 = CanCollide true + CollisionFidelity Default.
-- 재실행 방지: Props_before_19.Phase<PHASE> 가 있으면 중단.
local PHASE = 1 -- 1, 2 순서로 각각 1회 실행
local PORT = "http://127.0.0.1:34999/"
local HS = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local FLIP = CFrame.Angles(0, math.pi, 0)

local store = SS:WaitForChild("Props_before_19")
if store:FindFirstChild("Phase" .. PHASE) then error("이미 적용됨: Phase" .. PHASE) end

-- 계획 받기
local before = HS.HttpEnabled
HS.HttpEnabled = true
local ok, body = pcall(function() return HS:GetAsync(PORT .. ("plan_p%d.json"):format(PHASE)) end)
HS.HttpEnabled = before
assert(ok, "계획 받기 실패: " .. tostring(body))
local plan = HS:JSONDecode(body)

-- 템플릿 모델 찾기
local tmplModel
for _, d in ipairs(workspace:GetChildren()) do
	if d:IsA("Model") and d.Name:match("^props19_p" .. PHASE) then tmplModel = d end
end
assert(tmplModel, "가져온 모델 props19_p" .. PHASE .. " 없음")

-- 표시된 쐐기 모으기
local byGid = {}
local prefix = PHASE == 1 and "^G" or "^H"
for _, d in ipairs(workspace:GetDescendants()) do
	local g = d:IsA("WedgePart") and d:GetAttribute("R19G")
	if g and g:match(prefix) then
		byGid[g] = byGid[g] or {}
		table.insert(byGid[g], d)
	end
end

-- 사전 검사: 쐐기 수, 템플릿 존재/크기
local worstSize = 0
for _, e in ipairs(plan) do
	local ws = byGid[e.gid]
	assert(ws and #ws == e.n, e.gid .. " 쐐기 수 불일치 " .. tostring(ws and #ws) .. "/" .. e.n)
	local t = tmplModel:FindFirstChild(e.mesh)
	assert(t and t:IsA("MeshPart"), "템플릿 없음 " .. e.mesh)
	-- Import Queue 는 모델 전체를 균일 배율로 줄여 넣는다(p1 0.0227). 축별 배율이 같은지만 확인 (평평한 축 제외)
	local ms, rs = t.MeshSize, {}
	for i, a in ipairs({"X", "Y", "Z"}) do
		if e.size[i] > 0.02 and ms[a] > 0 then table.insert(rs, e.size[i] / ms[a]) end
	end
	for i = 2, #rs do worstSize = math.max(worstSize, math.abs(rs[i] / rs[1] - 1)) end
end
assert(worstSize < 0.01, ("템플릿 축 배율 불일치 %.4f"):format(worstSize))

local phaseFolder = Instance.new("Folder")
phaseFolder.Name = "Phase" .. PHASE
phaseFolder.Parent = store

local made, moved = 0, 0
for _, e in ipairs(plan) do
	local ws = byGid[e.gid]
	local src = ws[1]
	local parent = src.Parent
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
	mp.Parent = parent
	made += 1
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

tmplModel.Name = "Props_19_mesh_templates_p" .. PHASE
tmplModel.Parent = SS
return ("PHASE=%d meshparts=%d moved=%d worstAxisRatioDiff=%.4f"):format(PHASE, made, moved, worstSize)
