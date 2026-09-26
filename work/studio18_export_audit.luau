local h=workspace.Surter_Remodel_10.Surter_Medical_Centre;local r=h.Furniture_fit_18
local rows=r.Item_audit:GetChildren();table.sort(rows,function(a,b)return a.Name<b.Name end)
for _,q in rows do print('ITEM18|'..q.Name..'|'..q.Value..'|'..tostring(q:GetAttribute('Before'))..'|'..tostring(q:GetAttribute('After'))) end
for k,v in r:GetAttributes() do print('COUNT18',k,v) end
