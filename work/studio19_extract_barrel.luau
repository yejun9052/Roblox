-- 19번 반복 소품 최적화: 드럼통 1개(SD_014016) 삼각형 추출. 읽기 전용, 맵을 수정하지 않음.
-- 출력 형식 (Roblox 좌표, ORIGIN 기준 상대값):
--   ORIGIN x y z N count        -- 파트 Position 들의 bbox 중심 X/Z, 최소 Y
--   W <mat> ax ay az bx by bz cx cy cz   -- WedgePart 중앙면 삼각형
--   B <mat> 8개 꼭짓점 (ix*4+iy*2+iz 순서)  -- 박스 Part
-- WedgePart 삼각형은 로컬 (0,-Y,-Z),(0,-Y,+Z),(0,+Y,+Z) 로 가정 (Roblox 표준 쐐기 모양).
-- 결과가 길어 MCP 출력 한도를 넘으므로 저장 파일로 받아 assets/source/ 에 둔다.
local folder = workspace.SurterDays["Active/B12/StreetProps/Detail/Barrel"]
local parts = {}
for _, d in ipairs(folder:GetChildren()) do if d:IsA("BasePart") and d.Name:find("_SD_014016") then table.insert(parts, d) end end
local mn, mx = Vector3.new(1e9,1e9,1e9), Vector3.new(-1e9,-1e9,-1e9)
for _, p in ipairs(parts) do mn = mn:Min(p.Position) mx = mx:Max(p.Position) end
local o = Vector3.new((mn.X+mx.X)/2, mn.Y, (mn.Z+mx.Z)/2)
local function f(v) v = v - o return ("%.4f %.4f %.4f"):format(v.X, v.Y, v.Z) end
local lines = {("ORIGIN %.4f %.4f %.4f N %d"):format(o.X, o.Y, o.Z, #parts)}
for _, p in ipairs(parts) do
  local mat = p.Name:match("_(%a+)$")
  local s, cf = p.Size / 2, p.CFrame
  if p:IsA("WedgePart") then
    local a = cf:PointToWorldSpace(Vector3.new(0, -s.Y, -s.Z))
    local b = cf:PointToWorldSpace(Vector3.new(0, -s.Y,  s.Z))
    local c = cf:PointToWorldSpace(Vector3.new(0,  s.Y,  s.Z))
    table.insert(lines, "W " .. mat .. " " .. f(a) .. " " .. f(b) .. " " .. f(c))
  else
    local cs = {}
    for _, sx in ipairs({-1,1}) do for _, sy in ipairs({-1,1}) do for _, sz in ipairs({-1,1}) do
      table.insert(cs, f(cf:PointToWorldSpace(Vector3.new(sx*s.X, sy*s.Y, sz*s.Z)))) end end end
    table.insert(lines, "B " .. mat .. " " .. table.concat(cs, " "))
  end
end
return table.concat(lines, "\n")
