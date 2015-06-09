local tossam = require("tossam")
local sig = require("posix.signal")

-- Data Table
data = {}

period = 10
currentPeriod = math.floor(os.time()/period)

Tadjust={
[2]={offset=2.59461, alpha=0.68592, tp='MTS300A'},
[3]={offset=-1.34362, alpha=0.78082, tp='MTS300B'},
[4]={offset=4.61316, alpha=0.63973, tp='MTS300B'},
[5]={offset=5.18457, alpha=0.60445, tp='MTS300B'},
[6]={offset=1.82639, alpha=0.72983, tp='MTS300B'},
[8]={offset=4.46287, alpha=0.64626, tp='MTS300B'},
[11]={offset=3.74651, alpha=0.65442, tp='MTS300B'},
}

Tsalas = {
[2]="Sala X02",
[3]="Sala X03",
[4]="Sala X04",
[5]="Sala X05",
[6]="Sala X06",
[7]="Sala X07",
[8]="Sala X08",
[9]="Sala X09",
[10]="Sala X10",
[11]="Sala 504",
}

function convertDA(ADC,tipo,mote)
	local Temp = 0
	if tipo == "MDA" then
		a = 0.001010024
		b = 0.000242127
		c = 0.000000146
		R1 = 10000
		ADC_FS = 1023
		Rthr = (R1 * (ADC_FS - ADC)) / ADC
		Temp = (1 / (a + (b * math.log(Rthr)) + (c * math.pow(math.log(Rthr),3.0)))) - 272.15
	else
		a = 0.00130705
		b = 0.000214381
		c = 0.0000000093
		R1 = 10000
		ADC_FS = 1023
		Rthr = (R1 * (ADC_FS - ADC)) / ADC
		Temp = (1 / (a + (b * math.log(Rthr)) + (c * math.pow(math.log(Rthr),3.0)))) - 272.15
	end	
	return Tadjust[mote].offset + (Temp * Tadjust[mote].alpha)
end

function round5(num)
	num = num + 0.25
	fnum = math.floor(num)
	if (num - fnum) >= 0.5 then
		return fnum + 0.5
	else
		return fnum
	end
end

function fText(str,tam)
	tmp = str .. string.rep(" ",tam)
	return string.sub(tmp,1,tam)
end

--[[
function geraArq()
	-- DATA FILE
	file = io.open("data.txt","w+")
	file:write("\nPUC-Rio -- Departamento de Informática \t" .. os.date("%x %X") .. "\n\n")
	file:write("============  Monitoramento de temperatura  =============\n\n") 
	file:write(fText("Local",25)..fText("Temp(ºC)",15)..fText(" Data/Hora",17).."\n")
	for i=2,20 do
		if data[i] then
			file:write(fText(Tsalas[data[i].nodeId],25) .. fText(data[i].TempC,15) .. fText(data[i].date,17).."\n")
		end
	end
	file:write("\n=========================================================\n\n")
	file:close()
	os.execute("./transfer")
end
]]

function geraArq()
	-- DATA FILE
	file = io.open("index.html","w+")
	file:write("<html><head><meta http-equiv='refresh' content='10'><style>table, td, th {border:1px solid #98bf21;text-align: center;}table {width: 80%;max-width: 800px;}h4{text-align: center;}th{background-color: #A7C942;color: #ffffff;}</style><title> RSSF | PUC-Rio </title></head><body><h4>PUC-Rio -- Departamento de Informática  |  ".. os.date("%d/%m/%y %X") .."</h4><table align='center'>")
	file:write("<tr><th>" .. fText("Local",25).."</th><th>"..fText("Temp(ºC)",15).."</th><th>"..fText(" Data/Hora",17).."</th></tr>")
	for i=2,20 do
		if data[i] then
			file:write("<tr><td>" .. fText(Tsalas[data[i].nodeId],25).. "</td><td>" .. fText(data[i].TempC,15) .. "</td><td>" .. fText(data[i].date,17).."</td></tr>")
		end
	end
	file:write("</table><br/><p alig='center'>Developed by: Ian Baldo</p></body></html>")
	file:close()
	os.execute("./transfer")
end

function checaPeriodo()
	testPeriod = math.floor(os.time()/period)
	if testPeriod > currentPeriod then
		geraArq()
		currentPeriod = testPeriod
	end
end

function handler()
	geraArq()
	print("\nbye bye\n")	
	os.exit()
end

while (1) do	
	
	local conn = tossam.connect {
	  protocol = "sf",
	  host     = "localhost",
	  port     = 9002,
	  nodeid   = 1
	}

	if not(conn) then 
		print("Connection error!") 
	else

	
		conn:register [[ 
		  nx_struct msg_serial [150] { 
			nx_uint16_t	nodeId;
			nx_uint16_t seq_CTP;
			nx_uint8_t  id;
			nx_uint8_t	seq;
			nx_uint8_t  xxx[3];
			nx_uint16_t	temp;
			nx_uint16_t yyy[3];
		  }; 
		]]

		print("msgID","nodeID","seq","temp","date")
	--	file:write("nodeID\ttemp\t\tdate\n")
		while (conn) do
			sig.signal(sig.SIGINT,handler)
			sig.signal(sig.SIGTERM,handler)

			local stat, msg, emsg = pcall(function() return conn:receive() end) 
			if stat then
				if msg then
					checaPeriodo()
					local date = os.date("%d/%m/%y %X")
					local TempC = convertDA(msg.temp,Tadjust[msg.nodeId].tp,msg.nodeId)
					data[msg.nodeId] = {nodeId = msg.nodeId, seq=msg.seq, TempC=string.format("%.1f", round5(TempC)), date=date}
					print(msg.id,msg.nodeId,msg.seq,string.format("%.1f", round5(TempC)),date)
					--file:write(msg.nodeId,"\t\t" .. string.format("%.1f", round5(TempC)),"\t\t" .. date,"\n")
				else
					if emsg == "closed" then
						print("\nConnection closed!")
						break 
					end
				end
			else
				print("\nreceive() got an error:"..msg)
				exit = true
				break
			end
		end
		
		conn:unregister()
		conn:close()
	end
	
	os.execute("sleep " .. 5)
end
