local out=io.popen("timelimit -t 1 bc -l -q sbox.tmp"):read("*a"):gsub("\\\n","")--:gsub("(%.%d-)0+\n$","%1\n"):gsub("%.?%s-$","")
print(out)
print("Program done.")

