ocsql={}
function ocsql.new(file)
	local rd
	local wr
	local function sread()
		if wr then
			pcall(wr.close,wr)
			wr=nil
			rd=io.open(file,"rb")
		end
	end
	local function swrite()
		if rd then
			pcall(rd.close,rd)
			rd=nil
			wr=io.open(file,"ab")
		end
	end
	local function rlines()
		local buff=""
		local c=0
		sread()
		local m=rd:seek("end")
		return function()
			local out=""
			while out=="" do
				if c==-m then
					print("break")
					break
				end
				while not buff:match("\n") do
					sread()
					c=math.max(c-100,-m)
					print("c: "..c)
					assert(rd:seek("end",c))
					local b=rd:read(100) or "nil"
					buff=b..buff
				end
				buff,out=buff:match("^(.-)\n?(.*)$")
			end
			if out~="" then
				return out:match("(.*)=(.*)")
			end
		end
	end
	wr=io.open(file,"ab")
	local out
	out={
		get=function(name)
			for k,v in rlines() do
				if k==name then
					return unserialize(v)
				end
			end
		end,
		set=function(name,val)
			swrite()
			wr:write(name.."="..serialize(val).."\n")
		end,
		flush=function()
			swrite()
			wr:flush()
		end,
		clean=function(name,val)
			local file=io.open(file..".tmp","wb")
			local u={}
			for k,v in rlines() do
				if not u[k] then
					if v~="nil" then
						file:write(k.."="..v.."\n")
					end
					u[k]=true
				end
			end
			fs.delete(file)
			fs.move(file..".tmp",file)
		end,
	}
	return out
end