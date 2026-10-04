---------------------------------------------------------------- 건물 종류 2차 (5~31). kit.luau 뒤에 이어 붙여 실행 (deploy.sh)
local M2 = Enum.Material
local IRON2 = Color3.fromRGB(28, 28, 30)
local GLASS2 = Color3.fromRGB(170, 205, 215)
local fy = Kit.floorY
local function pastel(b) return Kit.PALETTES[b:pick(Kit.PASTELS)] end

-- 5. 돌출창(오리엘) 아파트: 짝수 칸 2층~꼭대기에 튀어나온 창 상자
Kit.TYPES.apt_bay = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(4, 5)
	local G, FH = 13, 12
	local H = G + FH * (floors - 1)
	local bays = p.bays or b.rng:NextInteger(4, 5)
	local W = p.w or bays * 8 + 4
	local D = p.d or 30
	local bw = (W - 4) / bays
	local faces = b:shell(W, D, H)
	local f = faces.front
	local door = math.ceil(bays / 2)
	for fl = 1, floors do
		local y0 = fy(G, FH, fl)
		for i = 1, bays do
			local cx = -W / 2 + 2 + bw * (i - 0.5)
			local oriel = (i % 2 == 0) and fl >= 2
			if fl == 1 then
				if i == door then f:open(cx, 0.6, 4.4, 9, "Door", b:pick({"door_green", "door_red"}), {recess = 0.7})
				else f:windowTrim(f:open(cx, 3.6, 4, 6, "Window", b:winTex()), "lintel") end
			elseif not oriel then
				local o = f:open(cx, y0 + 2.8, 4, 6, "Window", b:winTex())
				f:windowTrim(o, "frame")
				if b:chance(0.4) then f:flowerbox(o) end
			end
		end
	end
	f:buildWall(1)
	-- 오리엘: 칸마다 2층~꼭대기 한 덩어리 상자 (앞면 창 + 옆면 좁은 창)
	for i = 2, bays, 2 do
		local cx = -W / 2 + 2 + bw * (i - 0.5)
		local ow, od = math.min(bw - 1, 6.4), 2.4
		local y0, y1 = G, H - 1.5
		local of = b:face(f.cf * Vector3.new(cx, y0, od), f.cf.ZVector, ow, y1 - y0)
		for fl = 2, floors do
			local yy = fy(G, FH, fl) - y0
			local o = of:open(0, yy + 2.8, 4, 6, "Window", b:winTex())
			of:windowTrim(o, "lintel")
		end
		of:buildWall(1)
		for _, sx in ipairs({-1, 1}) do
			local sideX = cx + sx * (ow / 2 - 0.5)
			f:box("Walls", "OrielSide", sideX, (y0 + y1) / 2, od / 2, 1, y1 - y0, od, b.pal.wall, b.wallMat)
			for fl = 2, floors do
				local yy = fy(G, FH, fl)
				local card = f:box("Openings", "OrielSideWin", sideX + sx * 0.52, yy + 5.3, od / 2, 0.06, 5, 1.3, Color3.fromRGB(20, 22, 26), M2.SmoothPlastic)
				b:decal(card, b:winTex(), sx < 0 and Enum.NormalId.Left or Enum.NormalId.Right)
			end
		end
		f:box("Trim", "OrielBase", cx, y0 - 0.5, od / 2, ow + 0.6, 1, od + 0.6, b.pal.trim, M2.SmoothPlastic)
		f:box("Trim", "OrielCorbel", cx, y0 - 1.6, od / 2 - 0.3, ow - 1, 1.2, od - 0.6, b.pal.trim, M2.SmoothPlastic)
		f:box("Trim", "OrielTop", cx, y1 + 0.3, od / 2, ow + 0.6, 0.6, od + 0.6, b.pal.trim, M2.SmoothPlastic)
	end
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = floors})
	for _, s in pairs(faces) do s:band(G - 0.5, 0.6, 0.35) end
	b:plinth(faces, 2.4)
	b:cornice(faces, H, false)
	b:roofTop(W, D, H)
	if b:chance(0.3 + b.decay * 0.5) then f:vines(-W / 2 + b.rng:NextNumber(3, W - 3), H - 1.2, 6, b.rng:NextNumber(10, 18)) end
	return {W = W, D = D, H = H}
end

-- 6. 박공 정면 연립주택: 좁고 3층, 앞쪽으로 박공(삼각 지붕면)
Kit.TYPES.rowhouse_gable = function(b)
	local p = b.p
	local floors = p.floors or 3
	local G, FH = 12, 11
	local H = G + FH * (floors - 1)
	local W = p.w or b.rng:NextInteger(16, 19)
	local D = p.d or 26
	local faces = b:shell(W, D, H)
	local f = faces.front
	local shut = b:pick({Color3.fromRGB(60, 90, 80), Color3.fromRGB(90, 60, 70), Color3.fromRGB(70, 80, 110), Color3.fromRGB(240, 238, 230)})
	local dx = b:chance(0.5) and -W / 4 or W / 4
	f:open(dx, 1.2, 4.2, 8.6, "Door", b:pick({"door_green", "door_red"}), {recess = 0.7})
	f:box("Trim", "Step", dx, 0.6, 1.0, 5.4, 1.2, 2.0, b.pal.base, M2.Concrete)
	f:box("Trim", "DoorHood", dx, 10.6, 0.9, 5.8, 0.5, 1.8, b.pal.trim, M2.SmoothPlastic)
	local o = f:open(-dx, 3.4, 4, 6, "Window", b:winTex())
	f:windowTrim(o, "lintel") f:shutters(o, shut)
	for fl = 2, floors do
		local y0 = fy(G, FH, fl)
		for _, x in ipairs({-W / 4, W / 4}) do
			local w = f:open(x, y0 + 2.5, 4, 6, "Window", b:winTex())
			f:windowTrim(w, "lintel") f:shutters(w, shut)
			if fl == 2 and b:chance(0.5) then f:flowerbox(w) end
		end
	end
	f:buildWall(1)
	b:simpleFaces(faces, {"back"}, {G = G, FH = FH, floors = floors})
	faces.left:buildFlat(1) faces.right:buildFlat(1)
	b:plinth({front = f}, 1.6)
	for _, s in pairs(faces) do s:band(H - 0.6, 0.6, 0.5) end
	local roofC = b:pick({Color3.fromRGB(70, 74, 86), Color3.fromRGB(120, 66, 58), Color3.fromRGB(90, 60, 52)})
	local R = b:gableRoof(CFrame.new(0, H, 0) * CFrame.Angles(0, math.pi / 2, 0), D, W, {pitch = 40, color = roofC, mat = b:pick({M2.ClayRoofTiles, M2.RoofShingles}), overhang = 1.0})
	-- 다락 창 (박공 삼각면 위)
	local card = f:box("Openings", "AtticWin", 0, H + R * 0.32, 0.06, 2.6, 3.4, 0.1, Color3.fromRGB(20, 22, 26), M2.SmoothPlastic)
	b:decal(card, b:winTex(), Enum.NormalId.Back)
	-- 굴뚝
	b:part("Roof", "Chimney", Vector3.new(2.4, R + 3, 2.4), CFrame.new(W / 2 - 2.5, H + (R + 3) / 2, D / 6), Color3.fromRGB(140, 72, 58), M2.Brick)
	return {W = W, D = D, H = H + R}
end

-- 7. 현대식 아파트: 흰 콘크리트, 층마다 긴 발코니 + 유리 난간, 넓은 창
local MODERN_WALL = {Color3.fromRGB(236, 234, 228), Color3.fromRGB(214, 212, 206), Color3.fromRGB(196, 200, 204)}
Kit.TYPES.apt_modern = function(b)
	local p = b.p
	b.pal = {wall = b:pick(MODERN_WALL), trim = Color3.fromRGB(250, 250, 248), base = Color3.fromRGB(90, 92, 96)}
	b.wallMat = M2.SmoothPlastic
	local floors = p.floors or b.rng:NextInteger(6, 8)
	local G, FH = 13, 11
	local H = G + FH * (floors - 1)
	local bays = p.bays or b.rng:NextInteger(4, 6)
	local W = p.w or bays * 10 + 4
	local D = p.d or 32
	local bw = (W - 4) / bays
	local accent = b:pick({Color3.fromRGB(176, 120, 80), Color3.fromRGB(110, 140, 160), Color3.fromRGB(200, 150, 110)})
	local faces = b:shell(W, D, H)
	local f = faces.front
	for i = 1, bays do
		local cx = -W / 2 + 2 + bw * (i - 0.5)
		if i == math.ceil(bays / 2) then f:open(cx, 0.6, 8, 9.5, "Lobby", "shop_clean", {recess = 0.8})
		else f:open(cx, 3, 8, 6, "Window", b:chance(b.decay * 0.3) and "win_broken" or "win_modern_wide") end
		for fl = 2, floors do
			f:open(cx, fy(G, FH, fl) + 1.2, 8, 7.4, "Window", b:chance(b.decay * 0.25) and "win_broken" or "win_modern_wide")
		end
	end
	f:buildWall(1)
	-- 칸 사이 나무 패널 띠
	for i = 0, bays do
		f:box("Trim", "WoodFin", -W / 2 + 2 + bw * i, H / 2 + G / 2, 0.3, 1.2, H - G, 0.6, accent, M2.WoodPlanks)
	end
	-- 층마다 긴 발코니 (유리 난간)
	local bwid = W - 4
	for fl = 2, floors do
		local y = fy(G, FH, fl)
		f:box("Balconies", "Slab", 0, y - 0.3, 1.8, bwid, 0.6, 3.6, b.pal.trim, M2.SmoothPlastic)
		f:box("Balconies", "GlassRail", 0, y + 1.7, 3.5, bwid, 3.2, 0.15, GLASS2, M2.Glass, {transparency = 0.55})
		f:box("Balconies", "Handrail", 0, y + 3.35, 3.5, bwid, 0.15, 0.2, Color3.fromRGB(180, 182, 186), M2.Metal)
		for _, sx in ipairs({-1, 1}) do
			f:box("Balconies", "GlassRail", sx * (bwid / 2 - 0.1), y + 1.7, 1.8, 0.15, 3.2, 3.4, GLASS2, M2.Glass, {transparency = 0.55})
		end
		if b:chance(0.5) then b:prop("Planter_small", f.cf * CFrame.new(b.rng:NextNumber(-bwid / 2 + 2, bwid / 2 - 2), y, 2.4)) end
	end
	f:box("Trim", "EntryCanopy", -W / 2 + 2 + bw * (math.ceil(bays / 2) - 0.5), 10.8, 2, bw + 1, 0.6, 4, b.pal.trim, M2.SmoothPlastic)
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = floors, sill = 2.5, tex = function(bb) return bb:pick({"win_modern_a", "win_modern_b"}) end})
	b:roofTop(W, D, H, {parapet = 1.2})
	return {W = W, D = D, H = H}
end

-- 8. 주거 타워: 10~14층, 모서리 발코니, 세로 색띠
Kit.TYPES.apt_tower = function(b)
	local p = b.p
	b.pal = {wall = b:pick(MODERN_WALL), trim = Color3.fromRGB(250, 250, 248), base = Color3.fromRGB(90, 92, 96)}
	b.wallMat = M2.SmoothPlastic
	local floors = p.floors or b.rng:NextInteger(10, 14)
	local G, FH = 14, 11
	local H = G + FH * (floors - 1)
	local W = p.w or 40
	local D = p.d or 40
	local accent = b:pick({Color3.fromRGB(232, 160, 150), Color3.fromRGB(150, 196, 214), Color3.fromRGB(240, 210, 140), Color3.fromRGB(170, 200, 170)})
	local faces = b:shell(W, D, H)
	for name, s in pairs(faces) do
		local cnt = math.max(2, math.floor(s.w / 9))
		if name == "front" then s:open(0, 0.6, 12, 10, "Lobby", "shop_clean", {recess = 0.8}) end
		for fl = 2, floors do
			for i = 1, cnt do
				s:open(-s.w / 2 + s.w * (i - 0.5) / cnt, fy(G, FH, fl) + 2.5, 4, 6, "Window", b:chance(b.decay * 0.25) and "win_broken" or b:pick({"win_modern_a", "win_modern_b"}))
			end
		end
		if name == "front" then s:buildWall(1) else s:buildFlat(1) end
		-- 세로 색띠 (가운데)
		s:box("Trim", "ColorStripe", 0, (G + H) / 2, 0.15, 3, H - G, 0.3, accent, M2.SmoothPlastic)
	end
	-- 모서리 발코니 (앞 두 모서리)
	local f = faces.front
	for fl = 2, floors do
		local y = fy(G, FH, fl)
		for _, sx in ipairs({-1, 1}) do
			local cx = sx * (W / 2 - 4.5)
			f:box("Balconies", "Slab", cx, y - 0.3, 1.6, 9, 0.6, 3.2, b.pal.trim, M2.SmoothPlastic)
			f:box("Balconies", "GlassRail", cx, y + 1.7, 3.1, 9, 3.2, 0.15, GLASS2, M2.Glass, {transparency = 0.55})
		end
	end
	f:box("Trim", "EntryCanopy", 0, 11.2, 2.2, 16, 0.6, 4.4, b.pal.trim, M2.SmoothPlastic)
	for _, s in pairs(faces) do s:band(G - 0.6, 0.6, 0.4, accent) s:band(H - 1.2, 1.2, 0.5) end
	b:roofTop(W, D, H, {parapet = 1.5, tank = true})
	b:part("Roof", "Antenna", Vector3.new(0.4, 16, 0.4), CFrame.new(W / 4, H + 8, -D / 4), Color3.fromRGB(80, 80, 84), M2.Metal)
	return {W = W, D = D, H = H}
end

-- 9. 교외 단독주택: 2층, 박공지붕, 포치, 옆 차고
local SIDING = {Color3.fromRGB(236, 226, 206), Color3.fromRGB(196, 216, 224), Color3.fromRGB(226, 200, 196), Color3.fromRGB(214, 224, 200), Color3.fromRGB(240, 232, 190)}
Kit.TYPES.house_suburban = function(b)
	local p = b.p
	b.pal = {wall = b:pick(SIDING), trim = Color3.fromRGB(246, 244, 238), base = Color3.fromRGB(130, 120, 110)}
	b.wallMat = M2.WoodPlanks
	local G, FH = 11, 10
	local H = G + FH
	local W = p.w or b.rng:NextInteger(26, 30)
	local D = p.d or 22
	local shut = b:pick({Color3.fromRGB(50, 70, 64), Color3.fromRGB(110, 50, 50), Color3.fromRGB(50, 60, 90)})
	local faces = b:shell(W, D, H)
	local f = faces.front
	local dx = -W / 2 + 7
	f:open(dx, 1.2, 4.2, 8.4, "Door", b:pick({"door_green", "door_red"}), {recess = 0.6})
	for _, x in ipairs({dx + 8, dx + 15}) do
		if x < W / 2 - 3 then local o = f:open(x, 3.4, 4, 5.6, "Window", b:winTex()) f:windowTrim(o, "frame") f:shutters(o, shut) end
	end
	for _, x in ipairs({-W / 3, 0, W / 3}) do
		local o = f:open(x, G + 2, 4, 5.6, "Window", b:winTex())
		f:windowTrim(o, "frame") f:shutters(o, shut)
	end
	f:buildWall(1)
	f:porch(dx + 2, 12, 6, 8.6, {rail = true, roofColor = b.pal.trim})
	b:simpleFaces(faces, {"left", "back", "right"}, {G = G, FH = FH, floors = 2, ground = true, sill = 2.6, ww = 4, wh = 5.6, spacing = 10})
	b:plinth(faces, 1.2)
	local roofC = b:pick({Color3.fromRGB(70, 74, 86), Color3.fromRGB(96, 70, 60), Color3.fromRGB(60, 66, 60)})
	local R = b:gableRoof(CFrame.new(0, H, 0), W, D, {pitch = 30, color = roofC, mat = M2.RoofShingles})
	b:part("Roof", "Chimney", Vector3.new(2.6, R + 4, 2.6), CFrame.new(W / 2 - 4, H + (R + 4) / 2 - 1, 2), Color3.fromRGB(150, 80, 64), M2.Brick)
	-- 차고 날개 (오른쪽)
	local GW, GD, GH = 14, 20, 11
	local gO = CFrame.new(W / 2 + GW / 2, 0, (D - GD) / 2)
	local gf = b:face(gO * Vector3.new(0, 0, -GD / 2), Vector3.new(0, 0, -1), GW, GH)
	gf:open(0, 0, 10.5, 9, "Garage", b:chance(b.decay) and "garage_rust" or "garage_grey", {recess = 0.5})
	gf:buildWall(1)
	b:part("Walls", "GarageSide", Vector3.new(1, GH, GD), gO * CFrame.new(GW / 2 - 0.5, GH / 2, 0), b.pal.wall, b.wallMat)
	b:part("Walls", "GarageBack", Vector3.new(GW, GH, 1), gO * CFrame.new(0, GH / 2, GD / 2 - 0.5), b.pal.wall, b.wallMat)
	b:gableRoof(gO * CFrame.new(0, GH, 0) * CFrame.Angles(0, math.pi / 2, 0), GD, GW, {pitch = 26, color = roofC, mat = M2.RoofShingles, overhang = 0.8})
	-- 진입로
	b:part("Decor", "Driveway", Vector3.new(11, 0.2, 8), gO * CFrame.new(0, 0.1, -GD / 2 - 4), Color3.fromRGB(150, 146, 140), M2.Concrete, {deco = false})
	b:shift(-GW / 2, 0)
	return {W = W + GW, D = D, H = H + R}
end

-- 10. 단층 방갈로: 앞면 전체 포치
Kit.TYPES.house_bungalow = function(b)
	local p = b.p
	b.pal = {wall = b:pick(SIDING), trim = Color3.fromRGB(246, 244, 238), base = Color3.fromRGB(130, 120, 110)}
	b.wallMat = M2.WoodPlanks
	local H = 11
	local W = p.w or b.rng:NextInteger(22, 26)
	local D = p.d or 20
	local faces = b:shell(W, D, H)
	local f = faces.front
	local shut = b:pick({Color3.fromRGB(50, 70, 64), Color3.fromRGB(110, 50, 50), Color3.fromRGB(50, 60, 90)})
	f:open(0, 1.2, 4.2, 8.4, "Door", b:pick({"door_green", "door_red"}), {recess = 0.6})
	for _, x in ipairs({-W / 3, W / 3}) do local o = f:open(x, 3.4, 4, 5.6, "Window", b:winTex()) f:windowTrim(o, "frame") f:shutters(o, shut) end
	f:buildWall(1)
	f:porch(0, W - 2, 6, 7.8, {rail = b:chance(0.5)})
	b:simpleFaces(faces, {"left", "back", "right"}, {G = 0, FH = 0, floors = 1, ground = true, sill = 3.2, ww = 4, wh = 5.4, spacing = 9})
	b:plinth(faces, 1.2)
	local R = b:gableRoof(CFrame.new(0, H, 0), W, D, {pitch = 28, color = b:pick({Color3.fromRGB(70, 74, 86), Color3.fromRGB(110, 70, 56)}), mat = M2.RoofShingles, overhang = 1.6})
	b:part("Roof", "Chimney", Vector3.new(2.4, R + 3, 2.4), CFrame.new(-W / 2 + 4, H + (R + 3) / 2 - 1, 3), Color3.fromRGB(150, 80, 64), M2.Brick)
	return {W = W, D = D, H = H + R}
end

-- 11. 2세대 주택(듀플렉스): 좌우 대칭, 문 2개
Kit.TYPES.duplex = function(b)
	local p = b.p
	b.pal = {wall = b:pick(SIDING), trim = Color3.fromRGB(246, 244, 238), base = Color3.fromRGB(150, 80, 64)}
	b.wallMat = M2.WoodPlanks
	local G, FH = 11, 10
	local H = G + FH
	local W = p.w or 32
	local D = p.d or 24
	local faces = b:shell(W, D, H)
	local f = faces.front
	local dc = b:pick({"door_green", "door_red"})
	for _, sx in ipairs({-1, 1}) do
		local dx = sx * 3.5
		f:open(dx, 1.2, 4, 8.4, "Door", dc, {recess = 0.6})
		f:box("Trim", "DoorHood", dx, 10.2, 1.0, 5.2, 0.5, 2.0, b.pal.trim, M2.SmoothPlastic)
		f:box("Trim", "Step", dx, 0.6, 1.0, 5, 1.2, 2, Color3.fromRGB(150, 146, 140), M2.Concrete)
		local o = f:open(sx * (W / 2 - 6), 3.4, 6, 5.6, "Window", "win_modern_wide")
		f:windowTrim(o, "frame")
		for _, x in ipairs({sx * 4, sx * (W / 2 - 6)}) do
			local u = f:open(x, G + 2, 4, 5.6, "Window", b:winTex())
			f:windowTrim(u, "frame")
		end
	end
	f:buildWall(1)
	-- 1층 벽돌 띠 (앞면)
	f:box("Trim", "BrickBase", 0, 1.5, 0.15, W + 0.4, 3, 0.3, Color3.fromRGB(150, 80, 64), M2.Brick)
	b:simpleFaces(faces, {"left", "back", "right"}, {G = G, FH = FH, floors = 2, ground = true, sill = 2.6, ww = 4, wh = 5.6, spacing = 10})
	b:plinth(faces, 1.0)
	local R = b:gableRoof(CFrame.new(0, H, 0), W, D, {pitch = 30, color = Color3.fromRGB(80, 80, 90), mat = M2.RoofShingles})
	return {W = W, D = D, H = H + R}
end

-- 12. 좁은 다층집: 폭 12~14, 층마다 키 큰 창 + 줄리엣 발코니
Kit.TYPES.walkup_narrow = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(4, 5)
	local G, FH = 12, 11
	local H = G + FH * (floors - 1)
	local W = p.w or b.rng:NextInteger(12, 14)
	local D = p.d or 26
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 0.6, 4.4, 9, "Door", b:pick({"door_green", "door_red"}), {recess = 0.7})
	f:box("Trim", "DoorHood", 0, 10.4, 1.0, 6, 0.5, 2, b.pal.trim, M2.SmoothPlastic)
	for fl = 2, floors do
		local y0 = fy(G, FH, fl)
		local o = f:open(0, y0 + 1.6, 4, 7.5, "Window", b:chance(b.decay * 0.3) and "win_broken" or b:pick({"win_tall_a", "win_tall_b"}))
		f:windowTrim(o, fl == floors and "pediment" or "lintel")
		local r = f:box("Balconies", "JulietRail", 0, y0 + 2.6, 0.8, 5.4, 2.8, 0.1, IRON2, M2.Metal, {transparency = 1})
		b:decal(r, "rail_iron", Enum.NormalId.Back) b:decal(r, "rail_iron", Enum.NormalId.Front)
		f:box("Balconies", "JulietBase", 0, y0 + 1.1, 0.5, 5.6, 0.3, 1.0, b.pal.trim, M2.SmoothPlastic)
		f:box("Balconies", "Handrail", 0, y0 + 4.0, 0.8, 5.4, 0.18, 0.2, IRON2, M2.Metal)
	end
	f:buildWall(1)
	b:simpleFaces(faces, {"back"}, {G = G, FH = FH, floors = floors, spacing = 7})
	faces.left:buildFlat(1) faces.right:buildFlat(1)
	b:plinth({front = f}, 2.0)
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	if b:chance(0.4 + b.decay * 0.4) then f:vines(b.rng:NextNumber(-3, 3), H - 1.4, 5, b.rng:NextNumber(10, 20)) end
	return {W = W, D = D, H = H}
end

-- 13. 단층 상가 줄: 상점 3~5칸, 차양·간판
local AWN = {
	{Color3.fromRGB(46, 98, 84), Color3.fromRGB(240, 234, 220)}, {Color3.fromRGB(176, 58, 64), Color3.fromRGB(240, 234, 220)},
	{Color3.fromRGB(46, 70, 120), Color3.fromRGB(236, 230, 214)}, {Color3.fromRGB(214, 150, 60), Color3.fromRGB(246, 238, 220)},
	{Color3.fromRGB(226, 130, 150), Color3.fromRGB(250, 240, 240)},
}
local SHOPS2 = {"CAFE", "BAKERY", "MARKET", "PHARMACY", "BOOKS", "FLOWERS", "DELI", "HARDWARE", "LAUNDRY", "DINER", "TOYS", "PIZZA", "BARBER", "GIFTS", "SHOES", "ICE CREAM"}
Kit.TYPES.shop_row = function(b)
	local p = b.p
	local n = p.shops or b.rng:NextInteger(3, 5)
	local H = 16
	local W = p.w or n * 14 + 2
	local D = p.d or 24
	local faces = b:shell(W, D, H)
	local f = faces.front
	local u = (W - 2) / n
	for i = 1, n do
		local cx = -W / 2 + 1 + u * (i - 0.5)
		f:open(cx, 1.0, u - 2, 9.2, "Shopfront", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 0.6})
		local c = b:pick(AWN)
		if b:chance(0.8) then f:awning(cx, 11.2, u - 2.4, 4, c[1], c[2]) end
		f:sign(cx, 13.3, u - 3, 2.0, b:pick(SHOPS2), c[1], Color3.fromRGB(250, 244, 230))
	end
	f:buildWall(1)
	for i = 0, n do f:box("Trim", "ShopPier", -W / 2 + 1 + u * i, 7, 0.25, 1.4, 14, 0.5, b.pal.trim, M2.SmoothPlastic) end
	for _, side in ipairs({"left", "right", "back"}) do faces[side]:buildFlat(1) end
	b:cornice(faces, H, false)
	b:roofTop(W, D, H, {hut = false, parapet = 1.5})
	return {W = W, D = D, H = H}
end

-- 14. 카페 (2층): 큰 유리, 넓은 차양, 테라스 테이블
Kit.TYPES.cafe_terrace = function(b)
	local p = b.p
	local G, FH = 14, 11
	local H = G + FH
	local W = p.w or 30
	local D = p.d or 26
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(-W / 4, 1.0, W / 2 - 3, 9.2, "Shopfront", "shop_clean", {recess = 0.6})
	f:open(W / 4, 1.0, W / 2 - 3, 9.2, "Shopfront", "shop_clean", {recess = 0.6})
	for _, x in ipairs({-W / 3, 0, W / 3}) do
		local o = f:open(x, G + 2.6, 4, 6, "Window", b:winTex())
		f:windowTrim(o, "frame") f:flowerbox(o)
	end
	f:buildWall(1)
	local c = b:pick(AWN)
	f:awning(0, 11.4, W - 2, 5, c[1], c[2])
	f:sign(0, 13.0, 12, 1.8, b:pick({"CAFE", "COFFEE", "BISTRO", "TEA HOUSE"}), Color3.fromRGB(36, 40, 44))
	for i = -1, 1 do b:prop("CafeTable", f.cf * CFrame.new(i * W / 3, 0, 8)) end
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = 2})
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	return {W = W, D = D, H = H}
end

-- 15. 편의점: 전면 유리, 큰 간판 띠
Kit.TYPES.convenience_store = function(b)
	local p = b.p
	local H = 14
	local W = p.w or 40
	local D = p.d or 32
	b.pal = {wall = Color3.fromRGB(232, 230, 224), trim = Color3.fromRGB(250, 250, 248), base = Color3.fromRGB(110, 110, 112)}
	b.wallMat = M2.SmoothPlastic
	local brand = b:pick({{"24/7 MART", Color3.fromRGB(220, 60, 50)}, {"QUICK STOP", Color3.fromRGB(40, 120, 70)}, {"CORNER MART", Color3.fromRGB(240, 150, 40)}, {"MINI MARKET", Color3.fromRGB(50, 90, 170)}})
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(-W / 4 + 1, 1.0, W / 2 - 4, 8.4, "Shopfront", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 0.4})
	f:open(W / 4 - 1, 1.0, W / 2 - 4, 8.4, "Shopfront", "shop_clean", {recess = 0.4})
	f:buildWall(1)
	f:box("Signs", "SignBand", 0, 11.4, 0.4, W + 0.4, 3.2, 0.8, brand[2], M2.SmoothPlastic)
	f:sign(0, 11.4, W * 0.6, 2.4, brand[1], brand[2], Color3.fromRGB(255, 255, 255))
	f:box("Trim", "Canopy", 0, 9.7, 2, W, 0.4, 4, Color3.fromRGB(240, 240, 238), M2.SmoothPlastic)
	f:box("Decor", "IceBox", W / 2 - 3, 2.2, 1.8, 4, 4.4, 2.4, Color3.fromRGB(230, 236, 240), M2.SmoothPlastic)
	local ice = f:sign(W / 2 - 3, 3.4, 3.4, 1.2, "ICE", Color3.fromRGB(60, 130, 200), Color3.fromRGB(255, 255, 255))
	ice.CFrame *= CFrame.new(0, 0, 2.9)
	for side, s in pairs(faces) do if side ~= "front" then s:buildFlat(1) s:band(H - 3, 0.8, 0.3, brand[2]) end end
	b:roofTop(W, D, H, {hut = false, parapet = 1.2})
	return {W = W, D = D, H = H}
end

-- 16. 주유소: 캐노피 + 주유기 + 뒤쪽 매점
Kit.TYPES.gas_station = function(b)
	local p = b.p
	local W = p.w or 50
	local D = p.d or 44
	b.pal = {wall = Color3.fromRGB(236, 234, 228), trim = Color3.fromRGB(250, 250, 248), base = Color3.fromRGB(110, 110, 112)}
	b.wallMat = M2.SmoothPlastic
	local col = b:pick({Color3.fromRGB(214, 60, 52), Color3.fromRGB(40, 110, 180), Color3.fromRGB(46, 140, 80), Color3.fromRGB(240, 170, 40)})
	local name = b:pick({"GAS", "FUEL", "SUPER GAS", "PETRO"})
	-- 캐노피 (앞쪽)
	local cz = -D / 2 + 13
	for _, x in ipairs({-11, 11}) do for _, z in ipairs({-5, 5}) do
		b:part("Canopy", "Pillar", Vector3.new(1.4, 14, 1.4), CFrame.new(x, 7, cz + z), Color3.fromRGB(236, 236, 232), M2.SmoothPlastic)
	end end
	b:part("Canopy", "CanopyRoof", Vector3.new(32, 1, 20), CFrame.new(0, 14.5, cz), Color3.fromRGB(240, 240, 238), M2.SmoothPlastic)
	b:part("Canopy", "Fascia", Vector3.new(32.4, 2.4, 20.4), CFrame.new(0, 15.9, cz), col, M2.SmoothPlastic)
	local cf = b:face(Vector3.new(0, 14.7, cz - 10.2), Vector3.new(0, 0, -1), 32, 3)
	cf:sign(0, 1.2, 12, 2.0, name, col, Color3.fromRGB(255, 255, 255))
	for _, x in ipairs({-11, 11}) do
		b:part("Canopy", "Island", Vector3.new(2.2, 0.6, 10), CFrame.new(x, 0.3, cz), Color3.fromRGB(200, 196, 188), M2.Concrete)
		for _, z in ipairs({-2.5, 2.5}) do b:prop("FuelPump", CFrame.new(x, 0.6, cz + z)) end
	end
	-- 매점 (뒤쪽)
	local KW, KD, KH = 26, 14, 12
	local kO = CFrame.new(0, 0, D / 2 - KD / 2)
	local faces = b:shell(KW, KD, KH, 1, kO)
	faces.front:open(-4, 1.0, 12, 8, "Shopfront", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 0.4})
	faces.front:buildWall(1)
	faces.front:box("Signs", "SignBand", 0, 10.4, 0.4, KW, 2.4, 0.8, col, M2.SmoothPlastic)
	faces.front:sign(0, 10.4, 12, 1.8, "SHOP", col, Color3.fromRGB(255, 255, 255))
	for side, s in pairs(faces) do if side ~= "front" then s:buildFlat(1) end end
	b:roofTop(KW, KD, KH, {origin = kO, hut = false, parapet = 1})
	-- 가격 간판 기둥
	b:part("Signs", "PricePole", Vector3.new(1, 18, 1), CFrame.new(W / 2 - 3, 9, -D / 2 + 3), Color3.fromRGB(120, 120, 124), M2.Metal)
	local ps = b:part("Signs", "PriceSign", Vector3.new(6, 6, 0.8), CFrame.new(W / 2 - 3, 18, -D / 2 + 3), col, M2.SmoothPlastic)
	local fx = b:face(Vector3.new(W / 2 - 3, 15, -D / 2 + 2.6), Vector3.new(0, 0, -1), 6, 6)
	fx:sign(0, 3, 5, 1.6, name, col, Color3.fromRGB(255, 255, 255))
	-- 바닥 (콘크리트 앞마당)
	b:part("Decor", "Forecourt", Vector3.new(W, 0.2, D), CFrame.new(0, 0.1, 0), Color3.fromRGB(176, 172, 166), M2.Concrete)
	return {W = W, D = D, H = 18}
end

-- 17. 슈퍼마켓: 큰 상자, 가운데 유리 입구, 큰 간판
Kit.TYPES.supermarket = function(b)
	local p = b.p
	local H = 18
	local W = p.w or 80
	local D = p.d or 60
	b.pal = {wall = b:pick({Color3.fromRGB(236, 226, 206), Color3.fromRGB(220, 226, 220), Color3.fromRGB(232, 214, 200)}), trim = Color3.fromRGB(250, 250, 248), base = Color3.fromRGB(110, 110, 112)}
	b.wallMat = M2.Concrete
	local brand = b:pick({{"FRESH MARKET", Color3.fromRGB(46, 140, 80)}, {"SUPER SAVE", Color3.fromRGB(214, 60, 52)}, {"FOOD TOWN", Color3.fromRGB(40, 100, 170)}})
	local faces = b:shell(W, D, H)
	local f = faces.front
	for i = -1, 1 do f:open(i * 12.5, 1.0, 12, 9.4, "Shopfront", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 0.6}) end
	f:buildWall(1)
	f:box("Trim", "EntryCanopy", 0, 11.2, 2.5, 40, 0.8, 5, Color3.fromRGB(240, 240, 238), M2.SmoothPlastic)
	f:box("Signs", "SignBack", 0, 14.6, 0.4, 44, 4.6, 0.8, brand[2], M2.SmoothPlastic)
	f:sign(0, 14.6, 40, 3.6, brand[1], brand[2], Color3.fromRGB(255, 255, 255))
	f:band(4, 1.2, 0.3, brand[2])
	for side, s in pairs(faces) do if side ~= "front" then s:buildFlat(1) s:band(4, 1.2, 0.3, brand[2]) end end
	b:roofTop(W, D, H, {hut = false, parapet = 1.5})
	-- 카트 보관대
	for i = 1, 3 do b:prop("ShoppingCart", f.cf * CFrame.new(W / 2 - 8 + i * 1.6, 0, 6)) end
	return {W = W, D = D, H = H}
end

-- 18. 유리 오피스 타워: 면마다 파트 1장 + 커튼월 타일 텍스처
Kit.TYPES.office_glass = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(10, 16)
	local G, FH = 15, 12
	local H = G + FH * (floors - 1)
	local W = p.w or 8 * b.rng:NextInteger(5, 6)
	local D = p.d or 8 * b.rng:NextInteger(4, 5) + 2
	local tex = b:pick({"curtainwall_a", "curtainwall_a", "curtainwall_green"})
	local frameC = Color3.fromRGB(150, 156, 162)
	local faces = b:shell(W, D, H)
	for name, s in pairs(faces) do
		local wall = s:box("Walls", "CurtainWall", 0, (G + H) / 2, -0.5, s.w, H - G, 1, frameC, M2.Glass)
		wall.Reflectance = 0.1
		b:texture(wall, tex, Enum.NormalId.Back, 8, 12)
		if b.decay > 0.5 and b:chance(0.4) then
			local g = s:box("Decor", "Soot", 0, (G + H) / 2, 0.05, s.w, H - G, 0.05, Color3.new(0, 0, 0), M2.SmoothPlastic, {transparency = 1, deco = true, noShadow = true})
			b:texture(g, "soot_burn", Enum.NormalId.Back, 16, 16)
		end
		-- 1층 로비
		if name == "front" then
			s:open(0, 0.5, math.min(24, s.w - 8), 11, "Lobby", "shop_clean", {recess = 1})
			s.h = G
			s:buildWall(1, Color3.fromRGB(60, 62, 66), M2.Granite)
		else
			s.h = G
			s:buildFlat(1, Color3.fromRGB(60, 62, 66), M2.Granite)
		end
		s:band(G - 0.8, 0.8, 0.6, Color3.fromRGB(200, 204, 208))
		s:band(H - 1, 2.0, 0.4, Color3.fromRGB(200, 204, 208))
	end
	faces.front:box("Trim", "EntryCanopy", 0, 12, 3, 28, 0.8, 6, Color3.fromRGB(200, 204, 208), M2.Metal)
	b:roofTop(W, D, H + 1, {parapet = 1, color = Color3.fromRGB(200, 204, 208), mat = M2.Metal})
	b:part("Roof", "MechBox", Vector3.new(W * 0.4, 6, D * 0.4), CFrame.new(0, H + 3, 0), Color3.fromRGB(130, 134, 138), M2.Metal)
	return {W = W, D = D, H = H}
end

-- 19. 중층 석조 오피스: 6층, 기둥띠 + 창 격자, 입구 캐노피
local COMPANIES = {"CITY BANK", "MERIDIAN", "ATLAS CO.", "HARBOR TRUST", "NORTHWIND", "SUNRISE INS."}
Kit.TYPES.office_mid = function(b)
	local p = b.p
	b.pal = Kit.PALETTES.stone
	b.wallMat = M2.Limestone
	local floors = p.floors or b.rng:NextInteger(5, 7)
	local G, FH = 15, 11
	local H = G + FH * (floors - 1)
	local bays = p.bays or 6
	local W = p.w or bays * 7.5 + 3
	local D = p.d or 34
	local bw = (W - 3) / bays
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 0.6, 12, 10.5, "Lobby", "shop_clean", {recess = 1})
	for i = 1, bays do
		local cx = -W / 2 + 1.5 + bw * (i - 0.5)
		if math.abs(cx) > 7 then f:open(cx, 3, 4, 7, "Window", b:pick({"win_modern_a", "win_modern_b"})) end
		for fl = 2, floors do f:open(cx, fy(G, FH, fl) + 2.2, 4, 6.4, "Window", b:chance(b.decay * 0.25) and "win_broken" or b:pick({"win_modern_a", "win_modern_b"})) end
	end
	f:buildWall(1)
	for i = 0, bays do f:box("Trim", "Pilaster", -W / 2 + 1.5 + bw * i, (G + H) / 2, 0.3, 1.2, H - G, 0.6, b.pal.trim, M2.Limestone) end
	f:box("Trim", "EntryCanopy", 0, 12, 2.6, 16, 0.7, 5.2, Color3.fromRGB(70, 72, 76), M2.Metal)
	f:sign(0, 13.4, 14, 1.6, b:pick(COMPANIES), Color3.fromRGB(40, 42, 46), Color3.fromRGB(230, 214, 170))
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = floors, sill = 2.2, wh = 6.4, spacing = 7.5, tex = function(bb) return bb:pick({"win_modern_a", "win_modern_b"}) end})
	b:plinth(faces, 3.5)
	for _, s in pairs(faces) do s:band(G - 0.8, 0.8, 0.5) end
	b:cornice(faces, H, true)
	b:roofTop(W, D, H)
	return {W = W, D = D, H = H}
end

-- 20. 은행: 고전식 열주 현관 + 삼각 박공 + 계단
Kit.TYPES.bank = function(b)
	local p = b.p
	b.pal = Kit.PALETTES.stone
	b.wallMat = M2.Limestone
	local H = 26
	local W = p.w or 44
	local D = p.d or 36
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 2.4, 6, 12, "Door", "door_green", {recess = 0.8})
	for _, x in ipairs({-W / 2 + 6, W / 2 - 6, -12, 12}) do
		local o = f:open(x, 4.5, 4, 7.5, "Window", "win_tall_a")
		f:windowTrim(o, "pediment")
		local o2 = f:open(x, 15, 4, 6, "Window", b:winTex())
		f:windowTrim(o2, "frame")
	end
	f:buildWall(1)
	-- 계단 3단 + 열주 6개 + 엔타블러처 + 박공
	local pw = W * 0.62
	for k = 1, 3 do f:box("Trim", "Stairs", 0, k * 0.8 - 0.4, 7.5 - k * 1.4, pw + 4 - k, k * 0.8, 3, b.pal.trim, M2.Limestone) end
	local n = 6
	for i = 0, n - 1 do
		f:column(-pw / 2 + 1.5 + (pw - 3) * i / (n - 1), 2.4, 17, 1.1, 5.2, b.pal.trim, M2.Marble)
	end
	f:box("Trim", "Entablature", 0, 20.6, 4, pw + 2, 2.4, 9, b.pal.trim, M2.Limestone)
	local bs = f:sign(0, 20.6, pw * 0.6, 1.8, b:pick({"NATIONAL BANK", "CITY BANK", "SAVINGS & LOAN"}), b.pal.trim, Color3.fromRGB(80, 70, 56))
	bs.CFrame *= CFrame.new(0, 0, 8.4)
	local R = 5
	for _, sx in ipairs({-1, 1}) do
		local cf = f.cf * CFrame.new(sx * (pw + 2) / 4, 21.8 + R / 2, 4) * CFrame.Angles(0, sx < 0 and math.pi / 2 or -math.pi / 2, 0)
		b:part("Trim", "Pediment", Vector3.new(9, R, (pw + 2) / 2), cf, b.pal.trim, M2.Limestone, {wedge = true})
	end
	b:simpleFaces(faces, {"left", "right", "back"}, {G = 13, FH = 13, floors = 2, ground = true, sill = 4, ww = 4, wh = 7, spacing = 9, tex = function() return "win_tall_a" end})
	b:plinth(faces, 2.4)
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	b:shift(0, 4.5) -- 열주 현관(앞 9)까지 부지 안으로
	return {W = W, D = D + 9, H = H + R}
end

-- 21. 호텔: 8~10층, 세로 간판, 입구 캐노피
Kit.TYPES.hotel = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(8, 10)
	local G, FH = 15, 11
	local H = G + FH * (floors - 1)
	local bays = p.bays or 6
	local W = p.w or bays * 7 + 4
	local D = p.d or 34
	local bw = (W - 4) / bays
	b.pal = Kit.PALETTES[b:pick({"cream", "peach", "pink", "butter"})]
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 0.6, 12, 10.5, "Lobby", "shop_clean", {recess = 1})
	for i = 1, bays do
		local cx = -W / 2 + 2 + bw * (i - 0.5)
		if math.abs(cx) > 7 then f:windowTrim(f:open(cx, 3.4, 4, 6.5, "Window", b:winTex()), "lintel") end
		for fl = 2, floors do
			local o = f:open(cx, fy(G, FH, fl) + 2.4, 4, 6, "Window", b:winTex())
			f:windowTrim(o, "frame")
			if fl >= 3 and (i + fl) % 3 == 0 then
				local r = f:box("Balconies", "JulietRail", cx, fy(G, FH, fl) + 3.4, 0.8, 5.4, 2.6, 0.1, IRON2, M2.Metal, {transparency = 1})
				b:decal(r, "rail_iron", Enum.NormalId.Back) b:decal(r, "rail_iron", Enum.NormalId.Front)
				f:box("Balconies", "JulietBase", cx, fy(G, FH, fl) + 2.0, 0.5, 5.6, 0.3, 1.0, b.pal.trim, M2.SmoothPlastic)
			end
		end
	end
	f:buildWall(1)
	f:box("Trim", "Marquise", 0, 11.4, 3.5, 16, 0.8, 7, Color3.fromRGB(150, 40, 46), M2.Fabric)
	f:box("Trim", "MarquiseTrim", 0, 10.8, 7, 16, 0.4, 0.3, Color3.fromRGB(214, 176, 90), M2.Metal)
	f:bladeSign(W / 2 - 3, G + 2, math.min(26, H - G - 4), "HOTEL", Color3.fromRGB(40, 30, 34), Color3.fromRGB(255, 180, 110))
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = floors, spacing = 7})
	b:plinth(faces, 3)
	for _, s in pairs(faces) do s:band(G - 0.7, 0.7, 0.5) end
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {tank = true})
	return {W = W, D = D, H = H}
end

-- 22. 다이너: 단층, 크롬 띠, 지붕 간판
Kit.TYPES.diner = function(b)
	local p = b.p
	local H = 13
	local W = p.w or 32
	local D = p.d or 24
	b.pal = {wall = b:pick({Color3.fromRGB(160, 214, 200), Color3.fromRGB(240, 200, 200), Color3.fromRGB(240, 226, 170)}), trim = Color3.fromRGB(220, 224, 228), base = Color3.fromRGB(120, 40, 44)}
	b.wallMat = M2.SmoothPlastic
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(-W / 2 + 7, 0.6, 4.4, 9, "Door", "shop_clean", {recess = 0.5})
	for _, x in ipairs({-2, 7, W / 2 - 5}) do f:open(x, 3.6, 7, 5.4, "Window", b:chance(b.decay * 0.4) and "win_broken" or "win_modern_wide") end
	f:buildWall(1)
	for side, s in pairs(faces) do
		if side ~= "front" then s:buildFlat(1) end
		s:band(2.4, 0.8, 0.25, b.pal.base, 0.25, M2.SmoothPlastic)
		s:band(H - 2.4, 2.4, 0.3, b.pal.trim, 0.3, M2.Metal)
	end
	for _, sx in ipairs({-1, 1}) do
		b:part("Trim", "ChromeCorner", Vector3.new(H, 2, 2), CFrame.new(sx * W / 2, H / 2, -D / 2) * CFrame.Angles(0, 0, math.pi / 2), b.pal.trim, M2.Metal, {shape = Enum.PartType.Cylinder})
	end
	b:part("Signs", "RoofSignPost", Vector3.new(0.6, 4, 0.6), CFrame.new(0, H + 2, -D / 2 + 3), IRON2, M2.Metal)
	local rs = b:face(Vector3.new(0, H + 3.5, -D / 2 + 2.6), Vector3.new(0, 0, -1), 16, 4)
	local s = rs:sign(0, 1.6, 16, 3.2, b:pick({"DINER", "EAT", "BURGERS"}), Color3.fromRGB(40, 30, 34), Color3.fromRGB(255, 110, 120))
	s:FindFirstChildOfClass("SurfaceGui").LightInfluence = 0
	b:roofTop(W, D, H, {hut = false, parapet = 0.8})
	return {W = W, D = D, H = H + 6}
end

-- 23. 의원·약국: 2층 흰 건물, 초록 십자 간판
Kit.TYPES.clinic = function(b)
	local p = b.p
	local G, FH = 12, 11
	local H = G + FH
	local W = p.w or 30
	local D = p.d or 26
	b.pal = {wall = Color3.fromRGB(240, 240, 236), trim = Color3.fromRGB(200, 214, 210), base = Color3.fromRGB(110, 120, 118)}
	b.wallMat = M2.SmoothPlastic
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(-W / 4, 0.6, 9, 9, "Lobby", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 0.6})
	f:open(W / 4, 3, 8, 6, "Window", "win_modern_wide")
	for _, x in ipairs({-W / 3, 0, W / 3}) do f:open(x, G + 2.4, 4, 6, "Window", b:pick({"win_modern_a", "win_modern_b"})) end
	f:buildWall(1)
	local name = b:pick({"PHARMACY", "CLINIC", "MEDICAL"})
	f:box("Signs", "Band", 0, 10.6, 0.3, W, 2, 0.6, Color3.fromRGB(46, 150, 90), M2.SmoothPlastic)
	f:sign(0, 10.6, W * 0.5, 1.6, name, Color3.fromRGB(46, 150, 90), Color3.fromRGB(255, 255, 255))
	-- 초록 십자 (돌출)
	local cx, cy = W / 2 - 2, G + 6
	f:box("Signs", "CrossArm", cx, cy, 2.4, 0.4, 0.4, 3, IRON2, M2.Metal)
	f:box("Signs", "CrossV", cx, cy, 4, 0.5, 4, 1.3, Color3.fromRGB(60, 220, 110), M2.Neon)
	f:box("Signs", "CrossH", cx, cy, 4, 0.5, 1.3, 4, Color3.fromRGB(60, 220, 110), M2.Neon)
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = 2, tex = function(bb) return bb:pick({"win_modern_a", "win_modern_b"}) end})
	b:roofTop(W, D, H, {hut = false, parapet = 1})
	return {W = W, D = D, H = H}
end

-- 24. 주차 빌딩: 4층 개방형, 바깥 기둥 통으로, 층 난간벽
Kit.TYPES.parking_garage = function(b)
	local p = b.p
	local levels = p.floors or 4
	local FH = 10
	local H = FH * levels
	local W = p.w or 60
	local D = p.d or 50
	local conc = Color3.fromRGB(176, 172, 164)
	for lv = 1, levels do
		local y = FH * lv
		b:part("Structure", "Deck", Vector3.new(W, 1, D), CFrame.new(0, y - 0.5, 0), conc, M2.Concrete)
		for _, s in ipairs({{0, -D / 2 + 0.4, W, 0.8}, {0, D / 2 - 0.4, W, 0.8}, {-W / 2 + 0.4, 0, 0.8, D - 1.6}, {W / 2 - 0.4, 0, 0.8, D - 1.6}}) do
			b:part("Structure", "Parapet", Vector3.new(s[3], 3.2, s[4]), CFrame.new(s[1], y + 1.6, s[2]), conc:Lerp(Color3.new(1, 1, 1), 0.15), M2.Concrete)
		end
		if b:chance(0.5) then b:prop(b:pick({"WreckCar_A", "WreckTruck", "WreckVan"}), CFrame.new(b.rng:NextNumber(-W / 3, W / 3), y, b.rng:NextNumber(-D / 4, D / 4))) end
	end
	for i = 0, 4 do for _, z in ipairs({-D / 2 + 0.8, D / 2 - 0.8}) do
		b:part("Structure", "Column", Vector3.new(1.6, H + 3, 1.6), CFrame.new(-W / 2 + 0.8 + (W - 1.6) * i / 4, (H + 3) / 2, z), conc, M2.Concrete)
	end end
	for i = 1, 2 do for _, x in ipairs({-W / 2 + 0.8, W / 2 - 0.8}) do
		b:part("Structure", "Column", Vector3.new(1.6, H + 3, 1.6), CFrame.new(x, (H + 3) / 2, -D / 2 + D * i / 3), conc, M2.Concrete)
	end end
	-- 경사로 (1층 → 2층)
	local run = 30
	b:part("Structure", "Ramp", Vector3.new(10, 1, math.sqrt(run * run + FH * FH)), CFrame.new(W / 2 - 7, FH / 2, 0) * CFrame.Angles(math.atan2(FH, run), 0, 0), conc, M2.Concrete)
	-- 계단탑 + P 간판
	b:part("Structure", "StairTower", Vector3.new(8, H + 4, 8), CFrame.new(-W / 2 + 4, (H + 4) / 2, -D / 2 + 4), Color3.fromRGB(196, 190, 180), M2.Concrete)
	local f = b:face(Vector3.new(-W / 2 + 4, 0, -D / 2 - 0.05), Vector3.new(0, 0, -1), 8, H)
	f:sign(0, H - 3, 5, 5, "P", Color3.fromRGB(40, 90, 180), Color3.fromRGB(255, 255, 255))
	b:part("Structure", "GroundSlab", Vector3.new(W, 0.3, D), CFrame.new(0, 0.15, 0), Color3.fromRGB(120, 118, 114), M2.Asphalt)
	return {W = W, D = D, H = H + 4}
end

-- 25. 극장: 마키(차양 간판) + 세로 간판 + 포스터
Kit.TYPES.cinema = function(b)
	local p = b.p
	local H = 28
	local W = p.w or 40
	local D = p.d or 44
	b.pal = Kit.PALETTES[b:pick({"coral", "butter", "mint", "brick"})]
	b.wallMat = b.pal.mat or M2.Plaster
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 0.6, 14, 9, "Lobby", b:chance(b.decay * 0.5) and "shop_broken" or "shop_clean", {recess = 1})
	for _, x in ipairs({-W / 2 + 5, W / 2 - 5}) do f:open(x, 2, 4.4, 7, "Poster", nil) end
	for _, x in ipairs({-12, -4, 4, 12}) do f:windowTrim(f:open(x, 18, 4, 6, "Window", b:winTex()), "frame") end
	f:buildWall(1)
	-- 포스터 (색 판 + 글자)
	for i, x in ipairs({-W / 2 + 5, W / 2 - 5}) do
		local ps = f:sign(x, 5.5, 4.2, 6.8, i == 1 and "ZOMBIE\nNIGHT" or "LAST\nCITY", b:pick({Color3.fromRGB(120, 30, 40), Color3.fromRGB(30, 50, 100), Color3.fromRGB(40, 80, 60)}), Color3.fromRGB(255, 230, 180))
		ps.CFrame *= CFrame.new(0, 0, 0.5)
	end
	f:box("Signs", "Marquee", 0, 12.2, 4, W * 0.8, 3.6, 8, Color3.fromRGB(244, 236, 220), M2.SmoothPlastic)
	f:box("Signs", "MarqueeLights", 0, 10.3, 8.05, W * 0.8, 0.3, 0.1, Color3.fromRGB(255, 220, 140), M2.Neon)
	f:box("Signs", "MarqueeLights", 0, 14.1, 8.05, W * 0.8, 0.3, 0.1, Color3.fromRGB(255, 220, 140), M2.Neon)
	local m = f:sign(0, 12.2, W * 0.75, 2.8, b:pick({"NOW SHOWING", "CLOSED", "SOLD OUT"}), Color3.fromRGB(244, 236, 220), Color3.fromRGB(30, 30, 34))
	m.CFrame *= CFrame.new(0, 0, 7.9)
	f:bladeSign(0, 15, 12, "CINEMA", Color3.fromRGB(40, 30, 34), Color3.fromRGB(255, 120, 130))
	b:simpleFaces(faces, {"left", "right", "back"}, {G = 14, FH = 14, floors = 2, spacing = 12})
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	return {W = W, D = D, H = H}
end

-- 26. 창고: 골함석 벽, 셔터 2~3개, 하역장, 낮은 박공
Kit.TYPES.warehouse = function(b)
	local p = b.p
	local H = 18
	local W = p.w or 60
	local D = p.d or 50
	local wc = b:pick({Color3.fromRGB(170, 176, 180), Color3.fromRGB(196, 186, 160), Color3.fromRGB(150, 170, 160), Color3.fromRGB(180, 120, 100)})
	b.pal = {wall = wc, trim = Color3.fromRGB(220, 220, 216), base = Color3.fromRGB(110, 110, 112)}
	b.wallMat = M2.Metal
	local faces = b:shell(W, D, H)
	local f = faces.front
	local nd = W >= 56 and 3 or 2
	for i = 1, nd do
		f:open(-W / 2 + W * (i - 0.5) / nd, 1.6, 11, 11, "Garage", b:chance(0.3 + b.decay * 0.5) and "garage_rust" or "garage_grey", {recess = 0.4})
	end
	f:open(W / 2 - 4, 13, 4, 3, "Window", "win_modern_b")
	f:buildWall(1)
	f:box("Trim", "Dock", 0, 0.8, 2.5, W, 1.6, 5, Color3.fromRGB(150, 146, 140), M2.Concrete)
	f:sign(-W / 4, H - 2.4, 18, 2.2, b:pick({"WAREHOUSE 3", "STORAGE", "LOGISTICS", "DEPOT"}), Color3.fromRGB(240, 240, 236), Color3.fromRGB(40, 50, 60))
	for side, s in pairs(faces) do if side ~= "front" then s:buildFlat(1) end end
	for _, w in ipairs(b:folder("Walls"):GetChildren()) do b:texture(w, "corrugated", Enum.NormalId.Back, 2, 8, wc) end
	b:gableRoof(CFrame.new(0, H, 0), W, D, {pitch = 10, color = Color3.fromRGB(150, 156, 160), mat = M2.Metal, wallColor = wc, wallMat = M2.Metal, overhang = 0.8})
	return {W = W, D = D, H = H + 5}
end

-- 27. 공장: 벽돌, 톱니 지붕, 굴뚝
Kit.TYPES.factory = function(b)
	local p = b.p
	b.pal = Kit.PALETTES[b:pick({"brick", "brickdark"})]
	b.wallMat = M2.Brick
	local H = 20
	local W = p.w or 64
	local D = p.d or 48
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(-W / 2 + 10, 0.6, 12, 12, "Garage", b:chance(b.decay) and "garage_rust" or "garage_grey", {recess = 0.5})
	for _, x in ipairs({-4, 8, 20}) do
		if x + 4 < W / 2 then
			local o = f:open(x, 6, 8, 6, "Window", b:chance(b.decay * 0.5) and "win_broken" or "win_modern_wide")
			f:windowTrim(o, "lintel")
		end
	end
	f:buildWall(1)
	f:sign(6, H - 3, 24, 2.4, b:pick({"STEEL WORKS", "TEXTILE MILL", "CANNERY", "PRINT WORKS"}), Color3.fromRGB(230, 220, 200), Color3.fromRGB(80, 40, 30))
	b:simpleFaces(faces, {"left", "right", "back"}, {G = 0, FH = 0, floors = 1, ground = true, sill = 7, ww = 8, wh = 6, spacing = 14, tex = function(bb) return bb:chance(bb.decay * 0.5) and "win_broken" or "win_modern_wide" end})
	-- 톱니 지붕: 앞→뒤로 4개. 쐐기 높은 면(+Z)이 앞쪽(-Z)을 보게 → 수직 유리면이 북쪽
	local n = 4
	local tz = (D - 2) / n
	for i = 1, n do
		local z = -D / 2 + 1 + tz * (i - 0.5)
		b:part("Roof", "Sawtooth", Vector3.new(W - 2, 6, tz), CFrame.new(0, H + 3, z) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(110, 112, 116), M2.Metal, {wedge = true})
		local g = b:part("Roof", "SawGlass", Vector3.new(W - 3, 5, 0.2), CFrame.new(0, H + 3, z - tz / 2 - 0.12), Color3.fromRGB(20, 22, 26), M2.SmoothPlastic)
		b:decal(g, "curtainwall_a", Enum.NormalId.Front)
	end
	b:roofTop(W, D, H, {hut = false, parapet = 1})
	-- 굴뚝
	local cx, cz = W / 2 - 6, D / 2 - 6
	b:part("Roof", "Chimney", Vector3.new(44, 5, 5), CFrame.new(cx, 22, cz) * CFrame.Angles(0, 0, math.pi / 2), b.pal.wall, M2.Brick, {shape = Enum.PartType.Cylinder})
	b:part("Roof", "ChimneyBand", Vector3.new(1.2, 5.6, 5.6), CFrame.new(cx, 40, cz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(60, 58, 56), M2.Metal, {shape = Enum.PartType.Cylinder})
	return {W = W, D = D, H = 44}
end

-- 28. 소방서: 붉은 벽돌, 빨간 셔터 3개, 망루
Kit.TYPES.fire_station = function(b)
	local p = b.p
	b.pal = Kit.PALETTES.brick
	b.wallMat = M2.Brick
	local G, FH = 14, 11
	local H = G + FH
	local W = p.w or 44
	local D = p.d or 40
	local faces = b:shell(W, D, H)
	local f = faces.front
	for i = -1, 1 do f:open(i * 13.5, 0.4, 11.5, 12, "Garage", "garage_red", {recess = 0.6}) end
	for i = -2, 2 do f:windowTrim(f:open(i * 8.5, G + 2.6, 4, 6, "Window", b:winTex()), "lintel") end
	f:buildWall(1)
	f:box("Signs", "SignBand", 0, 13.2, 0.4, W - 4, 1.8, 0.8, Color3.fromRGB(236, 228, 210), M2.SmoothPlastic)
	f:sign(0, 13.2, W * 0.6, 1.6, "FIRE STATION " .. b.rng:NextInteger(1, 12), Color3.fromRGB(236, 228, 210), Color3.fromRGB(150, 30, 30))
	f:box("Trim", "Apron", 0, 0.15, 6, W, 0.3, 12, Color3.fromRGB(170, 166, 160), M2.Concrete)
	b:simpleFaces(faces, {"left", "right", "back"}, {G = G, FH = FH, floors = 2, spacing = 9})
	b:plinth(faces, 1.6)
	b:cornice(faces, H, true)
	b:roofTop(W, D, H, {hut = false})
	-- 망루
	local tx, tz = W / 2 - 5, D / 2 - 5
	b:part("Walls", "Tower", Vector3.new(9, 40, 9), CFrame.new(tx, 20, tz), b.pal.wall, M2.Brick)
	b:part("Roof", "TowerCap", Vector3.new(10.4, 1, 10.4), CFrame.new(tx, 40.5, tz), b.pal.trim, M2.SmoothPlastic)
	local tf = b:face(Vector3.new(tx, 0, tz - 4.5), Vector3.new(0, 0, -1), 9, 40)
	for _, y in ipairs({28, 33}) do
		local c = tf:box("Openings", "TowerWin", 0, y, 0.05, 3, 4, 0.1, Color3.fromRGB(20, 22, 26), M2.SmoothPlastic)
		b:decal(c, b:winTex(), Enum.NormalId.Back)
	end
	return {W = W, D = D, H = 41}
end

-- 29. 교회: 앞 박공 + 장미창, 옆 아치 스테인드글라스, 첨탑
Kit.TYPES.church = function(b)
	local p = b.p
	b.pal = Kit.PALETTES.stone
	b.wallMat = M2.Limestone
	local H = 22
	local W = p.w or 30
	local D = p.d or 60
	local faces = b:shell(W, D, H)
	local f = faces.front
	f:open(0, 0.6, 6, 11, "Door", "door_red", {recess = 1.0})
	f:box("Trim", "DoorArch", 0, 12.4, 0.4, 8, 1.2, 0.8, b.pal.trim, M2.Limestone)
	for _, x in ipairs({-W / 3, W / 3}) do f:open(x, 6, 3, 8, "Window", "stained_arch") end
	f:buildWall(1)
	for _, side in ipairs({"left", "right"}) do
		local s = faces[side]
		for i = 1, 5 do s:open(-s.w / 2 + s.w * (i - 0.5) / 5, 6, 4, 9, "Window", "stained_arch") end
		s:buildWall(1)
		for i = 0, 5 do s:box("Trim", "Buttress", -s.w / 2 + s.w * i / 5, 8, 1.0, 1.6, 16, 2.0, b.pal.trim, M2.Limestone) end
	end
	faces.back:buildFlat(1)
	b:plinth(faces, 1.6)
	local R = b:gableRoof(CFrame.new(0, H, 0) * CFrame.Angles(0, math.pi / 2, 0), D, W, {pitch = 42, color = Color3.fromRGB(70, 74, 84), mat = M2.Slate, overhang = 1})
	local rose = f:box("Openings", "RoseWindow", 0, H + R * 0.35, 0.08, 6, 6, 0.1, Color3.new(0, 0, 0), M2.SmoothPlastic, {transparency = 1})
	b:decal(rose, "stained_rose", Enum.NormalId.Back)
	-- 첨탑: 앞 왼쪽
	local tx, tz = -W / 2 - 4, -D / 2 + 5
	local TH = 40
	b:part("Walls", "BellTower", Vector3.new(10, TH, 10), CFrame.new(tx, TH / 2, tz), b.pal.wall, M2.Limestone)
	local tf = b:face(Vector3.new(tx, 0, tz - 5), Vector3.new(0, 0, -1), 10, TH)
	tf:box("Openings", "Belfry", 0, TH - 6, 0.05, 3.4, 6, 0.1, Color3.fromRGB(16, 16, 18), M2.SmoothPlastic)
	tf:box("Trim", "TowerBand", 0, TH - 1, 0.3, 11, 1, 0.6, b.pal.trim, M2.Limestone)
	b:spire(CFrame.new(tx, TH, tz), 10, 20, Color3.fromRGB(70, 74, 84), M2.Slate)
	b:shift(4.5, 0)
	return {W = W + 9, D = D, H = TH + 24}
end

-- 30. 폐허: 기존 종류를 짓고 위쪽을 들쭉날쭉 무너뜨림 + 그을음 + 잔해
Kit.TYPES.ruin = function(b)
	local p = b.p
	b.decay = 1
	local base = p.base or b:pick({"apt_balcony", "brick_tenement", "apt_bay", "corner_shop"})
	local info = Kit.TYPES[base](b)
	local W, D, H = info.W, info.D, info.H
	local cut0 = H * b.rng:NextNumber(0.4, 0.7)
	local ph1, ph2 = b.rng:NextNumber(0, 6), b.rng:NextNumber(0, 6)
	local function cutAt(x, z) return cut0 + math.sin(x * 0.18 + ph1) * 5 + math.sin(z * 0.23 + ph2) * 4 + math.sin((x + z) * 0.6) * 1.5 end
	-- 무너뜨리기: 바닥이 절단선 위 = 삭제. 절단선에 걸친 세운 구조물(벽·기둥·옆벽) = 잘라 낮춤. 나머지 걸친 장식은 중심이 선 근처 위면 삭제
	local STRUCT = {Wall = true, OrielSide = true, Parapet = true, Gable = true, Pilaster = true, ShopPier = true, WoodFin = true, ColorStripe = true, BaySide = true, Tower = true}
	local removed = 0
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") and d.Parent then
			local cf, sz = d.CFrame, d.Size / 2
			local hy = math.abs(cf.RightVector.Y) * sz.X + math.abs(cf.UpVector.Y) * sz.Y + math.abs(cf.LookVector.Y) * sz.Z
			local bot, top = d.Position.Y - hy, d.Position.Y + hy
			local c = cutAt(d.Position.X, d.Position.Z)
			if bot > c then
				d:Destroy() removed += 1
			elseif top > c then
				if STRUCT[d.Name] and math.abs(cf.UpVector.Y) > 0.99 and c - bot > 0.8 then
					d.Size = Vector3.new(d.Size.X, c - bot, d.Size.Z)
					d.CFrame = cf - Vector3.new(0, (top - c) / 2, 0)
				elseif d.Position.Y > c - 1 then
					d:Destroy() removed += 1
				end
			end
		end
	end
	-- 받침 검사: 아래에서 겹쳐 받쳐 주는 파트가 없으면 공중에 뜬 것 → 삭제 (낮은 것부터)
	local list = {}
	for _, d in ipairs(b.model:GetDescendants()) do
		if d:IsA("BasePart") and not (d.Parent and d.Parent:IsA("Model") and d.Parent ~= b.model) then
			local cf, sz = d.CFrame, d.Size / 2
			local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
			local h = Vector3.new(math.abs(r.X) * sz.X + math.abs(u.X) * sz.Y + math.abs(l.X) * sz.Z,
				math.abs(r.Y) * sz.X + math.abs(u.Y) * sz.Y + math.abs(l.Y) * sz.Z, math.abs(r.Z) * sz.X + math.abs(u.Z) * sz.Y + math.abs(l.Z) * sz.Z)
			table.insert(list, {p = d, mn = d.Position - h, mx = d.Position + h, keep = true})
		end
	end
	table.sort(list, function(a, c) return a.mn.Y < c.mn.Y end)
	for i, e in ipairs(list) do
		if e.mn.Y > 1.5 then
			local ok = false
			for j = 1, #list do
				local o = list[j]
				if o ~= e and o.keep and o.mn.Y < e.mn.Y - 0.05 and o.mx.Y >= e.mn.Y - 0.3
					and o.mn.X <= e.mx.X + 0.05 and o.mx.X >= e.mn.X - 0.05 and o.mn.Z <= e.mx.Z + 0.05 and o.mx.Z >= e.mn.Z - 0.05 then
					ok = true break
				end
			end
			if not ok then e.keep = false e.p:Destroy() removed += 1 end
		end
	end
	for _, m in ipairs(b.model:GetDescendants()) do
		if m:IsA("Model") and not m:FindFirstChildWhichIsA("BasePart", true) then m:Destroy() end
	end
	b.count -= removed
	-- 그을음 (네 면)
	for _, s in ipairs({{0, -D / 2 - 0.1, W, 0}, {0, D / 2 + 0.1, W, math.pi}, {-W / 2 - 0.1, 0, D, math.pi / 2}, {W / 2 + 0.1, 0, D, -math.pi / 2}}) do
		local sh = math.max(6, cut0 - 11) -- 들쭉날쭉한 윗선보다 항상 낮게
		local g = b:part("Decor", "Soot", Vector3.new(s[3], sh, 0.05), CFrame.new(s[1], sh / 2, s[2]) * CFrame.Angles(0, s[4], 0), Color3.new(0, 0, 0), M2.SmoothPlastic, {transparency = 1, deco = true, noShadow = true})
		b:texture(g, "soot_burn", Enum.NormalId.Front, 18, 18)
		b:texture(g, "grime_streaks", Enum.NormalId.Front, 14, 14)
	end
	-- 안쪽 검은 바닥판 (위에서 들여다볼 때 비어 보이지 않게)
	b:part("Decor", "CharredFloor", Vector3.new(W - 2, 0.6, D - 2), CFrame.new(0, math.max(2, cut0 - 8), 0), Color3.fromRGB(30, 28, 26), M2.Slate)
	-- 잔해 + 탄 들보
	local RC = {Color3.fromRGB(150, 146, 140), Color3.fromRGB(120, 116, 110), Color3.fromRGB(96, 92, 88), b.pal.wall}
	for pile = 1, b.rng:NextInteger(2, 4) do
		local px, pz = b.rng:NextNumber(-W / 2 + 3, W / 2 - 3), -D / 2 - b.rng:NextNumber(0.5, 3)
		for k = 1, b.rng:NextInteger(6, 10) do
			local sz = b.rng:NextNumber(0.8, 2.8)
			b:part("Rubble", "Rubble", Vector3.new(sz * b.rng:NextNumber(0.8, 1.6), sz * b.rng:NextNumber(0.4, 0.9), sz),
				CFrame.new(px + b.rng:NextNumber(-3, 3), sz * 0.25, pz + b.rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(b.rng:NextNumber(-0.5, 0.5), b.rng:NextNumber(0, 6.28), b.rng:NextNumber(-0.5, 0.5)),
				b:pick(RC), b:pick({M2.Concrete, M2.Slate, M2.Plaster}))
		end
	end
	for i = 1, 6 do
		b:part("Decor", "CharredBeam", Vector3.new(0.8, 0.8, b.rng:NextNumber(8, 16)),
			CFrame.new(b.rng:NextNumber(-W / 3, W / 3), cut0 - b.rng:NextNumber(2, 8), b.rng:NextNumber(-D / 3, D / 3)) * CFrame.Angles(b.rng:NextNumber(-0.6, 0.6), b.rng:NextNumber(0, 3), b.rng:NextNumber(-0.4, 0.4)),
			Color3.fromRGB(34, 30, 28), M2.Wood)
	end
	b.model:SetAttribute("Kit22RuinBase", base)
	return info
end

-- 31. 공사 중 골조: 기둥·슬래브 격자, 일부 벽돌, 비계
Kit.TYPES.skeleton = function(b)
	local p = b.p
	local floors = p.floors or b.rng:NextInteger(4, 6)
	local FH = 11
	local W = p.w or 40
	local D = p.d or 30
	local conc = Color3.fromRGB(176, 172, 164)
	local nx, nz = math.floor(W / 10), math.floor(D / 10)
	local built = b.rng:NextInteger(math.max(2, floors - 2), floors)
	for i = 0, nx do for j = 0, nz do
		b:part("Structure", "Column", Vector3.new(1.4, FH * built, 1.4), CFrame.new(-W / 2 + W * i / nx, FH * built / 2, -D / 2 + D * j / nz), conc, M2.Concrete)
		-- 꼭대기 철근
		b:part("Structure", "Rebar", Vector3.new(0.15, 3, 0.15), CFrame.new(-W / 2 + W * i / nx + 0.4, FH * built + 1.5, -D / 2 + D * j / nz), Color3.fromRGB(110, 70, 50), M2.CorrodedMetal, {deco = true})
	end end
	for lv = 1, built do
		b:part("Structure", "Slab", Vector3.new(W + 1, 0.9, D + 1), CFrame.new(0, FH * lv - 0.45, 0), conc, M2.Concrete)
	end
	b:part("Structure", "GroundSlab", Vector3.new(W + 1, 0.6, D + 1), CFrame.new(0, 0.3, 0), conc, M2.Concrete)
	-- 1~2층 일부 벽돌 벽
	for lv = 1, math.min(2, built) do
		local y = FH * (lv - 1) + FH / 2 + 0.3
		b:part("Walls", "BrickInfill", Vector3.new(W * b.rng:NextNumber(0.3, 0.7), FH - 1, 0.8), CFrame.new(b.rng:NextNumber(-W / 6, W / 6), y, D / 2), Color3.fromRGB(160, 86, 66), M2.Brick)
	end
	-- 정면 비계: 세로 파이프 + 발판
	local sz = -D / 2 - 2.5
	for i = 0, 4 do
		b:part("Scaffold", "Pipe", Vector3.new(0.3, FH * built + 3, 0.3), CFrame.new(-W / 2 + W * i / 4, (FH * built + 3) / 2, sz), Color3.fromRGB(150, 150, 154), M2.Metal)
		b:part("Scaffold", "Pipe", Vector3.new(0.3, FH * built + 3, 0.3), CFrame.new(-W / 2 + W * i / 4, (FH * built + 3) / 2, sz - 3), Color3.fromRGB(150, 150, 154), M2.Metal)
	end
	for lv = 1, built do
		b:part("Scaffold", "Plank", Vector3.new(W, 0.3, 3), CFrame.new(0, FH * lv - 1, sz - 1.5), Color3.fromRGB(176, 140, 90), M2.WoodPlanks)
		b:part("Scaffold", "Rail", Vector3.new(W, 0.2, 0.2), CFrame.new(0, FH * lv + 2, sz - 3), Color3.fromRGB(230, 170, 40), M2.Metal)
	end
	-- 공사 가림막
	local fence = b:part("Scaffold", "SiteFence", Vector3.new(W + 8, 6, 0.3), CFrame.new(0, 3, -D / 2 - 7), Color3.fromRGB(70, 110, 90), M2.Fabric)
	return {W = W, D = D + 7, H = FH * built + 3}
end

Kit.TYPE_LIST = {"apt_balcony", "townhouse", "corner_shop", "brick_tenement", "apt_bay", "rowhouse_gable", "apt_modern", "apt_tower", "house_suburban",
	"house_bungalow", "duplex", "walkup_narrow", "shop_row", "cafe_terrace", "convenience_store", "gas_station", "supermarket", "office_glass", "office_mid",
	"bank", "hotel", "diner", "clinic", "parking_garage", "cinema", "warehouse", "factory", "fire_station", "church", "ruin", "skeleton"}
