local listLayout = script.Parent.UIListLayout


local function changeCanvas ()
	local abSize = script.Parent.AbsoluteSize.X
	local abSizeY = script.Parent.AbsoluteSize.Y
	
	local cellSize = math.min(85/482*abSize, 85/100*abSizeY)
	listLayout.Padding = UDim.new(0, math.ceil(8/482*abSize))
	for i,v in pairs(script.Parent:GetChildren()) do
		if v:IsA("TextButton") then
			v.Size = UDim2.new(0,cellSize,0,cellSize)
		end
	end
	
	script.Parent.CanvasSize = UDim2.new(0, listLayout.AbsoluteContentSize.X+14, 0, listLayout.AbsoluteContentSize.Y)
end

script.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	changeCanvas()
end)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	changeCanvas()
end)

changeCanvas()

script.Parent.ChildAdded:Connect(changeCanvas)
