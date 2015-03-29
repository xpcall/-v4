function lex(txt)
	local o={}
	local stack={o}
	local function priority(tbl)
		local pr={"^","*","/","+","-"}
	end
	local tokens={
		["(%()"]=function()
			local n={}
			table.insert(stack[1],n)
			table.insert(stack,1,n)
		end,
		["(%))"]=function()
			table.remove(stack,1)
		end,
		["(%-?%d+)"]=function(n)
			table.insert(stack[1],tonumber(n))
		end,
		["([%+%-/%*%^])"]=function(o)
			table.insert(stack[1],o)
		end,
	}
	while #txt>0 do
		local s=true
		for k,v in pairs(tokens) do
			local r={txt:match("^"..k.."(.*)")}
			if r[1] then
				v(unpack(r,1,#r-1))
				txt=r[#r]
				s=false
				break
			end
		end
		if s then
			txt=txt:sub(2)
		end
	end
	return o
end


