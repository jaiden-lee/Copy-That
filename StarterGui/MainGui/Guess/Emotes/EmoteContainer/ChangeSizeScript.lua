local listLayout = script.Parent.UIListLayout


local function changeCanvas ()
	local abSize = script.Parent.AbsoluteSize.Y
	script.Parent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	
	listLayout.Padding = UDim.new(0, math.ceil(10/408*abSize))
	
	for i,v in pairs(script.Parent:GetChildren()) do
		if v:IsA("TextButton") then
			v.Size = UDim2.new(0,math.ceil(80/408*abSize),0,math.ceil(80/408*abSize))
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
