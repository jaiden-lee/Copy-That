local imageFolder = script.Parent:WaitForChild("Folder")

local imageCount = 1
local currentImage = imageFolder["Image1"]
while true do
	task.wait(5)
	imageCount+=1
	local nextImage = imageFolder:FindFirstChild("Image"..imageCount)
	if not nextImage then
		imageCount = 1
		nextImage = imageFolder[("Image"..imageCount)]
	end
	nextImage.Visible = true
	for i = 0,1,.05 do
		currentImage.ImageTransparency=i
		nextImage.ImageTransparency = 1-i
		task.wait()
	end
	currentImage.Visible = false
	currentImage = nextImage
end
