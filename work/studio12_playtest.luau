-- Run only in Studio Play client. Initial placement is setup; normal walking thereafter.
local player=assert(game:GetService('Players').LocalPlayer)
local char=player.Character or player.CharacterAdded:Wait()
local humanoid=char:WaitForChild('Humanoid');local hrp=char:WaitForChild('HumanoidRootPart')
char:PivotTo(CFrame.new(120,4.5,184));humanoid.WalkSpeed=16
workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=humanoid
local points={{120,4,205},{96,4,205},{96,4,218},{97.5,4,231},{97.5,4,240},{120,4,240},{120,4,205},{150,4,205},{200,4,205},{150,4,205},{120,4,205},{120,4,274},{120,4,298},{116,4,300},{116,22,333},{128,22,338},{128,22,309},{145,22,309},{180,22,319}}
task.wait(1);local passed=0
for i,p in points do
 humanoid:MoveTo(Vector3.new(table.unpack(p)))
 local ok=humanoid.MoveToFinished:Wait()
 print('HOSPITAL12 WALK',i,ok,hrp.Position)
 if not ok then warn('HOSPITAL12 WALK STOPPED',i);break end
 passed+=1
end
print('HOSPITAL12 PLAY RESULT',passed,'/',#points)
