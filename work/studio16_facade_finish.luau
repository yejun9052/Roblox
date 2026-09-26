local root=workspace.City_quality_16;assert(not root:GetAttribute('MainWallFinish'),'Already applied')
local C=Color3.fromRGB;local n=0
local tones={green={C(114,128,108),Enum.Material.Concrete},blue={C(105,126,134),Enum.Material.Concrete},brick={C(137,99,81),Enum.Material.Brick},wall={C(153,147,130),Enum.Material.Concrete}}
for _,q in workspace.SurterDays:GetDescendants() do if q:IsA('BasePart') then
 local key=q.Name:match('_Structure_(%a+)$');local tone=key and tones[key]
 if tone then
  q:SetAttribute('ColorBefore16',q.Color);q:SetAttribute('MaterialBefore16',q.Material.Name);q:SetAttribute('ReflectanceBefore16',q.Reflectance)
  q.Color=tone[1];q.Material=tone[2];q.Reflectance=0;n+=1
 end
end end
root:SetAttribute('MainWallFinish',n);print('CITY16 MAIN WALL FINISH',n)
