local ftxt="www/4540D/awards.txt"
local fbplain="www/4540D/bannerplain.png"
local fbout="www/4540D/banner.png"
function updatebanner()
	local fl=io.open(ftxt,"r")
	local otxt=""
	for l1=1,7 do
		local line=fl:read("*l")
		if not line then
			break
		end
		otxt=otxt..line.."\n"
	end
	local banner=img.load(fbplain)
	banner.text(440,80,otxt,"Courier",10,"bold",{255,255,255,200})
	banner.save(fbout)
end
hook.new("command_addaward",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	file[ftxt]=txt.."\n"..(file[ftxt] or "")
	updatebanner()
	return "added"
end)
