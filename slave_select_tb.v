`timescale 1ns/1ns
module slave_select_tb();

reg pclk,preset_n,mstr,spiswai,send_data;
reg [1:0]spi_mode;
reg [11:0]baud_rate_divisor;

wire receive_data,ss;
wire tip;

slave_control_select dut(pclk,preset_n,mstr,spiswai,spi_mode,send_data,baud_rate_divisor,receive_data,ss,tip);

initial
 forever #10 pclk=~pclk;
 
task reset;
 begin
   preset_n=0;
	#10 preset_n=1;
 end
 endtask									
									
task initialize;
 begin
   pclk=1'b0;
	preset_n=1'b0;
	mstr=1'b1;
	spiswai=1'b0;
	spi_mode=2'b01;
	send_data=1'b0;
	baud_rate_divisor=12'd4;
 end
endtask


initial
 begin
   initialize;
	#10 reset;
	send_data=1'b1;
	#20 send_data=1'b0;
   #700 $finish;
 end
endmodule