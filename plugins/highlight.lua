highlight={}
local tokens={
	structure={"and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"},
	global={},
}
local colors={
	bg={41,49,52},
	select={64,78,81},
	selectbg={47,57,60},
	linenum={129,150,154},
	linenumbg={63,75,78},
	default={224,226,228},
	comment={102,116,123},
	longstring={194,195,86},
	number={255,205,34},
	string={236,118,0},
	structure={147,199,99},
	global={103,140,177},
}
for k,v in tpairs(colors) do
	colors[k]=string.format("#%02X%02X%02X",unpack(v))
end
local css=[[
body {
	background-color: ]]..(colors.bg)..[[;
	color: ]]..(colors.default)..[[;
	font-family: "Lucida Console", Monaco, monospace;
	font-size: 15px;
	margin: 0;
	white-space: nowrap;
}
div {
	display: inline;
}
.linenum {
	background-color: ]]..(colors.linenumbg)..[[;
	color: ]]..(colors.linenum)..[[;
	float: left;
	text-align: right;
	padding-top: 0px;
	padding-bottom: 0px;
	padding-left: 8px;
	padding-right: 8px;
	display: block;
	min-height: 100%;
	-webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
}
.comment {
	color: ]]..(colors.comment)..[[;
}
.longstring {
	color: ]]..(colors.longstring)..[[;
}
.number {
	color: ]]..(colors.number)..[[;
}
.string {
	color: ]]..(colors.string)..[[;
}
.structure {
	color: ]]..(colors.structure)..[[;
}
.global {
	color: ]]..(colors.global)..[[;
}
]]
highlight.lua=function(txt)
	local o='<html><head><style type="text/css">'..css:gsub("[\t\r\n]+"," ")..'</style></head><body>'
	o=o..'<div class="linenum">'
	for l1=1,#txt:tmatch("\n")+1 do
		o=o..l1.."<br>"
	end
	o=o.."</div>"
	local function readUntil(v)
		local out
		out,txt=txt:match("^(.-)("..v..".*)$")
		return out
	end
	while #txt>0 do
		local u=true
		local to,otxt=txt:match("^(%s*)(.-)$")
		o=o..htmlencode(to)
		txt=otxt
		if txt:sub(1,1)=='"' then
			to=to..txt:sub(1,1)
			txt=txt:sub(2)
			repeat
				if txt:sub(1,1)=="\\" then
					to=to..txt:sub(1,1)
					txt=txt:sub(2)
				end
				to=to..txt:sub(1,1)
				txt=txt:sub(2)
			until to:sub(-1,-1)=='"' or to:sub(-1,-1)=='\n' or #txt<1
			o=o..'<div class="string">'..htmlencode(to).."</div>"
			u=false
		elseif txt:sub(1,1)=="'" then
			to=to..txt:sub(1,1)
			txt=txt:sub(2)
			repeat
				if txt:sub(1,1)=="\\" then
					to=to..txt:sub(1,1)
					txt=txt:sub(2)
				end
				to=to..txt:sub(1,1)
				txt=txt:sub(2)
			until to:sub(-1,-1)=="'" or #txt<1
			o=o..'<div class="string">'..htmlencode(to).."</div>"
			u=false
		elseif txt:sub(1,2)=="--" and not txt:match("^%-%-%[=*%[.-$") then
			local cm,otxt=txt:match("^(%-%-[^\r\n]*)(.-)$")
			txt=otxt
			o=o..'<div class="comment">'..htmlencode(cm).."</div>"
			u=false
		end
		local cm,otxt=txt:match("^(%-%-%[=*%[)(.-)$")
		if cm then
			txt=otxt
			local ec,otxt=txt:match("^(.-%]"..("="):rep(#cm-4).."%])(.-)$")
			if ec then
				o=o..'<div class="comment">'..htmlencode(cm..ec).."</div>"
				txt=otxt
				u=false
			else
				o=o..htmlencode(txt)
				u=false
				break
			end
		end
		local op,otxt=txt:match("^(%a[%a%d]*)(.-)$")
		if op then
			local su=true
			for k,v in pairs(tokens.structure) do
				if op==v then
					o=o..'<div class="structure">'..htmlencode(op).."</div>"
					u=false
					su=false
					break
				end
			end
			if su then
				o=o..htmlencode(op)
			end
			txt=otxt
		end
		local num,otxt=txt:match("^(0x%x+)(.-)$")
		if num then
			txt=otxt
			o=o..'<div class="number">'..htmlencode(num).."</div>"
			u=false
		end
		local num,otxt=txt:match("^(%d+)(.-)$")
		if num then
			txt=otxt
			o=o..'<div class="number">'..htmlencode(num).."</div>"
			u=false
		end
		if u then
			o=o..htmlencode(txt:sub(1,1))
			txt=txt:sub(2)
		end
	end
	return o..'</body></html>'
end
