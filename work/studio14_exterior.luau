local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(not h:FindFirstChild('Exterior_quality_14'),'Already applied')
local roof=h:FindFirstChild('Roof');assert(roof and math.abs(roof.Position.Y-54.5)<.1,'Roof changed')
local root=Instance.new('Model');root.Name='Exterior_quality_14';root.Parent=h
local V=Vector3.new;local C=Color3.fromRGB
local cream,teal,metal,dark=C(190,194,182),C(47,83,82),C(91,104,105),C(29,37,40)
local function p(n,x,y,z,s,c,solid,floor)
 local q=Instance.new('Part');q.Name=n;q.Size=V(table.unpack(s));q.Position=V(x,y,z);q.Color=c or metal;q.Material=Enum.Material.Metal;q.Anchored=true;q.CanCollide=solid==true;q.CanTouch=false;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=root
 if floor then q:SetAttribute('SupportY14',floor) end;return q
end
local function sign(n,text,x,y,z,s,rot)
 local q=p(n,x,y,z,s,teal);q.CFrame*=CFrame.Angles(0,math.rad(rot or 0),0)
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=32;g.LightInfluence=.3;g.Parent=q
 local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(.92,.88);t.Position=UDim2.fromScale(.04,.06);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamMedium;t.TextScaled=true;t.TextWrapped=true;t.TextColor3=cream;t.Text=text;t.Parent=g
end
-- Mechanical rooftop: restrained service zone, clear perimeter route.
for _,x in {58,92,166,199} do
 p('Equipment plinth',x,55.25,319,{19,.5,16},dark,true,55)
 for _,dx in {-5,5} do
  local fan=p('Fan guard',x+dx,62.58,319,{.22,5.5,5.5},dark);fan.Shape=Enum.PartType.Cylinder;fan.CFrame*=CFrame.Angles(0,0,math.pi/2)
  for n=-2,2 do p('Fan safety grille',x+dx+n,62.75,319,{.12,.12,4.2},metal) end
 end
 for z=313,325,2 do p('Air intake louver',x,59,z,{15,.28,.25},dark) end
 p('Service duct riser',x,56.5,307,{3,3,7},metal,true,55)
 p('Duct elbow',x,57.75,303,{3,.5,3},metal)
end
p('Insulated service trunk',127,57,300,{146,2,3},metal,true)
for _,x in {57,91,125,165,198} do p('Duct support',x,55.5,300,{1.2,1,4},dark,true,55) end
for x=54,200,10 do p('Duct seam',x,58.04,300,{.15,.08,3.1},cream) end
p('Roof service path',120,55.025,289,{164,.05,7},C(109,119,114))
for x=42,197,12 do p('Service path edge',x,55.06,285.5,{7,.06,.2},cream) end
-- Two benches against the facade; the centre remains open for stretchers.
for _,x in {67,174} do
 p('Waiting bench seat',x,2.55,188,{13,.5,3},teal,true)
 p('Waiting bench back',x,4,189.3,{13,2.5,.35},teal,true)
 for _,dx in {-4.8,4.8} do p('Bench leg',x+dx,1.3,188,{.6,2,2.4},metal,true,.3) end
 for _,dx in {-6,6} do p('Bench arm',x+dx,3.2,188,{.3,1,2.8},metal) end
end
for _,x in {97,143} do
 p('Entry safety bollard',x,2.3,158,{.8,4,.8},metal,true,.3)
 p('Bollard reflector',x,3.55,158,{.84,.3,.84},cream)
end
for _,x in {104,136} do
 p('Canopy fixture housing',x,12.24,179,{4,.42,1.8},dark)
 local q=p('Canopy lens',x,12,179,{3.5,.06,1.3},C(242,226,186));q.Material=Enum.Material.Neon
 local l=Instance.new('SurfaceLight');l.Face=Enum.NormalId.Bottom;l.Brightness=.6;l.Range=17;l.Angle=110;l.Parent=q
end
sign('Entrance directory','EMERGENCY\nRECEPTION  /  WARDS',89,4,193.25,{14,5,.3})
sign('Entrance number','01',103,11,193.2,{4,3,.3})
for _,x in {100,140} do p('Canopy edge fascia',x,13.1,164.35,{11,1.35,.3},metal) end
-- Existing ambulances remain static scenery. Add recognisable vehicle construction.
for _,a in h:GetChildren() do if a.Name=='Static ambulance' then
 local b=a:FindFirstChild('Body');assert(b,'Ambulance body missing');local x=b.Position.X
 p('Front bumper',x,1.4,140.2,{9.6,1,.65},dark)
 p('Rear bumper',x,1.4,161.8,{9.6,1,.65},dark)
 p('Radiator grille',x,2.6,140.35,{4.2,1,.18},dark)
 for _,dx in {-3.3,3.3} do
  p('Headlamp',x+dx,3,140.32,{1.5,1,.2},C(218,212,178))
  p('Rear lamp',x+dx,3,161.65,{.65,1.8,.18},C(154,44,37))
 end
 p('Rear door seam',x,4.4,161.56,{.12,5.6,.1},dark)
 for _,dx in {-2.1,2.1} do
  p('Rear door window',x+dx,5.8,161.6,{2.6,2,.15},C(59,85,96))
  p('Rear door handle',x+dx*.45,3.5,161.73,{.7,.2,.25},metal)
 end
 for _,dx in {-4.58,4.58} do
  p('Cab side window',x+dx,5.5,144,{.15,2.8,4.5},C(59,85,96))
  p('Cab door seam',x+dx,3.5,147,{.1,5.8,.12},dark)
  p('Door handle',x+dx,4,146.1,{.18,.25,1},metal)
  p('Mirror arm',x+dx*1.11,5.4,141,{1.2,.2,.2},metal)
  p('Side mirror',x+dx*1.23,5.65,141,{.35,1,.65},dark)
 end
 p('Rear medical cross vertical',x,5.2,161.78,{.45,1.9,.12},teal)
 p('Rear medical cross horizontal',x,5.2,161.79,{1.7,.45,.12},teal)
end end
-- Independent support and route checks; no teleport or gameplay logic installed.
local failures={};local contacts=0
for _,q in root:GetChildren() do if q:IsA('BasePart') then
 local f=q:GetAttribute('SupportY14');if f then contacts+=1;if math.abs(q.Position.Y-q.Size.Y/2-f)>.02 then table.insert(failures,q.Name..' support') end end
end end
local rp=RaycastParams.new();rp.RespectCanCollide=true
local rays=0
for _,route in {{{120,134},{120,204}},{{36,178},{204,178}}} do
 local a,b=route[1],route[2];local dir=V(b[1]-a[1],0,b[2]-a[2]);local side=V(-dir.Z,0,dir.X).Unit
 for _,offset in {-2,0,2} do for _,height in {1,3,5} do
  rays+=1;local origin=V(a[1],height,a[2])+side*offset;local hit=workspace:Raycast(origin,dir,rp)
  if hit then table.insert(failures,hit.Instance:GetFullName()) end
 end end
end
root:SetAttribute('SupportChecks',contacts);root:SetAttribute('RouteRays',rays);root:SetAttribute('Failures',#failures)
print('EXTERIOR14',#root:GetChildren(),'items',contacts,'support checks',rays,'clearance rays',#failures,'failures');for _,v in failures do warn(v) end
