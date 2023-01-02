local plr = game.Players:GetPlayers()
local emoteContainer = script.Parent:WaitForChild("EmoteContainer") -- these are the emotes being played
local emoteList = script.Parent:WaitForChild("EmotesList") -- these are the emotes owned
local canUseEmote = script.Parent:WaitForChild("CanUseEmote")
local useEmoteEvent = script.Parent:WaitForChild("UseEmoteEvent")
local remoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local emoteEvent = remoteEvents.EmoteEvent
local getEmotesOwnedEvent = remoteEvents.GetEmotesOwnedEvent
local openEmotesButton = script.Parent:WaitForChild("OpenEmotesButton")
local emotePlayedTemplate = game.ReplicatedStorage:WaitForChild("EmotePlayedTemplate")
local emoteOwnedTemplate = game.ReplicatedStorage:WaitForChild("EmoteOwnedTemplate")
local loadEmotesOwnedEvent = script.Parent:WaitForChild("LoadEmotesOwnedEvent")

local emoteMessages = game.ReplicatedStorage:WaitForChild("EmoteMessages")
local emotesFolder = game.ReplicatedStorage:WaitForChild("EmotesFolder")
local debris = game:GetService("Debris")

local layoutOrder = 10000

local constants = require(game.ReplicatedStorage:WaitForChild("Constants"))
local MSS = game:GetService("MarketplaceService")

useEmoteEvent.Event:Connect(function(emote)
	canUseEmote.Value = false
	openEmotesButton.CooldownFrame.Visible = true

	emoteEvent:FireServer(emote)
	emoteList.Visible = false
	
	local cooldownTime = 10
	pcall(function()
		if MSS:UserOwnsGamePassAsync(plr.UserId, constants.SHORTER_EMOTE_COOLDOWN_ID) then
			cooldownTime = 5
		end
	end)
	
	wait(cooldownTime)
	
	canUseEmote.Value = true
	openEmotesButton.CooldownFrame.Visible = false
end)

openEmotesButton.MouseButton1Click:Connect(function()
	if canUseEmote.Value == true then
		emoteList.Visible = not emoteList.Visible
	else
		pcall(function()
			if not MSS:UserOwnsGamePassAsync(plr.UserId, constants.SHORTER_EMOTE_COOLDOWN_ID) then
				MSS:PromptGamePassPurchase(plr, constants.SHORTER_EMOTE_COOLDOWN_ID)
			end
		end)
	end
end)

emoteMessages.ChildAdded:Connect(function(message)
	if message:IsA("BoolValue") then
		local temp = emotePlayedTemplate:Clone()
		temp.PlayerName.Text = message:WaitForChild("PlayerName").Value
		
		temp.EmoteIcon.Image = "rbxassetid://"..message.ImageID.Value
		
		temp.LayoutOrder = layoutOrder
		layoutOrder-=1
		
		temp.Parent = emoteContainer
		
		if message.Value == true then
			temp.EmoteAudio.SoundId = message.EmoteSound.SoundId
			temp.EmoteAudio:Play()
		end
		
		
		debris:AddItem(temp, 5)
	end
end)

function loadEmotesOwned ()
	local emotesOwned = getEmotesOwnedEvent:InvokeServer()
	for emoteName, _ in pairs(emotesOwned) do
		local emote = emotesFolder:FindFirstChild(emoteName)
		if emote then
			local temp = emoteOwnedTemplate:Clone()
			temp.EmoteIcon.Image = "rbxassetid://"..emote.ImageID.Value
			temp.Name = emoteName
			temp.Parent = emoteList
			if emote.Value == true then
				temp.HasSound.Visible = true
			end
		end
	end
end
loadEmotesOwned()

loadEmotesOwnedEvent.Event:Connect(function()
	for i,v in pairs(emoteList:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	loadEmotesOwned()
end)
