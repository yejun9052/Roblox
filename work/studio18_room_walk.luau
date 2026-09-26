-- Play client; one setup teleport per floor, then normal walking through changed rooms.
local char=game:GetService('Players').LocalPlayer.Character;local hu=char.Humanoid;local passed,total=0,0
local routes={
 {0,{{120,240},{98,240},{60,246},{98,246},{98,240},{120,240}}},
 {1,{{128,274},{145,274},{202,277},{145,277},{128,274},{98,274},{35,277},{98,277},{128,274},{128,309},{145,309},{202,312},{145,312},{128,309},{98,309},{35,312},{98,312}}},
 {2,{{128,274},{145,274},{202,277},{145,277},{128,274},{98,274},{35,277},{98,277},{128,274},{128,309},{145,309},{202,312},{145,312},{128,309},{98,309},{35,312},{98,312}}}
}
for _,r in routes do
 local y=r[1]*18+4;local first=r[2][1];char:PivotTo(CFrame.new(first[1],y,first[2]));task.wait(.7)
 for i=2,#r[2] do local p=r[2][i];total+=1;hu:MoveTo(Vector3.new(p[1],y,p[2]));local ok=hu.MoveToFinished:Wait();print('H18 ROOM WALK',r[1],i,ok,char.HumanoidRootPart.Position);if not ok then warn('H18 ROOM STOP',r[1],i);return end;passed+=1 end
end
print('H18 ROOM RESULT',passed,total)

