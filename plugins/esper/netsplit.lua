local split
hook.new("quit",function(nick,reason)
	local user=admin.perms[nick]
	if user and reason=="*.net *.split" then
		if not split then
			split={[(user.server or "error"):match("^(.-)%.")]=true}
			async.new(function()
				async.wait(2)
				local o=""
				for k,v in pairs(split) do
					o=o..k..","
				end
				irc.say("#oc","Oh noes! "..o:sub(1,-2).." split 3:")
			end,print)
		else
			split[(user.server or "error"):match("^(.-)%.") or "error"]=true
		end
	end
end)
