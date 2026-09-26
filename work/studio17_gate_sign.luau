local root=workspace.Campus_quality_17
assert(not root:FindFirstChild('School_wayfinding_frame'),'Already applied')
local sign=workspace.SurterDays.SchoolGrounds_WestGate:FindFirstChildWhichIsA('BasePart')
assert(sign and sign.Transparency==1,'Expected original transparent text carrier')
local V=Vector3.new
local cf=CFrame.new(1243,7.5,891)*CFrame.Angles(0,math.pi/2,0)
local op=OverlapParams.new();op.FilterType=Enum.RaycastFilterType.Exclude;op.FilterDescendantsInstances={sign}
assert(#workspace:GetPartBoundsInBox(cf,V(17,10,2),op)==0,'Sign placement occupied')
local supports={}
for _,dx in {-6.4,6.4} do
 local at=(cf*CFrame.new(dx,0,.2)).Position
 local hit=workspace:Raycast(V(at.X,3,at.Z),V(0,-5,0))
 assert(hit and hit.Normal.Y>.98 and hit.Position.Y<1,'No sign footing')
 table.insert(supports,{at=at,y=hit.Position.Y})
end
local m=Instance.new('Model');m.Name='School_wayfinding_frame';m.Parent=root
local function p(n,size,cframe,color)
 local q=Instance.new('Part');q.Name=n;q.Size=size;q.CFrame=cframe;q.Anchored=true;q.CanCollide=false;q.CanTouch=false;q.Color=color;q.Material=Enum.Material.Metal;q.Parent=m;return q
end
sign:SetAttribute('CFrameBefore17',sign.CFrame);sign.CFrame=cf
p('Solid sign backing',V(16,3.3,.3),cf*CFrame.new(0,0,.18),Color3.fromRGB(42,65,62))
p('Sign top cap',V(16.4,.2,.6),cf*CFrame.new(0,1.75,.18),Color3.fromRGB(105,116,103))
for _,s in supports do
 local h=7.5-s.y
 p('Grounded sign post',V(.4,h,.4),CFrame.new(s.at.X,s.y+h/2,s.at.Z),Color3.fromRGB(60,72,70))
end
root:SetAttribute('SignSupportChecks',2)
print('CAMPUS17 SIGN fixed floating text; 2 grounded posts; 4 new noncolliding parts')
