-- 20번 배치 수정 (병원): 계단 난간 공중 부양 + 병동 위쪽 줄 병상 12곳이 벽 없는 방 가운데 배치.
-- 옮기는 파트는 CFrameBefore20 / SizeBefore20 속성에 원래 값 보존. 새로 만든 파트는 Added20 속성. 삭제 없음.
-- 재실행 방지: CFrameBefore20 속성이 있는 병원 파트가 있으면 중단.
local R = workspace.Surter_Remodel_10
local H = R.Surter_Medical_Centre
local AF = H.Architectural_finish

for _, d in ipairs(R:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("CFrameBefore20") then error("이미 적용됨: " .. d:GetFullName()) end
end
local moved, added = 0, 0
local function keep(p)
	if p:GetAttribute("CFrameBefore20") == nil then
		p:SetAttribute("CFrameBefore20", p.CFrame)
		p:SetAttribute("SizeBefore20", p.Size)
		moved += 1
	end
end

-- 1. 계단: 디딤판 i 의 z = 304.6 + 1.6i, 윗면 = base + i (Level_0 base 1, Level_1 base 19), 디딤판 x 110..122
local TREAD_Z0, STEP_Z = 304.6, 1.6
local POST_W, POST_H = 0.25, 2.89
local XW, XE = 110.15, 121.85
for _, lv in ipairs({{"Level_0", 1.0}, {"Level_1", 19.0}}) do
	local level, base = H[lv[1]], lv[2]
	local posts = {}
	for _, d in ipairs(level:GetChildren()) do if d.Name == "Stair safety rail" then table.insert(posts, d) end end
	assert(#posts == 18, lv[1] .. " 난간 기둥 수 " .. #posts)
	for _, p in ipairs(posts) do
		local i = math.floor((p.Position.Z - TREAD_Z0) / STEP_Z + 0.5)
		local top = base + i
		keep(p)
		p.Size = Vector3.new(POST_W, POST_H, POST_W)
		p.CFrame = CFrame.new(XW, top + POST_H / 2, TREAD_Z0 + STEP_Z * i)
		local e = p:Clone()
		for a in pairs(e:GetAttributes()) do e:SetAttribute(a, nil) end
		e:SetAttribute("Added20", "east stair post")
		e.CFrame = CFrame.new(XE, top + POST_H / 2, TREAD_Z0 + STEP_Z * i)
		e.Parent = level
		added += 1
	end
end
-- 연속 손잡이: 기둥 위를 지나는 경사선 y = base + 3 + (z - 304.6)/1.6, z 303.8..332.6
local dir = Vector3.new(0, 18, 28.8).Unit
local len = math.sqrt(18 ^ 2 + 28.8 ^ 2)
local rails = {}
for _, d in ipairs(AF:GetChildren()) do if d.Name == "Continuous stair handrail" then table.insert(rails, d) end end
assert(#rails == 4, "손잡이 수 " .. #rails)
for _, r in ipairs(rails) do
	local base = r.Position.Y < 20 and 1.0 or 19.0
	local x = r.Position.X < 116 and XW or XE
	local c = Vector3.new(x, base + 3 + (318.2 - TREAD_Z0) / STEP_Z, 318.2)
	keep(r)
	r.Size = Vector3.new(r.Size.X, r.Size.Y, len)
	r.CFrame = CFrame.lookAt(c, c + dir)
end
-- 계단 구멍 가장자리 난간: 바닥 끝(x=109) 바깥 x=109.2 → 바닥 위 x=108.85
for _, d in ipairs(AF:GetChildren()) do
	if d.Name == "Landing guard post" or d.Name == "Landing guard rail" then
		keep(d)
		d.CFrame = d.CFrame + Vector3.new(108.85 - d.Position.X, 0, 0)
	end
end

-- 2. 병동 위쪽 줄 병상 12곳: 병상 구역(병상·머리판·수액대·모니터·의자·커튼·레일)을 z=245.225 축으로 180° 회전 →
--    머리판 뒷면 z 232.86 → 칸막이벽 북쪽 면 z 257.59.
local PIVOT_Z = (232.86 + 257.59) / 2
local SKIP = {["Ceiling luminaire"] = true, ["Ceiling fixed housing"] = true, ["Ceiling ventilation frame"] = true, ["Vent slat"] = true,
	["Ceiling light diffuser"] = true, ["Wayfinding stripe"] = true, ["Corridor protective rail"] = true}
local bayGroups = {}
for _, lv in ipairs({{"Level_1", 18.5, 36}, {"Level_2", 36.5, 54}}) do
	local level, y0, y1 = H[lv[1]], lv[2], lv[3]
	local bays = {}
	for _, b in ipairs(level:GetChildren()) do
		if b.Name == "Patient bay" then
			local cf = b:GetBoundingBox()
			if cf.Z < 245 then table.insert(bays, cf.X) end
		end
	end
	assert(#bays == 6, lv[1] .. " 위쪽 줄 병상 수 " .. #bays)
	for _, d in ipairs(R:GetDescendants()) do
		if d:IsA("BasePart") and not SKIP[d.Name] then
			local p, e = d.Position, d.ExtentsSize
			if p.Z > 226 and p.Z < 252 and p.Y > y0 - 0.2 and p.Y < y1 - 0.5 and e.X < 15 and e.Z < 15 and ((p.X > 24 and p.X < 105) or (p.X > 134 and p.X < 216)) then
				local best, bd = nil, 1e9
				for _, bx in ipairs(bays) do
					if (bx < 120) == (p.X < 120) and math.abs(p.X - bx) < bd then bd, best = math.abs(p.X - bx), bx end
				end
				local k = lv[1] .. ("%.2f"):format(best)
				bayGroups[k] = bayGroups[k] or {x = best, parts = {}}
				table.insert(bayGroups[k].parts, d)
			end
		end
	end
end
local nGroups, nBedParts = 0, 0
for _, g in pairs(bayGroups) do
	nGroups += 1
	local pivot = CFrame.new(g.x, 0, PIVOT_Z)
	local rot = pivot * CFrame.Angles(0, math.pi, 0) * pivot:Inverse()
	for _, p in ipairs(g.parts) do
		keep(p)
		p.CFrame = rot * p.CFrame
		nBedParts += 1
	end
end
assert(nGroups == 12, "병상 구역 수 " .. nGroups)
return ("계단·난간·병상 수정: 옮긴 파트 %d (병상 구역 %d곳, %d파트), 새 동쪽 계단 기둥 %d"):format(moved, nGroups, nBedParts, added)
