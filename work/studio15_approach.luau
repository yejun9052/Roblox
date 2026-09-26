local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(h:FindFirstChild('Exterior_quality_14'),'Wrong map version')
assert(not h:FindFirstChild('Approach_detail_15'),'Already applied')
local V=Vector3.new;local C=Color3.fromRGB
local rp=RaycastParams.new();rp.RespectCanCollide=true
local root=Instance.new('Model');root.Name='Approach_detail_15';root.Parent=h
rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={root}
local white,teal,metal,dark=C(204,202,182),C(48,79,77),C(100,111,108),C(35,43,43)
local function ground(x,z)
 local r=workspace:Raycast(V(x,10,z),V(0,-25,0),rp);if not r or r.Position.Y>=1 then return nil end;return r.Position.Y
end
local function p(n,x,y,z,s,c,solid)
 local q=Instance.new('Part');q.Name=n;q.Size=V(table.unpack(s));q.Position=V(x,y,z);q.Anchored=true;q.CanCollide=solid==true;q.CanTouch=false;q.Material=Enum.Material.Metal;q.Color=c or metal;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=root;return q
end
local function mark(n,x,z,s,c)
 local f=ground(x,z);if not f then print('APPROACH15 skipped occupied surface',x,z);return nil end;local q=p(n,x,f+.035,z,{s[1],.05,s[2]},c);q:SetAttribute('Surface15',f);return q
end
local function sign(text,x,z)
 local f=ground(x,z);local q=p('Wayfinding post',x,f+3.5,z,{.35,7,.35},metal,true);q:SetAttribute('Base15',f)
 local panel=p('Pedestrian directory',x,f+6.5,z-.25,{6,3.6,.25},teal)
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.PixelsPerStud=40;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.LightInfluence=.3;g.Parent=panel
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(.92,.9);t.Position=UDim2.fromScale(.04,.05);t.BackgroundTransparency=1;t.TextColor3=white;t.TextScaled=true;t.TextWrapped=true;t.Font=Enum.Font.GothamMedium;t.Text=text;t.Parent=g
end
-- Crossing aligned to the existing emergency entrance; surface sampled from actual road.
for z=110,130,3 do mark('Pedestrian crossing',120,z,{12,1.4},white) end
for _,x in {100,140} do mark('Crossing stop bar',x,120,{.7,18},white) end
-- A narrow walk route through the ambulance apron, avoiding all parking bays.
for z=136,158,4 do
 mark('Walkway left edge',112,z,{.25,2.5},teal)
 mark('Walkway right edge',128,z,{.25,2.5},teal)
end
-- Drainage hardware sits flush with the apron instead of floating above it.
for _,x in {33,86,154,207} do
 mark('Drain recess',x,134,{5,1.8},dark)
 for dx=-2,2,.5 do local q=mark('Drain grate',x+dx,134,{.16,1.6},metal);if q then q.Position+=V(0,.035,0) end end
end
for _,x in {69,172} do
 mark('Utility cover',x,153,{3,3},metal)
 for dx=-1,1,1 do local q=mark('Utility cover groove',x+dx,153,{.06,2.5},dark);if q then q.Position+=V(0,.035,0) end end
end
sign('EMERGENCY\nENTRANCE',105,146)
sign('AMBULANCE\nACCESS',214,164)
-- Street bins stay against the facade rather than in the main walk route.
for _,x in {49,197} do
 local f=ground(x,188);local q=p('Litter bin body',x,f+1.6,188,{2.8,3.2,2.8},teal,true);q:SetAttribute('Base15',f)
 p('Litter bin top',x,f+3.3,188,{3,.2,3},metal)
 p('Litter bin aperture',x,f+2.6,186.57,{1.7,.65,.12},dark)
 p('Bin base collar',x,f+.2,188,{3,.4,3},dark)
end
local fails={};local contacts=0
for _,q in root:GetChildren() do if q:IsA('BasePart') then
 local f=q:GetAttribute('Base15');if f then contacts+=1;if math.abs(q.Position.Y-q.Size.Y/2-f)>.02 then table.insert(fails,q.Name) end end
end end
local clear=RaycastParams.new();clear.RespectCanCollide=true
local rays=0
for _,r in {{{120,102},{120,204}},{{32,178},{208,178}},{{16,120},{102,120}},{{138,120},{224,120}}} do
 local a,b=V(r[1][1],0,r[1][2]),V(r[2][1],0,r[2][2]);local d=b-a;local side=V(-d.Z,0,d.X).Unit
 for _,off in {-2,0,2} do for _,y in {1,3,5} do
  rays+=1;local hit=workspace:Raycast(a+side*off+V(0,y,0),d,clear)
  if hit then table.insert(fails,hit.Instance:GetFullName()) end
 end end
end
root:SetAttribute('AuditFailures',#fails);root:SetAttribute('RouteRays',rays)
print('APPROACH15',#root:GetChildren(),'parts;',contacts,'support contacts;',rays,'route rays;',#fails,'failures');for _,f in fails do warn(f) end
