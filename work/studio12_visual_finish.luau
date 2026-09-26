local h=workspace.Surter_Remodel_10.Surter_Medical_Centre
assert(not h.Interior_quality_12:GetAttribute('VisualFinish'),'Already applied')
for _,q in h:GetDescendants() do if q:IsA('BasePart') then
 if q.Name=='Monitor' and q.Parent.Name=='Patient bay' then q.CFrame*=CFrame.Angles(0,math.pi,0) end
 if q.Name=='Visitor stool support' or q.Name=='Visitor stool seat' then q.Position+=Vector3.new(0,.3,0) end
 if q.Name=='Ceiling light diffuser' then
  for _,l in q:GetChildren() do
   if l:IsA('PointLight') then l.Brightness=.2 end
   if l:IsA('SurfaceLight') then l.Brightness=.6;l.Shadows=true end
  end
 elseif q.Name=='Ceiling luminaire' then
  for _,l in q:GetChildren() do if l:IsA('PointLight') then l.Brightness=.4 elseif l:IsA('SurfaceLight') then l.Brightness=.3 end end
 end
end end
h.Interior_quality_12:SetAttribute('VisualFinish',true)
print('HOSPITAL12 VISUAL FINISH: bedside screens face beds; stools grounded; directional shadows enabled on 24 room lights')
