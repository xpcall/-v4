

function antiping(name)
	local f=true
	for k,v in pairs(admin.perms) do
		if k:lower()==name:lower() then
			f=false
		end
	end
	if f then
		return name
	end
	local n=name:sub(1,-4)..name:sub(-2,-2)..name:sub(-3,-3)..name:sub(-1)
	if n==name then
		return n:sub(1,-2).."."..n:sub(-1)
	end
	return n
end

hook.new({"command_rep","command_repeat"},function(user,chant,txt)
	local str,num=txt:match("^(.+) (%d+)")
	return str and str:rep(tonumber(num)) or "Usage: .repeat <text> <number>"
end)

hook.new({"command_derp"},function()
	return "herp"
end)
hook.new({"command_herp"},function()
	return "derp"
end)
hook.new({"command_beep"},function()
	return "boop"
end)
hook.new({"command_boop"},function()
	return "beep"
end)

do
	local ukey={
		{"q","w","e","r","t","y","u","i","o","p"},
		{"a","s","d","f","g","h","j","k","l",";"},
		{"z","x","c","v","b","n","m",",",".","/"},
	}
	local ckey={
		{"Q","W","E","R","T","Y","U","I","O","P"},
		{"A","S","D","F","G","H","J","K","L",":"},
		{"Z","X","C","V","B","N","M","<",">","?"},
	}
	local k={}
	local function ins(key,n,x,y)
		local tn=(key[y] or {})[x]
		if tn then
			table.insert(k[n],tn)
		end
	end
	for _,key in pairs({ukey,ckey}) do
		for y=1,3 do
			for x=1,10 do
				local l=key[y][x]
				k[l]={}
				ins(key,l,x+1,y)
				ins(key,l,x-1,y)
				ins(key,l,x,y+1)
				ins(key,l,x,y-1)
				ins(key,l,x-1,y+1)
				ins(key,l,x+1,y-1)
				assert(#k[l]>0,l)
			end
		end
	end
	hook.new({"command_mispell"},function(user,chan,txt)
		if txt=="" then
			txt="Usage: .mispell text"
		end
		if #txt:gsub("[^%a<>%?/:,%./;]","")==0 then
			return txt
		end
		local otxt=txt
		while txt==otxt do
			txt=txt:gsub(".",function(t)
				local tk=k[t]
				if math.random(1,20)==1 and tk then
					return tk[math.random(1,#tk)]
				end
			end):gsub("..",function(t)
				if math.random(1,10)==1 then
					return t:reverse()
				end
			end)
		end
		return txt
	end)
end

function splitn(txt,num)
	local o={}
	while #txt>0 do
		table.insert(o,txt:sub(1,num))
		txt=txt:sub(num+1)
	end
	return o
end

hook.new({"command_slap"},function(user,chan,txt)
	send("PRIVMSG "..(chan==cnick and user.nick or chan).." :\1ACTION slaps "..txt.."\1")
end)

hook.new({"command_wikipedia"},function(user,chan,txt)
	local sv=socket.connect("en.wikipedia.org",80)
	sv:send("GET /wiki/Special:Random HTTP/1.1\r\nHost: en.wikipedia.org\r\n\r\n")
	sv:settimeout(2)
	local s,e=sv:receive()
	if not s then
		return e
	end
	while s do
		local l=s:match("Location: (.+)")
		if l then
			return l
		end
		s,e=sv:receive()
	end
	return e
end)

hook.new({"command_rainbow","command_rb"},function(user,chan,txt)
	local c=0
	local colors={"04","07","08","03","02","12","06","04","07"}
	return txt:gsub(".",function(t)
		c=(c%9)+1
		return "\3"..colors[c]..t
	end)
end)

hook.new({"command_source","command_sauce"},function(user,chan,txt)
	return "https://github.com/P-T-/-v4/"
end)

hook.new({"command_wobbo","command_dubstep"},function(user,chan,txt)
	return string.rep("Wobbo",math.random(5,15)):gsub("o",function() return ("o"):rep(math.random(1,10)) end)
end)

hook.new({"command_echo","command_say","command_spell"},function(user,chan,txt)
	return txt
end)

hook.new("command_commits",function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/contributors")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local o={}
	local t=0
	for name,contrib in dat:gmatch('{"login":"([^"]+)".-"contributions":(%d+)}') do
		contrib=tonumber(contrib)
		t=t+contrib
		o[#o+1]={name:gsub(".","%1"),contrib}
	end
	table.sort(o,function(a,b) return a[2]>b[2] end)
	local out="Total commits: "..t
	for l1=1,5 do
		if not o[l1] then
			break
		end
		out=out..", "..antiping(o[l1][1]).." "..(math.ceil((o[l1][2]/t)*1000)/10).."%"
	end
	return out
end)

do
	local u
	hook.new({"command_namegen"},function(user,chan,txt)
		send("cs namegen")
		u=user
	end)
	hook.new("raw",function(txt)
		local names=txt:match("^:ChanServ!ChanServ@services.esper.net NOTICE "..cnick.." :Some names to ponder: (.+)%.")
		if names then
			local o={}
			for name in names:gmatch("[^,%s]+") do
				table.insert(o,name:lower():reverse())
			end
			respond(u,u.nick..", "..table.concat(o,", "))
		end
	end)
end

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
		return "Not found"
	else
		return t[math.random(1,n)]
	end
end)

hook.new({"command_logmatch"},function(user,chan,fmatch)
	local t={}
	local n=0
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	local txt,name,rl
	while line do
		txt,name,rl=line:match("^%[%d+%] (<(%S-)> (.*))")
		if not txt then
			txt,name,rl=line:match("^%[%d+%] (%(%S-) (.*))")
		end
		if txt and rl:match(fmatch) then
			n=n+1
			t[n]=txt
		end
		line=file:read("*l")
	end
	file:close()
	if n==0 then
		return "Not found"
	else
		return "Total: "..n..", Random: "..t[math.random(1,n)]
	end
end)

hook.new({"command_blend"},function(user,chan,txt)
	local out={}
	for stxt in txt:gmatch("%S+") do
		local a={}
		for l1=1,#stxt do
			a[l1]=stxt:sub(l1,l1)
		end
		local b={}
		local o=""
		for l1=1,#stxt do
			local bc=math.random(1,#stxt)
			while b[bc] do
				bc=math.random(1,#stxt)
			end
			b[bc]=true
			o=o..a[bc]
		end
		table.insert(out,o)
	end
	return table.concat(out," ")
end)

hook.new({"command_stats","command_messages"},function(user,chan,txt)
	local o={}
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	local t=0
	local ch=0
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
		local rl=line:match("^%[%d+%] <%S-> (.*)") or line:match("^%[%d+%] %S+ (.*)")
		if usr then
			ch=ch+#rl
			t=t+1
			o[usr]=(o[usr] or 0)+1
		end
		line=file:read("*l")
	end
	file:close()
	local c=0
	for k,v in pairs(alias) do
		o[k]=o[k] or 0
		local ol=antiping(k)
		for n,l in pairs(v) do
			ol=ol.."/"..antiping(n)
			o[k]=o[k]+(o[n] or 0)
			o[n]=nil
		end
		o[ol]=o[k]
		o[k]=nil
	end
	for k,v in tpairs(o) do
		if k~="Sangar" then
			c=c+1
			o[k]=nil
			o[c]={k,v}
		end
	end
	table.sort(o,function(a,b) return a[2]>b[2] end)
	local out="Total messages: "..t..", chars: "..ch..", "..antiping("Sangar").." 9001%"
	for l1=1,4 do
		if not o[l1] then
			break
		end
		out=out..", "..antiping(o[l1][1]).." "..(math.ceil((o[l1][2]/t)*1000)/10).."%"
	end
	return out
end)

hook.new({"command_freq"},function(user,chan,txt)
	local o={}
	local cnt=0
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	while line do
		for word in line:gmatch("%w+") do
			word=word:lower()
			o[word]=(o[word] or 0)+1
			cnt=cnt+1
		end
		line=file:read("*l")
	end
	file:close()
	local c=0
	for k,v in tpairs(o) do
		c=c+1
		o[k]=nil
		o[c]={k,v}
	end
	table.sort(o,function(a,b) return a[2]>b[2] end)
	local out="Total words: "..cnt
	for l1=1,10 do
		if not o[l1] then
			break
		end
		out=out..", "..antiping(o[l1][1])
	end
	return out
end)

function shorturl(url)
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
		return "Error "..err
	end
	local out=res:match('"id": "([^"]+)",')
	if not out then
		return "Error parsing."
	end
	return out
end

hook.new({"command_len"},function(user,chan,txt)
	return tostring(#txt)
end)

hook.new({"command_s","command_short","command shorturl"},function(user,chan,txt)
	return shorturl(txt)
end)

hook.new({"command_reverse"},function(user,chan,txt)
	return txt:reverse()
end)

hook.new({"command_raw"},function(user,chan,txt)
	if admin.auth(user) then
		send(txt)
	end
end)

hook.new({"command_fc","command_failcaps"},function(user,chan,txt)
	return txt:gsub(".",function(t)
		return math.random(1,2)==1 and t:lower() or t:upper()
	end)
end)

hook.new({"command_fb","command_failblend"},function(user,chan,txt)
	local out={}
	for stxt in txt:gmatch("%S+") do
		local a={}
		for l1=1,#stxt do
			a[l1]=stxt:sub(l1,l1)
		end
		local b={}
		local o=""
		for l1=1,#stxt do
			local bc=math.random(1,#stxt)
			while b[bc] do
				bc=math.random(1,#stxt)
			end
			b[bc]=true
			o=o..a[bc]
		end
		table.insert(out,o)
	end
	return table.concat(out," "):gsub(".",function(t)
		return math.random(1,2)==1 and t:lower() or t:upper()
	end)
end)

hook.new({"command_lc","command_flipcaps"},function(user,chan,txt)
	return txt:gsub(".",function(n)
		return n:lower()==n and n:upper() or n:lower()
	end)
end)

hook.new({"command_sksboard"},function(user,chan,txt)
	return txt:gsub(".",function(n) return math.random(1,5)==1 and n:rep(2) or n end)
end)

hook.new({"command_aeiou"},function(user,chan,txt)
	local vowel={
		a="e",e="i",i="o",o="u",u="a",A="E",E="I",I="O",O="U",U="A",
	}
	return txt:gsub("[aeiouAEIOU]",function(t) return vowel[t] end)
end)

hook.new("command_2^14","command_16384",function()
	return "http://rudradevbasak.github.io/16384_hex/"
end)
hook.new({"command_2^53","command_9007199254740992"},function(user,chan)
	return "http://www.csie.ntu.edu.tw/~b01902112/9007199254740992/"
end)

function factor(n)
	n=math.floor(tonumber(n) or 0)
	if n==0 then
		return {0}
	elseif n==1 then
		return {1}
	end
	if math.sqrt(n)%1==0 then
		local x=factor(math.sqrt(n))
		return {x,x}
	end
	for x=n-1,2,-1 do
		if (n/x)%1==0 then
			return {factor(n/x),factor(x)}
		end
	end
	return {n}
end

hook.new({"command_factor"},function(user,chan,txt)
	if tonumber(txt)>1000000 then
		return "Nope."
	end
	return serialize(factor(txt)):gsub("{","("):gsub("}",")"):gsub(",","*"):gsub("%((%d*)%)","%1"):gsub("^%(",""):gsub("%)$","")
end)

hook.new("command_supermispell",function(user,chan,txt)
	for l1=1,5 do
		txt=hook.queue("command_mispell",user,chan,txt)
	end
	return txt
end)

local t2048={
	["doge"]="http://doge2048.com/",
	["undo"]="http://quaxio.com/2048/",
	["winning"]="http://jennypeng.me/2048/",
	["undo"]="http://quaxio.com/2048/",
	["pokemon"]="http://amschrader.github.io/2048/",
	["tetris"]="http://prat0318.github.io/2048-tetris/",
	["multiplayer"]="http://emils.github.io/2048-multiplayer/",
	["flappy"]="http://hczhcz.github.io/Flappy-2048/",
	["11"]="http://t2.technion.ac.il/~s7395779/",
	["9007199254740992"]="http://www.csie.ntu.edu.tw/~b01902112/9007199254740992/",
	["16384"]="http://rudradevbasak.github.io/16384_hex/",
	["troll"]="http://la-oui.ch/troll2048/",
	["quantum"]="http://uhyohyo.net/quantum2048/",
	["lhc"]="http://mattleblanc.github.io/LHC/",
	["doctor"]="http://games.usvsth3m.com/2048-doctor-who-edition/",
}
hook.new({"command_2^11","command_2048"},function(user,chan,txt)
	txt=txt:lower()
	if t2048[txt] then
		return t2048[txt]
	elseif txt=="random" then
		local t={}
		for k,v in pairs(t2048) do
			table.insert(t,k)
		end
		local r=t[math.random(1,#t)]
		return r..": "..t2048[r]
	end
	txt=txt:lower()
	return "http://gabrielecirulli.github.io/2048/"
end)

hook.new("command_pipe",function(user,chan,txt)
	local o=""
	for cmd in txt:gmatch("[^|]+") do
		local cm,tx=cmd:match("(%S+) ?(.*)")
		if not cm or not hook.hooks["command_"..cm] then
			return "Unknown command \""..(cm or "").."\""
		end
		print("piping "..tx..o)
		o=hook.queue("command_"..cm,user,chan,tx..o) or ""
	end
	return o
end)

hook.new("command_pastebin",function(user,chan,txt)
	local res={}
	local scc,err=http.request("http://pastebin.com/raw.php?i="..txt)
	if err==404 then
		return "Not found."
	end
	return scc or err
end)

hook.new("command_hastebin",function(user,chan,txt)
	local res={}
	local scc,err=http.request("http://hastebin.com/raw/"..txt)
	if err==404 then
		return "Not found."
	end
	return scc or err
end)

hook.new("command_tohastebin",function(user,chan,txt)
	local dat,err=http.request("http://hastebin.com/documents",txt)
	if dat and dat:match('{"key":"(.-)"') then
		return "http://hastebin.com/"..dat:match('{"key":"(.-)"')
	end
	return "Error "..err
end)

hook.new({"command_tob64","command_b64"},function(user,chan,txt)
	return tob64(txt)
end)

hook.new({"command_unb64","command_ub64"},function(user,chan,txt)
	return unb64(txt)
end)

hook.new({"command_drama"},function(user,chan,txt)
	local dat,err=http.request("http://asie.pl/drama.php?plain")
	return dat or "Error "..err
end)
function urlencode(txt)
	return txt:gsub("\r?\n","\r\n"):gsub("[^%w ]",function(t) return string.format("%%%02X",t:byte()) end):gsub(" ","+")
end