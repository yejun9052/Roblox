-- 19번 반복 소품 최적화: 드럼통 24개의 장식 854파트를 MeshPart 3개로 교체.
-- 전제: assets/fbx/barrel_detail.fbx 를 File → Import 3D 로 가져와 Workspace 에 Barrel_steel/plate/faded MeshPart 가 있음.
-- 원본 장식 파트는 ServerStorage.Props_before_19.Barrel_<id> 로 이동 (삭제 안 함), 각 파트에 OriginalParent19 속성.
-- 재실행 방지: Props_before_19 에 Barrel_ 폴더가 하나라도 있으면 중단.
local SS = game:GetService("ServerStorage")
local root = workspace.SurterDays

-- Blender 출력 bbox (ORIGIN 기준, Roblox 좌표). 가져오기 단위 변환에 의존하지 않고 Size 를 직접 지정.
local SPEC = {
	steel = {center = Vector3.new(0, 2.2998, 0),           size = Vector3.new(3.0848, 4.6003, 3.0848)},
	plate = {center = Vector3.new(0, 4.6065, 0),           size = Vector3.new(2.7723, 0.1771, 2.7724)},
	faded = {center = Vector3.new(0.3758, 2.3650, 1.4024), size = Vector3.new(0.5570, 0.3180, 0.1716)},
}

-- Import Queue 로 가져온 메시는 Y축 180° 돌아가 있음 (꼭짓점 대조: rotY180 오차 0.0001, identity 0.155)
local FLIP = CFrame.Angles(0, math.pi, 0)

local store = SS:FindFirstChild("Props_before_19")
if store then
	for _, c in ipairs(store:GetChildren()) do
		if c.Name:match("^Barrel_") then error("이미 적용됨: " .. c:GetFullName()) end
	end
end

-- 템플릿 MeshPart 찾기 (가져온 모델 안)
local tmpl = {}
for _, d in ipairs(workspace:GetDescendants()) do
	local m = d:IsA("MeshPart") and d.Name:match("^Barrel_(%a+)$")
	if m and SPEC[m] and not d:IsDescendantOf(root) then
		if tmpl[m] then error("템플릿 중복: " .. d:GetFullName()) end
		tmpl[m] = d
	end
end
for m in pairs(SPEC) do assert(tmpl[m], "템플릿 없음: Barrel_" .. m) end

-- 드럼통 그룹 수집
local groups, order = {}, {}
for _, f in ipairs(root:GetDescendants()) do
	if f.Name:match("StreetProps/Detail/Barrel$") then
		for _, d in ipairs(f:GetChildren()) do
			local id = d:IsA("BasePart") and d.Name:match("^Polish_Barrel_SD_(%d+)_")
			if id then
				if not groups[id] then groups[id] = {folder = f, parts = {}} table.insert(order, id) end
				table.insert(groups[id].parts, d)
			end
		end
	end
end
table.sort(order)
assert(#order == 24, "드럼통 수 " .. #order)

store = store or Instance.new("Folder")
store.Name = "Props_before_19"
store.Parent = SS

local log = {}
for _, id in ipairs(order) do
	local g = groups[id]
	assert(#g.parts == 854, id .. " 파트 수 " .. #g.parts)
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	local look = {}
	for _, p in ipairs(g.parts) do
		mn = mn:Min(p.Position) mx = mx:Max(p.Position)
		local m = p.Name:match("_(%a+)$")
		look[m] = look[m] or p
	end
	local o = Vector3.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)
	for m, s in pairs(SPEC) do
		local src = look[m]
		local mp = tmpl[m]:Clone()
		mp.Name = ("Polish_Barrel_SD_%s_mesh_%s"):format(id, m)
		mp.Size = s.size
		mp.CFrame = CFrame.new(o + s.center) * FLIP
		mp.DoubleSided = true -- 원본 쐐기는 두께 0.025 판이라 양면
		mp.Anchored = true
		mp.CanCollide = false
		mp.CanTouch = false
		mp.CanQuery = false
		mp.CastShadow = true
		mp.Material = src.Material
		mp.Color = src.Color
		mp.Reflectance = src.Reflectance
		mp.Transparency = 0
		pcall(function() mp.CollisionFidelity = Enum.CollisionFidelity.Box end)
		mp:SetAttribute("Rev19Origin", o)
		mp.Parent = g.folder
	end
	local keep = Instance.new("Folder")
	keep.Name = "Barrel_" .. id
	keep:SetAttribute("OriginalParent19", g.folder:GetFullName())
	keep:SetAttribute("Origin19", o)
	keep.Parent = store
	for _, p in ipairs(g.parts) do
		p:SetAttribute("OriginalParent19", g.folder:GetFullName())
		p.Parent = keep
	end
	table.insert(log, ("%s O=(%.3f,%.3f,%.3f) moved=%d"):format(id, o.X, o.Y, o.Z, #g.parts))
end

-- 가져온 템플릿 모델은 다음 소품 작업용으로 ServerStorage 에 보관
local tm = tmpl.steel.Parent
if tm and tm:IsA("Model") and tm.Parent == workspace then
	tm.Name = "Props_19_mesh_templates"
	tm.Parent = SS
end
return table.concat(log, "\n")
