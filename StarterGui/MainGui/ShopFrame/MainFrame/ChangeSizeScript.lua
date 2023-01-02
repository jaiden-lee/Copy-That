local listLayout = script.Parent.UIListLayout


local function changeCanvas ()
	local abSize = script.Parent.AbsoluteSize.Y
	for i,v in pairs(script.Parent:GetChildren()) do
		if v:IsA("TextLabel") then
			v.Size = UDim2.new(.5,0,0,math.ceil(abSize/289*50))
		elseif v:IsA("ScrollingFrame") then
			v.Size = UDim2.new(.95,0,0,math.ceil(abSize/289*100))
		elseif v:IsA("Frame") then
			v.Size = UDim2.new(.95,0,0, math.ceil(abSize/289*50))
		end
	end
	script.Parent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y+abSize/289*50*2)
	script.Parent.UIPadding.PaddingTop = UDim.new(0,abSize/289*50)
end

script.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	changeCanvas()
end)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	changeCanvas()
end)

changeCanvas()

script.Parent.ChildAdded:Connect(changeCanvas)
