local plr = game.Players.LocalPlayer
local canvas = script.Parent

local isDrawing = false
--local strokeCount = 0
--local currentStrokeFolder = nil
local strokeFolders = {}


local lastDrawnX = nil -- this is the previous frame so that we can draw a line between frames
local lastDrawnY = nil

local mouse = plr:GetMouse()

local undoButton = canvas.Undo

local colorSelected = canvas.Parent.ColorSelected

function drawLine (x1,y1,x2,y2)
	local abPos = canvas.AbsolutePosition
	local abSize = canvas.AbsoluteSize
	local line = Instance.new("Frame", strokeFolders[#strokeFolders])
	line.BackgroundColor3 = colorSelected.Value
	line.AnchorPoint = Vector2.new(.5,.5)
	local corner = Instance.new("UICorner", line)
	corner.CornerRadius = UDim.new(1,0)
	line.Size = UDim2.fromScale((math.sqrt(math.pow(x1-x2,2)+math.pow(y1-y2,2)))/abSize.X+10/667,10/500) -- keep line height consistent, we don't want to tinker around with the x bc that fills in the gaps
	line.Position = UDim2.fromScale(((x1+x2)/2-abPos.X)/abSize.X, ((y1+y2)/2-abPos.Y)/abSize.Y)
	local oppositeLength = y1-y2
	local adjacentLength = x1-x2
	if adjacentLength == 0 then
		adjacentLength = 1
	end
	line.Rotation = math.deg(math.atan(oppositeLength/adjacentLength))
	line.BorderSizePixel = 0
	line.ZIndex = 5
end

canvas.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		lastDrawnX = nil
		lastDrawnY = nil
		isDrawing = true
		
		local strokeFolder = Instance.new("Folder", canvas)
		table.insert(strokeFolders, strokeFolder)
		strokeFolder.Name = #strokeFolders
		
		drawLine(mouse.X, mouse.Y, mouse.X, mouse.Y)
		lastDrawnX = mouse.X
		lastDrawnY = mouse.Y
	end
end)

canvas.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDrawing = false
		lastDrawnX = nil
		lastDrawnY = nil
	end
end)



canvas.InputChanged:Connect(function(input)
	if isDrawing then
		local mousePosX = input.Position.X
		local mousePosY = input.Position.Y   -- these are in pixels
		if lastDrawnX ~= nil then
			drawLine(lastDrawnX,lastDrawnY,mousePosX,mousePosY)
		end
		lastDrawnX = mousePosX
		lastDrawnY = mousePosY
	end
end)



local canUndo = true
undoButton.MouseButton1Click:Connect(function()
	if canUndo then
		canUndo = false
		local folder = strokeFolders[#strokeFolders]
		table.remove(strokeFolders, #strokeFolders)
		if folder then
			folder:Destroy()
		end
		
		
		canUndo = true
	end
end)
