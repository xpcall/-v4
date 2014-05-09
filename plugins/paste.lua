local chars="qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0987654321"
function paste(txt)
	local id=""
	for l1=1,5 do
		local n=math.random(1,#chars)
		id=id..chars:sub(n,n)
	end
	local file=assert(io.open("www/paste/"..id..".txt","w"))
	file:write(txt:sub(1,100000))
	file:close()
	return "http://71.238.153.166/paste/"..id..".txt"
end
hook.new("command_paste",function(user,chan,txt)
	return paste(txt)
end,{
	desc="posts text to the webserver",
	group="misc",
})