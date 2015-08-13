local tossam = require("tossam") 
local sig = require("posix.signal")

timeout = 1

function handler()
	print("\nbye bye\n")	
	os.exit()
end

sig.signal(sig.SIGINT,handler)
sig.signal(sig.SIGTERM,handler)

function createFile()
	file = io.open("foo.html","w")
	file:write([===[
<style type="text/css" media="screen">
		* {margin: 0; padding: 0; }

		.tree ul {
			padding-top: 20px; position: relative;
	
			-webkit-transition: all 0.5s;
			-moz-transition: all 0.5s;
			transition: all 0.5s;
		}

		.tree li {
			float: left; text-align: center;
			list-style-type: none;
			position: relative;
			padding: 20px 5px 0 5px;
	
			-webkit-transition: all 0.5s;
			-moz-transition: all 0.5s;
			transition: all 0.5s;
		}

		/*We will use ::before and ::after to draw the connectors*/

		.tree li::before, .tree li::after{
			content: '';
			position: absolute; top: 0; right: 50%;
			border-top: 1px solid #ccc;
			width: 50%; height: 45px;
			z-index: -1;
		}
		.tree li::after{
			right: auto; left: 50%;
			border-left: 1px solid #ccc;
		}

		/*We need to remove left-right connectors from elements without 
		any siblings*/
		.tree li:only-child::after, .tree li:only-child::before {
			display: none;
		}

		/*Remove space from the top of single children*/
		.tree li:only-child{ padding-top: 0;}

		/*Remove left connector from first child and 
		right connector from last child*/
		.tree li:first-child::before, .tree li:last-child::after{
			border: 0 none;
		}
		/*Adding back the vertical connector to the last nodes*/
		.tree li:last-child::before{
			border-right: 1px solid #ccc;
			border-radius: 0 5px 0 0;
			
			-webkit-transform: translateX(1px);
			-moz-transform: translateX(1px);
			transform: translateX(1px);
			
			-webkit-border-radius: 0 5px 0 0;
			-moz-border-radius: 0 5px 0 0;
			border-radius: 0 5px 0 0;
		}
		.tree li:first-child::after{
			border-radius: 5px 0 0 0;
			-webkit-border-radius: 5px 0 0 0;
			-moz-border-radius: 5px 0 0 0;
		}

		/*Time to add downward connectors from parents*/
		.tree ul ul::before{
			content: '';
			position: absolute; top: -12px; left: 50%;
			border-left: 1px solid #ccc;
			width: 0; height: 32px;
			z-index: -1;
		}

		.tree li a{
			border: 1px solid #ccc;
			padding: 5px 10px;
			text-decoration: none;
			color: #666;
			font-family: arial, verdana, tahoma;
			font-size: 12px;
			display: inline-block;
			background: white;
	
			-webkit-border-radius: 5px;
			-moz-border-radius: 5px;
			border-radius: 5px;
	
			-webkit-transition: all 0.5s;
			-moz-transition: all 0.5s;
			transition: all 0.5s;
		}
		.tree li a+a {
			margin-left: 20px;
			position: relative;
		}
		.tree li a+a::before {
			content: '';
			position: absolute;
			border-top: 1px solid #ccc;
			top: 50%; left: -21px; 
			width: 20px;
		}

		/*Time for some hover effects*/
		/*We will apply the hover effect the the lineage of the element also*/
		.tree li a:hover, .tree li a:hover~ul li a {
			background: #ccc; color: #000; border: 1px solid #94a0b4;
		}
		/*Connector styles on hover*/
		.tree li a:hover~ul li::after, 
		.tree li a:hover~ul li::before, 
		.tree li a:hover~ul::before, 
		.tree li a:hover~ul ul::before
		{
			border-color: #94a0b4;
		}
	</style>
	<div class="tree" style="padding-right: 10px;" >
		Hierarquia da Configuração de um Teste
		<ul>
			<li>
				<a href="#">PC</a>
			</li>
		</ul>
	</div>
]===])
	file:close()
end

function createSimpleFile(date)
	boo = io.open("boo.html","w")
	boo:write("<meta http-equiv='refresh' content='1'><style>body{font-family: Helvetica Neue,Helvetica,Arial,sans-serif;background-color: #ffffff;}\ntable, td, th {text-align: center;}table {width: 80%;max-width: 800px;}\nh4{text-align:center;font-size:115%;}\nth{background-color: #4462ee;color: #ffffff;height: 25px;}\ntd{background-color: #E3E3E3;}\n#logopuc{float:left;}\n#logodi{float:right;}\n#header{margin-left: auto; margin-right: auto; text-align: center; max-width: 800px; width: 80%}\n#htd{background-color: #ffffff;}\n#all{margin-left: auto; margin-right: auto; background-color: #ffffff; height: 100%; width: 80%;max-width: 900px;}\n#wrn{background-color: #FF9393;}\n</style><br/><div align='center'><p>"..date.."</p></div><div><table align='center'><tr><th>ID</th><th>PAI</th><th>Seq ["..maxseq.."]</th><th>Seq ["..(maxseq-1).."]</th><th>Seq ["..(maxseq-2).."]</th></tr>\n")
	for id,parent in pairs(parents) do
		boo:write("<tr><td id="..field[id]..">"..id.."</td><td id="..field[id]..">"..parent.."</td>")
		for i=0,2 do
			boo:write("<td id="..field[id]..">"..(data[id][maxseq-i] or '-').."</td>")
		end
		boo:write("</tr>")
	end
	boo:write("</table></div>")
	boo:close()
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

		conn:settimeout(timeout)

		conn:register [[ 
		  nx_struct msg_serial [150] { 
			nx_uint16_t	nodeId;
			nx_uint16_t seq_CTP;
			nx_uint8_t  id;
			nx_uint8_t	xxx[1];
			nx_uint8_t  seq;
			nx_uint8_t  www[2];
			nx_uint16_t	temp;
			nx_uint16_t parent;
			nx_uint16_t zzz[2];
		  }; 
		]]

		conn:register [[ 
		  nx_struct msg_serial [145] { 
			nx_uint8_t  id;			
			nx_uint16_t	source;
			nx_uint16_t	target;
			nx_uint8_t replies;
			nx_uint8_t seq;
			nx_uint8_t x8[2];
			nx_uint16_t temp;
			nx_uint16_t nodeId;
			nx_uint16_t parent;
			nx_uint16_t nodeSeq;
		  }; 
		]]
		print("NODE\t TEMP \t PARENT");
	--	createFile()
		parents= {}
		data= {}
		field= {}  -- table field
		danger= {}
		maxseq= 0
		while (conn) do

			local stat, msg, emsg = pcall(function() return conn:receive() end) 
			if stat then
				if msg then
					local date = os.date("%d/%m/%y %X")	
					print(msg.id.."--ID")
					if not data[msg.nodeId] then
						data[msg.nodeId] = {}
						field[msg.nodeId] = 'std'
					end
					if msg.id == 2 then
						data[msg.nodeId][msg.seq]= msg.temp
						parents[msg.nodeId] = msg.parent
						if msg.seq > maxseq then
							maxseq= msg.seq
						end
					end
					if msg.id == 5 then
						field[msg.nodeId] = 'wrn'
						table.insert(data[msg.nodeId],msg.temp)
						if not danger[msg.nodeId] then
							danger[msg.nodeId]= {}
						end
						danger[msg.nodeId]= msg.temp
						print("WRN!!!")
					end
					--print("Node"..msg.nodeId,msg.yyy,msg.parent,msg.zzz[0],msg.zzz[1])
					print(msg.nodeId,msg.temp,msg.parent,date)
					createSimpleFile(date)
				else
					if emsg == "closed" then
						print("\nConnection closed!")
						break 
					elseif emsg == "timeout" then
						--checaPeriodo()
						--print(".") --print("timeout")
					else
						print(emsg)	
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
