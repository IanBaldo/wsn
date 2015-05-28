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


msg_reset = {
	id		= 3,
	source	= 0,
	target	= 1,
	d8		= {0, 0, 0, 0},
	d16		= {20, 0, 0, 0},
	d32		= {0, 0}
	}

mote:send(msg_reset,145,1)
print("Message Sent!")

	mote:unregister()
	mote:close() 


