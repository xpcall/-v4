local chars="qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0987654321"

function pasteraw(txt,nolimit)
	local id=""
	for l1=1,5 do
		local n=math.random(1,#chars)
		id=id..chars:sub(n,n)
	end
	local file=assert(io.open("www/paste/"..id..".txt","w"))
	file:write(nolimit and txt or txt:sub(1,100000))
	file:close()
	return "http://68.36.225.16/paste/"..id..".txt"
end

function pastehtml(txt,nolimit)
	local id=""
	for l1=1,5 do
		local n=math.random(1,#chars)
		id=id..chars:sub(n,n)
	end
	local file=assert(io.open("www/paste/"..id..".html","w"))
	file:write(nolimit and txt or txt:sub(1,1000000))
	file:close()
	return "http://68.36.225.16/paste/"..id..".html"
end

function paste(txt,nolimit)
	local id=""
	for l1=1,5 do
		local n=math.random(1,#chars)
		id=id..chars:sub(n,n)
	end
	local file=assert(io.open("www/paste/"..id..".html","w"))
	file:write([[
		<html>
			<head>
				<style type="text/css">
					body {
						font-family: "Lucida Console", Monaco, monospace;
						white-space: nowrap;
					}
				</style>
				<meta charset="utf-8"/>
			</head>
			<body>
	]])
	file:write(htmlencode(nolimit and txt or txt:sub(1,1000000)))
	file:write([[
			</body>
		</html>
	]])
	file:close()
	return "http://68.36.225.16/paste/"..id..".html"
end

hook.new("command_paste",function(user,chan,txt)
	return paste(txt)
end,{
	desc="posts text to the webserver",
	group="misc",
})