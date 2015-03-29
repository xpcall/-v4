function readmap(pid)
	local out={}
	local f="/proc/"..pid.."/maps"
	for line in assert(file[f],"error opening "..f):gmatch("[^\r\n]+") do
		local addr,param,fn=line:match("^(%x+)%-%x+ (%S+) %S+ %S+ %S+%s+(%S+)$")
		if param=="rw-p" then
			out[fn:match("([^/]+)$")]=unserialize("0x"..addr.."ULL")
		end
	end
	return out
end
function convDouble(txt)
	local sign=math.floor(txt:byte(1)/128)
	local exp=(txt:byte(1)%128)+math.floor(txt:byte(2)/16)
	
end