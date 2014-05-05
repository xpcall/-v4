hook.new("join",function(user,chan)
	if chan=="#ocbots" and (user=="GlitchBot" or user=="ThouBot") then
		send("MODE #ocbots +o "..user)
	end
end)