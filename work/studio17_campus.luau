-- Editor-only campus furniture and wayfinding. Preserve all existing geometry.
assert(not workspace:FindFirstChild('Campus_quality_17'),'Already applied')
local campus=workspace.Surter_Remodel_10.School_Athletics
local scoreboard=assert(campus:FindFirstChild('Scoreboard'))
assert(scoreboard:IsA('BasePart'))
local V,C=Vector3.new,Color3.fromRGB
local root=Instance.new('Model');root.Name='Campus_quality_17';root.Parent=workspace
local count,stations,checks,skipped=0,0,0,0
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={root}
local ov=OverlapParams.new();ov.FilterType=Enum.RaycastFilterType.Exclude;ov.FilterDescendantsInstances={root}
local function part(parent,name,pos,size,color,material)
 local q=Instance.new('Part');q.Name=name;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.Size=size;q.Position=pos;q.Color=color;q.Material=material or Enum.Material.Metal;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=parent;count+=1;return q
end
local function label(q,face,text)
 local g=Instance.new('SurfaceGui');g.Name='Campus_wayfinding_17';g.Face=face;g.AlwaysOnTop=false;g.LightInfluence=1;g.CanvasSize=Vector2.new(900,300);g.Parent=q
 local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.9,.86);t.Position=UDim2.fromScale(.05,.07);t.Text=text;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.TextColor3=C(221,222,201);t.Parent=g
end
-- The street-facing side was blank; the field-facing score display is preserved.
label(scoreboard,Enum.NormalId.Back,'SURTER SCHOOL\nATHLETICS  /  EAST CAMPUS')
for _,z in {684,772,860,992,1038} do
 local x=1250
 local hit=workspace:Raycast(V(x,8,z),V(0,-12,0),ray)
 if not hit or hit.Position.Y>1.5 or hit.Normal.Y<.98 then skipped+=1;continue end
 local y=hit.Position.Y
 local occupied=workspace:GetPartBoundsInBox(CFrame.new(x,y+3.3,z),V(10,6,17),ov)
 if #occupied>0 then skipped+=1;continue end
 local supported=true
 for _,dx in {-1.1,1.1} do for _,dz in {-3.5,3.5} do
  local h=workspace:Raycast(V(x+dx,y+1,z+dz),V(0,-2,0),ray)
  if not h or math.abs(h.Position.Y-y)>.06 then supported=false end
 end end
 if not supported then skipped+=1;continue end
 local m=Instance.new('Model');m.Name='Campus_rest_point_'..z;m.Parent=root
 -- Long axis follows the verge; backs face away from the public footway.
 for _,dx in {-1.1,1.1} do for _,dz in {-3.5,3.5} do part(m,'Grounded bench leg',V(x+dx,y+1,z+dz),V(.35,2,.35),C(49,62,63));checks+=1 end end
 for dx=-1.2,1.2,.6 do part(m,'Timber seat slat',V(x+dx,y+2.15,z),V(.5,.3,8.3),C(123,102,74),Enum.Material.Wood) end
 for _,dz in {-3.5,3.5} do part(m,'Back support',V(x+1.2,y+3.1,z+dz),V(.3,2.3,.3),C(49,62,63)) end
 for _,dy in {3,3.65} do part(m,'Timber backrest',V(x+1.25,y+dy,z),V(.3,.5,8.3),C(123,102,74),Enum.Material.Wood) end
 -- Bin is grounded and outside the bench circulation space.
 local bh=workspace:Raycast(V(x,8,z+6.5),V(0,-12,0),ray)
 if bh and math.abs(bh.Position.Y-y)<.06 then
  part(m,'Litter bin',V(x,y+1.65,z+6.5),V(2.3,3.3,2.3),C(55,77,70));checks+=1
  part(m,'Bin cap',V(x,y+3.4,z+6.5),V(2.5,.2,2.5),C(99,110,101))
  part(m,'Bin opening',V(x-1.16,y+2.75,z+6.5),V(.03,.55,1.4),C(24,31,32))
 end
 stations+=1
end
root:SetAttribute('RestPoints',stations);root:SetAttribute('NewParts',count);root:SetAttribute('SupportChecks',checks);root:SetAttribute('SkippedOccupied',skipped);root:SetAttribute('NewColliders',0)
assert(stations>0,'No suitable campus rest locations; inspect before retrying')
print('CAMPUS17 RESULT',stations,'rest points',count,'parts',checks,'support checks',skipped,'skipped','0 new colliders')
