git={}
local file=io.open("githubpassword.txt","r")
local auth=file:read("*a")
file:close()
function git.get(url)
	print("git get "..url)
	local dat,code=https.request("https://"..auth.."@"..url:gsub("^https://",""))
	if code~=200 then
		error("Error "..url..","..code)
	end
	local res=json.decode(dat)
	return res
end

hook.new("msg",function(user,chan,txt,act)
	local o
	txt:gsub("https://gist%.github%.com/%w-/(%w+)",function(id)
		local dat,err=https.request("https://api.github.com/gists/"..id)
		if not dat then
			return
		end
		local dat,err=json.decode(dat)
		if not dat or not next(dat.files or {}) then
			return
		end
		local fl=dat.files[next(dat.files)] or {}
		local lang=fl.language
		local desc=dat.description
		if not dec or #desc==0 then
			desc="No desc"
		end
		o=desc..
		(lang and " Written in "..lang or "")..
		" by "..((dat.owner or {}).login or "Error").." "..
		math.round((fl.size or 0)/1000,2).."KB"
	end)
	return o
end)