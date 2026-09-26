-- Explicit edit-mode polish. Old props retained in ServerStorage; no runtime scripts.
local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(not h:FindFirstChild('Interior_quality_12'),'Revision already applied')
local V,C=Vector3.new,Color3.fromRGB
local root=Instance.new('Model');root.Name='Interior_quality_12';root.Parent=h
local archive=Instance.new('Model');archive.Name='Hospital_before_12';archive.Parent=game.ServerStorage
local cream,teal,metal,dark=C(188,190,176),C(56,91,88),C(82,91,90),C(29,39,42)
local function group(n) local m=Instance.new('Model');m.Name=n;m.Parent=root;return m end
local function p(f,n,x,y,z,s,c,solid)
 local q=Instance.new('Part');q.Name=n;q.Position=V(x,y,z);q.Size=V(table.unpack(s));q.Color=c or cream;q.Anchored=true;q.CanCollide=solid==true;q.CanTouch=false;q.Material=Enum.Material.SmoothPlastic;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=f;return q
end
local function sign(f,n,t,x,y,z,s,angle)
 local q=p(f,n,x,y,z,s,teal);q.CFrame*=CFrame.Angles(0,math.rad(angle or 0),0)
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.PixelsPerStud=40;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.LightInfluence=.15;g.Parent=q
 local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Size=UDim2.fromScale(.92,.8);l.Position=UDim2.fromScale(.04,.1);l.Font=Enum.Font.GothamMedium;l.TextScaled=true;l.TextWrapped=true;l.Text=t;l.TextColor3=cream;l.Parent=g;return q
end
local function retire(q) q:SetAttribute('PreviousParent12',q.Parent:GetFullName());q.Parent=archive end
-- All 51 room/corridor luminaires meet the slab, with a real casing.
local lights=group('Flush_mounted_lighting');local nlights=0
for _,q in h:GetDescendants() do
 if q:IsA('BasePart') and (q.Name=='Ceiling luminaire' or q.Name=='Ceiling light diffuser') then
  local floor=math.floor(q.Position.Y/18);local ceiling=(floor+1)*18
  q:SetAttribute('OriginalY12',q.Position.Y);q.Position=V(q.Position.X,ceiling-.38,q.Position.Z)
  local housing=p(lights,'Ceiling fixed housing',q.Position.X,ceiling-.15,q.Position.Z,{q.Size.X+.5,.3,q.Size.Z+.5},metal)
  housing:SetAttribute('CeilingY',ceiling)
  q.Size=V(q.Size.X,.16,q.Size.Z);q.Material=Enum.Material.Neon
  for _,l in q:GetChildren() do if l:IsA('PointLight') then l.Brightness=.65;l.Range=30 end end
  local l=Instance.new('SurfaceLight');l.Face=Enum.NormalId.Bottom;l.Angle=125;l.Brightness=.65;l.Range=24;l.Color=C(235,230,211);l.Parent=q
  nlights+=1
 end
end
-- Replace the unsupported reading-light furniture with coherent bedside service units.
local ward=h:FindFirstChild('Ward_details')
if ward then for _,q in ward:GetChildren() do
 if q.Name=='Bedside overhead service rail' or q.Name=='Patient reading light' or q.Name=='Reading light upright' then retire(q)
 elseif q.Name=='Privacy curtain track' then
  local ceiling=(math.floor(q.Position.Y/18)+1)*18
  for _,dz in {-5,5} do local bottom=q.Position.Y+.125;p(lights,'Curtain track ceiling hanger',q.Position.X,(ceiling+bottom)/2,q.Position.Z+dz,{.12,ceiling-bottom,.12},metal) end
 end
end end
local medical=group('Bedside_support_and_services');local beds=0
for _,bay in h:GetDescendants() do if bay:IsA('Model') and bay.Name=='Patient bay' then
 local frame=bay:FindFirstChild('Bed frame');local cabinet=bay:FindFirstChild('Bedside cabinet');local monitor=bay:FindFirstChild('Monitor')
 if frame and cabinet and monitor then
  local x,z=frame.Position.X,frame.Position.Z;local floor=math.floor(frame.Position.Y/18)*18+.5
  -- Castors meet the floor, stems connect to the bed underframe.
  for _,q in bay:GetChildren() do if q:IsA('BasePart') and q.Name=='Castor' then q.Position=V(q.Position.X,floor+.55,q.Position.Z);p(medical,'Castor stem',q.Position.X,floor+1.3,q.Position.Z,{.32,1.5,.32},metal) end end
  local top=cabinet.Position.Y+cabinet.Size.Y/2;local bottom=monitor.Position.Y-monitor.Size.Y/2
  p(medical,'Monitor weighted foot',monitor.Position.X,top+.1,monitor.Position.Z,{2.2,.2,1.1},metal)
  p(medical,'Monitor support neck',monitor.Position.X,(top+bottom)/2,monitor.Position.Z,{.28,bottom-top,.3},metal)
  -- A floor-supported headboard anchors the light and medical outlets visually.
  for _,dx in {-2.7,2.7} do p(medical,'Headboard support',x+dx,floor+3.8,z-5.95,{.24,7.6,.35},metal) end
  p(medical,'Patient service headboard',x,floor+6.6,z-5.95,{6.3,2,.38},teal)
  p(medical,'Attached reading light',x,floor+7.9,z-5.7,{3,.35,.85},cream)
  for _,dx in {-1.5,0,1.5} do p(medical,'Medical service outlet',x+dx,floor+6.4,z-5.7,{.6,.55,.15},cream) end
  p(medical,'IV base crossbar',x-4.5,floor+.12,z-3,{2.3,.24,.35},metal)
  p(medical,'IV base crossbar',x-4.5,floor+.12,z-3,{.35,.24,2.3},metal)
  p(medical,'IV bag hook',x-4.2,floor+8.4,z-3,{.8,.18,.18},metal)
  beds+=1
 end
end end
-- Rework the public foyer, retaining clinical rooms and wide central circulation.
local gf=h.Emergency_and_diagnostics
for _,q in gf:GetChildren() do if q.Name=='Reception desk' or q.Name=='Reception terminal' or q.Name=='Chair' then retire(q) end end
for _,q in h.Architectural_finish:GetChildren() do
 if q.Name=='Reception identity' or q.Name=='Reception drawer cabinet' or q.Name=='Drawer handle' then retire(q) end
end
local lobby=group('Reception_and_staff_workspace')
p(lobby,'Reception backdrop wall',58.5,9.25,223.8,{68,17.5,.6},cream,true)
p(lobby,'Backdrop end pier',104,9.25,223.8,{4,17.5,.6},cream,true)
p(lobby,'Triage doorway header',97.5,14,223.8,{9,8,.6},cream,true)
p(lobby,'Lower wall panel',58.5,2.5,223.42,{68,4,.16},teal)
sign(lobby,'Reception wall identity','SURTER MEDICAL\nRECEPTION / CHECK IN',66,10,223.35,{29,4,.18})
sign(lobby,'Triage entrance plaque','TRIAGE',97.5,11,223.35,{8,1.4,.18})
-- Two service positions and a lower accessible counter at the open end.
p(lobby,'Counter front panel',66,2.6,209.2,{34,4.2,.65},teal,true)
p(lobby,'Counter worktop',66,4.9,211,{35,.4,5},C(173,151,116),true)
for _,x in {49.5,82.5} do p(lobby,'Counter end support',x,2.6,211,{.6,4.2,4.2},teal,true) end
p(lobby,'Accessible worktop',89,3.4,211,{10,.35,5},C(173,151,116),true)
for _,x in {85,93} do p(lobby,'Accessible counter leg',x,1.87,212,{.35,2.74,.35},metal,true) end
sign(lobby,'Counter position','01  CHECK IN',57,3.1,208.8,{10,1.25,.15})
sign(lobby,'Counter position','02  INFORMATION',74,3.1,208.8,{13,1.25,.15})
local function chair(f,x,z,angle)
 local m=Instance.new('Model');m.Name='Grounded chair';m.Parent=f
 p(m,'Seat',x,2.6,z,{3.2,.4,3.2},teal,true);p(m,'Backrest',x,4,z+1.45,{3.2,2.7,.3},teal,true)
 for _,dx in {-1.2,1.2} do for _,dz in {-1.2,1.2} do local q=p(m,'Chair foot',x+dx,1.45,z+dz,{.25,1.9,.25},metal);q:SetAttribute('FloorContact12',true) end end
 m:PivotTo(CFrame.new(x,.5,z)*CFrame.Angles(0,math.rad(angle or 0),0)*CFrame.new(-x,-.5,-z)*m:GetPivot());return m
end
for _,x in {58,75} do
 p(lobby,'Terminal stand base',x,5.2,212,{2.6,.2,1.4},metal)
 p(lobby,'Terminal neck',x,5.75,212,{.35,1,.35},metal)
 sign(lobby,'Staff monitor','PATIENT REGISTRY',x,7.1,212,{4.2,2.4,.35},180)
 p(lobby,'Keyboard',x,5.16,213,{3,.12,.8},dark)
 p(lobby,'Mouse',x+2.2,5.2,213,{.5,.2,.8},dark)
 chair(lobby,x,216.5,0)
 p(lobby,'Wall storage cabinet',x,2.4,222,{10,3.8,2.5},cream,true)
 for _,yy in {1.4,2.5,3.6} do p(lobby,'Cabinet handle',x,yy,220.65,{2.4,.15,.2},metal) end
end
p(lobby,'Document tray',80,5.22,211,{2.5,.24,1.8},cream)
p(lobby,'Paper stack',80,5.43,211,{2.2,.18,1.5},C(215,210,187))
local wait=group('Waiting_alcove')
-- Window-side seats face the circulation space; end seats create a small L.
for _,x in {151,157,163,176,182,188} do chair(wait,x,199.8,180) end
for _,z in {207,213} do chair(wait,211,z,-90) end
p(wait,'Waiting table top',170,2.55,200,{5,.3,4},C(173,151,116),true)
for _,dx in {-1.8,1.8} do for _,dz in {-1.4,1.4} do local q=p(wait,'Table foot',170+dx,1.45,200+dz,{.23,1.9,.23},metal);q:SetAttribute('FloorContact12',true) end end
p(wait,'Waiting table magazine',170,2.76,200,{2,.12,2.7},teal)
sign(wait,'Waiting direction','WAITING AREA\nPLEASE CHECK IN AT RECEPTION',204,5,195,{17,2.8,.18},180)
-- Wall-mounted items use brackets instead of unsupported props.
p(wait,'Hand sanitiser backplate',134.5,4.2,226,{.3,2.4,1.3},metal)
p(wait,'Hand sanitiser dispenser',134.9,4.2,226,{.6,1.4,1},cream)
root:SetAttribute('BedCount',beds);root:SetAttribute('FixedLights',nlights)
print('HOSPITAL12 APPLIED',beds,'beds supported;',nlights,'lights fixed;',#archive:GetChildren(),'old props retained')
