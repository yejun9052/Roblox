-- Explicit editor repair: individually identified assemblies, no gameplay scripts.
local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(not h:FindFirstChild('Furniture_fit_18'),'Already applied')
local V,C=Vector3.new,Color3.fromRGB
local root=Instance.new('Model');root.Name='Furniture_fit_18';root.Parent=h
local records=Instance.new('Folder');records.Name='Item_audit';records.Parent=root
local moved,changed,rows,checks={},{},{},{}
local function note(id,kind,before,after,why)
 local r=Instance.new('StringValue');r.Name=id;r.Value=kind..' | '..why;r:SetAttribute('Before',before);r:SetAttribute('After',after);r.Parent=records
end
local function shift(q,d)
 if not q:GetAttribute('CFrameBefore18') then q:SetAttribute('CFrameBefore18',q.CFrame) end
 q.CFrame+=d;moved[q]=true
end
local function resize(q,s)
 if not q:GetAttribute('SizeBefore18') then q:SetAttribute('SizeBefore18',q.Size) end
 q.Size=s;changed[q]=true
end
local function parts(m) local a={};if m:IsA('BasePart') then return {m} end;for _,p in m:GetDescendants() do if p:IsA('BasePart') then table.insert(a,p) end end;return a end
local function move(m,d) for _,p in parts(m) do shift(p,d) end end
local function check(q,dir,label,gap)
 table.insert(checks,{q=q,dir=dir,label=label,gap=gap or .02})
 q:SetAttribute('WallCheck18',dir);q:SetAttribute('WallGap18',gap or .02)
end
local wallNames={['Room partition']=true,['Window sill wall']=true,['Front sill']=true,['Window header wall']=true,['Window pier']=true,['Door lintel']=true,['Ward corridor wall']=true,['Reception backdrop wall']=true,['Backdrop end pier']=true,['Triage doorway header']=true}
local walls={};for _,q in h:GetDescendants() do if q:IsA('BasePart') and wallNames[q.Name] then table.insert(walls,q) end end
local wallRay=RaycastParams.new();wallRay.FilterType=Enum.RaycastFilterType.Include;wallRay.FilterDescendantsInstances=walls
-- Snapshot every bed first so detached detail parts can be matched to their original bed.
local beds={};for _,b in h:GetDescendants() do if b:IsA('Model') and b.Name=='Patient bay' then
 local p=b:FindFirstChild('Bed frame');assert(p);table.insert(beds,{m=b,at=p.Position,floor=math.floor(p.Position.Y/18)})
end end
table.sort(beds,function(a,b) if a.at.Y~=b.at.Y then return a.at.Y<b.at.Y elseif a.at.Z~=b.at.Z then return a.at.Z<b.at.Z else return a.at.X<b.at.X end end)
for i,b in beds do
 b.id=string.format('BED_%02d',i);b.delta=V(0,0,0)
 local probe=workspace:Raycast(V(b.at.X,b.floor*18+6,b.at.Z-6.2),V(0,0,-15),wallRay)
 if probe and probe.Normal.Z>.99 then
  b.wall=probe.Position.Z;b.delta=V(0,0,b.wall+6.2-b.at.Z)
 end
end
local detached=h.Interior_quality_12.Bedside_support_and_services
local detailOwners={}
for _,q in detached:GetChildren() do if q:IsA('BasePart') then
 local best,dist=nil,math.huge
 for _,b in beds do if math.floor(q.Position.Y/18)==b.floor then local d=(V(q.Position.X,0,q.Position.Z)-V(b.at.X,0,b.at.Z)).Magnitude;if d<dist then best,dist=b,d end end end
 assert(best and dist<12,'Unassigned bedside detail '..q.Name);detailOwners[q]=best
end end
local bedMoves,freeBeds=0,0
for _,b in beds do
 b.m:SetAttribute('ReviewId18',b.id)
 if b.wall then
  move(b.m,b.delta);bedMoves+=1
  note(b.id,'Patient bay',b.at,b.at+b.delta,'Move coherent bed assembly to existing partition; headboard rear gap 0.06')
 else freeBeds+=1;note(b.id,'Patient bay',b.at,b.at,'Front open ward: freestanding supported assembly retained; no wall behind, nurse circulation preserved') end
end
for q,b in detailOwners do if b.wall then shift(q,b.delta) end end
-- Move each privacy assembly with its row, including ceiling rods, not ceiling luminaires.
local follows={['Visitor stool seat']=true,['Visitor stool support']=true,['Privacy curtain track']=true,['Gathered privacy curtain']=true,['Curtain track ceiling hanger']=true,['Curtain hanger']=true}
for _,parent in {h.Ward_details,h.Interior_quality_12.Flush_mounted_lighting} do for _,q in parent:GetChildren() do if q:IsA('BasePart') and follows[q.Name] then
 local F=math.floor(q.Position.Y/18);local best,dist=nil,math.huge
 for _,b in beds do if b.floor==F then local d=math.abs(q.Position.Z-b.at.Z);if d<dist then best,dist=b,d end end end
 assert(best and dist<10);if best.wall then shift(q,best.delta) end
end end end
-- Bedside cabinets and their monitor supports meet the same partition independently.
local cabinetMoves=0
for _,b in beds do if b.wall then
 local cab=b.m:FindFirstChild('Bedside cabinet');local monitor=b.m:FindFirstChild('Monitor')
 local d=V(0,0,b.wall+cab.Size.Z/2+.06-cab.Position.Z)
 shift(cab,d);shift(monitor,d);cabinetMoves+=1
 for q,owner in detailOwners do if owner==b and (q.Name=='Monitor weighted foot' or q.Name=='Monitor support neck') then shift(q,d) end end
 check(cab,V(0,0,-1),b.id..'_cabinet',.06)
 for q,owner in detailOwners do if owner==b and q.Name=='Patient service headboard' then check(q,V(0,0,-1),b.id..'_headboard',.06) end end
 note(b.id..'_CAB','Bedside cabinet',cab.Position-d,cab.Position,'Cabinet and monitor base moved together to partition')
end end
local gf=h.Emergency_and_diagnostics
for _,q in gf:GetChildren() do if q.Name=='Privacy screen' then shift(q,V(0,0,-10.7)) end end
-- Each medical shelf gets its own placement record and rear-wall test.
local shelfCount=0
for _,m in h:GetDescendants() do if m:IsA('Model') and (m.Name=='Pharmacy stock' or m.Name=='Laboratory' or m.Name=='Ward medicine cabinet' or m.Name=='Emergency supplies') then
 local anchor=m:FindFirstChild('Upright');assert(anchor);local before=anchor.Position;local dir=m.Name=='Ward medicine cabinet' and -1 or 1
 local hit=workspace:Raycast(anchor.Position,V(0,0,dir*15),wallRay);assert(hit,'Missing shelf wall')
 local target=hit.Position.Z-dir*(anchor.Size.Z/2+.02);move(m,V(0,0,target-anchor.Position.Z));shelfCount+=1
 local id=string.format('SHELF_%02d',shelfCount);m:SetAttribute('ReviewId18',id);check(anchor,V(0,0,dir),id);note(id,m.Name,before,anchor.Position,'Shelf uprights, shelves and cartons moved together')
end end
local clinic=h.Clinical_quality_13;local lobby=h.Interior_quality_12.Reception_and_staff_workspace
-- Low wall cabinets: preserve drawer and handle alignment.
local storageCount=0
for _,parent in {lobby,clinic.Nurse_station_1,clinic.Nurse_station_2} do
 for _,q in parent:GetChildren() do if q.Name=='Wall storage cabinet' or q.Name=='Ward file cabinet' then
  local dir=q.Name=='Wall storage cabinet' and 1 or -1;local hit=workspace:Raycast(q.Position,V(0,0,dir*3),wallRay);assert(hit)
  local before=q.Position;local dz=hit.Position.Z-dir*(q.Size.Z/2+.02)-q.Position.Z
  for _,a in parent:GetChildren() do if a:IsA('BasePart') and (a==q or ((a.Name=='Cabinet handle' or a.Name=='File drawer handle') and math.abs(a.Position.X-q.Position.X)<.01)) then shift(a,V(0,0,dz)) end end
  storageCount+=1;local id='STORAGE_'..storageCount;check(q,V(0,0,dir),id);note(id,q.Name,before,q.Position,'Individual cabinet and handles fitted to wall')
 end end
end
-- Packing and laboratory benches: each base and top has its own wall contact.
local pharm=clinic.Pharmacy_dispensing
for _,q in pharm:GetChildren() do if q:IsA('BasePart') then
 if q.Name=='Packing storage' or q.Name=='Packing drawer seam' or q.Name=='Packing drawer handle' then shift(q,V(0,0,-.33))
 elseif q.Name=='Packing worktop' or (q.Position.X<80 and q.Position.Y>4.5) then shift(q,V(0,0,-.08)) end
 if q.Name=='Packing storage' or q.Name=='Packing worktop' then check(q,V(0,0,-1),'PACK_'..q.Name) end
end end
note('PACKING','Packing bench',V(62,2.5,261),pharm['Packing storage'].Position,'Separate top and base rear gaps reduced to 0.02')
local lab=clinic.Laboratory_workstations
for _,q in lab:GetChildren() do if q:IsA('BasePart') then
 if q.Name=='Lab base cabinet' or q.Name=='Lab cabinet handle' then shift(q,V(0,0,-.38))
 elseif q.Name=='Washable backsplash' then shift(q,V(0,0,-.025))
 elseif q.Name~='Laboratory identity' then shift(q,V(0,0,-.18)) end
 if q.Name=='Lab base cabinet' or q.Name=='Lab worktop' then check(q,V(0,0,-1),'LAB_'..q.Name..'_'..q.Position.X) end
end end
for _,x in {154,173,194} do note('LAB_'..x,'Laboratory bench',V(x,2.5,261),V(x,2.5,260.62),'Base, worktop, equipment and drawer handles fitted together') end
-- Rotate only the imaging operator console to the solid side partition, clear of its door.
local imaging=clinic.Imaging_console;local turn=CFrame.new(136.67,0,251)*CFrame.Angles(0,math.pi/2,0)*CFrame.new(-146,0,-252)
for _,q in imaging:GetDescendants() do if q:IsA('BasePart') and not q.Name:find('Scanner') then
 q:SetAttribute('CFrameBefore18',q.CFrame);q.CFrame=turn*q.CFrame;moved[q]=true
 if q.Name=='Operator cabinet' then shift(q,V(-.25,0,0));check(q,V(-1,0,0),'IMAGING_cabinet') end
 if q.Name=='Operator worktop' then check(q,V(-1,0,0),'IMAGING_worktop') end
end end
note('IMAGING_CONSOLE','Operator console',V(146,2.5,252),imaging['Operator cabinet'].Position,'Rotate cabinet, terminal and chair toward solid side partition; doorway kept open')
-- Wall signs: correct backing direction; never use nearest wall blindly.
local signCount=0
local function mount(q,pos,angle,dir,why)
 local before=q.Position;shift(q,pos-q.Position);if angle then q.CFrame=CFrame.new(pos)*CFrame.Angles(0,math.rad(angle),0) end
 signCount+=1;local id='SIGN_'..signCount;check(q,dir,id);note(id,q.Name,before,pos,why or 'Rear face fitted to solid wall')
end
for _,q in h.Architectural_finish:GetChildren() do
 if q.Name=='Department sign' then local left=q.Position.X<120;mount(q,V(left and 106.51 or 133.49,q.Position.Y,q.Position.Z),nil,V(left and -1 or 1,0,0)) end
end
mount(gf['Pharmacy sign'],V(66,12,258.52),180,V(0,0,-1))
-- Rear face must stay outside the partition at z=257.6.
mount(gf['Imaging sign'],V(174,13,257.455),nil,V(0,0,1))
local directory=h.Architectural_finish['Hospital directory'];resize(directory,V(10,6,.2));mount(directory,V(138,10.5,194.62),180,V(0,0,-1),'Moved off glazing onto solid front-wall pier')
mount(h.Interior_quality_12.Waiting_alcove['Waiting direction'],V(204,5,194.61),180,V(0,0,-1))
mount(lobby['Reception wall identity'],V(66,10,223.39),nil,V(0,0,1))
mount(lobby['Triage entrance plaque'],V(97.5,11,223.39),nil,V(0,0,1))
mount(lab['Laboratory identity'],V(175,12,258.52),180,V(0,0,-1))
mount(h.Emergency_generator_room['Generator door sign'],V(149,12,292.545),180,V(0,0,-1),'Previously faced into wall; now faces generator room')
mount(h.Architectural_finish['Power service notice'],V(177,11,292.52),180,V(0,0,-1),'Previously detached and facing wrong side of partition')
local wait=h.Interior_quality_12.Waiting_alcove
shift(wait['Hand sanitiser backplate'],V(.07,0,0));shift(wait['Hand sanitiser dispenser'],V(.07,0,0))
check(wait['Hand sanitiser backplate'],V(-1,0,0),'SANITISER')
note('SANITISER','Wall dispenser',V(134.5,4.2,226),V(134.57,4.2,226),'Backplate fitted to corridor wall; dispenser follows')
-- Battery was suspended 0.9 studs above the floor; terminals follow the body.
for _,q in h.Architectural_finish:GetChildren() do if q.Name=='Battery pickup prop' or q.Name=='Battery terminal' then shift(q,V(0,-.9,0)) end end
note('BATTERY','Battery prop',V(199,3,301),V(199,2.1,301),'Grounded body; terminals moved together')
-- Independent rear-face rays, through actual structural walls, catch missed attachment gaps.
local failures={};local function radius(q,d) return (math.abs(q.CFrame.RightVector:Dot(d))*q.Size.X+math.abs(q.CFrame.UpVector:Dot(d))*q.Size.Y+math.abs(q.CFrame.LookVector:Dot(d))*q.Size.Z)/2 end
for _,c in checks do
 local at=c.q.Position+c.dir*radius(c.q,c.dir);local hit=workspace:Raycast(at-c.dir*.005,c.dir*.35,wallRay)
 local gap=hit and (hit.Position-at):Dot(c.dir) or 999
 if math.abs(gap-c.gap)>.018 then table.insert(failures,c.label..' gap='..gap) end
end
for _,s in failures do warn('H18 FAIL',s) end
assert(#failures==0,'Wall fitting verification failed')
local n=0;for _ in moved do n+=1 end
root:SetAttribute('MovedParts',n);root:SetAttribute('BedAssembliesMoved',bedMoves);root:SetAttribute('FreestandingBedsReviewed',freeBeds);root:SetAttribute('BedsideCabinetsMoved',cabinetMoves);root:SetAttribute('ShelvesMoved',shelfCount);root:SetAttribute('StorageCabinetsMoved',storageCount);root:SetAttribute('WallSignsMoved',signCount);root:SetAttribute('WallChecks',#checks);root:SetAttribute('WallFailures',#failures)
print('H18 FIT RESULT',n,'parts',bedMoves,'beds',freeBeds,'freestanding reviewed',cabinetMoves,'bedside cabinets',shelfCount,'shelves',storageCount,'storage',signCount,'signs',#checks,'wall checks',#failures,'failures',#records:GetChildren(),'item records')
