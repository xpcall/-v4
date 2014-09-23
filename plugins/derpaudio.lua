function convle(num)
	num=tonumber(ffi.new("uint16_t",math.floor(num)))
	return string.char(math.floor(num/256))..string.char(num%256)
end
function playraw(txt,rate)
	local f=io.popen("avplay -ac 1 -ar "..rate.." -f s16be -i /dev/stdin","w")
	f:write(txt)
	f:close()
end
function play(f,rate,duration)
	local txt=""
	local char=string.char
	for l1=1,rate*duration do
		txt=txt..convle(f(l1))
	end
	playraw(txt,rate)
end