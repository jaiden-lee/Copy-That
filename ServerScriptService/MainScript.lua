-- Game Loop
local dataHandler = require(game.ServerScriptService:WaitForChild("DataHandler"))
local remoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local gameData = game.ReplicatedStorage:WaitForChild("GameData")
local timer = gameData.Timer
local drawings = gameData.Drawings

local Promise = require(game.ReplicatedStorage:WaitForChild("Promise"))

local promptsModule = require(game.ServerScriptService:WaitForChild("PromptList"))
local promptsList = promptsModule.Prompts


local chatEvent = remoteEvents:WaitForChild("ChatEvent")
local chatMessages = game.ReplicatedStorage:WaitForChild("ChatMessages")
local guessMessages = chatMessages.GuessMessages -- where players that are guessing go
local postGuessMessages = chatMessages.PostGuessMessages -- where players that are not guessing go

local playersGuessed = {["HypedShadow"] = true}
local numPlayersGuessed = 0

local prompts = {}
local copyDict1 = {}
local findOriginalPlayerDict = {}

local DataHandler = require(game.ServerScriptService.DataHandler)


local currentWord = "apple"
local currentPlayer = nil
local isCopy = false

local TextService = game:GetService("TextService")

local playersLessThan3 = false


local currentWinner = ""
local winnerPoints = 0

local MarketPlaceService = game:GetService("MarketplaceService")
local constants = require(game.ReplicatedStorage:WaitForChild("Constants"))

-- EMOTES
local emotesFolder = game.ReplicatedStorage:WaitForChild("EmotesFolder")
local emoteMessages = game.ReplicatedStorage:WaitForChild("EmoteMessages")
local debris = game:GetService("Debris")
remoteEvents.EmoteEvent.OnServerEvent:Connect(function(player, emoteName)
	local emote = emotesFolder:FindFirstChild(emoteName)
	if emote then
		local message = emote:Clone()
		local playerName = Instance.new("StringValue", message)
		playerName.Name = "PlayerName"
		playerName.Value = player.Name
		message.Parent = emoteMessages
		debris:AddItem(message, 5)
	end
end)

remoteEvents.GetEmotesOwnedEvent.OnServerInvoke = function(player)
	return DataHandler.GetEmotesOwned(player)
end

-- CODES
local codesList = game.ServerStorage:WaitForChild("CodesList")
remoteEvents.EnterCodeEvent.OnServerInvoke = function(plr, code)
	return DataHandler.UseCode(plr, code)
end



-- HANDLING PURCHASES
do
	local function processReceipt (receiptInfo)
		local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- means player left game, so if they come back, call back will be called again
			return Enum.ProductPurchaseDecision.NotProcessedYet
			-- need to return so that they get the money, says that they will need to call again
		end
		
		local coinsAmt = constants.PURCHASE_COINS_AMOUNT[receiptInfo.ProductId]
		if coinsAmt ~= nil then
			DataHandler.UpdateCoins(player, coinsAmt)
		end
		
		
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	MarketPlaceService.ProcessReceipt = processReceipt
end





remoteEvents.GetColorsEquippedEvent.OnServerInvoke = function(player)
	return DataHandler.GetColorsEquipped(player)
end
remoteEvents:WaitForChild("GetColorsOwnedEvent").OnServerInvoke = function(player)
	return DataHandler.GetColorsOwned(player)
end
remoteEvents.GetMaxColorsEquippedEvent.OnServerInvoke = function(player)
	return DataHandler.GetMaxColorsEquipped(player)
end
remoteEvents.CheckIfPlayerOwnsColorEvent.OnServerInvoke = function(player, color)
	return DataHandler.CheckIfPlayerOwnsColor(player, color)
end
remoteEvents.CheckIfPlayerOwnsEmoteEvent.OnServerInvoke = function(player, emote)
	return DataHandler.CheckIfPlayerOwnsEmote(player, emote)
end

remoteEvents.EquipColorEvent.OnServerInvoke = function(player, color, isEquipping)
	if isEquipping then
		return DataHandler.EquipColor(player, color)
	else
		return DataHandler.UnequipColor(player, color)
	end
end

local colorCost = 75
remoteEvents.BuyColorEvent.OnServerInvoke = function(player, color)
	local coins = DataHandler.GetCoins(player)
	if coins >= colorCost then
		local success = DataHandler.AddColorsOwned(player, color)
		if success then
			DataHandler.UpdateCoins(player, -colorCost)
			return true
		end
	end
	return false
end

remoteEvents.BuyEmoteEvent.OnServerInvoke = function(player, emote)
	local coins = DataHandler.GetCoins(player)
	if coins >= constants.EMOTE_COSTS[emote] then
		local success = DataHandler.AddEmoteOwned(player, emote)
		if success then
			DataHandler.UpdateCoins(player, -constants.EMOTE_COSTS[emote])
			return true
		end
	end
	return false
end


-- deal w/ player adding or removing
game.Players.PlayerRemoving:Connect(function(player)
	if playersGuessed[player.Name] == true then
		playersGuessed[player.Name] = nil
		numPlayersGuessed -= 1
	end
end)


local currentMenu = "Intermission"
local guessHide = ""
local hintHide = ""
game.Players.PlayerAdded:Connect(function(player)
	if currentMenu == "Intermission" then
		remoteEvents.ClearAllEvent:FireClient(player)
		if #game.Players:GetPlayers()<3 then
			remoteEvents.StartIntermissionEvent:FireClient(player, false)	
		else
			remoteEvents.StartIntermissionEvent:FireClient(player, true)
		end
	end
	if currentMenu == "Directions" then
		remoteEvents.OpenDirectionsEvent:FireClient(player)
	end
	if currentMenu == "Drawing" then
		remoteEvents.OpenPromptEvent:FireClient(player, "Please wait for everyone to finish their drawings.")
	end
	if currentMenu == "Copying" then
		remoteEvents.OpenCopyEvent:FireClient(player, "N/A", "N/A") -- ensures that they sit the round out
	end
	if currentMenu == "Guessing" then
		local promptFrame = drawings:FindFirstChild(currentWord) 
		local drawing = nil
		if promptFrame then
			drawing = promptFrame:FindFirstChild("2-"..currentPlayer)
		end
		if not drawing then
			drawing = promptFrame:FindFirstChild("1-"..currentPlayer)
		end
		if drawing then
			remoteEvents.OpenGuessEvent:FireClient(player, drawing, currentWord)
			local text = guessHide
			pcall(function()
				if MarketPlaceService:UserOwnsGamePassAsync(player.UserId, promptsModule.ExtraHint)  then
					text = hintHide
				end
			end)
			remoteEvents.SetGuessPromptEvent:FireClient(player, text, false)
		end
	end
	if currentMenu == "RevealAnswer" then
		remoteEvents.RevealAnswerEvent:FireClient(player, currentWord)
	end
	if currentMenu == "Leaderboard" then
		remoteEvents.OpenLeaderboard:FireClient(player)
	end
	if currentMenu == "Victory" then
		remoteEvents.Winner1Event:FireClient(player, currentWinner, winnerPoints)
	end
	if currentMenu ~= "Intermission" then
		task.wait(1.5)
		remoteEvents.CloseIntermissionEvent:FireClient(player)
	end
end)









local function updateScore(player, amount)
	pcall(function()
		game.Players[player].Data.CurrentPoints.Value+=amount
	end)
end

local voteSkipCount = 0
remoteEvents.VoteskipEvent.OnServerEvent:Connect(function(plr)
	if currentPlayer ~= plr.Name and not (isCopy and findOriginalPlayerDict[currentPlayer] == plr.Name) then
		voteSkipCount+=1
		local message = Instance.new("StringValue")
		message.Value = "<font color='#ff6365'><b>"..plr.Name.." has voted to skip this drawing. ("..voteSkipCount.."/"..(math.ceil(2/3 * (#game.Players:GetPlayers()-1-(isCopy and 1 or 0))))..")</b></font>"
		message.Parent = guessMessages
	end
end)

chatEvent.OnServerInvoke = function(player, message)
	print(#playersGuessed)
	local newChatObject = Instance.new("StringValue")
	local filteredMessage = message
	pcall(function()
		filteredMessage = TextService:FilterStringAsync(message, player.UserId, 1):GetNonChatStringForUserAsync(player.UserId)
	end)
	newChatObject.Value = "<b>["..player.Name.."]:</b> "..filteredMessage

	if playersGuessed[player.Name] ~= true  and not (player.Name == currentPlayer or (isCopy and findOriginalPlayerDict[currentPlayer] == player.Name)) then
		if string.lower(message) == string.lower(currentWord) then -- guess correctly
			numPlayersGuessed+=1
			playersGuessed[player.Name] = true -- remove them from the dictionary of players that are still guessing
			newChatObject.Value = "<font color='#3db800'><b>"..player.Name.." has guessed the word!</b></font>"
			newChatObject.Parent = guessMessages
			updateScore(player.Name, 100-(10*(numPlayersGuessed-2-(isCopy and 1 or 0)))) -- gives the player guessing
			updateScore(currentPlayer, 50) -- gives the player that drew it currently
			if isCopy then
				updateScore(findOriginalPlayerDict[currentPlayer], 50) -- gives the original player
			end

			return true -- this will tell the client to switch to the post guess mode
		end
		
		
		newChatObject.Parent = guessMessages
		return false
	end
	newChatObject.Value = "<font color='#3db800'><b>["..player.Name.."]:</b></font> "..filteredMessage
	newChatObject.Parent = postGuessMessages
	return false
end

remoteEvents.ExtractDrawingsEvent.OnServerInvoke = (function(plr, items, copy)
	local prompt = prompts[plr.Name]
	if copy == true then
		prompt = copyDict1[plr.Name]
	end
	-- only if the player drew before then we will do it
	if prompt then
		local newPrompt = drawings:FindFirstChild(prompt)
		if not newPrompt then
			return
		end
		
		local temp = game.ReplicatedStorage.DrawingCanvas:Clone()
		temp.Parent = newPrompt
		temp.Name = (#newPrompt:GetChildren()).."-"..plr.Name
		for i,v in pairs(items) do
			local line = Instance.new("Frame", temp)
			line.BackgroundColor3 = Color3.fromRGB(0,0,0)
			line.AnchorPoint = Vector2.new(.5,.5)
			local corner = Instance.new("UICorner", line)
			corner.CornerRadius = UDim.new(1,0)
			line.Size = v[1]
			line.Position = v[2]
			line.Rotation = v[3]
			line.BorderSizePixel = 0
			line.ZIndex = 5
			line.BackgroundColor3 = v[4]
		end
	end
end)


wait(2.5)

local function resetChat ()
	guessMessages:ClearAllChildren()
	postGuessMessages:ClearAllChildren()
	playersGuessed = {}
	numPlayersGuessed = 0
	voteSkipCount = 0
end

local function addDrawersToChat ()
	local plr = game.Players:FindFirstChild(currentPlayer)
	if plr then
		playersGuessed[currentPlayer] = true
	end

	if isCopy == true then
		local plr2 = game.Players:FindFirstChild(findOriginalPlayerDict[currentPlayer])
		if plr2 then
			playersGuessed[plr2.Name] = true
		end
	end
end

local function clearPrompts ()
	drawings:ClearAllChildren()
end

local function restartGame()
	remoteEvents.StartIntermissionEvent:FireAllClients(false)
	remoteEvents.ClearAllEvent:FireAllClients()
	copyDict1 = {}
	prompts = {}
	playersGuessed = {}
	findOriginalPlayerDict = {}
	isCopy = false
	currentPlayer = nil
	currentWord = "N/A"
	numPlayersGuessed = 0
	resetChat()
	clearPrompts()
	for i,v in pairs(game.Players:GetChildren()) do
		local data = v:FindFirstChild("Data")
		if data then
			local currentPoints = data:FindFirstChild("CurrentPoints")
			if currentPoints then
				currentPoints.Value = 0
			end
		end
	end
end

local function hidePrompt(prompt, isArtist)
	local text = ""
	if isArtist == true then
		text = prompt
	else
		for i = 1,#prompt,1 do
			local char = string.sub(text, i, i)
			if char~=" " then
				text = text.."_"
			else
				text = text.." "
			end
		end
	end
	return text
end




local function randomHint (taggedWord)
	local randomIndex = math.random(2, #currentWord)
	while (string.sub(taggedWord, randomIndex, randomIndex)~="_") do
		randomIndex = math.random(2, #currentWord)
	end
	local char = string.sub(currentWord, randomIndex, randomIndex)
	local newWord = string.sub(taggedWord, 1,randomIndex-1)..char..string.sub(taggedWord, randomIndex+1)
	return newWord
end

local function updatePlayerHints (prompt, isCopy)
	for i,v in pairs(game.Players:GetPlayers()) do
		if v.Name == currentPlayer or (isCopy == true and v.Name == findOriginalPlayerDict[currentPlayer]) then
			continue
		end
		local text = prompt
		pcall(function()
			if MarketPlaceService:UserOwnsGamePassAsync(v.UserId, promptsModule.ExtraHint)  then
				text = string.sub(currentWord, 1, 1)..string.sub(prompt, 2)
			end
		end)
		remoteEvents.RevealHintEvent:FireClient(v, text)
	end
end



local function guessTimer ()
	currentMenu = "Guessing"
	local text = ""
	for i = 1,#currentWord,1 do
		local char = string.sub(text, i, i)
		if char~=" " then
			text = text.."_"
		else
			text = text.." "
		end
	end
	
	for i = 45,35,-1 do
		timer.Value = i
		task.wait(1)
		if #game.Players:GetPlayers() <= numPlayersGuessed or voteSkipCount >= math.ceil(2/3 * (#game.Players:GetPlayers()-(game.Players:FindFirstChild(currentPlayer) and 1 or 0)-(isCopy and game.Players:FindFirstChild(findOriginalPlayerDict[currentPlayer]) and 1 or 0)))  then
			return
		end
	end
	
	text = randomHint(text)
	updatePlayerHints(text, isCopy)
	
	for i=34,25, -1 do
		timer.Value = i
		task.wait(1)
		if #game.Players:GetPlayers() <= numPlayersGuessed or voteSkipCount >= math.ceil(2/3 * (#game.Players:GetPlayers()-(game.Players:FindFirstChild(currentPlayer) and 1 or 0)-(isCopy and game.Players:FindFirstChild(findOriginalPlayerDict[currentPlayer]) and 1 or 0)))  then
			return
		end
	end
	if #currentWord>4 then
		text = randomHint(text)
		updatePlayerHints(text, isCopy)
	end
	for i=24,15,-1 do
		timer.Value = i
		task.wait(1)
		if #game.Players:GetPlayers() == numPlayersGuessed or voteSkipCount >= math.ceil(2/3 * (#game.Players:GetPlayers()-1-(isCopy and 1 or 0)))  then
			return
		end
	end
	if #currentWord>7 then
		text = randomHint(text)
		updatePlayerHints(text, isCopy)
	end
	for i=14,1,-1 do
		timer.Value = i
		task.wait(1)
		if #game.Players:GetPlayers() == numPlayersGuessed or voteSkipCount >= math.ceil(2/3 * (#game.Players:GetPlayers()-1-(isCopy and 1 or 0)))  then
			return
		end
	end
	timer.Value = 0
	currentMenu = "RevealAnswer"
end


while true do
	remoteEvents.StartIntermissionEvent:FireAllClients(false)
	currentMenu = "Intermission"
	restartGame()
	if #game.Players:GetPlayers() < 3 then
		repeat wait() until #game.Players:GetPlayers() >= 3    -- this yields until there are 3 players in the game
	end
	-- Game
	
	-- INTERMISSION
	remoteEvents.StartIntermissionEvent:FireAllClients(true)
	
	local restartTempVariable = false
	for i = 20,1,-1 do
		timer.Value = i	
		task.wait(1)
		if #game.Players:GetPlayers() < 3 then
			restartTempVariable = true
			break
		end
	end
	if restartTempVariable then
		continue
	end
	timer.Value = 0
	
	
	remoteEvents.OpenDirectionsEvent:FireAllClients()
	currentMenu = "Directions"
	for i = 5,1,-1 do
		timer.Value = i	
		task.wait(1)
	end
	timer.Value = 0
	
	
	-- START DRAWING
	do
		local usedPrompts = {}
		currentMenu = "Drawing"
		-- 	Choose prompts
		for i,v in pairs(game.Players:GetPlayers()) do
			local prompt = promptsList[math.random(1,#promptsList)]
			while usedPrompts[prompt] == true do
				prompt = promptsList[math.random(1,#promptsList)]
			end
			remoteEvents.OpenPromptEvent:FireClient(v, "Draw <b>"..prompt.."</b>")
			prompts[v.Name] = prompt
			usedPrompts[prompt] = true
			
			
			newPrompt = Instance.new("Folder", drawings)
			newPrompt.Name = prompt
		end
		task.wait(2.5)
		
		-- 	Update to drawing screen
		for name,prompt in pairs(prompts) do
			local player = game.Players:FindFirstChild(name)
			if not player then
				continue
			end
			remoteEvents.OpenDrawingEvent:FireClient(player, prompt, false)
		end
		
		-- 	Drawing Timer
		for i = 30,1,-1 do
			timer.Value = i	
			task.wait(1)
		end
		timer.Value = 0
		
		for name, prompt in pairs(prompts) do
			local player = game.Players:FindFirstChild(name)
			if not player then
				prompts[name] = nil
				continue
			end
			
			remoteEvents.ExtractClientEvent:FireClient(player, false)
		end
		task.wait(1)
	end
	
	-- COPYING
	local currentPlayers = game.Players:GetPlayers()
	currentMenu = "Copying"
	for k,v in pairs(prompts) do
		if #game.Players:GetPlayers() < 3 then
			playersLessThan3 = true
			break
		end
		
		
		
		local index = math.random(1,#currentPlayers) -- this is for randomly choosing a player
		local randomPlayer = currentPlayers[index]
		local lastPlayer = false
		while (randomPlayer.Name == k or copyDict1[randomPlayer.Name] ~= nil) do -- also make sure the player we choose is not copying
			index = math.random(1,#currentPlayers)
			randomPlayer = currentPlayers[index]
			if #currentPlayers == 1 then
				lastPlayer = true
				break -- this means that if everyone got assigned a random prompt except for 1 player, they won't get to copy
			end
		end
		if lastPlayer then
			break -- this means that if everyone got assigned a random prompt except for 1 player, they won't get to copy
		end
		copyDict1[randomPlayer.Name] = v -- stores the prompts by playername
		findOriginalPlayerDict[randomPlayer.Name] = k
		remoteEvents.OpenCopyEvent:FireClient(randomPlayer, v, "1-"..k)
		table.remove(currentPlayers, index) -- ensures that no players are repeated
	end
	
	-- USING THIS TO END GAME IF THERE ARE NOT ENOUGH PLAYERS
	if playersLessThan3 == true then
		continue
	end
	
	for i,v in pairs(currentPlayers) do
		pcall(function()
			remoteEvents.OpenCopyEvent:FireClient(v, "N/A", "N/A") -- ensures that they sit the round out
		end)
	end
	task.wait(1)
	for i = 10,1,-1 do
		timer.Value = i	
		task.wait(1)
	end
	timer.Value = 0
	
	for k,v in pairs(copyDict1) do -- loops through all the players that are assigned a prompt
		local player = game.Players:FindFirstChild(k)
		if player then
			remoteEvents.OpenDrawingEvent:FireClient(player, "Copy the drawing!", true)
		else
			copyDict1[k] = nil -- this basically checks to see if the player has left the game
			-- if they have, remove them from the copydrawing dictionary so we can show the player that is in game
		end
	end
	
	

	for i = 20,1,-1 do
		timer.Value = i	
		task.wait(1)
	end
	timer.Value = 0
	
	for name, prompt in pairs(copyDict1) do
		local player = game.Players:FindFirstChild(name)
		if not player then
			continue
		end

		remoteEvents.ExtractClientEvent:FireClient(player, true)
	end
	
	remoteEvents.OpenGuessPromptEvent:FireAllClients()
	task.wait(2.5)
	
	-- guessing
	
	
	local usedPrompts = {} -- makes sure we don't reuse players
	for name, prompt in pairs(copyDict1) do
		local promptFrame = drawings:FindFirstChild(prompt) 
		local drawing = nil
		if promptFrame then
			drawing = promptFrame:FindFirstChild("2-"..name)
		end
		if drawing ~= nil then
			usedPrompts[prompt] = true
			
			currentWord = prompt
			currentPlayer = name
			isCopy = true
			
			guessHide = hidePrompt(prompt, false)
			hintHide = string.sub(currentWord, 1, 1)..string.sub(guessHide, 2)
			
			for i,v in pairs(game.Players:GetPlayers()) do
				if v.Name == currentPlayer or v.Name == findOriginalPlayerDict[currentPlayer] then
					remoteEvents.OpenGuessEvent:FireClient(v, drawing, prompt)
					playersGuessed[v.Name] = true	
					numPlayersGuessed+=1
					remoteEvents.SetGuessPromptEvent:FireClient(v, currentWord, true)
				else
					remoteEvents.OpenGuessEvent:FireClient(v, drawing, prompt)
					local text = guessHide
					pcall(function()
						if MarketPlaceService:UserOwnsGamePassAsync(v.UserId, promptsModule.ExtraHint)  then
							text = hintHide
						end
					end)
					remoteEvents.SetGuessPromptEvent:FireClient(v, text, false)
				end
			end
						
			guessTimer()
		
			remoteEvents.RevealAnswerEvent:FireAllClients(prompt)
			task.wait(5)
			
			remoteEvents.OpenLeaderboard:FireAllClients()
			currentMenu = "Leaderboard"
			resetChat()
			task.wait(5)
		end
	end
	
	for name, prompt in pairs(prompts) do
		if usedPrompts[prompt] then -- checks to see if the prompt has been used
			continue
		end
		
		local promptFrame = drawings:FindFirstChild(prompt) 
		local drawing = nil
		if promptFrame then
			drawing = promptFrame:FindFirstChild("1-"..name)
		end
		
		if drawing then

			currentWord = prompt
			currentPlayer = name
			isCopy = false
			
			
			guessHide = hidePrompt(prompt, false)
			hintHide = string.sub(currentWord, 1, 1)..string.sub(guessHide, 2)

			for i,v in pairs(game.Players:GetPlayers()) do
				if v.Name == currentPlayer then
					remoteEvents.OpenGuessEvent:FireClient(v, drawing, prompt)
					playersGuessed[v.Name] = true	
					numPlayersGuessed+=1
					remoteEvents.SetGuessPromptEvent:FireClient(v, currentWord, true)
				else
					remoteEvents.OpenGuessEvent:FireClient(v, drawing, prompt)
					local text = guessHide
					pcall(function()
						if MarketPlaceService:UserOwnsGamePassAsync(v.UserId, promptsModule.ExtraHint)  then
							text = hintHide
						end
					end)
					remoteEvents.SetGuessPromptEvent:FireClient(v, text, false)
				end
			end

			guessTimer()

			remoteEvents.RevealAnswerEvent:FireAllClients(prompt)
			task.wait(3)
	
			remoteEvents.OpenLeaderboard:FireAllClients()
			currentMenu = "Leaderboard"
			resetChat()
			task.wait(2.5)			
		end
	end
	
	local playerList = game.Players:GetPlayers()
	local winner = playerList[1]
	local maxPoints = 0
	
	table.sort(playerList, function(player1, player2)
		local value = false
		pcall(function()
			if player1.Data.CurrentPoints.Value > player2.Data.CurrentPoints.Value then
				value = true
			end
		end)
		return value
	end)
	winner = playerList[1]
	pcall(function()
		maxPoints = winner.Data.CurrentPoints.Value
	end)
	
	
	--for i,v in pairs(playerList) do
	--	local data = v:FindFirstChild("Data")
		
	--	if data then
	--		local points = data:FindFirstChild("CurrentPoints")
	--		if points and points.Value >= maxPoints then
	--			maxPoints = points.Value
	--			winner = v
	--		end
	--	end
	--end
	
	remoteEvents.Winner1Event:FireAllClients(winner.Name, maxPoints)
	currentWinner = winner.Name
	winnerPoints = maxPoints
	currentMenu = "Victory"
	
	-- Award Points for winning
	for i,v in pairs(playerList) do
		if i == 1 then -- first place
			dataHandler.UpdateCoins(v, 50)
		elseif i==2 then -- 2nd place
			dataHandler.UpdateCoins(v, 40)
		elseif i==3 then -- 3rd place
			dataHandler.UpdateCoins(v, 30)
		else -- other
			dataHandler.UpdateCoins(v, 15)
		end
	end
	
	task.wait(10)
end
