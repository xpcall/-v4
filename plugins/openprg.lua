local function get(url)
	local dat,code=https.request(url)
	if code~=200 then
		error("Error "..url..","..code)
	end
	local res=json.decode(dat)
	return res
end
local last={}
local file=io.open("db/openprg","r")
if file then
	last=unserialize(file:read("*a"))
	if not last then
		last={}
	end
end
hook.new("command_openprg",function(user,chan,txt)
	local repos=git.get("https://api.github.com/orgs/OpenPrograms/repos")
	local updated={}
	local update=false
	for k,v in pairs(repos) do
		local commits=git.get(v.commits_url:match("[^{]+"))
		local tupdate=false
		for n,l in pairs(commits) do
			if tupdate or l.sha==last[v.name] then
				break
			end
			local commit=git.get(v.commits_url:gsub("{/sha}","/"..l.sha))
			for c,f in pairs(commit.files) do
				if f.filename=="programs.yaml" then
					table.insert(updated,v.name)
					update=true
					tupdate=true
					break
				end
			end
		end
		last[v.name]=commits[1].sha
	end
	local file=io.open("db/openprg","w")
	file:write(serialize(last))
	file:close()
	if update then
		local file=io.open("openprograms.bat","w")
		file:write([[cd C:\Users\Kevin\Documents\GitHub\openprograms.github.io
git pull
lua C:\Users\Kevin\Documents\GitHub\openprograms.github.io\generate.lua
git commit
git add index.html
git add style.css
git commit -m "Auto compile"
git push
exit]])
		file:close()
		os.execute("openprograms.bat")
		return "Updated "..table.concat(updated,", ")
	else
		return "No updates"
	end
end)
