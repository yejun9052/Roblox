-- Test only: teleport once per district, walk each sampled street segment normally.
local player=assert(game.Players.LocalPlayer)
local char=player.Character or player.CharacterAdded:Wait();local hu=char:WaitForChild('Humanoid');local hr=char:WaitForChild('HumanoidRootPart')
local routes={
 {name='SOUTH_RESIDENTIAL',start={480,5,1800},points={{520,4,1800},{560,4,1800},{600,4,1800}}},
 {name='COMMERCIAL',start={360,5,1200},points={{400,4,1200},{440,4,1200},{480,4,1200}}},
 {name='HOSPITAL_APPROACH',start={240,5,120},points={{200,4,120},{160,4,120},{120,4,120},{120,4,160},{120,4,200}}},
 {name='EAST_PUBLIC',start={1200,5,720},points={{1200,4,760},{1200,4,800},{1200,4,840}}}
}
local passed,total=0,0
hu.WalkSpeed=16
workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=hu
for _,r in routes do
 char:PivotTo(CFrame.new(Vector3.new(table.unpack(r.start))));hr.AssemblyLinearVelocity=Vector3.zero
 task.wait(2)
 for i,t in r.points do
  total+=1;hu:MoveTo(Vector3.new(table.unpack(t)));local ok=hu.MoveToFinished:Wait()
  print('CITY16 WALK',r.name,i,ok,hr.Position)
  if ok then passed+=1 else warn('CITY16 BLOCKED',r.name,i);break end
 end
end
print('CITY16 PLAY RESULT',passed,'passed',total,'attempted','14 planned')
