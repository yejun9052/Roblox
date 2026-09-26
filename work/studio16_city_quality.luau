-- City-wide material, rooftop and streetscape pass. Explicit edit, not runtime logic.
local city=workspace.SurterDays
assert(workspace.Surter_Remodel_10.Surter_Medical_Centre:FindFirstChild('Approach_detail_15'),'Expected revision15')
assert(not workspace:FindFirstChild('City_quality_16'),'Already applied')
local root=Instance.new('Model');root.Name='City_quality_16';root.Parent=workspace
local V,C=Vector3.new,Color3.fromRGB
local palettes={residential={C(151,132,113),C(161,150,128),C(129,139,120)},commercial={C(132,146,142),C(162,149,120),C(117,132,139)},industrial={C(116,123,123),C(137,124,103),C(108,126,125)},public={C(165,164,148),C(137,153,145),C(159,151,137)}}
local stats={facade=0,glass=0,trim=0,roads=0,roofFinish=0,roofKits=0,planters=0,newParts=0,skipped=0}
local districts={};local touched={};local supportChecks={}
local function hash(s) local h=7;for i=1,#s do h=(h*31+s:byte(i))%100003 end;return h end
local function zone(q)
 local key=q.Parent.Name;local id=key:match('(B%d+)');local z=ZONES16[id] or ((key:find('School') or key:find('Gym') or key:find('Library') or key:find('Court')) and 'public') or (q.Position.X>1200 and 'residential' or q.Position.Z<900 and 'industrial' or 'commercial')
 if not palettes[z] then z='public' end;return z,key,hash(key)
end
local function recolor(q,c,m)
 if q:GetAttribute('ColorBefore16')==nil then q:SetAttribute('ColorBefore16',q.Color);q:SetAttribute('MaterialBefore16',q.Material.Name);q:SetAttribute('ReflectanceBefore16',q.Reflectance) end
 q.Color=c;q.Material=m;q.Reflectance=0;touched[q.Parent.Name]=true
end
local function extent(q)
 local cf,s=q.CFrame,q.Size
 return V(math.abs(cf.RightVector.X)*s.X+math.abs(cf.UpVector.X)*s.Y+math.abs(cf.LookVector.X)*s.Z,math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.LookVector.Y)*s.Z,math.abs(cf.RightVector.Z)*s.X+math.abs(cf.UpVector.Z)*s.Y+math.abs(cf.LookVector.Z)*s.Z)
end
local roofs,lots,roads={},{},{}
for _,q in city:GetDescendants() do if q:IsA('BasePart') then
 local n=q.Name:gsub('%.%d+$','');local z,key,seed=zone(q);local pal=palettes[z];local base=pal[seed%#pal+1]
 if n=='East wall' or n=='West wall' or n=='Rear wall' or n=='Front wall doorway wing' or n=='Front wall doorway lintel' or n:find('_Facade_stone',1,true) or n:find('_Structure_stone',1,true) then
  recolor(q,base,Enum.Material.Concrete);stats.facade+=1;districts[z]=(districts[z] or 0)+1
 elseif n=='Window glazing' or n=='Blind window' or n:find('_Facade_glass',1,true) then
  local index=(math.floor(q.Position.X/9)+math.floor(q.Position.Y/6)+math.floor(q.Position.Z/9))%7
  local colors={C(48,65,69),C(63,82,84),C(84,101,97),C(57,73,79),C(87,95,90),C(55,72,77),C(113,107,83)}
  recolor(q,colors[index+1],Enum.Material.Glass);q.Reflectance=.035;stats.glass+=1
 elseif n=='Window surround' or n=='Window sill' or n=='Window mullion' or n=='Floor facade band' or n:find('_Facade_frame',1,true) then
  recolor(q,base:Lerp(C(41,51,52),.58),Enum.Material.Metal);stats.trim+=1
 elseif n=='Roof slab' or n:find('_Roof_roof',1,true) then
  recolor(q,seed%2==0 and C(63,73,76) or C(84,87,81),Enum.Material.Concrete);stats.roofFinish+=1
  local e=extent(q);if e.X>23 and e.Z>23 and e.Y<2 then table.insert(roofs,{part=q,e=e,z=z,seed=seed}) end
 elseif n=='Broken roof ledge' then recolor(q,C(74,81,80),Enum.Material.Concrete);stats.roofFinish+=1
 elseif n=='Road surface' or n:find('EastStreetNetwork_asphalt',1,true) then
  recolor(q,C(48,53,56),Enum.Material.Asphalt);stats.roads+=1
  local e=extent(q);if e.Y<1 and math.max(e.X,e.Z)>45 and math.min(e.X,e.Z)>14 then table.insert(roads,{part=q,e=e}) end
 elseif n=='Sidewalk' or n:find('EastStreetNetwork_paving',1,true) then
  recolor(q,C(125,128,118),Enum.Material.Concrete)
 elseif n:find('_Lot_paving',1,true) then
  recolor(q,C(105,114,108),Enum.Material.Concrete);local e=extent(q);if e.X>25 and e.Z>25 and e.Y<2 then table.insert(lots,{part=q,e=e,z=z,seed=seed}) end
 end
end end
local function model(n) local m=Instance.new('Model');m.Name=n;m.Parent=root;return m end
local roofroot,streetroot,greenroot=model('Rooftop_services'),model('Street_surface_details'),model('Courtyard_planting')
local function p(parent,n,pos,size,color,mat)
 local q=Instance.new('Part');q.Name=n;q.Position=pos;q.Size=size;q.Color=color;q.Material=mat or Enum.Material.Metal;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=parent;stats.newParts+=1;return q
end
local ov=OverlapParams.new();ov.FilterType=Enum.RaycastFilterType.Exclude;ov.MaxParts=1
local function vacant(pos,size,support)
 ov.FilterDescendantsInstances={support,root};return #workspace:GetPartBoundsInBox(CFrame.new(pos),size,ov)==0
end
-- Grounded service kits vary by building instead of copying one silhouette everywhere.
for _,r in roofs do
 local q,e=r.part,r.e;local y=q.Position.Y+e.Y/2
 local candidates={V(q.Position.X-e.X*.23,y,q.Position.Z-e.Z*.23),V(q.Position.X+e.X*.23,y,q.Position.Z+e.Z*.23)}
 for _,at in candidates do if vacant(at+V(0,3.6,0),V(13,7,12),q) then
  local kit=model('Roof_'..q.Parent.Name);kit.Parent=roofroot
  local foot=p(kit,'Anchored service plinth',at+V(0,.3,0),V(11,.6,9),C(79,84,81),Enum.Material.Concrete);table.insert(supportChecks,{p=foot,y=y})
  local style=r.seed%3
  if style==0 then
   p(kit,'Air handling cabinet',at+V(0,2.5,0),V(9,3.8,7),C(130,139,129))
   for x=-3,3,1 do p(kit,'Front ventilation slat',at+V(x,2.5,-3.55),V(.35,2.8,.16),C(44,56,58)) end
   p(kit,'Outlet hood',at+V(0,4.6,0),V(5,.4,4),C(67,84,85))
  elseif style==1 then
   p(kit,'Utility enclosure',at+V(-1,2.2,0),V(7,3.2,6),C(108,125,117))
   p(kit,'Metal roof cap',at+V(-1,4,0),V(7.6,.4,6.6),C(66,76,77))
   p(kit,'Exhaust riser',at+V(3.5,3,0),V(1.3,4.8,1.3),C(107,113,106))
   p(kit,'Exhaust weather hood',at+V(3.5,5.55,0),V(2.2,.3,2.2),C(59,69,70))
  else
   for _,x in {-2.5,2.5} do
    p(kit,'Skylight frame',at+V(x,1,0),V(4,.8,7),C(53,69,71))
    p(kit,'Skylight glazing',at+V(x,1.45,0),V(3.4,.1,6.3),C(86,119,120),Enum.Material.Glass)
    p(kit,'Skylight crossbar',at+V(x,1.54,0),V(3.6,.08,.2),C(47,62,64))
   end
  end
  stats.roofKits+=1;break
 else stats.skipped+=1 end end
end
-- Shallow road repairs and drain grilles follow actual road rectangles; no collision added.
for i,r in roads do
 local q,e=r.part,r.e;local horizontal=e.X>e.Z;local long=math.max(e.X,e.Z);local narrow=math.min(e.X,e.Z)
 if narrow<45 then
  local y=q.Position.Y+e.Y/2+.025;local at=q.Position+(horizontal and V(long*.19,0,narrow*.24) or V(narrow*.24,0,long*.19));at=V(at.X,y,at.Z)
  local sz=horizontal and V(11,.04,3.5) or V(3.5,.04,11)
  if vacant(at+V(0,.2,0),V(sz.X,.3,sz.Z),q) then p(streetroot,'Asphalt maintenance patch',at,sz,C(42,47,49),Enum.Material.Asphalt) end
  if i%2==0 then
   local drainAt=q.Position+(horizontal and V(-long*.2,0,narrow*.40) or V(narrow*.40,0,-long*.2));drainAt=V(drainAt.X,y,drainAt.Z)
   if vacant(drainAt+V(0,.2,0),V(3,.3,3),q) then
    p(streetroot,'Road drainage frame',drainAt,V(2.8,.04,2.8),C(31,39,40))
    for dx=-1,1,.5 do p(streetroot,'Road drainage bar',drainAt+V(dx,.035,0),V(.16,.03,2.4),C(84,95,94)) end
   end
  end
 end
end
-- Planting is reserved for empty lot corners; pavement and doorways remain usable.
for _,r in lots do
 local q,e=r.part,r.e;local y=q.Position.Y+e.Y/2
 for _,sgn in {-1,1} do
  local at=V(q.Position.X+sgn*(e.X/2-6),y,q.Position.Z-e.Z/2+6)
  if vacant(at+V(0,6,0),V(9,12,9),q) then
   local kit=model('Planter_'..q.Parent.Name);kit.Parent=greenroot
   local foot=p(kit,'Planter base',at+V(0,.25,0),V(7,.5,7),C(88,96,88),Enum.Material.Concrete);table.insert(supportChecks,{p=foot,y=y})
   p(kit,'Planter soil',at+V(0,.6,0),V(6.3,.2,6.3),C(62,59,46),Enum.Material.Ground)
   for _,dx in {-3.35,3.35} do p(kit,'Planter rim',at+V(dx,.9,0),V(.3,1.3,7),C(112,115,103),Enum.Material.Concrete) end
   for _,dz in {-3.35,3.35} do p(kit,'Planter rim',at+V(0,.9,dz),V(7,1.3,.3),C(112,115,103),Enum.Material.Concrete) end
   p(kit,'Tree trunk',at+V(0,3.3,0),V(.8,5.2,.8),C(94,82,66),Enum.Material.Wood)
   for j=0,2 do local crown=p(kit,'Low poly crown',at+V((j-1)*1.7,6.3+j*.9,(j%2)*1.1),V(4.5,4.8,4.5),C(74+j*7,94+j*5,66+j*5),Enum.Material.Grass);crown.Shape=Enum.PartType.Ball end
   stats.planters+=1;break
  end
 end
end
-- Save prior environment settings; keep shadow detail readable without washing out distant blocks.
local light=game.Lighting
for _,k in {'ClockTime','Brightness','ExposureCompensation','Ambient','OutdoorAmbient','FogStart','FogEnd'} do root:SetAttribute('LightingBefore_'..k,light[k]) end
light.ClockTime=16.4;light.Brightness=2;light.ExposureCompensation=.1;light.Ambient=C(63,69,76);light.OutdoorAmbient=C(105,112,117);light.FogStart=1200;light.FogEnd=6500
for _,fx in light:GetChildren() do
 if fx:IsA('Atmosphere') then
  for _,k in {'Density','Offset','Haze','Glare','Color','Decay'} do root:SetAttribute('AtmosphereBefore_'..k,fx[k]) end
  fx.Density=.095;fx.Offset=.1;fx.Haze=.55;fx.Glare=.06;fx.Color=C(183,194,194);fx.Decay=C(116,124,132)
 elseif fx:IsA('ColorCorrectionEffect') then
  for _,k in {'Brightness','Contrast','Saturation','TintColor'} do root:SetAttribute('GradeBefore_'..k,fx[k]) end
  fx.Brightness=0;fx.Contrast=.08;fx.Saturation=-.12;fx.TintColor=C(247,247,239)
 end
end
local failures=0
for _,t in supportChecks do if math.abs(t.p.Position.Y-t.p.Size.Y/2-t.y)>.02 then failures+=1;warn('CITY16 SUPPORT',t.p.Name) end end
local addedSolid=0;for _,q in root:GetDescendants() do if q:IsA('BasePart') and q.CanCollide then addedSolid+=1 end end
local groupCount=0;for _ in touched do groupCount+=1 end
for k,v in stats do root:SetAttribute(k,v) end
root:SetAttribute('SupportChecks',#supportChecks);root:SetAttribute('SupportFailures',failures);root:SetAttribute('NewColliders',addedSolid);root:SetAttribute('TouchedGroups',groupCount)
print('CITY16 COMPLETE',game:GetService('HttpService'):JSONEncode(stats),'groups',groupCount,'supports',#supportChecks,'failures',failures,'new colliders',addedSolid)
print('CITY16 DISTRICTS',game:GetService('HttpService'):JSONEncode(districts))
