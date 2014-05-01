hook.new("join",function(user,chan)
	if chan=="#ocbots" and user=="GlitchBot" then
		send("MODE #ocbots +o GlitchBot")
	end
end)