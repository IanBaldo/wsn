local tossam = require("tossam") 



	local mote = tossam.connect("sf@localhost:9002",1)
--	local micaz = tossam.connect("serial@/dev/ttyUSB1:micaz",1)
	if not(mote) then print("Connection error!"); return(1); end


	mote:register [[ 
	  nx_struct msg_serial [145] { 
		nx_uint8_t id;
		nx_uint16_t source;
		nx_uint16_t target;	
		nx_uint8_t  d8[4]; 
		nx_uint16_t d16[4];
		nx_uint32_t d32[2];
	  }; 
	]]

local i = 0
while (1) do
	local msg, err = mote:receive()
	if msg ~= nil then
		local msgId = msg.id
		local source = msg.source
		local target = msg.target
		local seq = msg.d8[1]
		local temp = msg.d16[1]
		local nodeId = msg.d16[2]
		local date = os.date("%x %X")
		if target == 65535 then
			target = "BCAST"
		end
		if msgId == 2 then
			i = 0
		end
		if seq > i then
			print("msgID","source","target","seq","temp","nodeID")
			i = seq
		end
		print(msgId,source,target,seq,temp,nodeId)
	end
end
