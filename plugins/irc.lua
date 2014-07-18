irc={}
function irc.say(chan,txt)
	for line in txt:gmatch("[^\r\n]+") do
		send("PRIVMSG "..chan.." :"..line)
	end
end
function send(txt)
	sv:send(txt.."\n")
end
function respond(user,txt)
	if not txt:match("^\1.+\1$") then
		txt=txt:gsub("\1","")
	end
	send(
		(user.chan==cnick and "NOTICE " or "PRIVMSG ")..
		(user.chan==cnick and user.nick or user.chan)..
		" :"..txt
		:gsub("^[\r\n]+",""):gsub("[\r\n]+$",""):gsub("[\r\n]+"," | ")
		:gsub("[%z\4\5\6\7\8\9\10\11\12\13\14\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31]","")
		:sub(1,446)
	)
end