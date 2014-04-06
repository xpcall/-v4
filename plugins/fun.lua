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

hook.new({"command_derp"},function()
	return "herp"
end)
hook.new({"command_herp"},function()
	return "derp"
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
	return shorturl(txt)
end)

hook.new({"command_j","command_jenkins","command_build","command_beta"},function(user,chan,txt)
	local dat,err=http.request("http://ci.cil.li/job/OpenComputers/")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local size,url
	for s,u in dat:gmatch('<td class="fileSize">(.-)</td><td><a href="lastSuccessfulBuild/artifact/build/(.-)/%*fingerprint%*/">') do
		size,url=s,u
	end
	local tme=dat:match(
		'<a class="permalink%-link model%-link inside tl%-tr" href="lastSuccessfulBuild/">Last successful build %(#%d+%), (.-)</a>'
	) or "Error grabbing time."
	if url then
		return "Last successful build "..size.." "..shorturl("http://ci.cil.li/job/OpenComputers/lastSuccessfulBuild/artifact/build/"..url).." "..tme
	else
		return "Error parsing page."
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
	["beiber"]="http://gabrielecirulli.github.io/2048/",
	["troll"]="http://la-oui.ch/troll2048/",
	["quantum"]="http://uhyohyo.net/quantum2048/",
	["lhc"]="http://mattleblanc.github.io/LHC/",
	["doctor"]="http://games.usvsth3m.com/2048-doctor-who-edition/",
}
hook.new({"command_2^11","command_2048"},function(user,chan,txt)
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