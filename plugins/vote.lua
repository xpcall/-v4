
hook.new("command_newvote",function(user,chan,txt)
	if not user.voice and not user.op then
		return "You must be voiced to make a new vote"
	elseif cvote then
		return "A vote is already started, use .endvote"
	elseif txt=="" then
		return "Usage: .newvote <option>,<option>[,...]"
	end
	local opt={}
	local cur={}
	for t in txt:gmatch("[^,]+") do
		t=t:gsub("^%s+",""):gsub("%s+$","")
		if cur[t] then
			return "Duplicate votes not allowed."
		end
		table.insert(opt,t)
		cur[t:lower()]=0
	end
	cvote={
		voted={},
		opt=opt,
		cur=cur,
		t=0
	}
	return "Vote started! end with .endvote"
end,{
	desc="creates a new vote",
	group="fun",
})

hook.new("command_vote",function(user,chan,txt)
	if not cvote then
		return "No vote started, use .newvote"
	end
	txt=txt:lower()
	local cu=user.account or user.host
	if cvote.voted[cu] then
		return "You already voted!"
	elseif not cvote.cur[txt] then
		return "No such vote, valid ones are: "..table.concat(cvote.opt,", ")
	end
	cvote.voted[cu]=true
	cvote.cur[txt]=cvote.cur[txt]+1
	cvote.t=cvote.t+1
	return "Voted"
end,{
	desc="",
	group="fun",
})

hook.new("command_endvote",function(user,chan,txt)
	if not user.voice and not user.op then
		return "You must be voiced to end a vote"
	end
	local t=cvote.t
	local cur=cvote.cur
	cvote=nil
	local o="Vote results:"
	for k,v in pairs(cur) do
		o=o.." "..k..": "..tostring(v)
	end
	return o
end,{
	desc="",
	group="fun",
})
