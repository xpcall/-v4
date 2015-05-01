local function min(...)
	local a={...}
	table.sort(a)
	return a[1]
end

function bfgen()
	local o={}
	for x=0,255 do
		o[x]={}
		for n=0,255 do
			local out
			if x>0 then
				for d=1,40 do
					local j=x
					local y=0
					for i=0,255 do
						if j==0 then
							break
						end
						j=(j-d+256)%256
						y=(y+n)%256
					end
					if j==0 then
						out=min("["..("-"):rep(d)..">"..("+"):rep(n).."<]>",out)
					end
					j=x
					y=0
					for i=0,255 do
						if j==0 then
							break
						end
						j=(j+d)%256
						y=(y-n+256)%256
					end
					if j==0 then
						out=min("["..("+"):rep(d)..">"..("-"):rep(n).."<]>",out)
					end
				end
			end
			o[x][n]=out or min(
				(n>x and "+" or "-"):rep(math.abs(n-x)),
				(n>x and "-" or "+"):rep(255-math.abs(n-x)),
				out
			)
		end
	end
	local file=io.open("db/bfencode","w")
	return o
end

local function bfload(a,b)
	
end

function bfencode(txt)
	local cr=0
	
end