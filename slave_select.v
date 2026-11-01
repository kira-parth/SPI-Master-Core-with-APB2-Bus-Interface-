module slave_control_select(pclk,preset_n,mstr,spiswai,spi_mode,send_data,baud_rate_divisor,receive_data,ss,tip);

input pclk,preset_n,mstr,spiswai,send_data;
input [1:0]spi_mode;
input [11:0]baud_rate_divisor;

output reg receive_data,ss;
output tip;

reg [15:0]count;
wire [15:0]target;
reg rcv;

parameter spi_run=2'b00,
          spi_wait=2'b01, 
          spi_stop=2'b10;

//target (time required to transfer or receive data)
assign target= baud_rate_divisor*4'd8; //here 20 is the pclock period

//transmission in progress(tip)
assign tip=(!ss);

always@(posedge pclk or negedge preset_n)
begin
  if(!preset_n)
  begin
    count<=16'hffff;
	 ss<=1'b1;
	 rcv<=1'b0;
  end
  else if((mstr)&&((spi_mode==spi_run)||((spi_mode==spi_wait)&&(!spiswai))))
    begin
	    if(send_data)
		 begin
		   count<=16'h0000;
			ss<=1'b0;
			rcv<=1'b0;
		 end
	    else if(count<(target-1'b1))
		  begin
			 count<= count+1'b1;
			 ss<=1'b0;
			 rcv<=1'b0;
			end
		 else if (count==(target-1'b1))
			begin
			 count<=16'hffff;
			 ss<=1'b1;
			 rcv<=1'b1;
			end					 
		 else
			begin
			 count<=16'hffff;
			 ss<=1'b1;
			 rcv<=1'b0;
			end
		end
  else
  begin
     count<=16'hffff;
	  ss<=1'b1;
	  rcv<=1'b0;
  end
end

always@(posedge pclk or negedge preset_n)
begin
  if(!preset_n)
	receive_data<=1'b0;
  else
  receive_data<= rcv;
end

endmodule