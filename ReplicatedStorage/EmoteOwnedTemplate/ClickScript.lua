local canUseEmote = script.Parent.Parent.Parent.CanUseEmote
local useEmoteEvent = script.Parent.Parent.Parent.UseEmoteEvent


script.Parent.MouseButton1Click:Connect(function()
	if canUseEmote.Value == true then
		useEmoteEvent:Fire(script.Parent.Name)
	end
end)
