sql={}
local dbs=setmetatable({},{__mode="v"})
reqplugin("async.lua")
local function start(db)
	if not db.transaction then
		db.db:execute("BEGIN TRANSACTION")
		db.transaction=true
		async.new(function()
			async.wait(1)
			if db.transaction then
				db.db:execute("COMMIT")
				db.transaction=nil
			end
		end)
	end
end
function sql.cleanup()
	for k,v in pairs(dbs) do
		if not v.nocleanup then
			v.close()
		end
	end
end
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
			start(out)
			db:exec("create table if not exists "..name.." ("..table.concat({...},",")..")")
			return {
				db=db,
				parent=out,
				pselect=function(...)
					return out.pselect(name,...)
				end,
				select=function(...)
					return out.select(name,...)
				end,
				update=function(...)
					return out.update(name,...)
				end,
				insert=function(...)
					return out.insert(name,...)
				end,
				delete=function(...)
					return out.delete(name,...)
				end,
			}
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
			start(out)
			local sn=db:prepare("select "..table.concat(vals,",").." from "..name..(where and " where " or "")..table.concat(w," and "))
			if not sn then
				error(db:errmsg())
			end
			if where then
				sn:bind_names(where)
				sn:step()
				sn:reset()
			end
			return sn:nrows()
		end,
		select=function(name,where,vals)
			for row in out.pselect(name,where,vals) do
				return row
			end
		end,
		update=function(name,where,vals)
			local bind={}
			local w={}
			if where then
				for k,v in pairs(where) do
					table.insert(w,k.."==:w"..k)
					bind["w"..k]=v
				end
			end
			local vl={}
			for k,v in pairs(vals) do
				table.insert(vl,k.."=:u"..k)
				bind["u"..k]=v
			end
			start(out)
			local sn=db:prepare("update "..name.." set "..table.concat(vl," ")..(where and " where " or "")..table.concat(w," and "))
			if not sn then
				error(db:errmsg().." statement: "..serialize("update "..name.." set "..table.concat(vl," ")..(where and " where " or "")..table.concat(w," and ")))
			end
			sn:bind_names(bind)
			sn:step()
			sn:finalize()
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
			start(out)
			local sn=db:prepare("insert into "..name.." ("..table.concat(keys,",")..") values ("..table.concat(vl,",")..")")
			if not sn then
				error(db:errmsg())
			end
			sn:bind_names(vals)
			sn:step()
			sn:finalize()
		end,
		delete=function(name,where)
			if not where then
				db:exec("delete from "..name)
			else
				local bind={}
				local w={}
				for k,v in pairs(where) do
					table.insert(w,k.."==:"..k)
					bind["w"..k]=v
				end
				start(out)
				local sn=db:prepare("delete from "..name.." where "..table.concat(w," and "))
				if not sn then
					error(db:errmsg())
				end
				sn:bind_names(where)
				sn:step()
				sn:finalize()
			end
		end,
		close=function()
			dbs[dir]=nil
			if out.transaction then
				db:execute("COMMIT")
				out.transaction=nil
			end
			db:close()
		end,
	},{__gc=function()
		out.close()
	end})
	if dir then
		dbs[dir]=out
	end
	return out
end
