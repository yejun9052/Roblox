local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
local root=h.Interior_quality_12;local V=Vector3.new
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
print('HOSPITAL12 AUDIT',floorChecks,'furniture feet;',castors,'bed wheels;',ceilingChecks,'ceiling housings;',rays,'clearance rays;',#fail,'failures')
for _,s in fail do warn(s) end
