local tossam = require("tossam") 

--[[
	local conn = tossam.connect {
	  protocol = "sf",
	  host     = "localhost",
	  port     = 9002,
	  nodeid   = 0xFFFF
	} ]]

--[[
	local conn = tossam.connect {
	  protocol = "serial",
	  port     = "/dev/ttyUSB1",
	  baud     = "micaz",
	  nodeid   = 0xFFFF
	} ]]

	local conn = tossam.connect {
	  protocol = "network",
	  host     = "localhost",
	  port     = 9001,
	  nodeid   = 1
	}

	if not(conn) then print("Connection error!"); return(1); end


	conn:register [[ 
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

local stat,err = conn:send(msg_cp,140)
print("send:",stat,err)
print("Message Sent! ; Period = " .. period .. (";  Seq = ") .. seq)

	conn:unregister()
	conn:close() 


