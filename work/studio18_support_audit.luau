local h=workspace.Surter_Remodel_10.Surter_Medical_Centre;local n,bad=0,0
for _,q in h:GetDescendants() do if q:IsA('BasePart') and (q.Name=='IV pole' or q.Name=='Bedside cabinet' or q.Name=='Upright' or q.Name=='Visitor stool support') then
 local f=math.floor(q.Position.Y/18)*18+.5;local bottom=q.Position.Y-q.Size.Y/2;n+=1
 if math.abs(bottom-f)>.025 then bad+=1;warn('H18 SUPPORT FAIL',q:GetFullName(),bottom,f) end
end end
h.Furniture_fit_18:SetAttribute('AdditionalFloorChecks',n);h.Furniture_fit_18:SetAttribute('AdditionalFloorFailures',bad);print('H18 SUPPORT RESULT',n,bad)
