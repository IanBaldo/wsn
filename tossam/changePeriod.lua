local tossam = require("tossam") 



	local mote = tossam.connect("sf@localhost:9002",1)
--	local micaz = tossam.connect("serial@/dev/ttyUSB1:micaz",1)
	if not(mote) then print("Connection error!"); return(1); end


	mote:register [[ 
	  nx_struct msg_serial [140] { 
		nx_uint16_t ReqMote;
		nx_uint16_t ReqSeq;
		nx_uint8_t	MaxHops;
		nx_uint8_t	HopNumber;

		nx_uint8_t	grId;
		nx_uint8_t	grParam;
		nx_uint16_t	TargetMote;
		nx_uint8_t	evtId;
		nx_uint8_t	d8[4];
		nx_uint16_t	d16[4];
		nx_uint32_t d32[2];
	  }; 
	]]

io.write("Digite o periodo(em segundos): ")
local period = tonumber(io.read())
io.write("seq: ")
local seq = tonumber(io.read())

msg_cp = {
	ReqMote = 1,
	ReqSeq = seq,
	MaxHops = 5,
	HopNumber = 0,

	grId = 1,
	grParam = 1,
	TargetMote = 0xFFFF,
	evtId = 2,
	d8 ={0,0,0,0},
	d16 ={period,0,0,0},
	d32 = {0,0}
	}

mote:send(msg_cp,140,1)
print("Message Sent! ; Period = " .. period .. (";  Seq = ") .. seq)

	mote:unregister()
	mote:close() 


