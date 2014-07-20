local cword={}
wordlist={}
for line in io.lines("/usr/share/dict/words") do
	if line==line:lower() and #line<9 then
		table.insert(wordlist,line)
	end
end
print((#wordlist).." words")
hook.new("command_unscramble",function(user,chan,txt)
	if not cword[chan] then
		local word=wordlist[math.random(1,#wordlist)]
		cword[chan]={word,hook.queue("command_blend",nil,nil,word)}
	end
	return "The scrambled word is \2"..cword[chan][2].."\2"
end)
hook.new("msg",function(user,chan,txt)
	if cword[chan] and txt:lower()==cword[chan][1] then
		cword[chan]=nil
		return "Congradululzations the correct answer was \2"..txt.."\2 you win \196\1440 because i hate you"
	end
end)
