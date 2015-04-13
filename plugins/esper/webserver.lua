-- webserver by PixelToast

-- read config
webserver={}
webserver.configfile="plugins/esper/webserver/config.txt"
webserver.version="0.1"
local config
function loadconfig()
	local file=assert(io.open(webserver.configfile))
	webserver.config={}
	config=webserver.config
	setfenv(assert(loadstring(file:read("*a"))),config)()
	assert(config.domains)
	assert(config.domains.default)
	setmetatable(config.domains,{
		__index=function(s,n)
			return config.domains.default
		end
	})
	for k,v in pairs(config.domains) do
		if k~="default" then
			setmetatable(v,{
				__index=config.domains.default,
			})
		end
	end
	print("loaded "..webserver.configfile)
end
loadconfig()


function parsepost(url)
	local out={}
	for var,dat in url:gmatch("([^&]+)=([^&]+)") do
		out[urldecode(var)]=urldecode(dat)
	end
	return out
end

function merge(a,b)
	for k,v in pairs(a) do
		if type(v)=="table" and b[k] then
			merge(v,b[k])
		else
			b[k]=v
		end
	end
end

-- load apis

reqplugin("esper/webserver/client.lua")
reqplugin("esper/webserver/receivehead.lua")
reqplugin("esper/webserver/runlua.lua")
reqplugin("esper/webserver/serve.lua")

-- start server

local sv=assert(socket.bind(config.bindTo or "*",config.port))
sv:settimeout(0) -- non-blocking
hook.newsocket(sv)
print("listening on port "..config.port)

hook.new("select",function(rq,sq)
	if rq[sv] then
		local sk=assert(sv:accept())
		while sk do
			print("got client "..sk:getfd().." "..(sk:getpeername() or "*"))
			hook.newsocket(sk)
			sk:settimeout(0)
			webserver.client.new(sk)
			sk=sv:accept()
		end
	end
end)
