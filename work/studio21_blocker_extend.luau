-- 21번 보정 (적용 완료, 재실행 금지): 바리케이드 보이지 않는 차단면 조정. Play 시험에서 발견한 두 가지 누수 수정.
-- 1) 높이 10 → 24: 폐차 지붕에 올라가 점프하면 넘어감.
-- 2) 폭: 원래 펜스 폭(29/34) 끝과 옆 부지 담장 사이 보도 틈으로 우회 가능 → 차단 중심(Center21)에서 좌우 레이(높이 5,
--    보도·연석·도로·잔해·가로등·비충돌 무시)로 첫 충돌 벽까지 + 0.5 겹치게 넓힘. 원래 폭은 SpanOrig21 속성.
--    한쪽 벽을 45 스터드 안에서 못 찾으면(21곳, 대부분 외곽 또는 열린 문으로 레이가 빠짐) 그쪽은 도로폭/2 + 6.5(보도 바깥 +2)까지만.
-- 3) R114·R121 은 B16·B13 정문 바로 앞이라 원래 펜스 폭으로 되돌림(정문 진입 Play 확인).
-- 실제 적용은 execute_luau 로 단계별 실행했고, 아래는 같은 처리를 한 번에 쓴 요약본.
local SS = game:GetService("ServerStorage")
local root = workspace.Apocalypse_21
local rp = RaycastParams.new() rp.FilterType = Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances = {root}
local IGN = {"Sidewalk", "Curb", "Road surface", "lane", "Lot apron", "Collapsed rubble", "Streetlamp", "bulkhead"}
local KEEP_ORIGINAL = {R114 = true, R121 = true}
local function cast(o, dir)
	local origin = o
	for _ = 1, 6 do
		local h = workspace:Raycast(origin, dir * 45, rp)
		if not h then return nil end
		local skip = not h.Instance.CanCollide
		for _, k in ipairs(IGN) do if h.Instance.Name:find(k) then skip = true break end end
		if not skip then return (h.Position - o):Dot(dir) end
		origin = h.Position + dir * 0.05
	end
	return nil
end
for _, g in ipairs(SS.Barricades_before_21:GetChildren()) do
	local name = g.Name:match("R%d+")
	local s = g:GetAttribute("Gate21") and root.Barricades:FindFirstChild(name)
	local b = s and s:FindFirstChild("Barricade_blocker_21")
	if b then
		local c, span, roadW = g:GetAttribute("Center21"), g:GetAttribute("Span21"), g:GetAttribute("RoadWidth21")
		local right = b.CFrame.RightVector
		if not b:GetAttribute("SpanOrig21") then b:SetAttribute("SpanOrig21", span) end
		local e1, e2 = span / 2, span / 2
		if not KEEP_ORIGINAL[name] then
			local o = Vector3.new(c.X, c.Y + 5, c.Z)
			local d1, d2 = cast(o, right), cast(o, -right)
			e1 = d1 and d1 + 0.5 or roadW / 2 + 6.5
			e2 = d2 and d2 + 0.5 or roadW / 2 + 6.5
		end
		b.Size = Vector3.new(e1 + e2, 24, 1.2)
		b.CFrame = CFrame.fromMatrix(Vector3.new(c.X, c.Y + 12, c.Z) + right * ((e1 - e2) / 2), right, Vector3.yAxis)
	end
end
