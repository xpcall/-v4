luann=require("luann")
nn={}
local snn={
	input=function(snn,input)
		snn.n:activate(input)
		local out={}
		for l1=1,snn.ots do
			table.insert(out,math.round(snn.n[3].cells[l1].signal,3))
		end
		return unpack(out)
	end,
	train=function(snn,input,output)
		snn.n:bp(input,output)
	end,
}
function nn.new(ins,hdn,ots,lr,tr)
	local o={ins=ins,hdn=hdn,ots=ots,lr=lr,tr=tr}
	for k,v in pairs(snn) do
		o[k]=v
	end
	o.n=luann:new({ins,hdn,ots},lr,tr)
	return o
end