local plr = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local typeBox = script.Parent.TypeBox
local chatList = script.Parent.CustomChat

local remoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local chatEvent = remoteEvents:WaitForChild("ChatEvent")

local chatMessages = game.ReplicatedStorage:WaitForChild("ChatMessages")
local guessMessages = chatMessages.GuessMessages
local postGuessMessages = chatMessages.PostGuessMessages
local isGuessing = script.Parent.IsGuessing

local chatMessageTemplate = game.ReplicatedStorage:WaitForChild("ChatMessage")

UIS.InputEnded:Connect(function(input, isTyping)
	if isTyping == false and input.KeyCode == Enum.KeyCode.Slash then
		typeBox:CaptureFocus()
	end
end)

local function chatFunction ()
	local message = typeBox.Text

	if #string.gsub(message, "%s+", '') > 0 then
		local response = chatEvent:InvokeServer(message)
		if response == true then
			isGuessing.Value = false
		end
	end
	typeBox:ReleaseFocus()
	typeBox.Text = ""
end


UIS.InputBegan:Connect(function(input, isTyping) 
	if isTyping == true and (input.KeyCode == Enum.KeyCode.Return) then
		chatFunction()
	end
end)

typeBox.ReturnPressedFromOnScreenKeyboard:Connect(function() -- for mobile
	chatFunction()

end)

local function addChatMessage (message)
	local temp = chatMessageTemplate:Clone()
	temp.Message.Text = message
	temp.Parent = chatList
end

guessMessages.ChildAdded:Connect(function(child)
	addChatMessage(child.Value)
end)

postGuessMessages.ChildAdded:Connect(function(child)
	if isGuessing.Value == false then
		addChatMessage(child.Value)
	end
end)



--wait(5)
--game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
