local socket=require("socket")
local sv=socket.connect("localhost",1337)
local https=require("ssl.https")
local http=require("socket.http")
function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end
local function send(txt)
	sv:send(txt.."\n")
end
local function respond(user,txt)
	send("PRIVMSG "..(user.chan=="^v" and user.nick or user.chan).." :"..txt)
end
dofile("hook.lua")

hook.new("msg",function(user,chan,txt)
	if txt:sub(1,1) then
		hook.queue("command",user,chan,txt:sub(2))
		local cmd,param=txt:match("^%.(%S+) ?(.*)")
		if cmd then
			hook.queue("command_"..cmd,user,chan,param)
		end
	end
end)

hook.new("raw",function(txt)
	txt:gsub("^PING (.+)",function(txt)
		send("PONG "..txt)
	end)
	txt:gsub("^:^v MODE ^v :%+i",function()
		send("JOIN #oc")
		send("JOIN #pixel")
	end)
	txt:gsub("^:([^!]+)!([^@]+)@(%S+) PRIVMSG (%S+) :(.+)",function(nick,real,host,chan,txt)
		local ctcp=txt:match("^\1(.-)\1?$")
		local user={chan=chan,nick=nick,real=real,host=host}
		if ctcp and chan=="^v" then
			hook.queue("ctcp",user,chan,ctcp)
		else
			hook.queue("msg",user,chan,txt)
		end
	end)
end)

do
	local wikinames={
		["api-colors"]={"color","colors","color api","colors api"},
		["api-component"]={"component api","components api"},
		["api-computer"]={"computer api"},
		["api-event"]={"event","events","event api","events api"},
		["api-filesystem"]={"fs","filesystem","fs api","filesystem api"},
		["api-internet"]={"internet api"},
		["api-http"]={"http","http api"},
		["api-keyboard"]={"keyboard","keys","keyboard api","keys api"},
		["api-robot"]={"robot api","robots api"},
		["api-shell"]={"shell api","shell"},
		["api-sides"]={"sides","sides api"},
		["api-term"]={"term","term api"},
		["api-text"]={"text","text api"},
		["api-unicode"]={"unicode","unicode api"},
		["apis"]={"apis","api","api list","apis list"},
		["blocks"]={"blocks","block list","blocks list"},
		["codeconventions"]={"conventions","code conventions"},
		["component-commandblock"]={"command block","commandblock","command block component"},
		["component-computer"]={"computer component","component computer"},
		["component-crafting"]={"crafting","crafter","crafting component","crafter component","craft api","crafting api","crafter api"},
		["component-generator"]={"generator","generator component","generator api"},
		["component-gpu"]={"gpu","gpu api","gpu component"},
		["component-modem"]={"modem","modem api","modem component","rednet","wireless","wireless api","rednet api"},
		["component-navigation"]={"navigation","navigation api","gps","gps api"},
		["component-noteblock"]={"noteblock","noteblock api","noteblock component"},
		["component-redstone"]={"redstone","rs","redstone api","rs api","redstone component","rs component"},
		["component-redstoneinmotion"]={"redstone in motion","rim","redstone in motion api","rim api","redstone in motion component","rim component"},
		["component-sign"]={"sign","sign api","sign component"},
		["componentaccess"]={"component access"},
		["components"]={"component","components","component list","components list"},
		["computercraft"]={"computercraft","cc"},
		["computerusers"]={"users","perms","uac"},
		["home"]={"home","main"},
		["items"]={"items","item list","items list"},
		["nonstandardlualibs"]={"non standard lua libs","non standard","nonstandard","sandbox"},
		["signals"]={"signal","signals"},
		["tutorial-basiccomputer"]={"tutorial1","tutorial basic","tutorial basic computer","tutorial computer"},
		["tutorial-harddrives"]={"tutorial2","tutorial hdd","tutorial hdds","tutorial filesystem","tutorial fs"},
		["tutorial-writingcode"]={"tutorial3","tutorial code","tutorial coding"},
		["tutorials"]={"tutorials","help","tutorial"},
	}
	do
		local o={}
		for k,v in pairs(wikinames) do
			for n,l in pairs(v) do
				o[l]=k
			end
		end
		wikinames=o
	end
	local twikinames={}
	for k,v in pairs(wikinames) do
		twikinames[v]=true
	end
	hook.new({"command_wiki","command_w"},function(user,chan,txt)
		txt=txt:lower()
		if txt=="ping" or txt=="pong" or txt=="^v" then
			respond(user,user.nick..", http://en.wikipedia.org/wiki/Mental_retardation")
			return
		end
		local out="Not found."
		local b="https://github.com/MightyPirates/OpenComputers/wiki/"
		if txt=="" then
			respond(user,user.nick..", "..b)
			return
		end
		if twikinames[txt] then
			out=b..txt
		elseif wikinames[txt] then
			out=b..wikinames[txt]
		end
		respond(user,user.nick..", "..out)
	end)
end

hook.new("command_commits",function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/contributors")
	if not dat then
		if err then
			respond(user,user.nick..", ".."Error grabbing page. ("..err..")")
		else
			respond(user,user.nick..", ".."Error grabbing page.")
		end
		return
	end
	local o={}
	local t=0
	for name,contrib in dat:gmatch('{"login":"([^"]+)".-"contributions":(%d+)}') do
		contrib=tonumber(contrib)
		t=t+contrib
		o[#o+1]={name:gsub(".","%1"),contrib}
	end
	table.sort(o,function(a,b) return a[2]>b[2] end)
	local out=user.nick..", Total commits: "..t
	for l1=1,5 do
		if not o[l1] then
			break
		end
		out=out..", "..o[l1][1].." "..(math.ceil((o[l1][2]/t)*1000)/10).."%"
	end
	respond(user,out)
end)

dofile("help.lua")
hook.new({"command_help","command_h"},function(user,chan,txt)
	txt=txt:lower():gsub("%s","")
	if txt=="" then
		respond(user,user.nick..", Usage: .help command Example: .help term.write")
		return
	end
	if help[txt] then
		respond(user,user.nick..", "..help[txt])
	else
		respond(user,user.nick..", Function not found.")
	end
end)

local function shorturl(url)
	url='{"longUrl": "'..url..'"}'
	local res={}
	local scc,err=https.request({
		url="https://www.googleapis.com/urlshortener/v1/url",
		source=ltn12.source.string(url),
		method="POST",
		sink=ltn12.sink.table(res),
		headers={
			["Content-Type"]="application/json",
			["Content-Length"]=tostring(#url),
		},
	})
	res=table.concat(res)
	if not scc then
		return err
	end
	local out=res:match('"id": "([^"]+)",')
	if not out then
		return "Error parsing."
	end
	return out
end

hook.new({"command_jenkins","command_build","command_beta"},function(user,chan,txt)
	local dat,err=http.request("http://ci.cil.li/job/OpenComputers/")
	if not dat then
		if err then
			respond(user,user.nick..", ".."Error grabbing page. ("..err..")")
		else
			respond(user,user.nick..", ".."Error grabbing page.")
		end
		return
	end
	local size,url
	for s,u in dat:gmatch('<td class="fileSize">(.-)</td><td><a href="lastSuccessfulBuild/artifact/build/(.-)/%*fingerprint%*/">') do
		size,url=s,u
	end
	local tme=dat:match(
		'<a class="permalink%-link model%-link inside tl%-tr" href="lastSuccessfulBuild/">Last successful build %(#%d+%), (.-)</a>'
	) or "Error grabbing time."
	if url then
		respond(user,user.nick..", Last successful build "..size.." "..shorturl("http://ci.cil.li/job/OpenComputers/lastSuccessfulBuild/artifact/build/"..url).." "..tme)
	else
		respond(user,user.nick..", ".."Error parsing page.")
	end
end)

sv:settimeout(0)
while true do
	local s,e=sv:receive()
	if s then
		hook.queue("raw",s)
	else
		if e=="closed" then
			error(e)
		end
	end
	socket.select({sv},nil,hook.interval)
end