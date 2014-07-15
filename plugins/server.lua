server={servers={}}
local servers=server.servers
function server.listen(port,func)
	local sv,err=socket.bind("*",port)
	if not sv then
		print("error listening on port "..port.." : "..err)
		return false,err
	end
	servers[sv]=func
	hook.newsocket(sv)
	print("registered "..tostring(sv))
	return true
end
hook.new("select",function(a)
	for k,v in pairs(servers) do
		local cl=k:accept()
		if cl then
			async.new(function()
				v(async.socket(cl))
			end)
		end
	end
end)

