local tossam = require("tossam")
local sig = require("posix.signal")
--[[
	old green: #98bf21
	new blue: #20A9EB
	dark blue: #000033
]]
-- Data Table
data = {}

period = 30 -- 300s = 5 minutos
timeout = 20 -- em segundos
currentPeriod = math.floor(os.time()/period)

-- Log file
logfile = io.open("log.txt","w")
logfile:write("Data/Hora Log, nodeId, Salas, Sequencial, Temperatura, Data/Hora Medição\n")
logfile:close()

Tadjust={
[2]={offset=2.59461, alpha=0.68592, tp='MTS300A'},
[3]={offset=-1.34362, alpha=0.78082, tp='MTS300B'},
[4]={offset=4.61316, alpha=0.63973, tp='MTS300B'},
[5]={offset=5.18457, alpha=0.60445, tp='MTS300B'},
[6]={offset=1.82639, alpha=0.72983, tp='MTS300B'},
[7]={offset=0, alpha=0, tp='MTS300B'},
[8]={offset=4.46287, alpha=0.64626, tp='MTS300B'},
[11]={offset=3.74651, alpha=0.65442, tp='MTS300B'},
}

Tsalas = {
[2]="XXX 02",
[3]="XXX 03",
[4]="XXX 04",
[5]="XXX 05",
[6]="XXX 06",
[7]="XXX 07",
[8]="XXX 08",
[9]="XXX 09",
[10]="XXX 10",
[11]="XXX 11",
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

function geraLog()
	logfile = io.open("log.txt","a")
	local logDate = os.date("%d/%m/%y %X")
	for i=2,20 do
		if data[i] then
			logfile:write(logDate ..', '.. data[i].nodeId ..', '..  (Tsalas[data[i].nodeId] or "Não cadastrado") ..', '.. data[i].seq ..', '.. data[i].TempC ..', '.. data[i].date ..'\n')
		end
	end
	logfile:close()
end


function geraArq()
	-- DATA FILE
	file = io.open("index.html","w+")
	file:write("<html><head><meta charset='UTF-8'><meta http-equiv='refresh' content='120'><style>body{font-family: Tahoma, Geneva, sans-serif;background-color: #000033;}table, td, th {text-align: center;}table {width: 80%;max-width: 800px;}h4{text-align:center;font-size:130%;}th{background-color: #20A9EB;color: #ffffff;}td{background-color: #bdbdbd;}#logopuc{float:left;}#logodi{float:right;}#header{margin-left: auto; margin-right: auto; text-align: center; max-width: 800px; width: 80%}#htd{background-color: #ffffff;}#all{margin-left: auto; margin-right: auto; background-color: #ffffff; height: 100%; width: 80%;max-width: 900px;}</style><title> RSSF | PUC-Rio </title></head><body><div id='all'><table id='header'><tr><td id='htd'>  <div id='logopuc'> <img src='http://www.puc-rio.br/imagens/brasao.jpg' alt='PUC-Rio'>  </div> </td><td id='htd'> <div id='mtext'> <h4>PUC-Rio -- Departamento de Informática </h4><h4>   16/06/15 18:56:03</h4>  </div> </td><td id='htd'> <div id='logodi'> <img src='http://www.inf.puc-rio.br/wp-content/themes/webdi2/imgs/logo_di1.png'> </div> </td></tr></table><br/><br/><br/><table align='center'>")
	file:write("<tr><th>" .. fText("LOCAL",25).."</th><th>"..fText("TEMP(ºC)",15).."</th><th>"..fText(" DATA/HORA",17).."</th></tr>")
	for i=2,20 do
		if data[i] then
			file:write("<tr><td>" .. fText(((data[i] and Tsalas[data[i].nodeId]) or 'Mote ' .. i .. ' não cadastrado'),25).. "</td><td>" .. fText(data[i].TempC,15) .. "</td><td>" .. fText(data[i].date,17).."</td></tr>")
		end
	end
	file:write("</table></body></html>")
	file:close()
--	os.execute("./transfer")
end

function checaPeriodo()
	testPeriod = math.floor(os.time()/period)
	if testPeriod > currentPeriod then
		geraArq()
		geraLog()
		currentPeriod = testPeriod
	end
end

function handler()
	print("\nbye bye\n")	
	os.exit()
end

sig.signal(sig.SIGINT,handler)
sig.signal(sig.SIGTERM,handler)


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

		conn:settimeout(timeout)

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

			local stat, msg, emsg = pcall(function() return conn:receive() end) 
			if stat then
				if msg then
					local date = os.date("%d/%m/%y %X")
					local TempC
					if Tadjust[msg.nodeId] then
						TempC = convertDA(msg.temp,Tadjust[msg.nodeId].tp,msg.nodeId)
					else
						TempC = 500
					end
					data[msg.nodeId] = {nodeId = msg.nodeId, seq=msg.seq, TempC=string.format("%.1f", round5(TempC)), date=date}
					checaPeriodo()
					print(msg.id,msg.nodeId,msg.seq,string.format("%.1f", round5(TempC)),date)
					--file:write(msg.nodeId,"\t\t" .. string.format("%.1f", round5(TempC)),"\t\t" .. date,"\n")
				else
					if emsg == "closed" then
						print("\nConnection closed!")
						break 
					elseif emsg == "timeout" then
						checaPeriodo()
						--print(".") --print("timeout")			
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
