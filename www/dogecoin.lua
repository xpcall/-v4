if not dogeaddrdb then
	dogeaddrdb=sql.new("dogeaddr").new("addr","addr","name")
end
local addr=dogeaddrdb
local o={}
for row in addr.pselect() do
	o[row.name]=row.addr
end
local on={}
for k,v in pairs(o) do
	on[#on+1]=v
end
if (cl.urldata or {}).json then
	res.type="text/plain"
	print(json.encode(o))
elseif (cl.urldata or {}).json2 then
	res.type="text/plain"
	print(json.encode(on))
elseif (cl.urldata or {}).lua then
	res.type="text/plain"
	print(serialize(o))
elseif (cl.urldata or {}).lua2 then
	res.type="text/plain"
	print(serialize(on))
else
	print('Other formats: <a href="dogecoin.lua?json=1">json</a> <a href="dogecoin.lua?json2=1">json2</a> <a href="dogecoin.lua?lua=1">lua</a> <a href="dogecoin.lua?lua2=1">lua2</a><br><br>Insert address:')
	local param=cl.postdata or {}
	if param.addr and param.pass and param.name then
		if param.pass~="TheDoctorisaPotatoWalrus" and param.pass~="total1tyashibe" then
			print("Invalid password!<br>")
		elseif param.addr:sub(1,1)~="D" or #param.addr~=34 then
			print("Invalid address!<br>")
		else
			if addr.select({addr=param.addr}) or addr.select({name=param.name}) then
				print("Address/name already used!<br>")
			else
				addr.insert({addr=param.addr,name=param.name})
				print("Inserted into database!<br>")
			end
		end
	end
	print([[
	<form method="post" action="dogecoin.lua"><table>
		<tr><td>Name: </td><td><input type="text" name="name" value="]]..htmlencode(param.name or "")..[["/></td></tr>
		<tr><td>Address: </td><td><input type="text" name="addr" value="]]..htmlencode(param.addr or "")..[["/></td></tr>
		<tr><td>Password: </td><td><input type="password" name="pass" value="]]..htmlencode(param.pass or "")..[["/></td></tr>
		<tr><td><input type="submit" value="Submit"></td></tr>
	</form></table><br>
	<table>]])
	print("Total: "..(#on).."<br><br>")
	for k,v in pairs(o) do
		print("<tr><td>"..k.."</td><td>"..v.."</td></tr>")
	end
	print("</table>")
end
