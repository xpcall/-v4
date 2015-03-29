local worth={
	cow=24000000,
	void=-50000,
	loan=-500000000,
	moo=1000000,
	moo2=500000000,
}

local special={
	["Your cows moo and (%d+) baby cows are born"]=function(cows)
		return tonumber(cows)*worth.cow
	end,
	["Your cows moo and 1 baby cow is born"]=function()
		return worth.cow
	end,
}

hook.new("msg",function(user,chan,txt)
	if (user.account=="jacobot" and user.nick=="Crackbot") or (user.account=="^v" and txt:match("^>")) then
		local ch=txt:match("%(%+(%-?$%d+)%)")
		local t
		if ch then
			ch=ch:gsub("%$","")
			t=tonumber(ch)
		else
			t=0
		end
		for n,o in txt:gmatch("%(%+?(%-?%d+) (%S-)s?%)") do
			t=t+(tonumber(n)*(worth[o] or 0))
		end
		for k,v in pairs(special) do
			local p={txt:match(k)}
			if p[1] then
				t=t+v(unpack(p))
			end
		end
		if t~=0 then
			return true,"$"..fancynum(t)
		end
	end
end)

function profitability(cowCount)
	local tc=0
	local o={}
	function logw(n,nm)
		tc=tc+n
		o[nm]=(o[nm] or 0)+n
	end
	function addCow(n)
		logw(n*24000000,"cow")
	end
	function addMoo(n)
		logw(n*1000000,"moo")
	end
	function addMoo2(n)
		logw(n*500000000,"moo2")
	end
	function addLoan(n)
		logw(n*-500000000,"loan")
	end
	function addVoid(n)
		logw(n*-50000,"void")
	end
	for rnd=1,100 do
		if rnd%5==1 and cowCount>2 then
			local amountgained=math.ceil(cowCount/24)
			addMoo(amountgained)
		elseif cowCount>10 and rnd%5==2 then
			local amountLost=math.ceil(cowCount*0.5/2)
			addCow(-amountLost)
		elseif cowCount>20 and rnd%5==3 then
			addLoan(0.1)
			local amountLost=math.ceil(rnd/5)
			local amountgained=(5*4+1)*25000000
			logw(amountgained*0.9,"cash")
			addCow(-amountLost*0.9)
		elseif rnd<=15 then
			addCow(-1)
		elseif rnd<=25 then
			addCow(1)
		elseif rnd<=30 then
			addCow(cowCount)
		elseif rnd<=50 then
			local voids=(45*cowCount)/2
			addVoid(voids)
		elseif rnd<=85 then
			addMoo(cowCount)
		elseif rnd<=88 then
			local amountLost=math.ceil(cowCount*0.5)
			addCow(-amountLost)
			addMoo2(1)
		end
	end
	return tc/100
end