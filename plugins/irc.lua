irc={}
function irc.say(chan,txt)
	for line in txt:gmatch("[^\r\n]+") do
		send("PRIVMSG "..chan.." :"..line)
	end
end