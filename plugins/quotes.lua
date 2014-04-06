quotes={}
local file=io.open("db/quotes","r")
if file then
	quotes=unserialize(file:read("*a")) or {}
end
local function update()
	local file=io.open("db/quotes","w")
	file:write(serialize(quotes))
	file:close()
end
hook.new("command_addquote",function(user,chan,txt)
	
end)