local crypt={}
testcrypt=crypt
function encodeKey(key,priv)
	key=tob64(key)
	local o="-----BEGIN RSA "..(priv and "PRIVATE" or "PUBLIC").." KEY-----\n"
	while #key>1 do
		o=o..key:sub(1,64).."\n"
		key=key:sub(65)
	end
	return o.."-----END RSA "..(priv and "PRIVATE" or "PUBLIC").." KEY-----\n"
end
function crypt.newKey(key,priv)
	if key then
		if type(key)=="string" then
			key=assert(crypto.pkey.from_pem(encodeKey(key,priv),priv))
		end
	else
		key=crypto.pkey.generate("rsa",2048)
	end
	return {
		key=key,
		encrypt=function(txt)
			return crypto.encrypt("rsa",txt,key)
		end,
		decrypt=function(txt)
			return crypto.decrypt("rsa",txt,key)
		end,
		tostring=function(priv)
			return unb64(key:to_pem(priv):match("%-\n(.-)\n%-"):gsub("%s",""))
		end
	}
end
local network={}
networktest=network
function networktest.newNode()
	
end