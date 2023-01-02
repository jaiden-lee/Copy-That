local DataHandler = {}

local Promise = require(game.ReplicatedStorage.Promise)
local MSS = game:GetService("MarketplaceService")
local colorsModule = require(game.ReplicatedStorage.ColorsScript)
local remoteEvents = game.ReplicatedStorage.RemoteEvents
local emotesFolder = game.ReplicatedStorage:WaitForChild("EmotesFolder")

local ProfileTemplate = {
	Level = 0,
	Coins = 0,
	ColorsOwned = {["Black"] = true},
	ColorsEquipped = {"Black"},
	EmotesOwned = {["Smile"] = true},
	CodesUsed = {}
}

local ProfileService = require(game.ServerScriptService.ProfileService)

local Players = game.Players

-- this is the equivalent of GetDataStore - basically, "PlayerData" here is the current datastore key - if we changed the name, everyones data would be reset
local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData1",
	ProfileTemplate
)

local Profiles = {}

local function PlayerAdded (player)
	local profile = ProfileStore:LoadProfileAsync("Player_"..player.UserId, "ForceLoad")
	if profile ~= nil then -- this will return nil if another server is has the data loaded at same time - basically it is session locked; we should kick player so no data issues
		profile:AddUserId(player.UserId) -- idk why we need this, apparently for some European Law w/ data tracking
		profile:Reconcile() -- fills in missing variables from ProfileTemplate if missing in current profile

		profile:ListenToRelease(function() -- this tracks when the profile is "released" - ex: it is getting force loaded from another server
			Profiles[player] = nil
			-- if player still in game, then kick basically
			player:Kick()
		end)
		if player:IsDescendantOf(Players) then -- makes sure that the player is still in game
			Profiles[player] = profile
			do -- create the data part in the player object for client side access
				local createValuesPromise = Promise.new(function(resolve, reject, onCancel)
					local dataFolder = Instance.new("Folder", player)
					dataFolder.Name = "Data"

					local coinsValue = Instance.new("IntValue", dataFolder)
					coinsValue.Name = "Coins"
					coinsValue.Value = profile.Data.Coins
					
					local levelValue = Instance.new("IntValue", dataFolder)
					levelValue.Name = "Level"
					levelValue.Value = profile.Data.Level
					
					local currentPointsValue = Instance.new("IntValue", dataFolder)
					currentPointsValue.Name = "CurrentPoints"
					currentPointsValue.Value = 0

					
					resolve("Loaded player values")
				end)
				createValuesPromise:andThen(print)
			end
		else
			profile:Release() -- this means got accidentally loaded in wrong server, so release it - or else can't be loaded into another server due to session-locking
		end
	else
		player:Kick()
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	-- this is used just in case players joined the server before the player added part below - meaning their data wasn't loaded
	task.spawn(PlayerAdded, player) -- basically just running this asynchronously; no need for Promise bc we are not decision making or error handling
	-- just want this to run asynchronously so that the player added event below can run
end

Players.PlayerAdded:Connect(PlayerAdded) -- the player argument automatically passed into here

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release() -- need to do this for session locking
		print(player.Name.."'s Profile has been released")
	end
end) 

-- Updating Player Data Functions
function DataHandler.UpdateCoins (player, amount)
	local profile = Profiles[player]
	if profile then
		profile.Data.Coins += amount
		pcall(function()
			player.Data.Coins.Value = profile.Data.Coins
		end)
	end
end

-- Get Methods
function DataHandler.GetCoins (player)
	local profile = Profiles[player]
	if profile then
		return profile.Data.Coins
	end
	return 0
end

function DataHandler.GetColorsOwned (player)
	local profile = Profiles[player]
	if profile then
		return profile.Data.ColorsOwned
	end
	return {["Black"] = true}
end

function DataHandler.GetColorsEquipped (player)
	local profile = Profiles[player]
	if profile then
		return profile.Data.ColorsEquipped
	end
	return {"Black"}
end

function DataHandler.GetMaxColorsEquipped (player)
	local num = 6
	pcall(function()
		if MSS:UserOwnsGamePassAsync(player.UserId, colorsModule.EXTRA_PALETTE_ID) then
			num = 9
		end
	end)
	return num
end

-- Set Methods
function DataHandler.AddColorsEquipped (player, color)
	local profile = Profiles[player]
	if profile then
		if colorsModule.RGB[color]~=nil and #profile.Data.ColorsEquipped < profile.Data.ColorsEquippedDataHandler.GetMaxColorsEquipped(player) then
			table.insert(profile.Data.ColorsEquipped, color)
		end
	end
end

function DataHandler.AddColorsOwned (player, color)
	local profile = Profiles[player]
	if profile then
		if colorsModule.RGB[color] ~= nil then
			profile.Data.ColorsOwned[color] = true
			return true
		end
	end
	return false
end

function DataHandler.CheckIfPlayerOwnsColor (player, color)
	local profile = Profiles[player]
	if profile then
		if profile.Data.ColorsOwned[color] == true then
			return true
		end
		return false
	end
	warn("Player is attempting to purchase while data has not been loaded")
	return nil
end

function DataHandler.CheckIfPlayerOwnsEmote (player, emote)
	local profile = Profiles[player]
	if profile then
		if profile.Data.EmotesOwned[emote] == true then
			return true
		end
		return false
	end
	warn("Player is attempting to purchase while data has not been loaded")
	return nil
end

function DataHandler.EquipColor (player, color)
	local profile = Profiles[player]
	if profile then
		if #profile.Data.ColorsEquipped >= DataHandler.GetMaxColorsEquipped(player) then
			return false
		end
		if colorsModule.RGB[color] == nil then
			return false
		end
		if profile.Data.ColorsOwned[color] == nil then
			return false
		end
		table.insert(profile.Data.ColorsEquipped, color)
		return true
	end
	return false
end

function DataHandler.UnequipColor (player, color)
	local profile = Profiles[player]
	if profile then
		local index = table.find(profile.Data.ColorsEquipped, color)
		if index ~= -1 then
			table.remove(profile.Data.ColorsEquipped, index)
		end
		return true
	end
	return false
end

function DataHandler.GetEmotesOwned (player)
	local profile = Profiles[player]
	if profile then
		return profile.Data.EmotesOwned
	end
	return {["Smile"] = true}
end

function DataHandler.AddEmoteOwned (player, emoteName)
	local profile = Profiles[player]
	if profile then
		if emotesFolder:FindFirstChild(emoteName) then
			profile.Data.EmotesOwned[emoteName] = true
			return true
		end
	end
	return false
end


local codesList = game.ServerStorage:WaitForChild("CodesList")
function DataHandler.UseCode (player, code)
	local profile = Profiles[player]
	if profile then
		local codeData = codesList:FindFirstChild(code)
		if codeData and profile.Data.CodesUsed[code]~= true then
			profile.Data.CodesUsed[code] = true
			local emoteName = codeData:FindFirstChild("EmoteName")
			
			if emoteName then
				DataHandler.AddEmoteOwned(player, emoteName.Value)
			end
			return emoteName.Value
		end
	end
	return false
end

return DataHandler
