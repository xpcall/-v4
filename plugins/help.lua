function fancynum(num)
	num=tostring(num) return num:gsub("%..+",""):reverse():gsub("...","%1,"):reverse():gsub("^,","")..(num:match("%..+") or "")
end

hook.new({"command_forums","command_f"},function(user,chan,txt)
	return "http://oc.cil.li/"
end)

hook.new({"command_git","command_github"},function(user,chan,txt)
	return "https://github.com/MightyPirates/OpenComputers/"
end)

hook.new({"command_openprograms","command_openp"},function(user,chan,txt)
	return "openprograms.github.io https://github.com/OpenPrograms/"..txt
end)

hook.new({"command_opencomponents","command_openc"},function(user,chan,txt)
	return "http://ci.cil.li/job/OpenComponents/"..txt
end)

jenkins={
	[{"http://ci.cil.li/job/OpenComputers/api/json?depth=1","OpenComputers"}]={"oc","opencomputers","16","164","oc16","oc164"},
	[{"http://ci.cil.li/job/OpenComputers-MC1.7/api/json?depth=1","OpenComputers 1.7"}]={"opencomputers17","17","172","oc17","oc172"},
	[{"http://ci.cil.li/job/OpenComponents/api/json?depth=1","OpenComponents"}]={"c","c16","components","opencomponents","ocomponents"},
	[{"http://ci.cil.li/job/OpenComponents-MC1.7/api/json?depth=1","OpenComponents 1.7"}]={"c17","components17","opencomponents17","ocomponents17"},
	[{"http://lanteacraft.com/jenkins/job/OpenPrinter/api/json?depth=1","OpenPrinters"}]={"op","op16","printer","printer16","openprinter","openprinters","openprinter16"},
	[{"http://lanteacraft.com/jenkins/job/OpenPrinter1.7/api/json?depth=1","OpenPrinters 1.7"}]={"op17","printer17","openprinter17","openprinters16"},
}
for k,v in tpairs(jenkins) do
	for n,l in pairs(v) do
		jenkins[l]=k
	end
	jenkins[k]=nil
end
hook.new({"command_j","command_build","command_beta"},function(user,chan,txt)
	txt=txt:lower():gsub("[%s%.]","")
	if txt=="" then
		txt="oc"
	end
	if jenkins[txt] then
		local dat,err=http.request(jenkins[txt][1])
		if not dat then
			if err then
				return "Error grabbing "..jenkins[txt][1].." ("..err..")"
			else
				return "Error grabbing "..jenkins[txt][1]
			end
		end
		local dat=json.decode(dat)
		if not dat then
			return "Error parsing page."
		end
		dat=dat.lastSuccessfulBuild
		local miliseconds=(socket.gettime()*1000)-dat.timestamp
		local seconds=math.floor(miliseconds/1000)
		local minutes=math.floor(seconds/60)
		local hours=math.floor(minutes/60)
		local days=math.floor(hours/24)
		miliseconds=miliseconds~=0 and ((miliseconds%1000).." milliseconds ") or ""
		seconds=seconds~=0 and ((seconds%60).." seconds ") or ""
		minutes=minutes~=0 and ((minutes%60).." minutes ") or ""
		hours=hours~=0 and ((hours%24).." hours ") or ""
		days=days~=0 and (days.." days ") or ""
		local url
		for k,v in pairs(dat.artifacts) do
			if v.relativePath:match("%-universal.jar$") then
				url=v.relativePath
			end
		end
		url=url or dat.artifacts[1].relativePath
		return "Last sucessful build for "..jenkins[txt][2]..": "..shorturl(dat.url.."artifact/"..url).." "..days..hours..minutes.."ago"
	end
end)

hook.new({"command_r","command_release","command_releases"},function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/releases")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local dat=json.decode(dat)
	if not dat or not dat[1] then
		error("Error parsing. "..serialize(dat))
	end
	dat=dat[1]
	local burl="https://github.com/MightyPirates/OpenComputers/releases/download/"..dat.tag_name.."/"
	return "Latest release: "..dat.name.." Download: 1.6.4 "..shorturl(burl..dat.assets[1].name).." 1.7.2 "..shorturl(burl..dat.assets[1].name)
end)

hook.new({"command_dlstats","command_downloads"},function(user,chan,txt)
	local dat,err=https.request("https://api.github.com/repos/MightyPirates/OpenComputers/releases")
	if not dat then
		if err then
			return "Error grabbing page. ("..err..")"
		else
			return "Error grabbing page."
		end
	end
	local dat=json.decode(dat)
	if not dat then
		return "Error parsing."
	end
	local total=0
	local v16=0
	local v17=0
	local cnt
	local mx=0
	for k,v in pairs(dat) do
		local cn=0
		if v.assets[1] then
			local c=v.assets[1].download_count
			total=total+c
			v16=v16+c
			cn=cn+c
		end
		if v.assets[2] then
			local c=v.assets[1].download_count
			total=total+c
			v17=v17+c
			cn=cn+c
		end
		if cn>mx then
			cnt=v.name
			mx=cn
		end
	end
	return "Total: "..fancynum(total).." 1.6: "..math.round((v16/total)*100,2).."% 1.7: "..math.round((v17/total)*100,2).."% Most popular: "..cnt.." with "..fancynum(mx).." downloads"
end)

dofile("help.lua")
local owikinames
do
	local wikinames={
		["api-colors"]={"color","colors","color api","colors api"},
		["api-component"]={"component api","components api"},
		["api-computer"]={"computer","computer api"},
		["api-event"]={"event","events","event api","events api"},
		["api-filesystem"]={"fs","filesystem","fs api","filesystem api"},
		["api-internet"]={"internet api","tcp","socket","sockets","http","http api"},
		["api-keyboard"]={"keyboard","keys","keyboard api","keys api"},
		["api-robot"]={"robot","robots","robot api","robots api","turtle","turtle api"},
		["api-serialization"]={"serialize","serialization","serial","serializer"},
		["api-shell"]={"shell api","shell"},
		["api-sides"]={"sides","sides api"},
		["api-term"]={"term","term api"},
		["api-text"]={"text","text api"},
		["api-unicode"]={"unicode","unicode api"},
		["apis"]={"apis","api","api list","apis list"},
		["blocks"]={"blocks","block list","blocks list"},
		["codeconventions"]={"conventions","code conventions"},
		["component-abstract-bus"]={"abstract bus"},
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
		["component-hologram"]={"holo","hologram","hologram component"},
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
		[":http://www.lua.org/manual/5.1/manual.html#5.4.1"]={"patterns","pattern","regex"},
		[":http://en.wikipedia.org/wiki/Sod's_law"]={"joshtheender","ender","josh"},
		[":http://en.wikipedia.org/wiki/Ping_of_death"]={"ping","pong","^v","pixeltoast"},
		[":http://en.wikipedia.org/wiki/Hydrofluoric_acid"]={"bizzycola","cola","bizzy"},
		[":http://en.wikipedia.org/wiki/OS_X"]={"asie","asiekierka","kierka"},
		[":http://en.wikipedia.org/wiki/Stoner_(drug_user)"]={"kenny"},
		[":http://en.wikipedia.org/wiki/Methylcyclopentadienyl_Manganese_Tricarbonyl"]={"vexatos"},
		[":http://en.wikipedia.org/wiki/Insomnia"]={"kodos"},
		[":http://en.wikipedia.org/wiki/Dustbin"]={"dusty","spiriteddusty","dustbin"},
		[":http://en.wikipedia.org/wiki/Wii_U"]={"ds","ds84182"},
		[":http://ci.cil.li/"]={"jenkins","build","builds","beta"},
	}
	owikinames=wikinames
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
		local b="https://github.com/MightyPirates/OpenComputers/wiki/"
		if txt=="" then
			return b
		end
		if twikinames[txt] then
			return b..txt
		elseif wikinames[txt] then
			local t=wikinames[txt]
			if t:sub(1,1)==":" then
				return t:sub(2)
			else
				return b..t
			end
		elseif help[txt] then
			return help[txt]
		else
			return "Not found."
		end
	end)
end

do
	local req={}
	for k,v in pairs(owikinames) do
		if k:match("^api%-") then
			local n=k:match("^api%-(.+)")
			local str="local "..n.."=require(\""..n.."\")"
			for n,l in pairs(v) do
				req[l]=str
			end
		elseif k:match("^component%-") then
			local n=k:match("^component%-(.+)")
			local str="local component=require(\"component\") local "..n.."=component."..n
			for n,l in pairs(v) do
				req[l]=str
			end
		end
	end
	for k,v in pairs(owikinames["component-redstoneinmotion"]) do
		req[v]="local component=require(\"component\") local carriage=component.carriage"
	end
	hook.new({"command_req","command_require"},function(user,chan,txt)
		return req[txt:lower()] or "Not found."
	end)
end
