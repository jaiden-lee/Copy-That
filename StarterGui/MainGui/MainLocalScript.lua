local plr = game.Players.LocalPlayer
local remoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local gameData = game.ReplicatedStorage:WaitForChild("GameData")
local timer = gameData.Timer
local anims = require(game.ReplicatedStorage:WaitForChild("AnimationScript"))
local music = script.Parent:WaitForChild("Music")
local drawings = gameData.Drawings
local MSS = game:GetService("MarketplaceService")
local constants = require(game.ReplicatedStorage:WaitForChild("Constants"))

local Promise = require(game.ReplicatedStorage:WaitForChild("Promise"))

local hasVoteKicked = false

local mainFrame = script.Parent:WaitForChild("MainFrame")
local directions = mainFrame.Directions
local drawRound1 = mainFrame.DrawingRound1
local colorPalette = drawRound1.Palette
local intermission = mainFrame.Intermission
local promptFrame = mainFrame.Prompt
local copyFrame = mainFrame.CopyDrawing
local guessFrame = mainFrame.Guess
local leaderboardFrame = mainFrame.Leaderboard
local revealAnswerFrame = mainFrame.RevealAnswer
local restartFrame = mainFrame.Restarting
local winnerFrame = mainFrame.Victory1


local leaderboardTemplate = game.ReplicatedStorage:WaitForChild('LeaderboardTemplate')
local uiGradients = game.ReplicatedStorage:WaitForChild("Gradients")
-- Timer Animations
local animList = { -- origX, origY, newX, newY
	["DirectionsTimer"] = {directions.TimeLeft, .075,.15, .125, .225},
	["DrawingRound1Timer"] = {drawRound1.TopHighlighter.TimeLeft, .075, .75, .1, 1},
	["CopyDrawingTimer"] = {copyFrame.TimeLeft, .075,.15, .125, .225},
	["IntermissionTimer"] = {intermission.TimeLeft, .075, .15 ,125, .225},
	["GuessTimer"] = {guessFrame.TopHighlighter.TimeLeft, .075, .75, .1, 1}
}

local intermissionPlayerTemplate = game.ReplicatedStorage:WaitForChild("IntermissionPlayerTemplate")
local intermissionPlayerList = intermission.PlayerList


timer.Changed:Connect(function()
	for i, v in pairs(animList) do
		anims.PopTextAnim(v[1], "<b>"..timer.Value.."</b>", v[4], v[5], v[2], v[3])
	end
end)

local function clearDrawing ()
	for i,v in pairs(drawRound1.DrawingCanvas:GetChildren()) do
		if v:IsA("Folder") then
			v:Destroy()
		end
	end
end

local function setCanvasZIndex (canvas, zIndex)
	canvas.ZIndex = zIndex
	for i,v in pairs(canvas:GetDescendants()) do
		if v:IsA("Frame") then
			v.ZIndex = zIndex+1
		end
	end
end


--music.Intermission:Play()


remoteEvents.OpenDirectionsEvent.OnClientEvent:Connect(function()
	directions.Visible = true
	directions:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	anims.FadeOutMusic(music.Intermission)
	music.Directions:Play()
	wait(1)
	intermission.Visible = false
end)

-- the prompt will be handled by the server
remoteEvents.OpenPromptEvent.OnClientEvent:Connect(function(prompt)
	promptFrame.Position = UDim2.fromScale(1, 0)
	promptFrame.Visible = true
	directions:TweenPosition(UDim2.fromScale(-1,0), "Out", "Quad", .5, true)
	promptFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", .5, true)
	promptFrame.Status.Text = prompt
	anims.FadeOutMusic(music.Directions)
	wait(.5)
	directions.Visible = false
	directions.Position = UDim2.fromScale(0, -1.5)
end)

local function clearCopy()
	local newDrawing = copyFrame:FindFirstChild("NewDrawing")
	if newDrawing then
		newDrawing:Destroy()
	end
end

local function setColorPalette ()
	local colorsEquipped = remoteEvents.GetColorsEquippedEvent:InvokeServer()
	colorPalette.SetColorPaletteEvent:Fire(colorsEquipped)
end
remoteEvents.OpenDrawingEvent.OnClientEvent:Connect(function(prompt, isCopying)
	setColorPalette()
	clearDrawing()
	copyFrame:TweenPosition(UDim2.fromScale(0,-1.5), "Out", "Quad", 1, true)
	
	clearCopy()
	
	drawRound1.Visible = true
	drawRound1.TopHighlighter.Prompt.Text = "<b>"..prompt.."</b>"
	promptFrame:TweenPosition(UDim2.fromScale(0,-1.5), "Out", "Quad", 1, true)
	if isCopying == true then
		music.CopyDrawing:Play()
	else
		music.Drawing:Play()
	end
	
	wait(1)
	promptFrame.Visible = false
	promptFrame.Position = UDim2.fromScale(1, 0)
	copyFrame.Visible = false
end)

local isCopying = false

remoteEvents.OpenCopyEvent.OnClientEvent:Connect(function(prompt, canvasName)
	--local items = {}
	--for i,v in pairs(drawRound1.DrawingCanvas:GetDescendants()) do
	--	if v:IsA("Frame") then
	--		table.insert(items, {v.Size, v.Position, v.Rotation})
	--	end
	--end
	
	--remoteEvents.ExtractDrawingsEvent:InvokeServer(items)
	local success, err = pcall(function()
		local newDrawing = drawings[prompt][canvasName]:Clone()
		newDrawing.Name = "NewDrawing"
		newDrawing.Parent = copyFrame
		newDrawing.Size = UDim2.fromScale(.45,.65)
		newDrawing.Position = UDim2.fromScale(.5,.575)
		setCanvasZIndex(newDrawing, 11)
		copyFrame.Status.Text = "Observe this drawing then copy it!"
	end)
	if err ~= nil then
		print(plr.Name.."    "..err)
	end
	isCopying = true
	if success == false then
		copyFrame.Status.Text = "Sorry, but you will have to sit this round out. There are not enough drawings."
		music.CopyDrawing:Play()
		isCopying = false
	end
	copyFrame.Visible = true
	copyFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	anims.FadeOutMusic(music.Drawing)
	
	wait(1)
	drawRound1.Visible = false
	clearDrawing()
end)

remoteEvents.OpenGuessPromptEvent.OnClientEvent:Connect(function()
	guessFrame.Emotes.LoadEmotesOwnedEvent:Fire()
	
	promptFrame.Position = UDim2.fromScale(0, -1.5)
	promptFrame.Visible = true
	
	copyFrame:TweenPosition(UDim2.fromScale(0,1),"Out","Quad", 1, true)
	promptFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	
	promptFrame.Status.Text = "Now try to guess what the prompt is!"
	anims.FadeOutMusic(music.CopyDrawing)
	
	
	wait(1)
	drawRound1.Visible = false
	copyFrame.Visible = false
	copyFrame.Position = UDim2.fromScale(0, -1.5)
	clearDrawing()
end)

local function clearChat ()
	for i,v in pairs(guessFrame.CustomChat.CustomChat:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	guessFrame.CustomChat.IsGuessing.Value = true
	hasVoteKicked = false
end

remoteEvents.SetGuessPromptEvent.OnClientEvent:Connect(function(text, isArtist)
	guessFrame.CustomChat.IsGuessing.Value = not isArtist
	guessFrame.TopHighlighter.Prompt.Text = text
end)

remoteEvents.OpenGuessEvent.OnClientEvent:Connect(function(drawing, prompt)
	clearChat()
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	
	
	
	local isNewDrawing = guessFrame:FindFirstChild("DrawingCanvas")
	if isNewDrawing then
		isNewDrawing:Destroy()
	end
	
	local newDrawing = drawing:Clone()
	newDrawing.Parent = guessFrame
	newDrawing.Name = "DrawingCanvas"
	newDrawing.Size = UDim2.new(.5,0,.7,0)
	newDrawing.Position = UDim2.new(.3,0,.5,0)
	
	guessFrame.Visible = true
	
	promptFrame:TweenPosition(UDim2.fromScale(0,-1.5), "Out", "Quad", 1, true)
	leaderboardFrame:TweenPosition(UDim2.fromScale(0, -1.5), "Out", "Quad", 1, true)
	music.Guessing:Play()
	
	wait(1)
	promptFrame.Visible = false
	leaderboardFrame.Visible = false
end)

local function clearLeaderboard ()
	for i,v in pairs(leaderboardFrame.PlayerList:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
end

local function loadLeaderboard ()
	local playerList = game.Players:GetChildren()
	table.sort(playerList, function(player1, player2)
		local value = false
		pcall(function()
			if player1.Data.CurrentPoints.Value > player2.Data.CurrentPoints.Value then
				value = true
			end
		end)
		return value
	end)
	for i,v in pairs (playerList) do
		local temp = leaderboardTemplate:Clone()
		temp.PlayerName.Text = "<b>"..i..") "..v.Name.."</b>"
		pcall(function()
			temp.Points.Text = v.Data.CurrentPoints.Value
		end)
		if i == 1 then
			uiGradients.GoldGradient:Clone().Parent = temp
			temp.Points.TextColor3 = Color3.fromRGB(127, 84, 0)
		elseif i==2 then
			uiGradients.SilverGradient:Clone().Parent = temp
			temp.Points.TextColor3 = Color3.fromRGB(132, 132, 132)
		elseif i==3 then
			uiGradients.BronzeGradient:Clone().Parent = temp
			temp.Points.TextColor3 = Color3.fromRGB(53, 35, 0)
		end
		
		temp.Parent = leaderboardFrame.PlayerList
	end
end


remoteEvents.OpenLeaderboard.OnClientEvent:Connect(function()
	leaderboardFrame.Position = UDim2.fromScale(1,0)
	clearLeaderboard()
	loadLeaderboard()
	leaderboardFrame.Visible = true
	leaderboardFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	revealAnswerFrame:TweenPosition(UDim2.fromScale(-1,0), "Out", "Quad", 1, true)
	
	wait(1)
	revealAnswerFrame.Visible = false
end)

local function clearRevealAnswer ()
	for i,v in pairs(revealAnswerFrame:GetChildren()) do
		if v.Name=="Drawing" then
			v:Destroy()
		end
	end
end

local function showRevealDrawings (prompt)
	local revealDrawings = drawings[prompt]:GetChildren()
	table.sort(revealDrawings, function(name1, name2)
		if name1.Name < name2.Name then
			return true
		end
		return false
	end)
	
	for i,v in pairs(revealDrawings) do
		local newDrawing = v:Clone()
		newDrawing.Name = "Drawing"
		setCanvasZIndex(newDrawing, 11)
		
		if #revealDrawings == 2 then
			newDrawing.Size = UDim2.fromScale(.4, .6)
			newDrawing.Position = UDim2.fromScale(.25+(i-1)*.5, .55)
		else
			newDrawing.Size = UDim2.fromScale(.4, .6)
			newDrawing.Position = UDim2.fromScale(.5, .55)
		end
		local revealPlayer = game.ReplicatedStorage.RevealDrawer:Clone()
		if i == 1 then
			revealPlayer.Text = "<b>Original</b>: "..string.sub(v.Name, 3)
		else
			revealPlayer.Text = "<b>Copy</b>: "..string.sub(v.Name, 3)
		end
		revealPlayer.Parent = newDrawing
		revealPlayer.Position = UDim2.fromScale(0,1.1)
		newDrawing.Parent = revealAnswerFrame
	end
	
end



remoteEvents.RevealAnswerEvent.OnClientEvent:Connect(function(prompt)
	revealAnswerFrame.Position = UDim2.fromScale(0,-1.5)
	clearRevealAnswer()
	revealAnswerFrame.Status.Text = "Correct Answer: <b>"..prompt.."</b>"
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
	anims.FadeOutMusic(music.Guessing)
	revealAnswerFrame.Visible = true
	revealAnswerFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	showRevealDrawings(prompt)
	
	
	wait(1)
	guessFrame.Visible = false
end)

remoteEvents.StartIntermissionEvent.OnClientEvent:Connect(function(isIntermission)
	if isIntermission then
		intermission.TimeLeft.Visible = true
		intermission.Status.Text = "INTERMISSION"
		intermission.Description.Text = "The game will be starting soon..."
	else
		intermission.TimeLeft.Visible = false
		intermission.Status.Text = "NOT ENOUGH PLAYERS"
		intermission.Description.Text = "Atleast <i><b>3</b></i> players are needed to start. Invite some friends!"
	end
end)

local canResetMusic = true
remoteEvents.ClearAllEvent.OnClientEvent:Connect(function()
	restartFrame:TweenPosition(UDim2.fromScale(0,0), "Out", "Quad", 1, true)
	winnerFrame:TweenPosition(UDim2.fromScale(0,1.5),"Out","Quad", 1, true)
	task.wait(1)
	intermission.Visible = true
	drawRound1.Visible = false
	winnerFrame.Visible = false
	winnerFrame.Victory2.Visible = false
	winnerFrame.Victory2.Size = UDim2.fromScale(.75,.75)
	
	clearDrawing()
	clearLeaderboard()
	clearRevealAnswer()
	clearCopy()
	
	if canResetMusic == true then
		canResetMusic = false
		local fadePromise = Promise.new(function(resolve, reject, onCancel)
			anims.FadeOutMusic(music.Victory)
			music.Intermission:Play()
			wait(5)
			canResetMusic = true
			resolve()
		end)
	end
	
	task.wait(.5)
	restartFrame:TweenPosition(UDim2.fromScale(0,-1.5), "Out", "Quad", 1, true)
end)

remoteEvents.Winner1Event.OnClientEvent:Connect(function(winner, points)
	winnerFrame.Victory2.Size = UDim2.fromScale(.75,.75)
	winnerFrame.Position = UDim2.fromScale(1,0)
	winnerFrame.Visible = true
	winnerFrame.Status.Visible = true
	winnerFrame.Victory2.Status.Text = "<b>"..winner.."</b>"
	winnerFrame.Victory2.Points.Text = "...with "..points.." points!"
	winnerFrame:TweenPosition(UDim2.fromScale(0,0), "Out","Linear",.5, true)
	leaderboardFrame:TweenPosition(UDim2.fromScale(-1,0), "Out", "Linear", .5, true)
	music.Drumroll:Play()
	task.wait(3.903)
	music.Victory:Play()
	task.wait(.75)
	winnerFrame.Status.Visible = false
	winnerFrame.Victory2.Visible = true
	winnerFrame.Victory2:TweenSize(UDim2.fromScale(1,1), "Out", "Linear", .05, true)
	wait(.05)
	winnerFrame.Victory2:TweenSize(UDim2.fromScale(1.5,1.5), "Out", "Linear", 10, true)
end)

remoteEvents.ExtractClientEvent.OnClientEvent:Connect(function(isCopy)
	local items = {}
	for i,v in pairs(drawRound1.DrawingCanvas:GetDescendants()) do
		if v:IsA("Frame") then
			table.insert(items, {v.Size, v.Position, v.Rotation, v.BackgroundColor3})
		end
	end

	remoteEvents.ExtractDrawingsEvent:InvokeServer(items, isCopy)
	-- roblox does not let you return values from client to server
	-- so I need to fire an event to the serverszprompt)
	guessFrame.TopHighlighter.Prompt.Text = prompt
end)

guessFrame.Voteskip.MouseButton1Click:Connect(function()
	if hasVoteKicked == false then
		hasVoteKicked = true
		remoteEvents.VoteskipEvent:FireServer()
	end
end)

remoteEvents.CloseIntermissionEvent.OnClientEvent:Connect(function()
	intermission.Visible = false
end)




-- Intermission Leaderboard
local function loadIntermissionLeaderboard () 
	for i,v in pairs(game.Players:GetPlayers()) do
		local temp = intermissionPlayerTemplate:Clone()
		temp.Name = v.Name
		temp.PlayerName.Text = v.Name
		temp.Parent = intermissionPlayerList
	end
	game.Players.PlayerAdded:Connect(function(v)
		local temp = intermissionPlayerTemplate:Clone()
		temp.Name = v.Name
		temp.PlayerName.Text = v.Name
		temp.Parent = intermissionPlayerList
	end)
end
loadIntermissionLeaderboard()

game.Players.PlayerRemoving:Connect(function(v)
	local temp = intermissionPlayerList:FindFirstChild(v.Name)
	if temp then
		temp:Destroy()
	end
end)



-- SHOP SECTION
local openShopButton = intermission.OpenShopButton
local shopFrame = mainFrame.ShopFrame
local closeShopButton = shopFrame.CloseButton
local confirmPurchaseFrame = mainFrame.ConfirmPurchaseFrame
local purchaseEmotesFrame = shopFrame.MainFrame.EmotesFrame

openShopButton.MouseEnter:Connect(function()
	openShopButton:TweenPosition(UDim2.new(0.1, 0,0.915, 0),"Out","Quad",.125, true)
end)
openShopButton.MouseLeave:Connect(function()
	openShopButton:TweenPosition(UDim2.new(0.1, 0,0.925, 0),"Out","Quad",.125, true)
end)

local function closeShopFrame ()
	shopFrame.Visible = false
	shopFrame.Position = UDim2.new(.5,0,.5,0)
	shopFrame.Size = UDim2.new(.6,0,.6,0)
end

closeShopButton.MouseButton1Click:Connect(function()
	closeShopFrame()
end)

function closeConfirmPurchaseFrame ()
	confirmPurchaseFrame.Visible = false
	confirmPurchaseFrame.Size = UDim2.fromScale(.4,.35)
	confirmPurchaseFrame.Position = UDim2.fromScale(.5,.6)
end

function openShopFrame()
	shopFrame.Visible = true
	shopFrame:TweenPosition(UDim2.new(.5,0,.45,0), "Out", "Linear", .125, true)
	shopFrame:TweenSize(UDim2.new(.7,0,.7,0), "Out", "Linear", .075, true)
end

openShopButton.MouseButton1Click:Connect(function()
	if shopFrame.Visible == false then
		openShopFrame()
		closeConfirmPurchaseFrame()
	else
		closeShopFrame()
	end
end)

local playerData = plr:WaitForChild("Data")
local coins = playerData.Coins

coins.Changed:Connect(function()
	intermission.CoinsDisplay.Amount.Text = coins.Value
	shopFrame.CoinsDisplay.Amount.Text = coins.Value
	confirmPurchaseFrame.CoinsDisplay.Amount.Text = coins.Value
	
end)
intermission.CoinsDisplay.Amount.Text = coins.Value
shopFrame.CoinsDisplay.Amount.Text = coins.Value
confirmPurchaseFrame.CoinsDisplay.Amount.Text = coins.Value

-- SETTING UP SHOP
local strokeColorsFrame = shopFrame.MainFrame.StrokeColorsFrame
local function resetStrokeColors ()
	for i,v in pairs(strokeColorsFrame:GetChildren()) do
		if v:IsA("TextButton") then
			v.CoinsIcon.Visible = true
			v.EquippedIcon.Visible = false
			v.Cost.Text = v.CostValue.Value
		end
	end
end

local function setUpShop ()
	local colorsEquipped = remoteEvents.GetColorsEquippedEvent:InvokeServer()
	local colorsOwned = remoteEvents:WaitForChild("GetColorsOwnedEvent"):InvokeServer()
	local maxColorsEquipped = remoteEvents.GetMaxColorsEquippedEvent:InvokeServer()
	shopFrame.MainFrame.StrokeColors.Text = "<b>BRUSH COLOR</b> ("..#colorsEquipped.."/"..maxColorsEquipped..")"
	for i,v in pairs(strokeColorsFrame:GetChildren()) do
		if v:IsA("TextButton") then
			if colorsOwned[v.Name] ~= nil then
				v.CoinsIcon.Visible = false
				v.Cost.Text = "Owned"
				continue
			end
			v.CoinsIcon.Visible = true
			v.EquippedIcon.Visible = false
			v.Cost.Text = v.CostValue.Value
		end
	end

	for i,v in pairs(colorsEquipped) do
		strokeColorsFrame[v].EquippedIcon.Visible = true
	end
	local emotesOwned = remoteEvents.GetEmotesOwnedEvent:InvokeServer()
	for i,v in pairs(purchaseEmotesFrame:GetChildren()) do
		if v:IsA("TextButton") then
			local cost = constants.EMOTE_COSTS[v.Name]
			if cost~="CODE" then
				v.LayoutOrder = cost
			else
				v.LayoutOrder = 99999999
				v.CoinsIcon.Visible = false
			end
			v.Cost.Text = cost
			if emotesOwned[v.Name] ~= nil then
				v.CoinsIcon.Visible = false
				v.Cost.Text = "Owned"
				continue
			end
			if cost~="CODE" then
				v.CoinsIcon.Visible = true
				v.Cost.Text = cost
			end
		end
	end
end
task.wait(1)
setUpShop()

local function openPurchasePrompt (cost, itemName, itemCategory)
	confirmPurchaseFrame.Cost.Value = cost
	confirmPurchaseFrame.ItemName.Value = itemName
	confirmPurchaseFrame.ItemCategory.Value = itemCategory
	
	confirmPurchaseFrame.Visible = true
	confirmPurchaseFrame:TweenPosition(UDim2.new(.5,0,.5,0), "Out", "Linear", .125, true)
	confirmPurchaseFrame:TweenSize(UDim2.new(.5,0,.45,0), "Out", "Linear", .075, true)
end


-- Buying or Equipping stuff
local canPerformShopAction = true
for i,v in pairs(strokeColorsFrame:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			if canPerformShopAction == false then
				return
			end
			canPerformShopAction = false
			local playerOwnsItem = remoteEvents.CheckIfPlayerOwnsColorEvent:InvokeServer(v.Name)
			if playerOwnsItem == nil then
				canPerformShopAction = true
				return -- this prevents the player from purchasing when his data is not loaded yet
			end
			
			if playerOwnsItem == true then -- he is trying to equip or unequip the item
				local success = remoteEvents.EquipColorEvent:InvokeServer(v.Name, not v.EquippedIcon.Visible)
				-- CHANGE THIS TO MAKE IT SO EQUIPCOLOREVENT IS A REMOTE FUNCTION
				-- THEN, MAKE IT SO THAT IT RETURNS WHETHER OR NOT THE ACTION WAS A SUCCESS - THEN, WITH THAT WE CAN UPDATE
				if success then
					v.EquippedIcon.Visible = not v.EquippedIcon.Visible
					local colorsEquipped = remoteEvents.GetColorsEquippedEvent:InvokeServer()
					local maxColorsEquipped = remoteEvents.GetMaxColorsEquippedEvent:InvokeServer()
					shopFrame.MainFrame.StrokeColors.Text = "<b>BRUSH COLOR</b> ("..#colorsEquipped.."/"..maxColorsEquipped..")"
				end
			else -- this means he does not own the item and is trying to purchase it
				closeShopFrame()
				openPurchasePrompt(75, v.Name, "Color")
				local colorValue = v.Title.TextColor3
				confirmPurchaseFrame.Title.Text = "<b>Would you like to purchase the brush color <font color='rgb("..(math.floor(255*colorValue.R)..","..math.floor(255*colorValue.G)..","..math.floor(255*colorValue.B))..")'>"..v.Name.."</font> for <font color='#ffce0a'>75 coins</font>?</b>"
			end
			
			wait(.25)
			canPerformShopAction = true
		end)
	end
end

confirmPurchaseFrame.YesButton.MouseButton1Click:Connect(function()
	if canPerformShopAction == true then
		canPerformShopAction = false
		
		if coins.Value >= confirmPurchaseFrame.Cost.Value then
			if confirmPurchaseFrame.ItemCategory.Value == "Color" then
				local success = remoteEvents.BuyColorEvent:InvokeServer(confirmPurchaseFrame.ItemName.Value)
				if success then
					strokeColorsFrame[confirmPurchaseFrame.ItemName.Value].CoinsIcon.Visible = false
					strokeColorsFrame[confirmPurchaseFrame.ItemName.Value].Cost.Text = "Owned"
				end
			elseif confirmPurchaseFrame.ItemCategory.Value == "Emote" then
				local success = remoteEvents.BuyEmoteEvent:InvokeServer(confirmPurchaseFrame.ItemName.Value)
				if success then
					purchaseEmotesFrame[confirmPurchaseFrame.ItemName.Value].CoinsIcon.Visible = false
					purchaseEmotesFrame[confirmPurchaseFrame.ItemName.Value].Cost.Text = "Owned"
				end
			end
		end
		closeConfirmPurchaseFrame()
		openShopFrame()
		wait(.25)
		canPerformShopAction = true
	end
end)

confirmPurchaseFrame.NoButton.MouseButton1Click:Connect(function()
	if canPerformShopAction == true then
		canPerformShopAction = false

		closeConfirmPurchaseFrame()
		openShopFrame()
		wait(.25)
		canPerformShopAction = true
	end
end)

-- GAMEPASSES
local gamePassFrame = shopFrame.MainFrame.GamepassFrame
for i,v in pairs(gamePassFrame:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			if canPerformShopAction == true then
				canPerformShopAction = false
				
				pcall(function()
					if not MSS:UserOwnsGamePassAsync(plr.UserId, v.AssetID.Value) then
						MSS:PromptGamePassPurchase(plr, v.AssetID.Value)
					end
				end)
				
				wait(.25)
				canPerformShopAction = true
			end
		end)
	end
end

-- PURCHASE COINS
local purchaseCoinsFrame = shopFrame.MainFrame.CoinsFrame
for i,v in pairs(purchaseCoinsFrame:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			if canPerformShopAction == true then
				canPerformShopAction = false
				
				pcall(function()
					MSS:PromptProductPurchase(plr, constants.PURCHASE_COINS_ID[v.Name])
				end)
				
				wait(.25)
				canPerformShopAction = true
			end
		end)
	end
end

-- EMOTES SHOP
for i,v in pairs(purchaseEmotesFrame:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			if canPerformShopAction == false then
				return
			end
			canPerformShopAction = false
			local playerOwnsItem = remoteEvents.CheckIfPlayerOwnsEmoteEvent:InvokeServer(v.Name)
			if playerOwnsItem == nil then
				canPerformShopAction = true
				return -- this prevents the player from purchasing when his data is not loaded yet
			end

			if playerOwnsItem == false then -- he is trying to equip or unequip the item
				if constants.EMOTE_COSTS[v.Name]~="CODE" then
					closeShopFrame()
					openPurchasePrompt(constants.EMOTE_COSTS[v.Name], v.Name, "Emote")
					confirmPurchaseFrame.Title.Text = "<b>Would you like to purchase this emote for <font color='#ffce0a'>"..constants.EMOTE_COSTS[v.Name].." coins</font>?</b>"
				end
			else
				purchaseEmotesFrame[v.Name].CoinsIcon.Visible = false
				purchaseEmotesFrame[v.Name].Cost.Text = "Owned"
			end
			
			wait(.25)
			canPerformShopAction = true
		end)
		local emoteSound = v:FindFirstChild("EmoteSound")
		if emoteSound then
			v.MouseEnter:Connect(function()
				emoteSound:Play()
			end)
			v.MouseLeave:Connect(function()
				emoteSound:Stop()
			end)
		end
	end
end

local codesFrame = shopFrame.MainFrame.CodesFrame
local codesInput = codesFrame.CodeBox
local codesSubmit = codesFrame.SubmitButton

local canUseCode = true
codesSubmit.MouseButton1Click:Connect(function()
	if canUseCode == true then
		canUseCode = false
		local text = codesInput.Text
		local result = remoteEvents.EnterCodeEvent:InvokeServer(text)
		if result ~= false then
			codesInput.Text = "Code redeemed!"
			local emote = purchaseEmotesFrame:FindFirstChild(result)
			if emote then
				emote.CoinsIcon.Visible = false
				emote.Cost.Text = "Owned"
			end
		else
			codesInput.Text = "Invalid code!"
		end
		
		
		
		wait(.5)
		canUseCode = true
	end
end)

	
	
-- LOAD FONTS
for i,v in pairs(mainFrame:GetDescendants()) do if v:IsA("TextButton") or v:IsA("TextLabel") or v:IsA("TextBox") then v.RichText = false v.RichText = true end end
