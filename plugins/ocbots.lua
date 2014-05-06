local bots={
	["$a:Sorroko"]={"LuaBar!*@*"},
	["$a:wolfmitchell"]={"$a:mitchbot"},
	["$a:SuPeRMiNoR2"]={"$a:SuperBot"},
	["*!~alekso56@"]={"*!~TOILET@*"},
	["$r:Meep Meep"]={"EnderBot!TheEnders@thatjoshgreen.me"},
}
hook.new("join",function(user,chan)
	if chan=="#ocbots" and (user=="GlitchBot" or user=="ThouBot") then
		send("MODE #ocbots +o "..user)
	end
end)
