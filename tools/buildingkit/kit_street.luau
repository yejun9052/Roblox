---------------------------------------------------------------- 서울 골목 가로시설 (6차, 사용자 참고 사진 느낌 — 모양은 새로 만듦)
-- 맨홀·빗물받이, 볼라드, 콘크리트/플라스틱 방호벽, 시멘트 블록, 벽 계량기함·우편함, 소화기함, 벽보, 전봇대 띠, 바깥 철계단, 카페 테라스
-- 모두 cf = 바닥 중심. 반환 Model (나중에 optimize 단계가 합침)
local PS = Kit.P
local MT = Enum.Material

local function model(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- 맨홀 뚜껑 / 빗물받이 (바닥에 붙는 납작한 것)
function Kit.manhole(parent, cf, rng)
	local m = model(parent, "Manhole")
	local c = PS(m, "Cover", Vector3.new(0.12, 3.2, 3.2), cf * CFrame.new(0, 0.07, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 46, 48), MT.DiamondPlate, {shape = Enum.PartType.Cylinder, noShadow = true})
	if rng and rng:NextNumber() < 0.25 then -- 열린 맨홀: 뚜껑이 옆으로
		c.CFrame = cf * CFrame.new(2.6, 0.1, 0.8) * CFrame.Angles(0, 0, math.pi / 2 + 0.1)
		PS(m, "Hole", Vector3.new(0.05, 2.8, 2.8), cf * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(8, 8, 8), MT.SmoothPlastic, {shape = Enum.PartType.Cylinder, deco = true})
	end
	return m
end
function Kit.drainGrate(parent, cf)
	local m = model(parent, "Drain")
	PS(m, "Grate", Vector3.new(3, 0.08, 1.2), cf * CFrame.new(0, 0.05, 0), Color3.fromRGB(40, 40, 42), MT.DiamondPlate, {noShadow = true})
	return m
end

-- 볼라드 (노랑·검정 띠 머리)
function Kit.bollard(parent, cf, rng)
	local m = model(parent, "Bollard")
	local lean = rng and rng:NextNumber() < 0.15
	local base = cf * (lean and CFrame.Angles(math.rad(rng:NextNumber(-25, 25)), 0, math.rad(rng:NextNumber(-25, 25))) or CFrame.new())
	PS(m, "Post", Vector3.new(3, 0.8, 0.8), base * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 48, 50), MT.Metal, {shape = Enum.PartType.Cylinder})
	PS(m, "Band", Vector3.new(0.5, 0.85, 0.85), base * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(230, 190, 30), MT.SmoothPlastic, {shape = Enum.PartType.Cylinder})
	return m
end

-- 방호벽: 콘크리트(회색) 또는 플라스틱(주황·흰 줄) 저지 배리어
function Kit.jersey(parent, cf, rng)
	local m = model(parent, "Barrier")
	local plastic = rng:NextNumber() < 0.45
	local L = plastic and 4 or 6
	local col = plastic and Color3.fromRGB(214, 100, 50) or Color3.fromRGB(170, 166, 158)
	local mat = plastic and MT.Plastic or MT.Concrete
	local tilt = rng:NextNumber() < 0.2 and CFrame.Angles(0, 0, math.rad(rng:NextNumber(-60, 60))) or CFrame.new()
	local b = cf * tilt
	PS(m, "Base", Vector3.new(2.2, 1.2, L), b * CFrame.new(0, 0.6, 0), col, mat)
	PS(m, "Mid", Vector3.new(1.3, 1.2, L), b * CFrame.new(0, 1.8, 0), col, mat)
	PS(m, "Top", Vector3.new(0.9, 0.6, L), b * CFrame.new(0, 2.7, 0), col, mat)
	if plastic then
		PS(m, "Stripe", Vector3.new(1.35, 0.4, L + 0.02), b * CFrame.new(0, 1.9, 0), Color3.fromRGB(236, 232, 224), MT.Plastic)
	end
	return m
end

-- 시멘트 블록 (구멍 두 개 블록) 1~5개 흩어짐
function Kit.cinderBlocks(parent, cf, rng)
	local m = model(parent, "CinderBlocks")
	for i = 1, rng:NextInteger(1, 5) do
		local c = cf * CFrame.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		if i > 2 and rng:NextNumber() < 0.5 then c = c * CFrame.new(0, 0.9, 0) end
		PS(m, "Block", Vector3.new(1.8, 0.9, 0.9), c * CFrame.new(0, 0.45, 0), Color3.fromRGB(150, 148, 142), MT.Concrete)
	end
	return m
end

-- 벽 부착물 (벽면 cf: 바깥을 보는 방향 = LookVector, 바닥 기준 높이 y)
local POSTER_C = {Color3.fromRGB(226, 214, 190), Color3.fromRGB(230, 120, 110), Color3.fromRGB(240, 220, 120), Color3.fromRGB(150, 196, 220), Color3.fromRGB(236, 236, 230)}
function Kit.wallStuff(parent, wallCf, rng)
	local m = model(parent, "WallStuff")
	local kind = rng:NextNumber()
	if kind < 0.3 then -- 전기 계량기 3~6개 (가로 줄)
		local n = rng:NextInteger(3, 6)
		for i = 1, n do
			PS(m, "Meter", Vector3.new(1.0, 1.4, 0.6), wallCf * CFrame.new((i - (n + 1) / 2) * 1.2, 6.5, -0.3), Color3.fromRGB(214, 206, 190), MT.SmoothPlastic)
		end
		PS(m, "Conduit", Vector3.new(0.25, 6, 0.25), wallCf * CFrame.new(0, 3.2, -0.15), Color3.fromRGB(70, 70, 72), MT.Metal)
	elseif kind < 0.5 then -- 우편함 묶음 (2~3단)
		local cols, rows = rng:NextInteger(3, 5), rng:NextInteger(2, 3)
		for c = 1, cols do for r = 1, rows do
			PS(m, "MailBox", Vector3.new(1.2, 0.9, 0.9), wallCf * CFrame.new((c - (cols + 1) / 2) * 1.25, 3.4 + r * 0.95, -0.45), Color3.fromRGB(196, 198, 200), MT.Metal)
		end end
	elseif kind < 0.65 then -- 소화기함 (빨강)
		PS(m, "ExtBox", Vector3.new(1.4, 2.4, 0.7), wallCf * CFrame.new(0, 4.2, -0.35), Color3.fromRGB(190, 30, 30), MT.SmoothPlastic)
	elseif kind < 0.85 then -- 벽보 2~5장
		for i = 1, rng:NextInteger(2, 5) do
			local p = PS(m, "Poster", Vector3.new(rng:NextNumber(1.2, 2.2), rng:NextNumber(1.6, 2.8), 0.04), wallCf * CFrame.new(rng:NextNumber(-3, 3), rng:NextNumber(4, 6.5), -0.03) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-6, 6))),
				POSTER_C[rng:NextInteger(1, #POSTER_C)]:Lerp(Color3.fromRGB(120, 110, 96), rng:NextNumber(0.1, 0.5)), MT.Fabric, {deco = true, noShadow = true})
		end
	else -- 가스 계량기 + 노란 가스관
		PS(m, "GasMeter", Vector3.new(1.3, 1.6, 0.9), wallCf * CFrame.new(0, 3.5, -0.45), Color3.fromRGB(190, 192, 186), MT.Metal)
		PS(m, "GasPipe", Vector3.new(0.3, 7, 0.3), wallCf * CFrame.new(0.9, 4.5, -0.2), Color3.fromRGB(226, 182, 40), MT.Metal)
		PS(m, "GasPipe", Vector3.new(3, 0.3, 0.3), wallCf * CFrame.new(-0.3, 7.8, -0.2), Color3.fromRGB(226, 182, 40), MT.Metal)
	end
	return m
end

-- 전봇대 아래 노랑·검정 보호 띠 (pole 위치 cf)
function Kit.poleGuard(parent, cf)
	local m = model(parent, "PoleGuard")
	for i = 0, 3 do
		PS(m, "Guard", Vector3.new(0.7, 1.4, 1.4), cf * CFrame.new(0, 0.5 + i * 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), i % 2 == 0 and Color3.fromRGB(230, 190, 30) or Color3.fromRGB(30, 30, 30), MT.SmoothPlastic, {shape = Enum.PartType.Cylinder})
	end
	return m
end

-- 바깥 철계단 (건물 벽을 따라 2층으로): cf = 계단 아래 끝 바닥, 계단은 cf 의 -Z 방향으로 올라감, 높이 h
function Kit.outdoorStair(parent, cf, h, rng)
	local m = model(parent, "OutdoorStair")
	local run = h * 1.1
	local L = math.sqrt(run * run + h * h)
	local ang = math.atan2(h, run)
	local IRONC = Color3.fromRGB(56, 58, 60):Lerp(Color3.fromRGB(120, 76, 50), rng:NextNumber(0, 0.6))
	local mid = cf * CFrame.new(0, h / 2, -run / 2)
	for _, sx in ipairs({-1.4, 1.4}) do
		PS(m, "Stringer", Vector3.new(0.25, 0.6, L), mid * CFrame.new(sx, 0, 0) * CFrame.Angles(ang, 0, 0), IRONC, MT.CorrodedMetal)
		PS(m, "Rail", Vector3.new(0.18, 0.18, L), mid * CFrame.new(sx, 3, 0) * CFrame.Angles(ang, 0, 0), IRONC, MT.CorrodedMetal)
	end
	local n = math.floor(h / 0.9)
	for i = 1, n do
		local t = (i - 0.5) / n
		PS(m, "Tread", Vector3.new(2.8, 0.15, 1.0), cf * CFrame.new(0, h * t, -run * t), IRONC, MT.DiamondPlate)
	end
	PS(m, "Landing", Vector3.new(3.2, 0.25, 3.2), cf * CFrame.new(0, h, -run - 1.6), IRONC, MT.DiamondPlate)
	for _, sx in ipairs({-1.5, 1.5}) do
		PS(m, "Leg", Vector3.new(0.3, h, 0.3), cf * CFrame.new(sx, h / 2, -run - 3), IRONC, MT.CorrodedMetal)
	end
	return m
end

-- 카페 테라스: 테이블·의자 몇 개(넘어진 것 포함) + 접힌/기운 파라솔
function Kit.cafeTerrace(parent, cf, rng)
	local m = model(parent, "CafeTerrace")
	local WOOD = Color3.fromRGB(110, 80, 56)
	for t = 1, rng:NextInteger(1, 3) do
		local tc = cf * CFrame.new((t - 2) * 5 + rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-1, 1))
		local fallen = rng:NextNumber() < 0.3
		local base = fallen and (tc * CFrame.new(0, 1.2, 0) * CFrame.Angles(math.pi / 2, rng:NextNumber(0, 6), 0)) or tc
		PS(m, "TableTop", Vector3.new(0.2, 3, 3), base * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.pi / 2), WOOD, MT.WoodPlanks, {shape = Enum.PartType.Cylinder})
		PS(m, "TableLeg", Vector3.new(0.3, 2.5, 0.3), base * CFrame.new(0, 1.3, 0), Color3.fromRGB(40, 40, 40), MT.Metal)
		for c = 1, 2 do
			local cc = tc * CFrame.Angles(0, c * math.pi + rng:NextNumber(-0.5, 0.5), 0) * CFrame.new(0, 0, 2.3)
			if rng:NextNumber() < 0.35 then cc = cc * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.pi / 2 * (rng:NextNumber() < 0.5 and 1 or -1), 0, 0) end
			PS(m, "Seat", Vector3.new(1.6, 0.2, 1.6), cc * CFrame.new(0, 1.6, 0), WOOD, MT.WoodPlanks)
			PS(m, "Back", Vector3.new(1.6, 1.6, 0.2), cc * CFrame.new(0, 2.5, 0.75), WOOD, MT.WoodPlanks)
			for _, o in ipairs({{-0.7, -0.7}, {0.7, -0.7}, {-0.7, 0.7}, {0.7, 0.7}}) do
				PS(m, "ChairLeg", Vector3.new(0.15, 1.6, 0.15), cc * CFrame.new(o[1], 0.8, o[2]), Color3.fromRGB(40, 40, 40), MT.Metal)
			end
		end
	end
	-- 접힌 파라솔 (기울어짐)
	local pc = cf * CFrame.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-1, 1)) * CFrame.Angles(math.rad(rng:NextNumber(-12, 12)), 0, math.rad(rng:NextNumber(-12, 12)))
	PS(m, "UmbrellaPole", Vector3.new(0.25, 8, 0.25), pc * CFrame.new(0, 4, 0), Color3.fromRGB(200, 196, 186), MT.Metal)
	local cone = Instance.new("Part")
	cone.Name, cone.Anchored = "UmbrellaCloth", true
	cone.Size = Vector3.new(1.4, 5, 1.4)
	cone.CFrame = pc * CFrame.new(0, 5.5, 0)
	cone.Color = ({Color3.fromRGB(196, 186, 160), Color3.fromRGB(120, 140, 110), Color3.fromRGB(170, 90, 80)})[rng:NextInteger(1, 3)]
	cone.Material = MT.Fabric
	cone.Parent = m
	return m
end

-- 덩굴 (벽면 cf, 바닥 기준): 잎 카드 세로 줄 여러 장 — 참고 사진처럼 위층에서 늘어짐
function Kit.wallVines(parent, wallCf, height, width, rng)
	local m = model(parent, "WallVines")
	local p = PS(m, "Vines", Vector3.new(width, height, 0.05), wallCf * CFrame.new(0, height / 2 + rng:NextNumber(4, 10), -0.08), Color3.new(0, 0, 0), MT.SmoothPlastic, {transparency = 1, deco = true, noShadow = true})
	local d = Instance.new("Decal") d.Texture = Kit.TEX.vines_a d.Face = Enum.NormalId.Front d.Parent = p
	return m
end
