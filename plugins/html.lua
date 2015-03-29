html={}
function html.decode(txt)
	local o={}
	local st={o}
	while #txt>0 do
		local c=st[1]
		txt=txt:gsub("^[\t\r\n]+","")
		local cmd,param,se,etxt=txt:match("^<%s*([^%s>]+)%s*([^%s>]-)%s*(/?)%s*>(.*)")
		local cmd2,etxt2=txt:match("^</%s*(.-)%s*>(.*)")
		if cmd2 then
			print(1)
			table.remove(st,1)
			txt=etxt2
		elseif cmd then
			print(2)
			local pr={cmd}
			local o={pr}
			table.insert(c,o)
			if se~="" then
				table.insert(st,1,o)
			end
			txt=etxt
		else
			print(3)
			if type(c[#c])=="string" then
				c[#c]=c[#c]..txt:sub(1,1)
			else
				c[#c+1]=txt:sub(1,1)
			end
			txt=txt:sub(2)
		end
	end
	return o
end