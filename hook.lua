hook={}
local hooks={}
function hook.queue(name,...)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		for k,v in tpairs(hooks[nme] or {}) do
			if v(...)==false then
				hook.del(v)
			end
		end
	end
end
function hook.new(name,func)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		hooks[nme]=hooks[nme] or {}
		table.insert(hooks[nme],func)
	end
	return func
end
function hook.del(name)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		if type(name)=="function" then
			for k,v in pairs(hooks) do
				for n,l in pairs(v) do
					if l==name then
						hooks[k][n]=nil
					end
				end
			end
		else
			hooks[name]=nil
		end
	end
end