-- Explicit Studio edit. Scope: clinical rooms, nurses, duplicate lights, mounting.
local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(not h:FindFirstChild('Clinical_quality_13'),'Already applied')
local V,C=Vector3.new,Color3.fromRGB
local root=Instance.new('Model');root.Name='Clinical_quality_13';root.Parent=h
local archive=Instance.new('Model');archive.Name='Hospital_before_13';archive.Parent=game.ServerStorage
local cream,teal,metal,dark=C(186,189,177),C(56,91,88),C(89,99,98),C(31,41,43)
local function g(n) local f=Instance.new('Model');f.Name=n;f.Parent=root;return f end
local function p(f,n,x,y,z,s,c,solid,floor)
 local q=Instance.new('Part');q.Name=n;q.Position=V(x,y,z);q.Size=V(table.unpack(s));q.Anchored=true;q.CanCollide=solid==true;q.CanTouch=false;q.Color=c or cream;q.Material=Enum.Material.SmoothPlastic;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=f
 if floor then q:SetAttribute('FloorY13',floor) end;return q
end
local function label(f,n,text,x,y,z,s,angle)
 local q=p(f,n,x,y,z,s,teal);q.CFrame*=CFrame.Angles(0,math.rad(angle or 0),0)
 local sg=Instance.new('SurfaceGui');sg.Face=Enum.NormalId.Front;sg.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;sg.PixelsPerStud=40;sg.LightInfluence=.25;sg.Parent=q
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.92,.84);t.Position=UDim2.fromScale(.04,.08);t.Font=Enum.Font.GothamMedium;t.TextScaled=true;t.TextWrapped=true;t.TextColor3=cream;t.Text=text;t.Parent=sg;return q
end
local function retire(q) q:SetAttribute('PreviousParent13',q.Parent:GetFullName());q.Parent=archive end
-- The two earlier light passes overlapped in rooms. Keep one room fixture per location.
local mounts=h.Interior_quality_12.Flush_mounted_lighting;local removed=0
for _,q in h:GetDescendants() do if q:IsA('BasePart') and q.Name=='Ceiling luminaire' and (math.abs(q.Position.X-65)<.01 or math.abs(q.Position.X-175)<.01) then
 for _,m in mounts:GetChildren() do if m.Name=='Ceiling fixed housing' and math.abs(m.Position.X-q.Position.X)<.01 and math.abs(m.Position.Z-q.Position.Z)<.01 and math.abs(m.Position.Y-q.Position.Y)<1 then retire(m);break end end
 retire(q);removed+=1
end end
local function chair(f,x,F,z)
 local m=Instance.new('Model');m.Name='Staff chair';m.Parent=f
 p(m,'Seat',x,F+2.1,z,{3,.4,3},teal,true);p(m,'Backrest',x,F+3.4,z+1.3,{3,2.4,.3},teal,true)
 for _,dx in {-1.1,1.1} do for _,dz in {-1.1,1.1} do p(m,'Chair leg',x+dx,F+.95,z+dz,{.25,1.9,.25},metal,false,F) end end
end
local function terminal(f,x,top,z,text)
 p(f,'Terminal base',x,top+.1,z,{2.6,.2,1.4},metal)
 p(f,'Terminal neck',x,top+.65,z,{.3,1.1,.3},metal)
 label(f,'Terminal display',text,x,top+2.1,z,{4,2.5,.35},180)
 p(f,'Keyboard',x,top+.07,z+1.4,{3,.14,.8},dark)
 p(f,'Mouse',x+2.1,top+.12,z+1.4,{.55,.24,.8},dark)
end
local gf=h.Emergency_and_diagnostics
local pharmacy=g('Pharmacy_dispensing');local lab=g('Laboratory_workstations');local image=g('Imaging_console')
-- Shelves against rear walls, with an uninterrupted aisle in front.
for _,m in gf:GetChildren() do
 if m:IsA('Model') and (m.Name=='Pharmacy stock' or m.Name=='Laboratory') then m:PivotTo(m:GetPivot()+V(0,0,7.3)) end
 if m.Name=='Pharmacy desk' or m.Name=='Lab worktop' then retire(m) end
 if m.Name=='Imaging sign' then m.CFrame=CFrame.new(174,13,257.48) end
end
p(pharmacy,'Dispensing cabinet',91,2.5,274,{5,4,18},teal,true,.5)
p(pharmacy,'Dispensing worktop',91,4.7,274,{5.5,.4,18.5},cream,true)
for _,z in {268,274,280} do
 local s=label(pharmacy,'Dispensing label',z==274 and 'RX / COLLECTION' or 'MEDICAL SUPPLIES',93.8,3,z,{5,1.3,.16},-90)
 p(pharmacy,'Cabinet pull',88.4,3,z,{.18,.2,2.3},metal)
end
-- Packing bench fixed to the front wall.
p(pharmacy,'Packing storage',62,2.5,261,{30,4,4.5},cream,true,.5)
p(pharmacy,'Packing worktop',62,4.7,261,{31,.4,5},metal,true)
for _,x in {51,58,65,72} do
 p(pharmacy,'Packing drawer seam',x,2.5,263.3,{.08,3.7,.08},metal)
 p(pharmacy,'Packing drawer handle',x+2,3.2,263.4,{1.6,.18,.2},metal)
end
terminal(pharmacy,55,4.9,261,'RX INVENTORY')
chair(pharmacy,55,.5,266)
for _,x in {65,67,69,71} do p(pharmacy,'Medicine bottle',x,5.5,261,{.7,1.2,.7},cream);p(pharmacy,'Bottle cap',x,6.15,261,{.75,.1,.75},teal) end
p(pharmacy,'Prescription tray',75,5.04,262,{2,.28,1.6},teal)
-- Laboratory: three supported benches, each with a distinct task.
for _,x in {154,173,194} do
 p(lab,'Lab base cabinet',x,2.5,261,{13,4,4.4},cream,true,.5)
 p(lab,'Lab worktop',x,4.7,261,{13.5,.4,4.8},metal,true)
 for _,dx in {-3.2,3.2} do p(lab,'Lab cabinet handle',x+dx,3.2,263.35,{1.8,.18,.2},dark) end
 p(lab,'Washable backsplash',x,6,258.62,{13.5,3,.35},cream)
end
label(lab,'Laboratory identity','LABORATORY / SPECIMENS',175,12,258.58,{32,2.7,.2},180)
-- Microscope with connected base, arm, stage, barrel and eyepiece.
p(lab,'Microscope base',154,5.08,261,{2.4,.36,2},cream)
p(lab,'Microscope arm',154,6.4,260.4,{.45,2.5,.45},metal)
p(lab,'Microscope stage',154,6,261,{1.7,.2,1.5},dark)
p(lab,'Microscope head',154,7.5,261,{.65,.65,1.6},cream)
p(lab,'Microscope lens',154,7,261.55,{.4,.5,.4},dark)
p(lab,'Microscope eyepiece',154,7.9,260.5,{.45,.5,.45},dark)
-- Inset-looking sink and visibly attached faucet.
p(lab,'Sink basin',173,4.93,261,{5,.06,3},dark)
for _,dx in {-2.55,2.55} do p(lab,'Sink rim',173+dx,5.02,261,{.18,.22,3.3},cream) end
for _,dz in {-1.6,1.6} do p(lab,'Sink rim',173,5.02,261+dz,{5.3,.22,.18},cream) end
p(lab,'Faucet stem',173,5.65,259.5,{.25,1.5,.25},metal)
p(lab,'Faucet spout',173,6.35,260.1,{.25,.25,1.4},metal)
p(lab,'Specimen analyser',194,5.9,261,{5,2,3},cream)
label(lab,'Analyser display','READY / SAMPLE',194,6.2,262.58,{3,1,.15},180)
p(lab,'Specimen rack',200,5.1,261,{2.6,.4,1.7},teal)
for _,x in {199.2,200,200.8} do p(lab,'Sample tube',x,5.75,261,{.35,1.2,.35},cream);p(lab,'Sample lid',x,6.4,261,{.4,.15,.4},teal) end
-- Imaging bed no longer cuts through the laboratory partition.
local tablepart=gf:FindFirstChild('Scanner table');assert(tablepart);tablepart.Position=V(173,3.5,245.5)
p(image,'Scanner bed pedestal',173,1.7,247,{4,2.4,8},metal,true,.5)
local skid=gf:FindFirstChild('Scanner base');skid.Position+=V(0,.5,0);skid:SetAttribute('FloorY13',.5)
p(image,'Operator cabinet',146,2.5,252,{11,4,4},teal,true,.5)
p(image,'Operator worktop',146,4.7,252,{11.5,.4,4.5},cream,true)
terminal(image,146,4.9,252,'IMAGING / STANDBY');chair(image,146,.5,256)
label(image,'Scanner safety sign','IMAGING / KEEP CLEAR',173,12,238.35,{9,1.5,.2})
-- Both upper-level nurse stations get supported terminals, working seats and wall storage.
for floor=1,2 do
 local F=floor*18+.5;local level=h['Level_'..floor];local f=g('Nurse_station_'..floor)
 for _,q in level:GetChildren() do if q.Name=='Nursing terminal' then retire(q) end end
 local desk=level:FindFirstChild('Nurse station');desk.Position=V(68,F+2.1,212);desk.Size=V(29,4.2,5);desk:SetAttribute('FloorY13',F)
 p(f,'Nursing worktop',68,F+4.4,212,{30,.4,5.5},cream,true)
 for _,x in {60,75} do terminal(f,x,F+4.6,212,'WARD '..floor..' / PATIENTS');chair(f,x,F,218) end
 -- Back wall lies at z194; low storage stays below the windows.
 for _,x in {49,66,83} do
  p(f,'Ward file cabinet',x,F+2,196,{12,4,2.6},cream,true,F)
  for _,yy in {1,2.2,3.3} do p(f,'File drawer handle',x,F+yy,197.4,{2.6,.15,.2},metal) end
 end
 p(f,'Nurse counter return',52,F+2.1,213.8,{3,4.2,8.6},teal,true,F)
 label(f,'Nurse counter identity','NURSES / LEVEL '..floor,68,F+2.5,209.38,{22,1.6,.18})
 local stock=level:FindFirstChild('Ward medicine cabinet');if stock then stock:PivotTo(stock:GetPivot()+V(0,0,-15.7)) end
end
-- Hang existing corridor signs from the slab instead of leaving them unsupported.
local fix=g('Signs_and_service_mounts')
for _,q in h:GetDescendants() do if q:IsA('BasePart') and q.Name=='Level guide' then
 local top=q.Position.Y+q.Size.Y/2;local ceiling=(math.floor(q.Position.Y/18)+1)*18
 for _,dx in {-10,10} do p(fix,'Wayfinding suspension',q.Position.X+dx,(top+ceiling)/2,q.Position.Z,{.15,ceiling-top,.15},metal) end
end end
for _,q in h.Emergency_generator_room:GetChildren() do
 if q.Name=='Generator skid' then q.Position+=V(0,.5,0);q:SetAttribute('FloorY13',.5) end
end
root:SetAttribute('RemovedDuplicateLights',removed)
print('HOSPITAL13 APPLIED: duplicate room lamps retired',removed,'new detail parts',#root:GetDescendants())
