local tossam = require("tossam") 

-- DATA FILE
file = io.open("data.txt","w+")

Tadjust={
[2]={offset=2.59461, alpha=0.68592, tp='MTS300A'},
[3]={offset=-1.34362, alpha=0.78082, tp='MTS300B'},
[4]={offset=4.61316, alpha=0.63973, tp='MTS300B'},
[5]={offset=5.18457, alpha=0.60445, tp='MTS300B'},
[6]={offset=1.82639, alpha=0.72983, tp='MTS300B'},
[8]={offset=4.46287, alpha=0.64626, tp='MTS300B'},
[11]={offset=3.74651, alpha=0.65442, tp='MTS300B'},
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
		file:write("nodeID\ttemp\tdate\n")
		while (mote) do

			local stat, msg, emsg = pcall(function() return mote:receive() end) 
			if stat then
				if msg then
					local date = os.date("%x %X")
					local TempC = convertDA(msg.temp,Tadjust[msg.nodeId].tp,msg.nodeId)
					print(msg.id,msg.nodeId,msg.seq,string.format("%.1f", round5(TempC)),date)
					file:write(msg.nodeId,"\t\t" .. string.format("%.1f", round5(TempC)),"\t\t" .. date,"\n")
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
		file:close()
	end
	
	os.execute("sleep " .. 5)
end
