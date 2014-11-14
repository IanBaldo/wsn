local tossam = require("tossam") 

local exit = false
while not(exit) do
--	local mote = tossam.connect("sf@localhost:9002",1)
	local mote = tossam.connect("serial@/dev/ttyACM0:micaz",1)
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


msg2 = {
	id		= 1,
	source	= 2,
	target	= 3,
	d8		= {4, 0, 0, 0},
	d16		= {5, 0, 0, 0},
	d32		= {6, 7}
	}

	print("Program [ON] OFF")

	while (mote) do
		a = io.read()
		if a == "bye" then
			break
		end
			mote:send(msg2,145,1)
			print("message sent")
	--		os.execute("sleep " .. 3);	
	end

	print("Program ON [OFF]")
	mote:unregister()
	mote:close() 
	if a == "bye" then
		break
	end
end


