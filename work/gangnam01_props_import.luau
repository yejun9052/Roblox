-- 강남 01: 키트 소품(AI 메시)을 새 장소에 다시 만들기. 데이터 = assets/source/kit22_props.json (22번 파일 ServerStorage.Kit22_Props 에서 읽음).
-- AssetService:CreateMeshPartAsync(MeshId) + TextureID + Size. 피벗 = 바닥 중심. 이미 있으면 건너뜀(여러 번 실행해도 됨).
local HS = game:GetService("HttpService")
local AS = game:GetService("AssetService")
local SS = game:GetService("ServerStorage")
local was = HS.HttpEnabled
HS.HttpEnabled = true
local ok, src = pcall(function() return HS:GetAsync("http://127.0.0.1:34999/kit22_props.json", true) end)
HS.HttpEnabled = was
assert(ok, src)
local list = HS:JSONDecode(src)
local lib = SS:FindFirstChild("Kit22_Props") or Instance.new("Folder")
lib.Name = "Kit22_Props"
lib.Parent = SS
local made, skipped, failed = 0, 0, {}
for _, e in ipairs(list) do
	if lib:FindFirstChild(e.name) then
		skipped += 1
	else
		local okm, mp = pcall(function() return AS:CreateMeshPartAsync(e.mesh) end)
		if okm then
			mp.Name = "body_geom"
			mp.TextureID = e.tex
			mp.Size = Vector3.new(e.size[1], e.size[2], e.size[3])
			mp.Anchored = true
			mp.CFrame = CFrame.new(0, e.size[2] / 2, 0)
			local m = Instance.new("Model")
			m.Name = e.name
			m:SetAttribute("Kit22Prop", "AI generate_mesh (22번에서 옮김)")
			mp.Parent = m
			m.WorldPivot = CFrame.new()
			m.Parent = lib
			made += 1
		else
			table.insert(failed, e.name .. ": " .. tostring(mp))
		end
	end
end
return ("만듦 %d, 건너뜀 %d, 실패 %d %s"):format(made, skipped, #failed, table.concat(failed, "; "))
