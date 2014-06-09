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
local prgdir="/home/nadine/openprograms.github.io/"
hook.new("command_openprg",function(user,chan,txt)
	local out=""
	out=out..io.popen("git --git-dir="..prgdir..".git --work-tree="..prgdir.." pull"):read("*a").."\n"
	out=out..io.popen("lua "..prgdir.."generate.lua "..prgdir):read("*a").."\n"
	out=out..io.popen("git --git-dir="..prgdir..".git --work-tree="..prgdir.." add index.html"):read("*a").."\n"
	out=out..io.popen("git --git-dir="..prgdir..".git --work-tree="..prgdir.." add style.css"):read("*a").."\n"
	out=out..io.popen("git --git-dir="..prgdir..".git --work-tree="..prgdir.." commit -m \"Auto compile\""):read("*a").."\n"
	out=out..io.popen("git --git-dir="..prgdir..".git --work-tree="..prgdir.." push"):read("*a")
	return paste(out)
end,{
	desc="compiles and pushes openprograms site",
	group="help",
})
