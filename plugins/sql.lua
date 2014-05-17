sql={}
local dbs=setmetatable({},{__mode="v"})
function sql.new(dir)
	local db
	if not dir then
		db=sqlite.open_memory()
	else
		db=sqlite.open("db/"..dir..".db")
	end
	local out
	out=setmetatable({
		db=db,
		new=function(name,...)
			return db:exec("create table if not exists "..name.." ("..table.concat({...},",")..")")
		end,
		pselect=function(name,where,vals)
			if not vals then
				vals={"*"}
			end
			local w={}
			if where then
				for k,v in pairs(where) do
					table.insert(w,k.."==:"..k)
				end
			end
			local sn=db:prepare("select "..table.concat(vals,",").." from "..name..(where and " where " or "")..table.concat(w," and "))
			if where then
				sn:bind_names(where)
				sn:step()
				sn:reset()
			end
			return sn:nrows()
		end,
		select=function(name,vals,where)
			for row in out.pselect(name,vals,where) do
				return row
			end
		end,
		update=function(name,where,vals)
			local w={}
			if where then
				for k,v in tpairs(where) do
					table.insert(w,k.."==:w"..k)
					where["w"..k]=v
					where[k]=nil
				end
			end
			local vl={}
			for k,v in tpairs(vals) do
				table.insert(vl,k.."=:u"..k)
				vals["u"..k]=v
				vals[k]=nil
			end
			local sta="update "..name.." set "..table.concat(vl," ")..(where and " where " or "")..table.concat(w," and ")
			local sn=db:prepare(sta)
			if not sn then
				return "ERROR "..sta
			end
			if where then
				sn:bind_names(where)
			end
			sn:bind_names(vals)
			sn:step()
			sn:finalize()
			return sta,serialize(where),serialize(vals)
		end,
		insert=function(name,vals)
			local keys={}
			for k,v in pairs(vals) do
				table.insert(keys,k)
			end
			local vl={}
			for l1=1,#keys do
				vl[l1]=":"..keys[l1]
			end
			print("executing ".."insert into "..name.." ("..table.concat(keys,",")..") values ("..table.concat(vl,",")..")")
			local sn=assert(db:prepare("insert into "..name.." ("..table.concat(keys,",")..") values ("..table.concat(vl,",")..")"))
			print("where "..serialize(vals))
			sn:bind_names(vals)
			sn:step()
			sn:finalize()
		end,
	},{__gc=function()
		dbs[dir]=nil
		db:close()
	end})
	if dir then
		dbs[dir]=out
	end
	return out
end
