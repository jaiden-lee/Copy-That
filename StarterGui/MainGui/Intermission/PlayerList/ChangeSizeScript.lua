local listLayout = script.Parent.UIListLayout


local function changeCanvas ()
	local abSize = script.Parent.AbsoluteSize.Y
	script.Parent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	listLayout.Padding = UDim.new(0, math.ceil(8/272*abSize))
	for i,v in pairs(script.Parent:GetChildren()) do
		if v:IsA("Frame") then
			v.Size = UDim2.new(.925,0,0,math.ceil(35/272*abSize))
		end
	end
end

script.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	changeCanvas()
end)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	changeCanvas()
end)

changeCanvas()

script.Parent.ChildAdded:Connect(changeCanvas)
