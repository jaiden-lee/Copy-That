local anim = {}


function anim.PopTextAnim(UIElement, text, popSizeX, popSizeY, origSizeX, origSizeY)
	UIElement.Text = text
	UIElement.Size = UDim2.fromScale(popSizeX, popSizeY)
	UIElement:TweenSize(UDim2.fromScale(origSizeX, origSizeY), "Out", "Quad", .25, true)
end

function anim.FadeOutMusic(audioTrack)
	for i = .5,0,-.01 do
		audioTrack.Volume = i
		task.wait()
	end
	audioTrack:Stop()
	audioTrack.Volume = .5
end

return anim
