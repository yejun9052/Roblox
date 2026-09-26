-- Play client only. Test setup teleports once; all route legs use normal walking.
local player=assert(game:GetService('Players').LocalPlayer)
local char=player.Character or player.CharacterAdded:Wait();local hu=char:WaitForChild('Humanoid');local hrp=char:WaitForChild('HumanoidRootPart')
char:PivotTo(CFrame.new(120,4.5,205));hu.WalkSpeed=16
workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=hu
local points={{120,4,240},{145,4,240},{145,4,247},{145,4,240},{120,4,240},{120,4,274},{150,4,274},{200,4,274},{150,4,274},{120,4,274},{98,4,274},{98,4,286},{83,4,286},{83,4,274},{65,4,274},{65,4,267},{65,4,274},{83,4,274},{83,4,286},{98,4,286},{98,4,274},{120,4,274},{120,4,298},{116,4,300},{116,22,333},{128,22,338},{128,22,298},{128,22,210},{92,22,210},{92,22,220},{84,22,220},{92,22,220},{92,22,210},{128,22,210},{128,22,298},{116,22,300},{116,40,333},{128,40,338},{128,40,309},{145,40,309},{128,40,309},{128,40,210},{92,40,210},{92,40,220},{84,40,220}}
task.wait(1);local passed=0
for i,p in points do
 hu:MoveTo(Vector3.new(table.unpack(p)));local ok=hu.MoveToFinished:Wait()
 print('HOSPITAL18 WALK',i,ok,hrp.Position)
 if not ok then warn('HOSPITAL18 WALK STOPPED',i);break end
 passed+=1
end
print('HOSPITAL18 PLAY RESULT',passed,'/',#points)
