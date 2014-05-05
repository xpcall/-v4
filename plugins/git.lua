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
	txt:gsub("https://gist%.github%.com/(%w-)/(%d+)",function(user,id)
		local dat,err=https.request("https://api.github.com/gists/"..id)
		if not dat then
			return
		end
		local desc=""
		local cn=dat:match('"description":"()')
		if cn then
			local esc=false
			while true do
				local cc=dat:sub(cn,cn)
				desc=desc..cc
				io.write(cc)
				cn=cn+1
				if esc then
					esc=false
				else
					if cc=="\\" then
						desc=desc:sub(1,-2)
						esc=true
					elseif cc=='"' then
						desc=desc:sub(1,-2)
						break
					end
				end
			end
		else
			desc="No desc."
		end
		local lang=dat:match('"language":"(.-)",')
		o=desc..
		(lang and " Written in "..lang or "")..
		" by "..(dat:match('.+"login":"(.-)",') or "Error").." "..
		math.round((tonumber(dat:match('"size":(.-),')) or 0)/1000,2).."KB"
	end)
	return o
end)