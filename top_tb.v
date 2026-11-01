`timescale 1ns/1ns
module top_tb();

reg pclk,preset_n,pwrite,penable,psel,miso;
reg [2:0]paddr;
reg [7:0]pwdata;

wire pready,pslverr,ss,sclk,mosi,spi_interrupt_request;
wire [7:0]prdata;

Apb_slave_spi_master dut(pclk,preset_n,paddr,pwrite,penable,psel,pwdata,prdata,pready,pslverr,
                            ss,sclk,mosi,miso,spi_interrupt_request);	 
									 
initial
 forever #10 pclk=~pclk;
 
task reset;
 begin
   @(negedge pclk)
   preset_n=0;
	@(negedge pclk)
	preset_n=1;
 end
 endtask	

task initialize;
 begin
  pclk=1'b0;
  preset_n=1'b1;
  pwrite=1'b0;
  penable=1'b0;
  psel=1'b0;
  miso=1'b0;
  paddr=3'b000;
  pwdata=8'h00; 
 end
 endtask


task write(input [2:0]address,input [7:0]data);
 begin
  @(negedge pclk)
  pwrite=1'b1;
  psel=1'b1;
  penable=1'b0;
  paddr=address;
  pwdata=data;
  @(negedge pclk)
  psel=1'b1;
  penable=1'b1;
  @(negedge pclk)
  psel=1'b0;
  penable=1'b0;
  
 end
 endtask

task read(input [2:0]address);
 begin
  @(negedge pclk)
  pwrite=1'b0;
  psel=1'b1;
  penable=1'b0;
  paddr=address;
  @(negedge pclk)
  psel=1'b1;
  penable=1'b1;
  @(negedge pclk)
  psel=1'b0;
  penable=1'b0;
 end
 endtask

task slave_data;
 begin
		@(negedge sclk)
		miso=1'b1;
		@(negedge sclk)
		miso=1'b0;
		@(negedge sclk)
		miso=1'b1;
		@(negedge sclk)
		miso=1'b1;
		@(negedge sclk)
		miso=1'b1;
		@(negedge sclk)
		miso=1'b0;
		@(negedge sclk)
		miso=1'b1;
		@(negedge sclk)  //ba
		miso=1'b0;		
 end
 endtask

initial
 begin
  initialize;
  #20;
  reset; 
  write(3'b000,8'h54);
  write(3'b001,8'hf0);	//0001 0000  
  write(3'b010,8'h01);	//0000 0001 (/4)
  write(3'b101,8'h99);	
  slave_data;
  read(3'b000);	
  read(3'b001);
  read(3'b010);
  read(3'b011);
  read(3'b101);
  #100 $finish;
 end


endmodule