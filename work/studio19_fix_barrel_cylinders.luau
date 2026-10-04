-- 19번 보정: studio19_replace_barrel.luau 직후 실행. 뚜껑 원판/볼트 와셔(원본 Shape=Cylinder Part 3개)가
-- v1 메시에 사각 박스로 들어가 사각 판이 튀어나옴 → steel/plate 를 v2 메시(원통 제외)로 바꾸고 원통 Part 3개는 원래 폴더로 복귀.
-- 전제: assets/fbx/barrel_detail_v2.fbx 를 Import Queue 로 가져와 Workspace 에 모델(Barrel_steel/plate MeshPart)이 있음.
-- v1 steel/plate MeshPart 는 이 세션에서 만든 미저장 객체라 제거. faded(v1) 는 원본도 Block 이라 유지.
-- 재실행 방지: 복귀된 원통 Part(Rev19KeptAsPart)가 있으면 중단.
local SS = game:GetService("ServerStorage")
local root = workspace.SurterDays
local store = SS.Props_before_19

local SPEC = { -- Blender v2 출력 bbox (ORIGIN 기준)
	steel = {center = Vector3.new(0, 2.2849, 0),           size = Vector3.new(3.0848, 4.5703, 3.0846)},
	plate = {center = Vector3.new(0.0075, 4.6430, 0.0368), size = Vector3.new(1.5651, 0.1040, 0.8527)},
}
local FLIP = CFrame.Angles(0, math.pi, 0) -- Import Queue 가져오기 Y 180° (v2 도 꼭짓점 대조로 확인)

for _, d in ipairs(root:GetDescendants()) do
	if d:GetAttribute("Rev19KeptAsPart") then error("이미 적용됨: " .. d:GetFullName()) end
end

local tmpl = {}
for _, d in ipairs(workspace:GetChildren()) do
	if d:IsA("Model") and d.Name:match("barrel_detail_v2") then
		for m in pairs(SPEC) do tmpl[m] = d:FindFirstChild("Barrel_" .. m) end
		tmpl.model = d
	end
end
for m in pairs(SPEC) do assert(tmpl[m], "v2 템플릿 없음: Barrel_" .. m) end

local log, restored = {}, 0
for _, keep in ipairs(store:GetChildren()) do
	local id = keep.Name:match("^Barrel_(%d+)$")
	if id then
		local folder = nil
		local o = keep:GetAttribute("Origin19")
		for m in pairs(SPEC) do
			local old = nil
			for _, d in ipairs(root:GetDescendants()) do
				if d.Name == ("Polish_Barrel_SD_%s_mesh_%s"):format(id, m) then old = d break end
			end
			assert(old, id .. " v1 메시 없음 " .. m)
			folder = old.Parent
			local mp = tmpl[m]:Clone()
			mp.Name = old.Name
			mp.Size = SPEC[m].size
			mp.CFrame = CFrame.new(o + SPEC[m].center) * FLIP
			mp.DoubleSided = true
			mp.Anchored, mp.CanCollide, mp.CanTouch, mp.CanQuery, mp.CastShadow = true, false, false, false, true
			mp.Material, mp.Color, mp.Reflectance, mp.Transparency = old.Material, old.Color, old.Reflectance, 0
			pcall(function() mp.CollisionFidelity = Enum.CollisionFidelity.Box end)
			mp:SetAttribute("Rev19Origin", o)
			mp.Parent = folder
			old:Destroy()
		end
		local n = 0
		for _, p in ipairs(keep:GetChildren()) do
			if p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
				p.Parent = folder
				p:SetAttribute("OriginalParent19", nil)
				p:SetAttribute("Rev19KeptAsPart", true)
				n += 1
			end
		end
		assert(n == 3, id .. " 원통 수 " .. n)
		restored += n
		table.insert(log, id .. " ok")
	end
end

tmpl.model.Name = "Props_19_mesh_templates_v2"
tmpl.model.Parent = SS
table.insert(log, "restored cylinders=" .. restored)
return table.concat(log, "\n")
