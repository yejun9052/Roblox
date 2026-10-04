-- 21번 D: 조명 — 먼지·연기 낀 아포칼립스 색감. 원래 값은 각 객체의 Before21_<속성> 속성에 보존(최초 1회만 기록).
local L = game:GetService("Lighting")
local function set(obj, prop, value)
	local key = "Before21_" .. prop
	if obj:GetAttribute(key) == nil then obj:SetAttribute(key, obj[prop]) end
	obj[prop] = value
end
local atm = L:FindFirstChildOfClass("Atmosphere")
local cc = L:FindFirstChildOfClass("ColorCorrectionEffect")
assert(atm and cc, "Atmosphere/ColorCorrection 없음")
set(atm, "Density", 0.24)
set(atm, "Offset", 0.2)
set(atm, "Color", Color3.new(0.62, 0.58, 0.53))
set(atm, "Decay", Color3.new(0.38, 0.34, 0.30))
set(atm, "Glare", 0)
set(atm, "Haze", 1.8)
set(cc, "Saturation", -0.3)
set(cc, "Contrast", 0.14)
set(cc, "TintColor", Color3.new(0.98, 0.93, 0.86))
set(L, "OutdoorAmbient", Color3.new(0.40, 0.38, 0.36))
set(L, "ExposureCompensation", 0)
set(L, "FogColor", Color3.new(0.45, 0.42, 0.38))
return "lighting 21 적용"
