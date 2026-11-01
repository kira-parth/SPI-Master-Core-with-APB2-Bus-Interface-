`timescale 1ns/1ns
module spi_baud_gen_tb();

reg pclk,preset_n,spiswai,cpol,cpha,ss;
reg [2:0]sppr,spr;
reg [1:0]spi_mode;

wire sclk,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg;
wire [11:0]baud_rate_divisor;

spi_baud_gen dut(pclk,preset_n,spi_mode,spiswai,sppr,spr,cpol,cpha,ss,sclk,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,baud_rate_divisor);

task initialize;
begin

   pclk=1'b0;
	preset_n=1'b0;
	spiswai=1'b0;
	cpol=1'b0;
	cpha=1'b1;
	ss=1'b1;
	sppr=3'b000;
	spr=3'b000;
	spi_mode=2'b00;
	
end
endtask

initial
 forever #10 pclk=~pclk;
 
task reset;
 begin
   preset_n=0;
	#10 preset_n=1;
 end
 endtask
 
 task inputs(input [2:0]i,j,input a,b);
 begin
   spiswai=1'b0;
	cpol=a;
	cpha=b;
	ss=1'b0;
	sppr=i;
	spr=j;
	spi_mode=2'b00;
 end
 endtask
 
 initial
 begin
   initialize;
	#10 reset;
	#10 inputs(3'd1,3'd1,1'b1,1'b1); //divide by 8
	#500 inputs(3'd0,3'd1,1'b1,1'b1); //divide by 4
	#500 $finish;
 end
endmodule