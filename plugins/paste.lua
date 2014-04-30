function paste(txt)
	local id=""
	for l1=1,5 do
		id=id.._tob64[math.random(0,#_tob64)]
	end
	local file=assert(io.open("www/paste/"..id..".txt","w"))
	file:write(txt)
	file:close()
	return "http://71.238.153.166/paste/"..id..".txt"
end
hook.new("command_paste",function(user,chan,txt)
	return paste(txt)
end)