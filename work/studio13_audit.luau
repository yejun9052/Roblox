local h=workspace.Surter_Remodel_10.Surter_Medical_Centre;local root=h.Clinical_quality_13;local V=Vector3.new
local failures={};local contacts,fixtures,lights=0,0,0
for _,q in h:GetDescendants() do if q:IsA('BasePart') then
 local F=q:GetAttribute('FloorY13')
 if F then contacts+=1;if math.abs(q.Position.Y-q.Size.Y/2-F)>.02 then table.insert(failures,'Floor '..q:GetFullName()) end end
 local H=q:GetAttribute('CeilingY');if H then fixtures+=1;if math.abs(q.Position.Y+q.Size.Y/2-H)>.02 then table.insert(failures,'Ceiling '..q:GetFullName()) end end
 if q.Name=='Ceiling luminaire' or q.Name=='Ceiling light diffuser' then lights+=1 end
end end
local scanner=h.Emergency_and_diagnostics['Scanner table']
if scanner.Position.Z+scanner.Size.Z/2>257.6 then table.insert(failures,'Scanner crosses lab partition') end
local segments={
 {0,120,274,98,274},{0,98,274,98,286},{0,98,286,83,286},{0,83,286,83,274},{0,83,274,65,274},{0,65,274,65,267},
 {0,120,274,150,274},{0,150,274,200,274},{0,120,240,145,240},{0,145,240,145,247},{0,145,240,154,240},
 {0,120,205,120,298}
}
for level=1,2 do
 for _,r in {{128,210,92,210},{92,210,92,220},{92,220,84,220},{128,210,128,298},{128,274,145,274},{128,309,145,309}} do table.insert(segments,{level,table.unpack(r)}) end
end
local rp=RaycastParams.new();rp.RespectCanCollide=true;local rays=0
for i,r in segments do
 local a,b=V(r[2],0,r[3]),V(r[4],0,r[5]);local d=b-a;local side=V(-d.Z,0,d.X).Unit
 for _,dx in {-1.3,0,1.3} do for _,yy in {.6,3,5.2} do
  local hit=workspace:Raycast(a+side*dx+V(0,r[1]*18+.5+yy,0),d,rp);rays+=1
  if hit then table.insert(failures,'Route '..i..' '..hit.Instance:GetFullName()) end
 end end
end
root:SetAttribute('AuditFailures',#failures);root:SetAttribute('AuditRays',rays);root:SetAttribute('FloorContacts',contacts)
print('HOSPITAL13 AUDIT',contacts,'floor contacts;',fixtures,'ceiling mounts;',lights,'active fixtures;',rays,'clearance rays;',#failures,'failures')
for _,s in failures do warn(s) end
