vex={}

function vex.update()
	fs.write("vex",ahttp.get('http://www.robotevents.com/robot-competitions/vex-robotics-competition?limit=all'))
end

function vex.updateMatches()
	local t=#vex.turnoments()
	local q={}
	for k,v in pairs(vex.turnoments()) do
		local fn=v.code
		local f="www/data/"..fn..".txt"
		if not fs.exists(f) or fs.read(f):match("There are no matches to show at this time.") then
			table.insert(q,{f,"http://ajax.robotevents.com/tm/results/matches/?format=txt&sku="..fn.."&div=1"})
		end
		local f="www/data2/"..fn..".txt"
		if not fs.exists(f) or fs.read(f):match("There are no rankings to show at this time.") then
			table.insert(q,{f,"http://ajax.robotevents.com/tm/results/rankings/?format=txt&sku="..fn.."&div=1"})
		end
	end
	print((#q).." to download")
	dispatchthreads(1,function(fn,url)
		print("downloading "..url)
		local http=require("socket.http")
		local lfs=require("lfs")
		local data=assert(http.request(url))
		local file=io.open(fn,"w")
		file:write(data)
		file:close()
		print("downloaded "..url)
	end,q)
end

function vex.turnoments()
	local txt=fs.read("vex")
	local o={}
	local dl={}
	for tn in txt:gmatch('<tr class="listing%-item">(.-)</tr>') do
		local ou={}
		local url=tn:match('<a href="(.-)"')
		local code=url:match("/([^/]+).html$"):lower()
		if not code:match("^re%-vrc%-%d+%-%d+") and not fs.exists("www/data3/"..code..".html") then
			print("inserting code: "..code)
			table.insert(dl,{url,code})
		end
		ou.title=tn:match('title="(.-)"')
		ou.location=tn:match('<td style="border%-bottom:1px solid #e5e5e5;">%s+(.-)%s+%&nbsp;'):gsub("[\r\n]","")
		ou.date=tn:match('<td style="text%-align:left;border%-bottom:1px solid #e5e5e5;">%s+(.-)%s+%&nbsp;')
		ou.url=url
		ou.code=code
		table.insert(o,ou)
	end
	dispatchthreads(1,function(url,code)
		local http=require("socket.http")
		local lfs=require("lfs")
		local data=assert(http.request(url))
		if lfs.attributes("www/data3/"..code..".html")~=nil then
			error("watf exists")
		end
		local file=io.open("www/data3/"..code..".html","w")
		file:write(data)
		file:close()
		print("found code: "..data:match("<b>Event Code:</b> (.-)</div>"):lower())
	end,dl)
	for k,v in pairs(o) do
		if not v.code:match("^re%-vrc%-%d+%-%d+") then
			print("reading code: "..v.code)
			v.code=fs.read("www/data3/"..v.code..".html"):match("<b>Event Code:</b> (.-)</div>"):lower()
		end
	end
	return o
end

function vex.matches()
	
end

function vex.count()
	local o={}
	for k,v in pairs(fs.list("www/data")) do
		local txt=fs.read("www/data/"..v)
		for txt2 in txt:gmatch('<div class="matchbit">(.-)<div class="clearer">') do
			local d={red={},blue={}}
			local tm={}
			local cn=0
			for t,e,r in txt2:gmatch('<div class="matchcol2 (%S+) (%S*)">(.-)</div>') do
				cn=cn+1
				if (t=="red" or t=="blue") and e~="sitting" then
					if cn>6 then
						d[t].score=tonumber(r)
					else
						table.insert(d[t],r)
						tm[r]=t
					end
				end
			end
			if d.red.score~=d.blue.score then
				d.winner=d.red.score>d.blue.score and "red" or "blue"
				for k,v in pairs(tm) do
					o[k]=o[k] or {w=0,l=0,t=0,m={}}
					d.score=d[v].score
					d.oscore=d[v=="red" and "blue" or "red"].score
					table.insert(o[k].m,{score=d.score,oscore=d.oscore})
					local i=v==d.winner and "w" or "l"
					o[k][i]=o[k][i]+1
				end
			else
				for k,v in pairs(tm) do
					o[k]=o[k] or {w=0,l=0,t=0,m={}}
					d.score=d[v].score
					d.oscore=d[v=="red" and "blue" or "red"].score
					table.insert(o[k].m,{score=d.score,oscore=d.oscore})
					o[k].t=o[k].t+1
				end
			end
		end
	end
	return o
end

function vex.rankings()
	local o={}
	for k,v in pairs(fs.list("www/data2")) do
		local txt=fs.read("www/data2/"..v)
		for txt2 in txt:gmatch('<div class="rankbit">(.-)<div class="clearer">') do
			local team=txt2:match('<div class="rankcol2">#(.-)</div>')
			local place=tonumber(txt2:match('<div class="rankcol1">(%d+).</div>'))
			o[team]=o[team] or {}
			table.insert(o[team],place)
		end
	end
	return o
end

function vex.generate(team)
	local rk=vex.rankings()["4540D"]
	local mt=vex.count()["4540D"]
	local o=""
	o=o.."<h1>Team "..team.."</h1>"
	o=o.."<h2>Statistics:</h2>"
	local a=0
	for l1=1,#rk do
		a=a+(rk[l1]/#rk)
	end
	o=o.."Average rank: "..(math.floor(a*10)/10).."<br>"
	o=o.."Total matches: "..(#mt.m).."<br>"
	o=o.."Matches won: "..mt.w.."<br>"
	o=o.."Matches tied: "..mt.t.."<br>"
	o=o.."Matches lost: "..mt.l.."<br>"
	table.sort(mt.m,function(a,b) return a.score>b.score end)
	o=o.."Best match: "..mt.m[1].score.."<br>"
	o=o.."Worst match: "..mt.m[#mt.m].score.."<br>"
	fs.write("www/vexdata/"..team..".html",o)
end
