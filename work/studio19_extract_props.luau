-- 19번 소품 일괄 최적화: 작은 WedgePart 묶음을 메시로 바꾸기 위한 추출.
-- 실행 기록: 2026-10-03 PHASE=1, PHASE=2 각각 DRY=false 로 1회씩 실행함. 재실행 금지(이미 R19G 표시된 쐐기는 건너뜀).
-- DRY=true 면 집계만. DRY=false 면 (1) 각 쐐기에 R19G 속성(묶음 id) 기록 (2) 메시 데이터/배치 계획을
-- 로컬 수신기(127.0.0.1:34999, scratchpad recv.py)로 전송 → assets/source/props19_p<PHASE>_{meshes.txt,plan.json}.
-- HttpEnabled 는 전송 동안만 켰다가 원래 값으로 되돌림.
-- 대상: Workspace 의 WedgePart 중 최대 변 < 1.5, Transparency < 1, 자식 없음.
--   PHASE 1 = 묶음 안 쐐기가 전부 CanCollide false, PHASE 2 = 하나라도 CanCollide true.
-- 묶음: 같은 Parent + 같은 Name (= 소품 1개) 의 쐐기 MIN_GROUP 개 이상 → 외형(재질/색/반사/그림자/Query/Touch)별 분할 → 삼각형 10k 단위 분할.
-- 중복 제거: 이름 패턴(숫자→#)·외형·개수가 같고, 순서대로 대응시킨 쐐기 전부가 하나의 강체 변환으로 겹치면 같은 메시 공유.
-- 기하: 두께(Size.X) ≤ THIN 은 중앙면 삼각형 1개(메시 DoubleSided), 그보다 두꺼우면 쐐기 프리즘 8삼각형.
-- 메시 좌표: 기준 묶음의 월드 축 그대로, 꼭짓점 bbox 중심을 원점으로. 배치 CFrame = T * CFrame.new(중심) (가져오기 Y180 보정은 교체 스크립트에서).
local DRY = true
local PHASE = 1
local MIN_GROUP = 12
local THIN = 0.05
local MAX_TRIS = 10000
local PORT = "http://127.0.0.1:34999/"
local MESH_PREFIX = PHASE == 1 and "P19_" or "P19B_"
local GID_PREFIX = PHASE == 1 and "G" or "H"

local HS = game:GetService("HttpService")

local function appearance(p)
	return table.concat({p.Material.Name, p.Color:ToHex(), ("%.3f"):format(p.Transparency), ("%.3f"):format(p.Reflectance),
		tostring(p.CastShadow), tostring(p.CanQuery), tostring(p.CanTouch), p.MaterialVariant}, "|")
end

-- 1. 후보 수집
local keys, keyOrder = {}, {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("WedgePart") then
		local s = d.Size
		if math.max(s.X, s.Y, s.Z) < 1.5 and d.Transparency < 1 and #d:GetChildren() == 0 then
			if d:GetAttribute("R19G") then continue end
			local k = d.Parent:GetFullName() .. "\0" .. d.Name
			local g = keys[k]
			if not g then g = {parent = d.Parent, name = d.Name, parts = {}, coll = false} keys[k] = g table.insert(keyOrder, k) end
			table.insert(g.parts, d)
			if d.CanCollide then g.coll = true end
		end
	end
end

-- 2. 묶음 → 외형 분할 → 삼각형 분할
local function trisOf(p) return p.Size.X <= THIN and 1 or 8 end
local units = {}
local skipped, skippedParts = 0, 0
for _, k in ipairs(keyOrder) do
	local g = keys[k]
	local want = (PHASE == 1 and not g.coll) or (PHASE == 2 and g.coll)
	if not want or #g.parts < MIN_GROUP then
		skipped += 1 skippedParts += #g.parts
	else
		local subs, subOrder = {}, {}
		for _, p in ipairs(g.parts) do
			local a = appearance(p)
			if not subs[a] then subs[a] = {} table.insert(subOrder, a) end
			table.insert(subs[a], p)
		end
		local pattern = g.name:gsub("%d+", "#")
		for si, a in ipairs(subOrder) do
			local list, chunk, ct, ci = subs[a], {}, 0, 1
			local function flush()
				if #chunk > 0 then
					table.insert(units, {parts = chunk, app = a, sig = pattern .. "|" .. a .. "|" .. si .. "|" .. ci .. "|" .. #chunk, parentPath = g.parent:GetFullName()})
					chunk, ct, ci = {}, 0, ci + 1
				end
			end
			for _, p in ipairs(list) do
				local t = trisOf(p)
				if ct + t > MAX_TRIS then flush() end
				table.insert(chunk, p) ct += t
			end
			flush()
		end
	end
end

-- 3. 중복 제거
local refsBySig = {}
local meshes = {}
local function rigid(ref, u)
	local T = u.parts[1].CFrame * ref.parts[1].CFrame:Inverse()
	for i, p in ipairs(u.parts) do
		local q = ref.parts[i]
		if (p.Size - q.Size).Magnitude > 0.002 then return nil end
		local c = T * q.CFrame
		if (c.Position - p.Position).Magnitude > 0.005 then return nil end
		if c.RightVector:Dot(p.CFrame.RightVector) < 0.9999 or c.UpVector:Dot(p.CFrame.UpVector) < 0.9999 then return nil end
	end
	return T
end
for _, u in ipairs(units) do
	local list = refsBySig[u.sig]
	if not list then list = {} refsBySig[u.sig] = list end
	for _, ref in ipairs(list) do
		local T = rigid(ref, u)
		if T then u.mesh, u.T = ref.mesh, T break end
	end
	if not u.mesh then
		table.insert(meshes, u)
		u.mesh = MESH_PREFIX .. ("%04d"):format(#meshes)
		u.T = CFrame.identity
		table.insert(list, u)
	end
end

if DRY then
	local parts, tris = 0, 0
	for _, u in ipairs(units) do parts += #u.parts end
	for _, m in ipairs(meshes) do for _, p in ipairs(m.parts) do tris += trisOf(p) end end
	return ("DRY PHASE=%d units=%d 고유메시=%d 대상쐐기=%d 삼각형=%d 제외묶음=%d(쐐기 %d)"):format(PHASE, #units, #meshes, parts, tris, skipped, skippedParts)
end

-- 4. 메시 기하 (기준 묶음 월드 좌표)
local function triangles(p, out)
	local s, cf = p.Size / 2, p.CFrame
	local function w(x, y, z) return cf:PointToWorldSpace(Vector3.new(x, y, z)) end
	if p.Size.X <= THIN then
		table.insert(out, {w(0, -s.Y, -s.Z), w(0, -s.Y, s.Z), w(0, s.Y, s.Z)})
	else
		local a1, a2 = w(-s.X, -s.Y, -s.Z), w(s.X, -s.Y, -s.Z)
		local b1, b2 = w(-s.X, -s.Y, s.Z), w(s.X, -s.Y, s.Z)
		local c1, c2 = w(-s.X, s.Y, s.Z), w(s.X, s.Y, s.Z)
		for _, t in ipairs({{a1, b1, c1}, {a2, c2, b2}, {a1, a2, b2}, {a1, b2, b1}, {b1, b2, c2}, {b1, c2, c1}, {a1, c1, c2}, {a1, c2, a2}}) do
			table.insert(out, t)
		end
	end
end
local totalTris, totalParts = 0, 0
local meshLines, planEntries = {}, {}
local byName = {}
for _, m in ipairs(meshes) do
	byName[m.mesh] = m
	local tris = {}
	for _, p in ipairs(m.parts) do triangles(p, tris) end
	local keep = {}
	local mn, mx = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, t in ipairs(tris) do
		if (t[2] - t[1]):Cross(t[3] - t[1]).Magnitude > 1e-7 then
			table.insert(keep, t)
			for _, v in ipairs(t) do mn = mn:Min(v) mx = mx:Max(v) end
		end
	end
	m.center, m.size = (mn + mx) / 2, mx - mn
	totalTris += #keep
	table.insert(meshLines, "M " .. m.mesh .. " " .. #keep)
	for _, t in ipairs(keep) do
		local r = {}
		for _, v in ipairs(t) do local q = v - m.center table.insert(r, ("%.4f %.4f %.4f"):format(q.X, q.Y, q.Z)) end
		table.insert(meshLines, table.concat(r, " "))
	end
end

-- 5. 배치 계획 + R19G 표시
for gi, u in ipairs(units) do
	totalParts += #u.parts
	local ref = byName[u.mesh]
	local cf = u.T * CFrame.new(ref.center)
	local gid = GID_PREFIX .. ("%05d"):format(gi)
	table.insert(planEntries, {gid = gid, mesh = u.mesh, cf = {cf:GetComponents()}, size = {ref.size.X, ref.size.Y, ref.size.Z}, n = #u.parts, parent = u.parentPath})
	for _, p in ipairs(u.parts) do p:SetAttribute("R19G", gid) end
end

local before = HS.HttpEnabled
HS.HttpEnabled = true
local ok, err = pcall(function()
	HS:RequestAsync({Url = PORT .. ("meshes_p%d.txt"):format(PHASE), Method = "POST", Body = table.concat(meshLines, "\n")})
	HS:RequestAsync({Url = PORT .. ("plan_p%d.json"):format(PHASE), Method = "POST", Body = HS:JSONEncode(planEntries)})
end)
HS.HttpEnabled = before
if not ok then error("전송 실패: " .. tostring(err) .. " (HttpEnabled=" .. tostring(HS.HttpEnabled) .. ")") end
return ("sent: meshes=%d units=%d parts=%d tris=%d HttpEnabled=%s"):format(#meshes, #units, totalParts, totalTris, tostring(HS.HttpEnabled))
