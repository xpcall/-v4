local file=io.open("routerpassword.txt","r")
local pass=file:read("*a")
file:close()
function portforward()
	local res,code=http.request("http://"..pass.."@192.168.1.1/SingleForward.asp")
	local dat={}
	print(code,res)
	for val,ind,num in res:gmatch("value='?(%d+)'? name=(%a+)(%d+)") do
		num=tonumber(num)-4
		if num>0 then
			dat[num]=dat[num] or {}
			if ind=="ip" or ind=="from" or ind=="to" then
				dat[num][ind]=tonumber(val)
			elseif ind=="enable" then
				dat[num][ind]=val=="on"
			end
		end
	end
	return dat
end