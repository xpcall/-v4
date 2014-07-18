hook.new({"command_alot","command_ALOT"},function(user,chan,txt)
	return "http://hyperboleandahalf.blogspot.no/2010/04/alot-is-better-than-you-at-everything.html"
end,{
	desc="links to alot is better than you at everything",
	group="fun"
})

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
end,{
	desc="repeats a string",
	group="misc",
})

hook.new("command_sdate",function(user,chan,txt)
	return "Sep " .. math.ceil(os.difftime(os.time(),os.time({year=1993,month=9,day=1,hour=0}))/86400) .. ", 1993"
end,{
	desc="gets Eternal September time",
	group="fun",
})

hook.new({"command_ip2num"},function(user,chan,txt)
	local ip=txt:tmatch("%d+")
	return tostring((ip[1]*16777216)+(ip[2]*65536)+(ip[3]*256)+ip[4])
end,{
	desc="converts a ip to a number",
	group="fun",
})

hook.new({"command_num2ip"},function(user,chan,txt)
	local num=tonumber(txt) or 0
	return math.floor(num/16777216).."."..(math.floor(num/65536)%256).."."..(math.floor(num/256)%256).."."..(num%256)
end,{
	desc="converts a number to a ip",
	group="fun",
})

hook.new({"command_derp"},function()
	return "herp"
end,{
	desc="herp",
	group="fun",
})
hook.new({"command_herp"},function()
	return "derp"
end,{
	desc="derp",
	group="fun",
})
hook.new({"command_beep"},function()
	return "boop"
end,{
	desc="boop",
	group="fun",
})
hook.new({"command_boop"},function()
	return "beep"
end,{
	desc="beep",
	group="fun",
})

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
	end,{
		desc="mispells text",
		group="fun",
	})
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
	return true,"\1ACTION slaps "..txt.."\1"
end,{
	desc="slaps someone",
	group="fun",
})

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
end,{
	desc="generates random wikipedia page",
	group="fun",
})

hook.new({"command_rainbow","command_rb"},function(user,chan,txt)
	local c=0
	local colors={"04","07","08","03","02","12","06","04","07"}
	return txt:gsub(".",function(t)
		c=(c%9)+1
		return "\3"..colors[c]..t
	end)
end,{
	desc="turns text into a rainbow",
	group="fun",
})

hook.new({"command_source","command_sauce"},function(user,chan,txt)
	return "https://github.com/P-T-/-v4/"
end,{
	desc="my source",
	group="misc",
})

hook.new({"command_wobbo","command_dubstep"},function(user,chan,txt)
	return string.rep("Wobbo",math.random(5,10)):gsub("o",function() return ("o"):rep(math.random(1,10)) end)
end,{
	desc="WooooooobboooooWobboooooooooooooo",
	group="fun",
})

hook.new({"command_echo","command_say","command_spell"},function(user,chan,txt)
	return txt
end,{
	desc="echos",
	group="misc",
})

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
end,{
	desc="OC commit statistics",
	group="help",
})

do
	local u
	hook.new({"command_namegen"},function(user,chan,txt)
		send("cs namegen")
		u=user
	end,{
		desc="generates names using chanserv",
		group="misc",
	})
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
end,{
	desc="random quote",
	group="misc",
})

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
end,{
	desc="finds random quote that matches",
	group="misc",
})

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
end,{
	desc="scrambles text",
	group="fun",
})

--[[hook.new({"command_stats","command_messages"},function(user,chan,txt)
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
end,{
	desc="channel stats",
	group="misc",
})]]

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
end,{
	desc="word frequency statistics",
	group="misc",
})

hook.new({"command_acronym"},function(user,chan,txt)
	local o={}
	local file=io.open("log.txt","r")
	local line=file:read("*l")
	local used={}
	while line do
		for word in line:gmatch("%w+") do
			word=word:lower()
			if not used[word] then
				used[word]=true
				local b=word:sub(1,1)
				o[b]=o[b] or {}
				table.insert(o[b],word)
			end
		end
		line=file:read("*l")
	end
	file:close()
	local ot={}
	for letter in txt:gmatch("%S") do
		local c=o[letter:lower()] or {letter}
		table.insert(ot,c[math.random(1,#c)])
	end
	return table.concat(ot," ")
end,{
	desc="generates words for acronyms",
	group="misc",
})

local magic8={
	"It is certain",
	"It is decidedly so",
	"Without a doubt",
	"Yes definitely",
	"You may rely on it",
	"As I see it, yes",
	"Most likely",
	"Outlook good",
	"Yes",
	"Signs point to yes",
	"Reply hazy try again",
	"Ask again later",
	"Better not tell you now",
	"Cannot predict now",
	"Concentrate and ask again",
	"Don't count on it",
	"My reply is no",
	"My sources say no",
	"Outlook not so good",
	"Very doubtful",
}
hook.new("msg",function(user,chan,txt)
	local question=txt:match("^"..cnick.."[,:] (.+)")
	if question then
		local ch=question:match("%s+$")
		local range=(ch==" " and {1,10}) or (ch=="  " and {16,20}) or (ch=="   " and {11,15}) or {1,20}
		return magic8[math.random(range[1],range[2])]
	end
end)

--[[function shorturl(url)
	if not url then
		return "Error url nil"
	end
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
end]]

local pass=fs.read("pass/bitlytoken.txt"):gsub("%X","")
function shorturl(url)
	local res,err=https.request("https://api-ssl.bitly.com/v3/shorten?access_token="..pass.."&uri="..urlencode(url))
	print("getting ".."https://api-ssl.bitly.com/v3/shorten?access_token="..pass.."&uri="..urlencode(url))
	if not res then
		return "Error "..url
	end
	local out=json.decode(res)
	if out.status_code~=200 then
		return "Error "..(out.status_txt or out.status_code)
	end
	return out.data.url
end

hook.new({"command_len"},function(user,chan,txt)
	return tostring(#txt)
end,{
	desc="shows length of text",
	group="misc",
})

hook.new({"command_s","command_short","command shorturl"},function(user,chan,txt)
	return shorturl(txt)
end,{
	desc="shortens url",
	group="misc",
})

hook.new({"command_reverse"},function(user,chan,txt)
	return txt:reverse()
end,{
	desc="reverses text",
	group="misc",
})

hook.new({"command_raw"},function(user,chan,txt)
	if admin.auth(user) then
		send(txt)
	end
end,{
	desc="sends raw data",
	group="admin",
})

hook.new({"command_fc","command_failcaps"},function(user,chan,txt)
	return txt:gsub(".",function(t)
		return math.random(1,2)==1 and t:lower() or t:upper()
	end)
end,{
	desc="scrambles caps",
	group="fun",
})

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
end,{
	desc="scrambles letters and caps",
	group="fun",
})

hook.new({"command_lc","command_flipcaps"},function(user,chan,txt)
	return txt:gsub(".",function(n)
		return n:lower()==n and n:upper() or n:lower()
	end)
end,{
	desc="flips caps",
	group="fun",
})

hook.new({"command_sksboard"},function(user,chan,txt)
	return txt:gsub(".",function(n) return math.random(1,5)==1 and n:rep(2) or n end)
end,{
	desc="siimulatees SKS''s kkeyboarrd",
	group="fun",
})

hook.new({"command_aeiou"},function(user,chan,txt)
	local vowel={
		a="e",e="i",i="o",o="u",u="a",A="E",E="I",I="O",O="U",U="A",
	}
	return txt:gsub("[aeiouAEIOU]",function(t) return vowel[t] end)
end,{
	desc="aeiou rotate math -> meth blame gamax",
	group="fun",
})

hook.new({"command_2^14","command_16384"},function()
	return "http://rudradevbasak.github.io/16384_hex/"
end,{
	desc="2048 clone",
	group="fun",
})

hook.new({"command_2^53","command_9007199254740992"},function(user,chan)
	return "http://www.csie.ntu.edu.tw/~b01902112/9007199254740992/"
end,{
	desc="2048 clone",
	group="fun",
})

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
end,{
	desc="factors a number",
	group="misc",
})

hook.new("command_supermispell",function(user,chan,txt)
	for l1=1,5 do
		txt=hook.queue("command_mispell",user,chan,txt)
	end
	return txt
end,{
	desc="super mispells text",
	group="fun",
})

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
end,{
	desc="2048 game",
	group="fun",
})

hook.new("command_pipe",function(user,chan,txt)
	local o=""
	for cmd in txt:gmatch("[^|]+") do
		local cm,tx=cmd:match("(%S+) ?(.*)")
		if not cm or not hook.hooks["command_"..cm] then
			return "Unknown command \""..(cm or "").."\""
		end
		print("piping "..tx..o)
		local t
		o,t=hook.queue("command_"..cm,user,chan,tx..o)
		o=(o==true and t or o) or ""
	end
	return o
end,{
	desc="pipes commands",
	group="misc",
})

hook.new("command_pastebin",function(user,chan,txt)
	local res={}
	local scc,err=http.request("http://pastebin.com/raw.php?i="..txt)
	if err==404 then
		return "Not found."
	end
	return scc or err
end,{
	desc="grabs pastebin id",
	group="misc",
})

hook.new("command_hastebin",function(user,chan,txt)
	local res={}
	local scc,err=http.request("http://hastebin.com/raw/"..txt:match("%S+"))
	if err==404 then
		return "Not found."
	end
	return scc or err
end,{
	desc="grabs hastebin id",
	group="misc",
})

hook.new("command_tohastebin",function(user,chan,txt)
	local dat,err=http.request("http://hastebin.com/documents",txt)
	if dat and dat:match('{"key":"(.-)"') then
		return "http://hastebin.com/"..dat:match('{"key":"(.-)"')
	end
	return "Error "..err
end,{
	desc="uploads to hastebin",
	group="misc",
})

hook.new({"command_tob64","command_b64"},function(user,chan,txt)
	return tob64(txt)
end,{
	desc="base64 encodes",
	group="misc",
})

hook.new({"command_unb64","command_ub64"},function(user,chan,txt)
	return unb64(txt)
end,{
	desc="base64 decodes",
	group="misc",
})

hook.new({"command_bytes"},function(user,chan,txt)
	return table.concat({txt:byte(1,-1)}," ")
end)

hook.new({"command_drama"},function(user,chan,txt)
	local dat,err=http.request("http://asie.pl/drama.php?plain")
	return dat or "Error "..err
end,{
	desc="asie's drama generator",
	group="misc",
})

hook.new({"command_lines"},function(user,chan,txt)
	local count
	function count(dir)
		local t=0
		for k,v in pairs(fs.list(dir)) do
			local file=fs.combine(dir,v)
			if fs.isDir(file) then
				t=t+count(file)
			elseif v:match("%.lua$") then
				local fl=assert(io.open(file,"r"))
				for l in fl:read("*a"):gmatch("\n") do
					t=t+1
				end
				fl:close()
			end
		end
		return t
	end
	return count(lfs.currentdir())
end,{
	desc="counts total lines of lua in the bot",
	group="misc",
})

hook.new({"command_!"},function(user,chan,txt)
	return txt..("!"):rep(math.random(10,20)):gsub("!",function()
		if math.random(1,5)==1 then
			return 1
		elseif math.random(1,10)==1 then
			return "one"
		end
	end):gsub("11",function()
		if math.random(1,5)==1 then
			return "eleven"
		end
	end)
end,{
	desc="epic!!!!1!!!1!!!!1!!1!one",
	group="fun",
})

hook.new({"command_mcdown","command_mcstats","command_mcstat","command_mc"},function(user,chan,txt)
	local res,err=http.request("http://status.mojang.com/check")
	if err~=200 then
		return "error "..err
	end
	local dat=json.decode(res)
	if not dat then
		return "error parsing"
	end
	local nm={
		["minecraft.net"]="minecraft.net",
		["session.minecraft.net"]="sessions",
		["account.mojang.com"]="account",
		["auth.mojang.com"]="auth",
		["skins.minecraft.net"]="skins",
		["authserver.mojang.com"]="auth-server",
		["sessionserver.mojang.com"]="session-server",
		["login.minecraft.net"]="legacy-login",
		["api.mojang.com"]="api",
		["textures.minecraft.net"]="textures",
	}
	local up={}
	local slow={}
	local down={}
	for l1=1,#dat do
		local k=next(dat[l1])
		local v=dat[l1][k]
		table.insert((v=="green" and up) or (v=="yellow" and slow) or (v=="red" and down) or {},nm[k] or k)
	end
	if #slow==0 and #down==0 then
		return #up==0 and "error parsing" or "all good"
	end
	local o={}
	if #down~=0 then
		if #up>=#down or #slow~=0 then
			o[#o+1]=table.concat(down," ").." "..(#down==1 and "is" or "are").." down"
		else
			o[#o+1]="everything but "..table.concat(up," ").." is down"
		end
	end
	if #slow~=0 then
		if #up>=#slow or #down~=0 then
			o[#o+1]=table.concat(slow," ").." "..(#slow==1 and "is" or "are").." slow"
		else
			o[#o+1]="everything but "..table.concat(up," ").." is slow"
		end
	end
	return table.concat(o," and ")
end,{
	desc="checks if mojang's servers are down",
	group="fun",
})


hook.new({"command_steal","command_wouldsteal"},function(user,chan,txt)
	return "https://www.youtube.com/watch?v=zhKdH8MT6j0"
end,{
	desc="links to 10/10 would steal",
	group="fun",
})

hook.new({"command_lazyupdateoc"},function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	local res=hook.queue("command_j",user,chan,"")
	respond(user,"Downloading...")
	local data,err=ahttp.get(res:match("http://%S+"))
	if not data then
		return err
	end
	file["/home/nadine/Desktop/server/mods/oc.jar"]=data
	return "Updated"
end,{
	desc="updates OC on my server automatically",
	group="fun",
})

function guesshax(min,max)
	local last=math.floor((min+max)/2)
	return {
		less=function()
			max=last-1
			last=math.floor((min+max)/2)
			return last
		end,
		more=function()
			min=last+1
			last=math.floor((min+max)/2)
			return last
		end,
	},last
end

do
	local function z(val)
		local size=val<0x10000 and (val<0x800 and (val<0x80 and 1 or 2) or 3) or 4
		if size==1 then
			return string.char(val)
		end
		local b={string.char((240*2^(4-size)%256)+(val/2^18)%(2^(7-size)))}
		for i=size*6-12,0,-6 do
			b[#b+1]=string.char(128+(val/2^i)%64)
		end
		return table.concat(b)
	end
	local fonts={
		swank={0x1D56C,0x1D56C},
		serif={0x1D5A0,0x1D5A0,0x1D7E2},
		ultrabold={0x1D400,0x1D400,0x1D7EC},
		bold={0x1D5D4,0x1D5D4,0x1D7EC},
		script={0x1D4D0,0x1D4D0},
		monospace={0x1D670,0x1D670,0x1D7F6},
		doublestruck={0x1D538,0x1D538,0x1D7D8},
		greek={0x1D756,0x1D756},
	}
	local types={
		{"%l",71},
		{"%u",65},
		{"%d",48},
	}
	local function conv(txt,font)
		for n,l in pairs(font) do
			txt=txt:gsub(types[n][1],function(t)
				return z(l+t:byte()-types[n][2])
			end)
		end
		return txt
	end
	local flist={}
	local nlist={}
	for k,v in pairs(fonts) do
		table.insert(flist,v)
		if v[3] then
			table.insert(nlist,v)
		end
		hook.new("command_"..k,function(user,chan,txt)
			return conv(txt,v)
		end,{
			desc="unicode font",
			group="fun",
		})
	end
	hook.new({"command_derpfont"},function(user,chan,txt)
		txt=txt:gsub("%a",function(t)
			return conv(t,flist[math.random(1,#flist)])
		end):gsub("%d",function(t)
			return conv(t,nlist[math.random(1,#nlist)])
		end)
		return txt
	end,{
		desc="randomizes the unicode font",
		group="fun",
	})
end

