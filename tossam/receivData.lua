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
[2]="Sala 502",
[3]="Sala 503",
[4]="Sala 504",
[5]="Sala 505",
[6]="Sala 506",
[7]="Sala 507",
[8]="Sala 508",
[9]="Sala 509",
[10]="Sala 510",
[11]="Sala 511",
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

	local mote = tossam.connect("sf@localhost:9002",1)
--	local micaz = tossam.connect("serial@/dev/ttyUSB1:micaz",1)
	if not(mote) then 
		print("Connection error!") 
	else

	
		mote:register [[ 
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
		while (mote) do
			sig.signal(sig.SIGINT,handler)
			sig.signal(sig.SIGTERM,handler)

			local stat, msg, emsg = pcall(function() return mote:receive() end) 
			if stat then
				if msg then
					checaPeriodo()
					local date = os.date("%x %X")
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
		
		mote:unregister()
		mote:close()
	end
	
	os.execute("sleep " .. 5)
end
