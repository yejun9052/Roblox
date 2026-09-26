local root=workspace.City_quality_16;assert(not root:FindFirstChild('Corner_planting_verified'),'Already applied')
local f=Instance.new('Model');f.Name='Corner_planting_verified';f.Parent=root
local V,C=Vector3.new,Color3.fromRGB;local count,parts,checks=0,0,0
local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={root};rp.RespectCanCollide=true
local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Exclude;op.FilterDescendantsInstances={root};op.MaxParts=1
local function p(n,pos,size,c,m) local q=Instance.new('Part');q.Name=n;q.Position=pos;q.Size=size;q.Color=c;q.Material=m or Enum.Material.Concrete;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.TopSurface=Enum.SurfaceType.Smooth;q.BottomSurface=Enum.SurfaceType.Smooth;q.Parent=f;parts+=1;return q end
for _,q in workspace.SurterDays:GetDescendants() do if q:IsA('BasePart') and q.Name:find('_Lot_paving',1,true) then
 local r,s=q.CFrame,q.Size;local ex=math.abs(r.RightVector.X)*s.X+math.abs(r.UpVector.X)*s.Y+math.abs(r.LookVector.X)*s.Z;local ez=math.abs(r.RightVector.Z)*s.X+math.abs(r.UpVector.Z)*s.Y+math.abs(r.LookVector.Z)*s.Z
 if ex>40 and ez>40 then for _,dx in {-1,1} do
  local x,z=q.Position.X+dx*(ex/2-3),q.Position.Z+ez/2-3
  local hit=workspace:Raycast(V(x,8,z),V(0,-12,0),rp)
  if hit and hit.Position.Y<1 then
   local y=hit.Position.Y;local at=V(x,y,z);checks+=1
   if #workspace:GetPartBoundsInBox(CFrame.new(at+V(0,2.1,0)),V(4,4,4),op)==0 then
    p('Grounded planter',at+V(0,.4,0),V(3.8,.8,3.8),C(104,108,95))
    p('Soil inset',at+V(0,.83,0),V(3.3,.06,3.3),C(58,54,40),Enum.Material.Ground)
    for _,shift in {-0.8,.8} do local b=p('Low shrub',at+V(shift,1.65,0),V(2.2,1.7,2.7),C(72,92,61),Enum.Material.Grass);b.Shape=Enum.PartType.Ball end
    count+=1
   end
  end
 end end
end end
root:SetAttribute('CornerPlanters',count);root:SetAttribute('CornerParts',parts);print('CITY16 COURTYARDS',count,'planters',parts,'parts',checks,'space checks')
