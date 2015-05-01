local lang={
	clay="Clay",
	ironNugget="Iron nugget",
	redstone="Redstone dust",
	paper="Paper",
	goldNugget="Gold nugget",
	cactusGreen="Cactus green",
	rawpcb="Raw PCB",
	pcb="PCB",
	transitor="Transistor",
	microchip2="T2 Microchip",
	holo1="Holo projector",
	obsidian="Obsidian",
	diamond="Diamond",
	pane="Glass pane",
	glowstone="Glowstone",
}
local craft={
	rawpcb={
		1,"clay",
		1,"goldNugget",
		1,"cactusGreen",
	},
	pcb={
		1,"rawpcb",
	},
	transistor={
		3,"ironNugget",
		2,"goldNugget",
		1,"redstone",
		1,"paper",
	},
	microchip2={
		1,"transitor",
		2,"redstone",
		4,"goldNugget",
	},
	holo1={
		2,"microchip2",
		2,"pcb",
		2,"obsidian",
		1,"diamond",
		1,"pane",
		1,"glowstone",
	},
}

local _craft
function _craft(res)
	if not craft[res] then
		return lang[res] or "Undefined"
	end
	local o={}
	for l1=1,#craft[res],2 do
		local camt=craft[res][l1]
		local cres=craft[res][l1+1]
		table.insert(o,consoleCat(camt.."x ",_craft(cres)))
	end
	local p=(lang[res] or "Undefined").." = "
	if #o>1 then
		return consoleCat(p,consoleBox(table.concat(o,"\n")))
	else
		return consoleCat(p,o[1])
	end
end

hook.new("command_craft",function(user,chan,txt)
	local o=_craft(txt)
	return (o:match("\n") and paste or limitoutput)(o)
end)
