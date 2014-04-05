persist={persist=function(tbl)
	local stateFile = "sbox.eris"
	local autosaveInterval = 10
	local perms, uperms = {}, {}
	do
		local processed = {}
		local function flattenAndStore(path, t)
			local keys = {}
			for k, v in pairs(t) do
				if type(k) ~= "string" and type(k) ~= "number" then
					io.stderr:write("Cannot generate permanent value for global with non-string key at " .. path .. ". Things may not go well.\n")
				else
					table.insert(keys, k)
				end
			end
			table.sort(keys)
			for _, k in ipairs(keys) do
				local name = path .. "." .. k
				local v = t[k]
				-- This avoids duplicate permanent value entries, see above.
				if perms[v] == nil then
					local vt = type(v)
					if "function" == vt or "userdata" == vt then
						perms[v] = name
						uperms[name] = v
					elseif "table" == vt and not processed[v] then
						processed[v] = true
						flattenAndStore(name, v)
					end
				end
			end
		end
		flattenAndStore("_G", _G)
	end
end
-- [[ Autosave background task ]]

local lastSave = os.time()
local function autosave()
	if os.difftime(os.time(), lastSave) > autosaveInterval then
		lastSave = os.time()
		local data, reason = eris.persist(perms, _ENV)
		if not data then
			io.stderr:write("Failed to persist environment: " .. tostring(reason) .. "\n")
		else
			local f, reason = io.open(stateFile, "wb")
			if not f then
				io.stderr:write("Failed to save environment: " .. tostring(reason) .. "\n")
			else
				f:write(data)
				f:close()
			end
		end
	end
	-- Check again later. This basically uses the garbage collector as a
	-- scheduler (this method is called when the table is collected). It
	-- is a concept I first saw posted by Roberto on the list a while
	-- back, in the context of sandboxing I think.
	setmetatable({}, {__gc=autosave})
end
autosave()

-- [[ Startup / load autosave ]]

local f = io.open(stateFile, "rb")
if f then
	-- Got a previous state, try to restore it.
	local data = f:read("*a")
	f:close()
	local env, reason = eris.unpersist(uperms, data)
	if not env then
		io.stderr:write("Failed to unpersist environment: " .. tostring(reason) .. "\n")
	else
		for k, v in pairs(env) do
			_ENV[k] = env[k]
			setmetatable(_ENV, getmetatable(env))
		end
	end
end