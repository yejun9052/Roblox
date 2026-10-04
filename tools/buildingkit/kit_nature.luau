---------------------------------------------------------------- 자연물 (22번): 가로수. kit.luau 뒤에 이어 붙임 (deploy.sh)
-- 줄기·가지 = 원기둥, 캐노피 = 안쪽 채움 구(그림자·빈틈 막기) + 잎 뭉치 카드(텍스처 leaf_a/b/c, 앞뒤 데칼) 2장씩 교차.
Kit.TEX.leaf_a = "rbxassetid://139663632630483"
Kit.TEX.leaf_b = "rbxassetid://114574566966248"
Kit.TEX.leaf_c = "rbxassetid://133447301261962"

local MN = Enum.Material
local LEAF_SETS = {
	{tex = {"leaf_a", "leaf_b"}, fill = Color3.fromRGB(92, 140, 60)},
	{tex = {"leaf_b", "leaf_b", "leaf_a"}, fill = Color3.fromRGB(110, 156, 64)},
	{tex = {"leaf_c", "leaf_a"}, fill = Color3.fromRGB(80, 126, 56)},
}

local function np(parent, name, size, cf, color, mat, opt)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material, p.Anchored = name, size, cf, color, mat, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if opt then
		if opt.shape then p.Shape = opt.shape end
		if opt.deco then p.CanCollide, p.CanTouch, p.CanQuery = false, false, false end
		if opt.transparency then p.Transparency = opt.transparency end
		if opt.noShadow then p.CastShadow = false end
	end
	p.Parent = parent
	return p
end

-- 원기둥을 a → b 로 (반지름 r)
local function limb(parent, a, b, r, color)
	local d = b - a
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0) -- 원기둥 길이축(X)을 a→b 로
	return np(parent, "Limb", Vector3.new(d.Magnitude, r * 2, r * 2), cf, color, MN.Wood, {shape = Enum.PartType.Cylinder})
end

-- cf = 바닥 중심. opts: seed, height, radius, planter(bool), leaves(1~3)
function Kit.tree(parent, cf, opts)
	opts = opts or {}
	local rng = Random.new(opts.seed or 1)
	local m = Instance.new("Model")
	m.Name = "Tree22"
	m:SetAttribute("Kit22Tree", true)
	local H = opts.height or rng:NextNumber(20, 26)
	local R = opts.radius or rng:NextNumber(6.5, 8.5)
	local set = LEAF_SETS[opts.leaves or rng:NextInteger(1, #LEAF_SETS)]
	local bark = Color3.fromRGB(84 + rng:NextInteger(-8, 8), 64, 50)
	local trunkH = H - R * 1.6
	local lean = CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-4, 4)))
	local base = Vector3.new(0, 0, 0)
	local top = (lean * CFrame.new(0, trunkH, 0)).Position
	limb(m, base, top + Vector3.new(0, 0.5, 0), 0.75, bark)
	-- 뿌리 부분 살짝 두껍게
	np(m, "TrunkBase", Vector3.new(1.4, 2.2, 2.2), CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), bark, MN.Wood, {shape = Enum.PartType.Cylinder})
	-- 가지 4개: 줄기 끝에서 위·바깥으로
	local center = top + Vector3.new(0, R * 0.75, 0)
	for i = 1, 4 do
		local yaw = (i / 4) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local out = Vector3.new(math.cos(yaw), 0, math.sin(yaw))
		local tip = top + out * R * 0.55 + Vector3.new(0, R * rng:NextNumber(0.6, 0.9), 0)
		limb(m, top - Vector3.new(0, 1.2, 0), tip, 0.38, bark)
	end
	-- 안쪽 채움 구 (그림자 + 카드 사이 빈틈 가림)
	for i = 1, 3 do
		local off = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 0.6), rng:NextNumber(-1, 1)) * R * 0.3
		local s = R * rng:NextNumber(1.0, 1.2)
		np(m, "CanopyFill", Vector3.new(s, s * 0.85, s), CFrame.new(center + off), set.fill, MN.Grass, {shape = Enum.PartType.Ball})
	end
	-- 잎 카드: 타원체 표면에 고르게 (피보나치 구), 맨 아래 일부 제외
	local n = opts.cards or 30
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, n - 1 do
		local y = 1 - (i + 0.5) / n * 2
		if y > -0.75 then
			local rr = math.sqrt(1 - y * y)
			local th = golden * i + rng:NextNumber(-0.2, 0.2)
			local dir = Vector3.new(math.cos(th) * rr, y, math.sin(th) * rr)
			local depth = rng:NextNumber(0.7, 0.95)
			local pos = center + Vector3.new(dir.X * R * depth, dir.Y * R * 0.78 * depth, dir.Z * R * depth)
			local s = R * rng:NextNumber(0.85, 1.15)
			local tex = set.tex[rng:NextInteger(1, #set.tex)]
			local look = CFrame.lookAt(pos, pos + Vector3.new(dir.X, dir.Y * 0.4, dir.Z)) * CFrame.Angles(0, 0, rng:NextNumber(-0.5, 0.5))
			for k = 0, 1 do
				local c = np(m, "LeafCard", Vector3.new(s, s, 0.05), look * CFrame.Angles(0, k * math.pi / 2, 0), Color3.new(0, 0, 0), MN.SmoothPlastic,
					{transparency = 1, deco = true, noShadow = true})
				for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
					local d = Instance.new("Decal")
					d.Texture = Kit.TEX[tex]
					d.Face = face
					d.Parent = c
				end
			end
		end
	end
	-- 화단 (선택)
	if opts.planter ~= false then
		local pc = Color3.fromRGB(196, 190, 180)
		for _, s in ipairs({{0, 2.1, 4.8, 0.6}, {0, -2.1, 4.8, 0.6}, {2.1, 0, 0.6, 3.6}, {-2.1, 0, 0.6, 3.6}}) do
			np(m, "Planter", Vector3.new(s[3], 0.7, s[4]), CFrame.new(s[1], 0.35, s[2]), pc, MN.Concrete)
		end
		np(m, "Soil", Vector3.new(3.6, 0.4, 3.6), CFrame.new(0, 0.2, 0), Color3.fromRGB(90, 66, 46), MN.Ground)
	end
	m.WorldPivot = CFrame.new()
	m:PivotTo(cf * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	m.Parent = parent
	return m
end
