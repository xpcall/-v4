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
	send((user.chan=="^v" and "NOTICE " or "PRIVMSG ")..(user.chan=="^v" and user.nick or user.chan).." :"..txt)
end
local function antiping(name)
	return name:sub(1,-2).."."..name:sub(-1,-1)
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
	txt:gsub("^:^v MODE ^v :%+i",function()
		send("JOIN #oc")
		send("JOIN #pixel")
	end)
	txt:gsub("^:([^!]+)!([^@]+)@(%S+) PRIVMSG (%S+) :(.+)",function(nick,real,host,chan,txt)
		local ctcp=txt:match("^\1(.-)\1?$")
		local user={txt=txt,chan=chan,nick=nick,real=real,host=host}
		if ctcp and chan=="^v" then
			hook.queue("ctcp",user,chan,ctcp)
		else
			if ctcp and ctcp:sub(1,7)=="ACTION " then
				hook.queue("msg",user,chan,txt:sub(8,-2),true)
			else
				hook.queue("msg",user,chan,txt)
			end
		end
	end)
end)

local perms={}
hook.new("raw",function(txt)
	txt:gsub("^:%S+ 354 ^v (%S+) (%S+) (%S+)",function(host,nick,account)
		print(host..","..nick..","..account)
		perms[nick]={
			host=host,
		}
		if account~="0" then
			perms[nick].account=account
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@(%S+) JOIN #oc",function(nick,host)
		perms[nick]={
			host=host,
		}
		send("WHOIS "..nick)
	end)
	txt:gsub("^:%S+ 330 ^v (%S+) (%S+)",function(nick,account)
		local p=perms[nick]
		if p and account~="0" then
			p.account=account
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ PART #oc :.*",function(nick)
		perms[nick]=nil
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@%S+ NICK :(.+)",function(nick,tonick)
		if perms[nick] then
			perms[tonick]=perms[nick]
			perms[nick]=nil
		end
	end)
	txt:gsub("^:([^%s!]+)![^%s@]+@(%S+) QUIT :.*",function(nick)
		perms[nick]=nil
	end)
end)

hook.new("command_account",function(user,chan,txt)
	respond(user,user.nick..", "..((perms[txt] or {}).account or "none"))
end)

hook.new({"command_source","command_sauce"},function(user,chan,txt)
	respond(user,user.nick..", https://github.com/P-T-/-v4/")
end)

dofile("help.lua")
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
		["api-robot"]={"robot","robots","robot api","robots api","turtle","turtle api"},
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
		[":http://www.lua.org/manual/5.2/manual.html#6.8"]={"io","io api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.7"]={"bit32","bit32 api","bit","bit api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.6"]={"math","math api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.5"]={"table","table api","tables","tables api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.4"]={"string","string api","strings","strings api"},
		[":http://www.lua.org/manual/5.2/manual.html#6.2"]={"coroutine","coroutine api","coroutines","coroutine api"},
		[":http://en.wikipedia.org/wiki/Sod's_law"]={"joshtheender","ender","josh"},
		[":http://en.wikipedia.org/wiki/Ping_of_death"]={"ping","pong","^v","pixeltoast"},
		[":http://en.wikipedia.org/wiki/Hydrofluoric_acid"]={"bizzycola","cola","bizzy"},
		[":http://en.wikipedia.org/wiki/OS_X"]={"asie","asiekierka","kierka"},
		[":http://en.wikipedia.org/wiki/Stoner_(drug_user)"]={"kenny"},
		[":http://en.wikipedia.org/wiki/Methylcyclopentadienyl_Manganese_Tricarbonyl"]={"vexatos"},
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
	hook.new({"command_wiki","command_w","command_help","command_h"},function(user,chan,txt)
		txt=txt:lower()
		local out="Not found."
		local b="https://github.com/MightyPirates/OpenComputers/wiki/"
		if txt=="" then
			respond(user,user.nick..", "..b)
			return
		end
		if twikinames[txt] then
			out=b..txt
		elseif wikinames[txt] then
			local t=wikinames[txt]
			if t:sub(1,1)==":" then
				out=t:sub(2)
			else
				out=b..t
			end
		elseif help[txt] then
			out=help[txt]
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

hook.new({"command_random"},function(user,chan,fname)
	local t={}
	local n=0
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	local txt,name
	while line do
		txt,name=line:match("^%[%d+%] (<(%S-)> .*)")
		if not txt then
			txt,name=line:match("^%[%d+%] (%(%S-) .*)")
		end
		if txt and (name==fname or fname=="") then
			n=n+1
			t[n]=txt
		end
		line=file:read("*l")
	end
	file:close()
	if n==0 then
		respond(user,user.nick..", Not found")
	else
		respond(user,user.nick..", "..t[math.random(1,n)])
	end
end)

hook.new({"command_stats","command_messages"},function(user,chan,txt)
	local o={}
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	local t=0
	local alias={}
	while line do
		local fnick,tonick=line:match("^%[%d+%] (%S+) is now known as (%S+)")
		if fnick then
			if alias[fnick] then
				alias[fnick][tonick]=true
			elseif alias[tonick] then
				alias[tonick][fnick]=true
			else
				alias[fnick]={[tonick]=true}
			end
		end
		local usr=line:match("^%[%d+%] <(%S-)> .*") or line:match("^%[%d+%] (%S+) .*")
		if usr then
			t=t+1
			o[usr]=(o[usr] or 0)+1
		end
		line=file:read("*l")
	end
	file:close()
	local c=0
	for k,v in pairs(alias) do
		o[k]=o[k] or 0
		for n,l in pairs(v) do
			o[k]=o[k]+(o[n] or 0)
			o[n]=nil
		end
	end
	for k,v in tpairs(o) do
		c=c+1
		o[k]=nil
		o[c]={k,v}
	end
	table.sort(o,function(a,b) return a[2]>b[2] end)
	local out=user.nick..", Total messages: "..t
	for l1=1,10 do
		if not o[l1] then
			break
		end
		out=out..", "..o[l1][1].." "..(math.ceil((o[l1][2]/t)*1000)/10).."%"
	end
	respond(user,out)
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

hook.new({"command_s","command_short","command shorturl"},function(user,chan,txt)
	respond(user,user.nick..", "..shorturl(txt))
end)

hook.new({"command_j","command_jenkins","command_build","command_beta"},function(user,chan,txt)
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

send("WHO #oc %hna")
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