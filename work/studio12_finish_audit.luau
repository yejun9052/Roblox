local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
local root=h.Interior_quality_12;local V=Vector3.new
-- Follow-up after viewing the actual foyer; remove the superseded floating label.
local old=h.Emergency_and_diagnostics:FindFirstChild('Triage wall sign')
if old then old:SetAttribute('PreviousParent12',old.Parent:GetFullName());old.Parent=game.ServerStorage.Hospital_before_12 end
for _,q in h:GetDescendants() do if q:IsA('BasePart') then
 if q.Name=='Floor around stairwell' or q.Name=='Roof' then q.Material=Enum.Material.SmoothPlastic;q.Color=Color3.fromRGB(151,158,148) end
 if q.Name=='Patient service headboard' then q.Size=V(6.3,2.3,.38);q.Position+=V(0,.15,0) end
 if q.Name=='Ceiling ventilation frame' or q.Name=='Vent slat' then
  local ceiling=(math.floor(q.Position.Y/18)+1)*18
  q.Position=V(q.Position.X,ceiling-(q.Name=='Vent slat' and .24 or .1),q.Position.Z)
 end
end end
for _,m in root.Waiting_alcove:GetChildren() do if m:IsA('Model') and m.Name=='Grounded chair' then
 local seat=m:FindFirstChild('Seat');if seat and seat.Position.X>210 then
  local c=V(seat.Position.X,.5,seat.Position.Z);m:PivotTo(CFrame.new(c)*CFrame.Angles(0,math.pi,0)*CFrame.new(-c)*m:GetPivot())
 end
end end
-- Add physical curtain suspension rings in the gap below each track.
for _,q in h.Ward_details:GetChildren() do if q.Name=='Gathered privacy curtain' and not q:GetAttribute('Hangers12') then
 for _,dz in {-1,0,1} do local p=Instance.new('Part');p.Name='Curtain hanger';p.Size=V(.12,.6,.12);p.Position=V(q.Position.X,q.Position.Y+5.2,q.Position.Z+dz);p.Anchored=true;p.CanCollide=false;p.Color=Color3.fromRGB(82,91,90);p.Parent=root.Flush_mounted_lighting end
 q:SetAttribute('Hangers12',true)
end end
local fail={};local floorChecks,ceilingChecks,castors=0,0,0
for _,q in h:GetDescendants() do if q:IsA('BasePart') then
 if q:GetAttribute('FloorContact12') then floorChecks+=1;if math.abs(q.Position.Y-q.Size.Y/2-.5)>.02 then table.insert(fail,'Floor '..q:GetFullName()) end end
 if q:GetAttribute('CeilingY') then ceilingChecks+=1;if math.abs(q.Position.Y+q.Size.Y/2-q:GetAttribute('CeilingY'))>.02 then table.insert(fail,'Ceiling '..q:GetFullName()) end end
 if q.Name=='Castor' and q.Parent.Name=='Patient bay' then castors+=1;local floor=math.floor(q.Position.Y/18)*18+.5;if math.abs(q.Position.Y-q.Size.Y/2-floor)>.02 then table.insert(fail,'Bed wheel '..q:GetFullName()) end end
end end
local routes={
 {{120,184},{120,205}},{{120,205},{96,205}},{{96,205},{96,218}},{{96,218},{97.5,231}},{{97.5,231},{97.5,240}},{{97.5,240},{120,240}},
 {{120,205},{150,205}},{{150,205},{200,205}},{{120,205},{120,298}},{{120,274},{96,274}},{{120,274},{145,274}},{{126,298},{126,309}},{{126,309},{136,309}}
}
local rp=RaycastParams.new();rp.RespectCanCollide=true;local rays=0
for i,r in routes do
 local a,b=V(r[1][1],0,r[1][2]),V(r[2][1],0,r[2][2]);local d=b-a;local side=V(-d.Z,0,d.X).Unit
 for _,dx in {-1.35,0,1.35} do for _,y in {1.1,3.5,5.8} do local hit=workspace:Raycast(a+side*dx+V(0,y,0),d,rp);rays+=1;if hit then table.insert(fail,'Route '..i..' '..hit.Instance:GetFullName()) end end end
end
root:SetAttribute('AuditFailures',#fail);root:SetAttribute('ClearanceRays',rays)
print('HOSPITAL12 AUDIT',floorChecks,'furniture feet;',castors,'bed wheels;',ceilingChecks,'ceiling housings;',rays,'clearance rays;',#fail,'failures')
for _,s in fail do warn(s) end
local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.Focus=CFrame.new(69,5.5,218);c.CFrame=CFrame.lookAt(V(93,6.4,198.5),V(69,5.5,218));c.FieldOfView=70
game:GetService('Selection'):Set({})
