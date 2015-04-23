rpg.regItems({
	millisecond={
		plural="milliseconds",
		color=6,
	},
	nanoseconds={
		plural="nanoseconds",
		color=6,
	},
})
local begCooldown=3600
hook.new("rpg_beg",function(dat,user,chan,txt)
	if not dat.lastBeg then dat.lastBeg=0 end
	local timeLeft=begCooldown-(socket.gettime()-dat.lastBeg)
	if socket.gettime(timeLeft)-dat.lastBeg<begCooldown then
		if timeLeft<0.0001 then
			return "You must wait "..toTime(timeLeft).." before begging again "..rpg.addItem(dat,"nanosecond",1000-math.floor(timeLeft*1000000))
		elseif timeLeft<1 then
			return "You must wait "..toTime(timeLeft).." before begging again "..rpg.addItem(dat,"millisecond",1000-math.floor(timeLeft*1000))
		end
		return "You must wait "..toTime(timeLeft).." before begging again"
	end
	dat.lastBeg=socket.gettime()
	return "You get some change "..rpg.addItem(dat,"gold",math.random(1,100))
end)