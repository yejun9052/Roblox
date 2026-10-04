---------------------------------------------------------------- 서울형 건물 (강남 맵): 다세대 빌라, 근린상가. kit_apoc 뒤에 붙임 (deploy.sh)
-- 정면 = -Z, 원점 = 바닥 중심 (다른 종류와 같음). 간판 상호는 모두 가상의 이름.
Kit.TEX.win_kr_bars = "rbxassetid://123286166037188"
Kit.TEX.win_kr_bars_b = "rbxassetid://83600247036392"
Kit.TEX.win_kr_plain = "rbxassetid://134252798573211"
Kit.TEX.win_kr_wide = "rbxassetid://133769164538809"
Kit.TEX.win_kr_broken = "rbxassetid://86706735738326"

local MS = Enum.Material
local KR_FONT = Font.fromEnum(Enum.Font.GothamBlack)


-- 글씨 카드: 미리 구운 글씨 이미지(Kit.SIGN_H)가 있으면 데칼로. 판(p) 바깥면 앞에 얇은 투명 판을 비율에 맞춰 둠
-- (SurfaceGui 는 간판이 천 개를 넘으면 편집 화면에서 글씨가 안 그려지는 일이 있었음)
local function textCard(b, boardPart, text, fg, wMax, hMax, outZ)
	-- 세로로 긴 판이면 세로 글씨 이미지
	local e = (hMax > wMax * 1.5 and Kit.SIGN_V and Kit.SIGN_V[text]) or (Kit.SIGN_H and Kit.SIGN_H[text])
	if not e then return false end
	local th = hMax
	local tw = th * e[2]
	if tw > wMax then tw = wMax th = tw / e[2] end
	local c = Instance.new("Part")
	c.Name, c.Anchored, c.CanCollide, c.CanTouch, c.CanQuery, c.CastShadow = "SignText", true, false, false, false, false
	c.Transparency = 1
	c.Size = Vector3.new(tw, th, 0.02)
	c.CFrame = boardPart.CFrame * CFrame.new(0, 0, outZ)
	local d = Instance.new("Decal")
	d.Texture = e[1]
	d.Face = Enum.NormalId.Back
	d.Color3 = fg or Color3.new(1, 1, 1)
	d.Parent = c
	c.Parent = boardPart.Parent
	b.count += 1
	return true
end
Kit.textCard = textCard

-- 한글 간판 (면 좌표). bg 배경색, fg 글자색. glow 면 조명 영향 없이 밝게(네온 느낌)
function F:signKR(cx, y, w, h, text, bg, fg, z, glow)
	local b = self.b
	local p = self:box("Signs", "Sign", cx, y, (z or 0.25), w, h, 0.5, bg, MS.SmoothPlastic)
	if textCard(b, p, text, fg, w * 0.9, h * 0.7, 0.27) then return p end
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	g.LightInfluence = glow and 0 or 1
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.FontFace = KR_FONT
	t.TextColor3 = fg or Color3.new(1, 1, 1)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.08, 0), UDim.new(0.08, 0)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.03, 0), UDim.new(0.03, 0)
	pad.Parent = t
	-- TextScaled 는 최대 100px 이라 PixelsPerStud 를 간판 높이에 맞춰 글자가 판을 채우게
	g.PixelsPerStud = math.clamp(math.floor(110 / h), 10, 60)
	t.Parent = g
	g.Parent = p
	return p
end

-- 창문 시트지 글자 (유리 위 투명 판)
function F:windowText(o, text, color)
	local w, h = o.x1 - o.x0, o.y1 - o.y0
	local p = self:box("Signs", "WindowText", (o.x0 + o.x1) / 2, (o.y0 + o.y1) / 2, -0.25, w - 0.6, h * 0.5, 0.05, Color3.new(1, 1, 1), MS.SmoothPlastic,
		{transparency = 1, deco = true, noShadow = true})
	if textCard(self.b, p, text, color or Color3.fromRGB(255, 230, 120), w - 1, h * 0.4, 0.04) then return end
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 30
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.FontFace = KR_FONT
	t.TextColor3 = color or Color3.fromRGB(255, 230, 120)
	t.TextStrokeTransparency = 0.6
	t.Parent = g
	g.Parent = p
end


---------------------------------------------------------------- 폐허 디테일 도구
local RUBC = {Color3.fromRGB(150, 146, 140), Color3.fromRGB(122, 118, 112), Color3.fromRGB(176, 166, 150), Color3.fromRGB(96, 92, 88)}
local PLANK = {Color3.fromRGB(112, 86, 60), Color3.fromRGB(94, 72, 52), Color3.fromRGB(128, 100, 70)}
-- 무너진 입구: 잔해 더미(입구 높이의 절반쯤) + 기운 콘크리트판 + 판자 못질 + 출입금지 테이프. o = F:open 결과
function F:collapsedEntrance(o, rng)
	local b = self.b
	rng = rng or b.rng
	local cx, w, h = (o.x0 + o.x1) / 2, o.x1 - o.x0, o.y1 - o.y0
	-- 잔해 더미
	for i = 1, rng:NextInteger(8, 13) do
		local sz = rng:NextNumber(0.8, 2.6)
		local x = cx + rng:NextNumber(-w / 2 - 1, w / 2 + 1)
		local z = rng:NextNumber(0.2, 3.2)
		local y = o.y0 + sz * 0.3 + math.max(0, (3.2 - z)) * rng:NextNumber(0.2, 0.9)
		local rb = self:box("Rubble", "Rubble", x, y, z, sz * rng:NextNumber(0.8, 1.5), sz * rng:NextNumber(0.4, 0.9), sz, RUBC[rng:NextInteger(1, #RUBC)], rng:NextNumber() < 0.5 and MS.Concrete or MS.Slate)
		rb.CFrame *= CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5))
	end
	-- 떨어져 기댄 콘크리트판 (입구 앞을 비스듬히 막음)
	local slab = self:box("Rubble", "FallenSlab", cx + rng:NextNumber(-0.5, 0.5), o.y0 + h * 0.4, 1.4, w + 2, h * 0.9, 0.7, Color3.fromRGB(160, 156, 148), MS.Concrete)
	slab.CFrame *= CFrame.Angles(math.rad(rng:NextNumber(18, 32)), 0, math.rad(rng:NextNumber(-12, 12)))
	-- 철근
	for i = 1, 3 do
		local rb = self:box("Rubble", "Rebar", cx + rng:NextNumber(-w / 2, w / 2), o.y0 + h * rng:NextNumber(0.3, 0.8), 1.8, 0.15, rng:NextNumber(2, 4), 0.15, Color3.fromRGB(110, 70, 50), MS.CorrodedMetal, {deco = true})
		rb.CFrame *= CFrame.Angles(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
	end
	-- 판자 못질 (입구 위쪽 남은 틈)
	for k = 1, rng:NextInteger(2, 3) do
		local pl = self:box("Rubble", "Plank", cx, o.y0 + h * (0.55 + 0.15 * k), 0.15 + k * 0.06, w + 1.2, 0.6, 0.15, PLANK[rng:NextInteger(1, #PLANK)], MS.WoodPlanks)
		pl.CFrame *= CFrame.Angles(0, 0, math.rad(rng:NextNumber(-14, 14)))
	end
	-- 출입금지 테이프 (노랑·검정, X 자)
	for _, a in ipairs({-1, 1}) do
		local tp = self:box("Rubble", "Tape", cx, o.y0 + h * 0.5, 0.5, math.sqrt(w * w + h * h) * 0.9, 0.35, 0.03, Color3.fromRGB(230, 190, 30), MS.SmoothPlastic, {deco = true, noShadow = true})
		tp.CFrame *= CFrame.Angles(0, 0, a * math.atan2(h, w))
	end
end

-- 창에 판자 못질 (3D). opening 파트(Openings 폴더) 앞 벽면에
function Kit.boardWindow(part, rng)
	local look = part.CFrame.LookVector
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local walls = part.Parent and part.Parent.Parent and part.Parent.Parent:FindFirstChild("Walls")
	if not walls then return end
	rp.FilterDescendantsInstances = {walls}
	-- 바깥(-Look 가 정면... 면 cf 의 Z = 바깥) → 면 좌표에서 바깥은 +Z = -LookVector
	local out = -look
	local hit = workspace:Raycast(part.Position + out * 3, -out * 6, rp)
	local base = hit and (hit.Position + out * 0.12) or (part.Position + out * 0.7)
	local w, h = part.Size.X, part.Size.Y
	local f = part.Parent
	for k = 1, rng:NextInteger(2, 4) do
		local pl = Instance.new("Part")
		pl.Name, pl.Anchored = "Plank", true
		pl.Size = Vector3.new(w + rng:NextNumber(0.6, 1.4), rng:NextNumber(0.45, 0.7), 0.14)
		pl.Color, pl.Material = PLANK[rng:NextInteger(1, #PLANK)], MS.WoodPlanks
		local y = -h / 2 + h * (k - 0.5) / 3.2 + rng:NextNumber(-0.3, 0.3)
		pl.CFrame = CFrame.lookAt(base, base - out) * CFrame.new(0, y, -0.08 * k) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12)))
		pl.Parent = f
	end
end

-- 실외기 무리 (면 좌표): 벽에 받침대 + 실외기, 배관
function F:acCluster(x, y, n, rng)
	local b = self.b
	rng = rng or b.rng
	for i = 1, n do
		local ax, ay = x + (i - 1) * 3 * (rng:NextNumber() < 0.5 and 1 or -1) + rng:NextNumber(-0.3, 0.3), y + rng:NextNumber(-1, 1)
		if math.abs(ax) < self.w / 2 - 1.5 then
			self:box("Decor", "ACUnit", ax, ay, 0.9, 2.4, 1.8, 1.2, Color3.fromRGB(222, 222, 218):Lerp(Color3.fromRGB(150, 140, 120), rng:NextNumber(0, 0.4)), MS.SmoothPlastic)
			self:box("Decor", "ACGrille", ax - 0.3, ay, 1.52, 1.3, 1.3, 0.05, Color3.fromRGB(70, 72, 76), MS.DiamondPlate)
			self:box("Decor", "ACRack", ax, ay - 1.0, 0.9, 2.6, 0.15, 1.4, Color3.fromRGB(90, 90, 92), MS.Metal)
			self:box("Decor", "ACPipe", ax + 1.4, ay + 1.5, 0.25, 0.25, 3, 0.25, Color3.fromRGB(200, 200, 196), MS.SmoothPlastic)
		end
	end
end

local VILLA_NAMES = {"청솔빌라", "한빛빌라", "드림하우스", "그린빌", "해피하우스", "은하빌라", "세종빌라", "미래하우스", "샛별빌라", "다온빌", "로즈빌", "현대빌라"}
local VILLA_WALLS = {
	{Color3.fromRGB(150, 78, 60), MS.Brick}, {Color3.fromRGB(128, 70, 56), MS.Brick}, {Color3.fromRGB(196, 168, 138), MS.Brick},
	{Color3.fromRGB(176, 150, 126), MS.Brick}, {Color3.fromRGB(214, 210, 200), MS.CeramicTiles}, {Color3.fromRGB(190, 186, 176), MS.CeramicTiles},
}
local CONC = Color3.fromRGB(196, 192, 184)
local GASY = Color3.fromRGB(226, 182, 40)

-- 다세대 빌라: 1층 필로티 주차 + 위 3~4층. 정면 창, 실외기, 가스관, 옥상 초록 방수·파란 물탱크
Kit.TYPES.villa_kr = function(b)
	local p = b.p
	local wc = b:pick(VILLA_WALLS)
	b.pal = {wall = wc[1], trim = CONC, base = Color3.fromRGB(120, 116, 110)}
	b.wallMat = wc[2]
	local W = p.w or b.rng:NextInteger(26, 40)
	local D = p.d or b.rng:NextInteger(26, 38)
	local floors = p.floors or b.rng:NextInteger(4, 5)
	local G, FH = 10, 9
	local H = G + FH * (floors - 1)
	local up = CFrame.new(0, G, 0)
	local faces = b:shell(W, D, H - G, 1, up)
	-- 필로티: 바닥 슬래브 아래면, 기둥, 뒤쪽 벽, 계단실
	b:part("Structure", "Soffit", Vector3.new(W, 0.8, D), CFrame.new(0, G - 0.4, 0), CONC, MS.Concrete)
	-- 주차 바닥 (인도 높이 0.7 위) + 주차선
	b:part("Structure", "ParkingFloor", Vector3.new(W - 0.4, 0.2, D - 0.4), CFrame.new(0, 0.8, 0), Color3.fromRGB(120, 118, 114), MS.Concrete)
	local stall = 9
	local nSt = math.max(1, math.floor((W - 2) / stall))
	local x0s = -((nSt * stall) / 2)
	local lineLen = math.min(14, D * 0.55)
	for k = 0, nSt do
		b:part("Structure", "ParkingLine", Vector3.new(0.35, 0.03, lineLen), CFrame.new(x0s + k * stall, 0.92, -D / 2 + 1 + lineLen / 2), Color3.fromRGB(226, 224, 216), MS.SmoothPlastic, {deco = true})
	end
	for k = 1, nSt do -- 바퀴 멈춤턱
		b:part("Structure", "WheelStop", Vector3.new(4, 0.4, 0.6), CFrame.new(x0s + (k - 0.5) * stall, 1.1, -D / 2 + 1 + lineLen - 1), Color3.fromRGB(230, 200, 40), MS.Concrete)
	end
	b.stalls = {x0 = x0s, n = nSt, w = stall, z = -D / 2 + 1 + lineLen / 2}
	for _, x in ipairs({-W / 2 + 0.7, W / 2 - 0.7}) do
		b:part("Structure", "Pillar", Vector3.new(1.3, G - 0.8, 1.3), CFrame.new(x, (G - 0.8) / 2, -D / 2 + 0.7), CONC, MS.Concrete)
	end
	b:part("Walls", "Wall", Vector3.new(W, G - 0.8, 1), CFrame.new(0, (G - 0.8) / 2, D / 2 - 0.5), wc[1], wc[2])
	local coreW, coreD = math.min(10, W * 0.32), math.min(12, D * 0.4)
	local cx = -W / 2 + coreW / 2 + 0.5
	local core = b:face(Vector3.new(cx, 0, D / 2 - coreD), Vector3.new(0, 0, -1), coreW, G - 0.8)
	local cdoor = core:open(0, 0.9, 4, 7.4, "Door", "shop_broken", {recess = 0.3})
	core:buildWall(1)
	core:collapsedEntrance(cdoor)
	b:part("Walls", "Wall", Vector3.new(1, G - 0.8, coreD), CFrame.new(cx + coreW / 2 - 0.5, (G - 0.8) / 2, D / 2 - coreD / 2), wc[1], wc[2])
	core:signKR(0, 8.4, coreW - 1, 1.4, b:pick(VILLA_NAMES), Color3.fromRGB(40, 44, 50), Color3.fromRGB(240, 236, 220))
	-- 위층: 층마다 창 개수·크기를 바꾸고(불규칙), 일부 층은 작은 발코니, 층 사이 콘크리트 띠
	local f = faces.front
	local stoneBand = b:chance(0.6)
	for fl = 1, floors - 1 do
		local y0 = FH * (fl - 1)
		local nWin = b.rng:NextInteger(W >= 34 and 2 or 2, W >= 34 and 4 or 3)
		local xs = {}
		local tot = 0
		for i = 1, nWin do xs[i] = b.rng:NextNumber(0.7, 1.3) tot += xs[i] end
		local xx = -W / 2 + 1.5
		for i = 1, nWin do
			local slot = (W - 3) * xs[i] / tot
			local x = xx + slot / 2
			xx += slot
			local wide = slot > 9 and b:chance(0.6)
			local ww = math.min(slot - 2.4, wide and b.rng:NextNumber(6, 8.5) or b.rng:NextNumber(3, 4.5))
			local wh = wide and 5 or b.rng:NextNumber(3.6, 5)
			local o = f:open(x, y0 + 2.2, ww, wh, "Window", wide and "win_kr_wide" or b:pick({"win_kr_bars", "win_kr_bars_b", "win_kr_plain"}))
			f:box("Trim", "Sill", x, y0 + 2.0, 0.2, ww + 0.4, 0.3, 0.4, CONC, MS.Concrete)
			if wide and fl >= 2 and b:chance(0.35) then -- 작은 발코니 (난간)
				f:box("Balconies", "Slab", x, y0 + 1.7, 1.4, ww + 1, 0.4, 2.8, CONC, MS.Concrete)
				local rl = f:box("Balconies", "Railing", x, y0 + 3.3, 2.75, ww + 1, 3, 0.1, Color3.fromRGB(60, 60, 64), MS.Metal, {transparency = 1})
				b:decal(rl, "rail_iron", Enum.NormalId.Back) b:decal(rl, "rail_iron", Enum.NormalId.Front)
				f:box("Balconies", "Handrail", x, y0 + 4.8, 2.75, ww + 1, 0.18, 0.2, Color3.fromRGB(60, 60, 64), MS.Metal)
			elseif b:chance(0.45) then -- 실외기
				local ax = x + (ww / 2 + 1.6) * (b:chance(0.5) and 1 or -1)
				if math.abs(ax) < W / 2 - 1.5 then
					f:box("Decor", "ACUnit", ax, y0 + 1.6, 0.9, 2.4, 1.8, 1.2, Color3.fromRGB(226, 226, 222), MS.SmoothPlastic)
					f:box("Decor", "ACGrille", ax - 0.3, y0 + 1.6, 1.52, 1.3, 1.3, 0.05, Color3.fromRGB(70, 72, 76), MS.DiamondPlate)
				end
			end
		end
		if stoneBand and fl < floors - 1 then
			f:box("Trim", "FloorBand", 0, y0 + FH - 0.3, 0.12, W + 0.3, 0.9, 0.24, CONC, MS.Concrete)
		end
	end
	-- 2층 정면 중앙 세로 줄눈 기둥 (벽돌 건물 장식)
	if wc[2] == MS.Brick and b:chance(0.5) then
		f:box("Trim", "Pier", b.rng:NextNumber(-W / 6, W / 6), (H - G) / 2, 0.15, 1.4, H - G, 0.3, CONC, MS.Concrete)
	end
	-- 현관 캐노피
	b:part("Trim", "EntryCanopy", Vector3.new(coreW + 1, 0.4, 3), CFrame.new(cx, 8.2, D / 2 - coreD - 1.4), Color3.fromRGB(70, 74, 78), MS.Metal)
	f:buildWall(1)
	for _, side in ipairs({"left", "right", "back"}) do
		local s = faces[side]
		local n = math.max(1, math.floor(s.w / 12))
		for fl = 1, floors - 1 do
			for i = 1, n do
				s:open(-s.w / 2 + s.w * (i - 0.5) / n, FH * (fl - 1) + 2.2, 4, 4.5, "Window", b:pick({"win_kr_bars", "win_kr_plain"}))
			end
		end
		s:buildFlat(1)
	end
	-- 가스관 (노란 관): 오른쪽 옆면 세로 + 층마다 가로
	local r = faces.right
	r:box("Decor", "GasPipe", r.w / 2 - 2, (H - G) / 2 - 1, 0.35, 0.35, H - G + 2, 0.35, GASY, MS.Metal)
	for fl = 1, floors - 1 do
		r:box("Decor", "GasPipe", r.w / 2 - 5, FH * (fl - 1) + 1.0, 0.35, 6, 0.3, 0.3, GASY, MS.Metal)
	end
	-- 홈통
	f:box("Decor", "Drain", W / 2 - 0.4, (H - G) / 2, 0.3, 0.4, H - G, 0.4, Color3.fromRGB(150, 150, 150), MS.SmoothPlastic)
	-- 층 띠, 옥상
	for _, s in pairs(faces) do s:band(-0.2, 0.6, 0.3, CONC, 0.3, MS.Concrete) end
	b:part("Roof", "GreenProof", Vector3.new(W - 2, 0.1, D - 2), CFrame.new(0, H + 0.05, 0), Color3.fromRGB(86, 132, 92), MS.SmoothPlastic)
	if b:chance(0.55) then -- 일조권 사선(서울 빌라 특유의 뒤가 깎인 꼭대기층): 옥상 뒤쪽에 비스듬한 벽 + 다락 창
		local sd = D * 0.45
		local roofW = Instance.new("WedgePart")
		roofW.Name, roofW.Anchored = "SetbackRoof", true
		roofW.Size = Vector3.new(W, 7, sd)
		roofW.CFrame = CFrame.new(0, H + 3.5, D / 2 - sd / 2) * CFrame.Angles(0, math.pi, 0)
		roofW.Color = b:pick({Color3.fromRGB(70, 74, 86), Color3.fromRGB(120, 66, 58), wc[1]})
		roofW.Material = b:pick({MS.RoofShingles, MS.Slate, wc[2]})
		roofW.Parent = b:folder("Roof")
		b:part("Walls", "Wall", Vector3.new(W, 7, 1), CFrame.new(0, H + 3.5, D / 2 - sd - 0.5), wc[1], wc[2])
		local aw = b:face(Vector3.new(0, H, D / 2 - sd - 1.05), Vector3.new(0, 0, -1), W, 7)
		local c = aw:box("Openings", "Window", b.rng:NextNumber(-W / 4, W / 4), 3.5, 0.03, 4, 3.6, 0.05, Color3.fromRGB(20, 22, 26), MS.SmoothPlastic)
		b:decal(c, "win_kr_plain", Enum.NormalId.Back)
	end
	b:roofTop(W, D, H - G, {origin = up, hut = false, parapet = 1.2, color = wc[1], mat = wc[2]})
	local tx, tz = b.rng:NextNumber(-W / 4, W / 4), b.rng:NextNumber(0, D / 4)
	b:part("Roof", "WaterTank", Vector3.new(5, 4.6, 4.6), CFrame.new(tx, H + 2.8, tz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 96, 168), MS.SmoothPlastic, {shape = Enum.PartType.Cylinder})
	b:part("Roof", "TankStand", Vector3.new(5, 0.5, 5), CFrame.new(tx, H + 0.35, tz), CONC, MS.Concrete)
	-- 필로티 아래 차: 주차칸에 맞춰 0~2대, 검은색·흰색만
	local st = b.stalls
	if st then
		local used = {}
		for i = 1, b.rng:NextInteger(0, math.min(2, st.n)) do
			local k = b.rng:NextInteger(1, st.n)
			if not used[k] then
				used[k] = true
				local yaw = (b:chance(0.5) and 0 or math.pi) + math.rad(b.rng:NextNumber(-6, 6))
				b:prop(b:pick({"RbxSedanBlack", "RbxSedanWhite", "RbxSUVBlack", "RbxSedanBlack"}), CFrame.new(st.x0 + (k - 0.5) * st.w + b.rng:NextNumber(-0.6, 0.6), 0.9, st.z) * CFrame.Angles(0, yaw, 0))
			end
		end
	end
	-- 필로티 안쪽 빈 공간 (주차칸 뒤 ~ 뒷벽): 자전거 거치대 + 잡동사니
	do
		local zBack = D / 2 - 1
		local zFront = -D / 2 + 1 + math.min(14, D * 0.55)
		local depth = zBack - zFront
		local xL, xR = cx + coreW / 2 + 1.2, W / 2 - 1.2
		if depth >= 6 and xR - xL >= 5 then
			local nRack = math.clamp(math.floor((xR - xL) / 2.2) - 1, 2, 7)
			local rackX = (xL + xR) / 2 + b.rng:NextNumber(-1, 1)
			Kit.bikeRack(b:folder("Props"), CFrame.new(rackX, 0.9, zBack - 3.4), nRack, {seed = b.rng:NextInteger(1, 1e6), fill = b.rng:NextNumber(0.3, 0.8), roof = false})
			-- 잡동사니: 스티로폼 텃밭·재활용 봉투·양동이 (코어 옆, 거치대 옆)
			if b:chance(0.6) then Kit.plantSpot(b:folder("Props"), CFrame.new(xR - 2.5, 0.9, zFront + 2.5), {seed = b.rng:NextInteger(1, 1e6)}) end
			if b:chance(0.5) then Kit.rubbleMix(b:folder("Props"), CFrame.new(b.rng:NextNumber(xL, xR), 0.9, zFront + b.rng:NextNumber(1, depth - 6)), {seed = b.rng:NextInteger(1, 1e6), spread = 2}) end
			if b:chance(0.6) then b:prop("TrashPile", CFrame.new(cx + coreW / 2 + 2, 0.9, zFront + 2)) end
		end
	end
	-- 옆·뒤 실외기 무리, 위성 안테나
	for _, side in ipairs({"left", "right", "back"}) do
		if b:chance(0.6) then
			local sf = faces[side]
			sf:acCluster(b.rng:NextNumber(-sf.w / 3, sf.w / 3), FH * b.rng:NextInteger(0, floors - 2) + 1.6, b.rng:NextInteger(1, 3))
		end
	end
	if b:chance(0.4) then
		local dx, dz = b.rng:NextNumber(-W / 3, W / 3), b.rng:NextNumber(-D / 3, 0)
		b:part("Roof", "DishPole", Vector3.new(0.3, 3, 0.3), CFrame.new(dx, H + 1.5, dz), Color3.fromRGB(150, 150, 150), MS.Metal)
		b:part("Roof", "Dish", Vector3.new(0.4, 3, 3), CFrame.new(dx, H + 3, dz) * CFrame.Angles(0, b.rng:NextNumber(0, 6), math.rad(70)), Color3.fromRGB(226, 226, 222), MS.SmoothPlastic, {shape = Enum.PartType.Cylinder})
	end
	return {W = W, D = D, H = H}
end

local SHOP_GROUND = {"행복치킨", "24시 편의점", "우리약국", "한빛부동산", "온누리세탁", "명가김밥", "참숯구이", "꽃담 꽃집", "밝은안경", "동네정육점", "해피헤어", "왕만두분식", "철물점", "엄마반찬"}
local SHOP_UPPER = {"블루PC방", "스타노래연습장", "탑수학학원", "튼튼치과", "참좋은내과", "용감한태권도", "피아노교습소", "당구장", "영어전문학원", "한의원", "스크린골프", "독서실", "필라테스"}
local SIGN_BG = {Color3.fromRGB(200, 40, 40), Color3.fromRGB(30, 80, 170), Color3.fromRGB(240, 180, 30), Color3.fromRGB(30, 140, 80), Color3.fromRGB(240, 110, 30),
	Color3.fromRGB(120, 40, 140), Color3.fromRGB(20, 20, 24), Color3.fromRGB(240, 240, 236)}
local SHOP_WALLS = {
	{Color3.fromRGB(214, 210, 202), MS.Concrete}, {Color3.fromRGB(196, 186, 170), MS.Granite}, {Color3.fromRGB(226, 222, 214), MS.CeramicTiles},
	{Color3.fromRGB(150, 146, 140), MS.Granite}, {Color3.fromRGB(176, 120, 96), MS.Brick},
}
local AWN_KR = {
	{Color3.fromRGB(40, 90, 150), Color3.fromRGB(230, 230, 226)}, {Color3.fromRGB(190, 50, 46), Color3.fromRGB(236, 232, 224)},
	{Color3.fromRGB(40, 120, 70), Color3.fromRGB(230, 230, 220)}, {Color3.fromRGB(230, 150, 40), Color3.fromRGB(240, 236, 226)},
}
local function fgFor(bg) return (bg.R + bg.G + bg.B > 2.2) and Color3.fromRGB(30, 30, 34) or Color3.new(1, 1, 1) end

-- 근린상가: 1층 상점 1~2칸 + 위층 학원·PC방 등. 층마다 간판, 세로 간판, 창문 글씨
Kit.TYPES.shop_kr = function(b)
	-- 근린상가 (강남 이면도로 상가 사진 참고): 층마다 다른 창 배치, 타일 색 띠, 창마다 붙은 간판·시트지, 세로 현수막, 1층 가게 2~3칸 + 계단 출입구
	local p = b.p
	local wc = b:pick(SHOP_WALLS)
	b.pal = {wall = wc[1], trim = Color3.fromRGB(230, 228, 222), base = Color3.fromRGB(90, 90, 92)}
	b.wallMat = wc[2]
	local W = p.w or b.rng:NextInteger(26, 44)
	local D = p.d or b.rng:NextInteger(24, 36)
	local floors = p.floors or b.rng:NextInteger(4, 6)
	local G, FH = 12, 10
	local H = G + FH * (floors - 1)
	local faces = b:shell(W, D, H)
	local f = faces.front
	-- 1층: 계단 출입구(좁은 문) + 가게 1~3칸, 칸마다 다른 차양/간판
	local stairW = 5
	local stairX = (b:chance(0.5) and -1 or 1) * (W / 2 - stairW / 2 - 1)
	local sdoor = f:open(stairX, 0.6, 3.6, 8.2, "Door", "shop_broken", {recess = 0.8})
	b.stairDoor = sdoor
	f:signKR(stairX, 9.6, stairW - 0.6, 1.0, b:pick({"2F~5F", "층별안내", "주차불가", "↑ 계단"}), Color3.fromRGB(30, 30, 34), Color3.fromRGB(240, 240, 230), 0.3)
	local avail = W - stairW - 2
	local x = stairX < 0 and (-W / 2 + stairW + 1) or (-W / 2 + 1)
	local nShop = math.clamp(math.floor(avail / 11), 1, 3)
	for i = 1, nShop do
		local sw = avail / nShop
		local cx = x + sw * (i - 0.5)
		f:open(cx, 0.6, sw - 1.6, 8.6, "Shopfront", b:chance(b.decay * 0.6) and "shop_broken" or "shop_clean", {recess = 0.6})
		local bg = b:pick(SIGN_BG)
		f:signKR(cx, 10.5, sw - 0.6, 2.2, b:pick(SHOP_GROUND), bg, fgFor(bg), 0.55)
		if b:chance(0.4) then local c = b:pick(AWN_KR) f:awning(cx, 9.3, sw - 1.4, 3, c[1], c[2]) end
	end
	-- 위층: 층마다 배치 무늬를 고름
	local bandC = {wc[1]:Lerp(Color3.new(0, 0, 0), 0.18), wc[1]:Lerp(Color3.new(1, 1, 1), 0.2), Color3.fromRGB(120, 84, 66), Color3.fromRGB(196, 190, 176)}
	for fl = 2, floors do
		local y0 = G + FH * (fl - 2)
		local pattern = b:pick({"ribbon", "multi", "multi", "vertical"})
		local wins = {}
		if pattern == "ribbon" then
			table.insert(wins, f:open(0, y0 + 2.4, W - 6, 5.0, "Window", b:pick({"win_kr_wide", "win_kr_wide", "win_modern_wide"})))
		elseif pattern == "multi" then
			local n = b.rng:NextInteger(2, 4)
			local slots = {}
			local tot = 0
			for k = 1, n do slots[k] = b.rng:NextNumber(0.6, 1.4) tot += slots[k] end
			local span = W - 4
			local xx = -W / 2 + 2
			for k = 1, n do
				local ww = span * slots[k] / tot
				local winW = math.max(3, ww - b.rng:NextNumber(1.2, 2.6))
				local winH = b.rng:NextNumber(4.0, 5.6)
				table.insert(wins, f:open(xx + ww / 2, y0 + 2.2, winW, winH, "Window", winW > 6 and "win_kr_wide" or b:pick({"win_kr_plain", "win_kr_bars", "win_modern_a"})))
				xx += ww
			end
		else
			local n = math.max(2, math.floor((W - 4) / 5.5))
			for k = 1, n do
				local cx = -W / 2 + 2 + (W - 4) * (k - 0.5) / n
				table.insert(wins, f:open(cx, y0 + 1.6, 3, 6.6, "Window", "win_modern_b"))
				if k < n then f:box("Trim", "Pilaster", cx + (W - 4) / n / 2, y0 + FH / 2, 0.3, 0.9, FH, 0.6, b.pal.trim, MS.Concrete) end
			end
		end
		-- 층 띠 (창 아래 벽에 다른 색 타일)
		if b:chance(0.65) then
			f:box("Trim", "TileBand", 0, y0 + 1.0, 0.08, W + 0.2, 1.6, 0.16, b:pick(bandC), b:pick({MS.CeramicTiles, MS.Concrete, MS.Granite}))
		end
		-- 간판: 창 위 가로 간판 1~2개 (폭 들쭉날쭉) + 창 시트지
		local nSign = b.rng:NextInteger(1, 2)
		for k = 1, nSign do
			local bg = b:pick(SIGN_BG)
			local sw = b.rng:NextNumber(W * 0.3, W * (nSign == 1 and 0.9 or 0.45))
			local sx = nSign == 1 and b.rng:NextNumber(-(W - sw) / 2, (W - sw) / 2) or ((k == 1 and -1 or 1) * (W / 4))
			f:signKR(sx, y0 + 8.7, sw, b.rng:NextNumber(1.3, 1.9), b:pick(SHOP_UPPER), bg, fgFor(bg), 0.35 + k * 0.05)
		end
		for _, o in ipairs(wins) do
			if b:chance(0.55) then f:windowText(o, b:pick(SHOP_UPPER), b:pick({Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 140)})) end
		end
		-- 실외기
		if b:chance(0.4) then
			local ax = b.rng:NextNumber(-W / 2 + 2, W / 2 - 2)
			f:box("Decor", "ACUnit", ax, y0 + 1.2, 0.8, 2.4, 1.8, 1.2, Color3.fromRGB(226, 226, 222), MS.SmoothPlastic)
		end
	end
	f:buildWall(1)
	f:collapsedEntrance(b.stairDoor)
	for _, side in ipairs({"left", "right", "back"}) do
		if b:chance(0.65) then
			local sf = faces[side]
			sf:acCluster(b.rng:NextNumber(-sf.w / 3, sf.w / 3), G + FH * b.rng:NextInteger(0, floors - 2) + 1.4, b.rng:NextInteger(2, 4))
		end
	end
	-- 세로 현수막·세로 간판 (1~3개, 정면 가장자리·기둥 위)
	for k = 1, b.rng:NextInteger(1, 3) do
		local bg = b:pick(SIGN_BG)
		local hx = (k == 1) and (W / 2 - 1.2) or b.rng:NextNumber(-W / 2 + 2, W / 2 - 2)
		if k == 1 then
			f:bladeSign(hx, G, math.min(FH * (floors - 1) - 2, 24), b:pick({"노래방", "PC방", "모텔", "당구장", "치킨", "호프", "학원", "병원"}), bg, fgFor(bg))
		else
			local y0 = G + b.rng:NextNumber(0, FH * (floors - 2))
			f:signKR(hx, y0 + 4, 2.2, 7, b:pick({"PC방", "노래방", "당구장", "학원", "병원", "치킨", "호프"}), bg, fgFor(bg), 0.5)
		end
	end
	for _, side in ipairs({"left", "right", "back"}) do
		local s2 = faces[side]
		local n = math.max(1, math.floor(s2.w / 10))
		for fl = 2, floors do
			for i = 1, n do
				if b:chance(0.75) then s2:open(-s2.w / 2 + s2.w * (i - 0.5) / n + b.rng:NextNumber(-1.5, 1.5), G + FH * (fl - 2) + 2.6, b:pick({3, 4, 5}), 4.5, "Window", b:pick({"win_kr_plain", "win_kr_bars"})) end
			end
		end
		s2:buildFlat(1)
	end
	-- 옆면 큰 세로 간판판 (모퉁이 건물 느낌)
	if b:chance(0.35) then
		local r = faces.right
		local bg = b:pick(SIGN_BG)
		r:signKR(-r.w / 2 + 3, G + FH * (floors - 1) / 2, 3.5, math.min(FH * (floors - 1) - 3, 22), b:pick({"병원", "학원", "모텔", "PC방", "노래방"}), bg, fgFor(bg), 0.5)
	end
	for _, s2 in pairs(faces) do s2:band(G - 0.6, 0.6, 0.4, b.pal.trim, 0.4, MS.Concrete) end
	b:roofTop(W, D, H, {hut = b:chance(0.6), parapet = b.rng:NextNumber(1.0, 2.4)})
	-- 옥상 광고판 틀 / 상가 교회 십자가
	if b:chance(0.25) then
		local bg = b:pick(SIGN_BG)
		b:part("Signs", "RoofFrame", Vector3.new(0.6, 8, 0.6), CFrame.new(-W / 4, H + 4, 0), Color3.fromRGB(70, 70, 74), MS.Metal)
		b:part("Signs", "RoofFrame", Vector3.new(0.6, 8, 0.6), CFrame.new(W / 4, H + 4, 0), Color3.fromRGB(70, 70, 74), MS.Metal)
		local rf = b:face(Vector3.new(0, H + 5, -0.4), Vector3.new(0, 0, -1), W * 0.7, 6)
		rf:signKR(0, 3, W * 0.7, 5, b:pick({"분양중", "임대", "SALE", "병원", "학원"}), bg, fgFor(bg), 0.2)
	elseif b:chance(0.15) then
		local cxr, czr = b.rng:NextNumber(-W / 4, W / 4), b.rng:NextNumber(-D / 4, D / 4)
		b:part("Signs", "Cross", Vector3.new(0.8, 12, 0.8), CFrame.new(cxr, H + 7.5, czr), Color3.fromRGB(255, 40, 40), MS.Neon)
		b:part("Signs", "Cross", Vector3.new(6, 0.8, 0.8), CFrame.new(cxr, H + 10, czr), Color3.fromRGB(255, 40, 40), MS.Neon)
	end
	return {W = W, D = D, H = H}
end

Kit.SEOUL_TYPES = {"villa_kr", "shop_kr"}

---------------------------------------------------------------- 3등급(먼 건물): 상자 1개 + 창문 반복 텍스처
Kit.TEX.facade_kr_tile = "rbxassetid://119651586588236"
Kit.TEX.facade_office_tile = "rbxassetid://129408307466706"
local BOX_COLS = {Color3.fromRGB(196, 186, 172), Color3.fromRGB(176, 120, 100), Color3.fromRGB(206, 204, 198), Color3.fromRGB(160, 150, 138), Color3.fromRGB(190, 170, 150)}
local OFFICE_COLS = {Color3.fromRGB(150, 160, 170), Color3.fromRGB(120, 132, 146), Color3.fromRGB(176, 180, 184)}
Kit.TYPES.box_simple = function(b)
	local p = b.p
	local office = p.office
	local W, D = p.w or 30, p.d or 30
	local FH = office and 10 or 9
	local floors = p.floors or 4
	local H = floors * FH + 2
	local col = office and b:pick(OFFICE_COLS) or b:pick(BOX_COLS)
	b.pal = {wall = col, trim = Color3.fromRGB(210, 208, 202), base = Color3.fromRGB(100, 100, 100)}
	local body = b:part("Walls", "Wall", Vector3.new(W, H, D), CFrame.new(0, H / 2, 0), col, MS.Concrete)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right}) do
		local t = Instance.new("Texture")
		t.Texture = office and Kit.TEX.facade_office_tile or Kit.TEX.facade_kr_tile
		t.Face = face
		t.StudsPerTileU, t.StudsPerTileV = office and 8 or 10, FH
		t.OffsetStudsV = (H - 2) % FH
		t.Color3 = col:Lerp(Color3.new(1, 1, 1), 0.25)
		t.Parent = body
	end
	b:part("Roof", "RoofCap", Vector3.new(W + 0.6, 1.2, D + 0.6), CFrame.new(0, H + 0.6, 0), b.pal.trim, MS.Concrete)
	-- 1층 가게 띠 + 간판 띠 (정면만): 멀리서도 상자가 아니라 상가로 보이게
	if not office or b:chance(0.5) then
		local gf = b:part("Walls", "ShopStrip", Vector3.new(W - 1, 8, 0.4), CFrame.new(0, 4.6, -D / 2 - 0.15), Color3.fromRGB(30, 32, 36), MS.SmoothPlastic)
		local t = Instance.new("Texture") t.Texture = Kit.TEX.shop_clean t.Face = Enum.NormalId.Front t.StudsPerTileU, t.StudsPerTileV = 12, 8 t.Parent = gf
		local sb = b:part("Signs", "SignBand", Vector3.new(W - 1, 1.8, 0.5), CFrame.new(0, 9.6, -D / 2 - 0.2), b:pick(SIGN_BG), MS.SmoothPlastic)
	end
	-- 정면·옆 실외기 (텍스처 상자의 밋밋함 줄이기)
	for _, sgn in ipairs({-1, 1}) do
		for i = 1, b.rng:NextInteger(1, 4) do
			local y = FH * b.rng:NextInteger(1, math.max(1, floors - 1)) + 1.5
			local x = b.rng:NextNumber(-W / 2 + 2, W / 2 - 2)
			b:part("Decor", "ACUnit", Vector3.new(2.4, 1.8, 1.2), CFrame.new(x, y, sgn * (D / 2 + 0.6)), Color3.fromRGB(222, 222, 218), MS.SmoothPlastic)
		end
	end
	b:part("Decor", "Drain", Vector3.new(0.4, H, 0.4), CFrame.new(W / 2 - 0.5, H / 2, -D / 2 - 0.25), Color3.fromRGB(150, 150, 150), MS.SmoothPlastic)
	-- 층 띠 2~3개 (다른 색)
	for k = 1, b.rng:NextInteger(0, 2) do
		local y = b.rng:NextInteger(2, math.max(2, floors - 1)) * FH
		b:part("Trim", "Band", Vector3.new(W + 0.4, 1, D + 0.4), CFrame.new(0, y, 0), col:Lerp(Color3.new(0, 0, 0), 0.2), MS.Concrete)
	end
	if b:chance(0.5) then b:prop("RoofAC", CFrame.new(b.rng:NextNumber(-W / 3, W / 3), H + 1.2, b.rng:NextNumber(-D / 3, D / 3))) end
	return {W = W, D = D, H = H}
end
