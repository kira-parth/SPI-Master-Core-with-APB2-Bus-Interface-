module apb_slave_interface_tb();

reg pclk,preset_n,pwrite,psel,penable,ss,receive_data,tip;
reg [2:0]paddr;
reg [7:0]pwdata,data_miso;                        
									
wire mstr,cpol,cpha,lsbfe,spiswai,pready,pslverr;
wire send_data,spi_interrupt_request;								
wire [7:0]prdata;
wire [7:0]data_mosi;						
wire [2:0]sppr,spr;					
wire [1:0]spi_mode;										
									
									
apb_slave_interface dut(pclk,preset_n,paddr,pwrite,psel,penable,pwdata,ss,data_miso,receive_data,tip,
                           prdata,mstr,cpol,cpha,lsbfe,spiswai,sppr,spr,spi_interrupt_request,
									pready,pslverr,send_data,data_mosi,spi_mode);									
									
									
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
	ss=1'b1;
	paddr=3'b000;
	receive_data=1'b0;
	data_miso=8'h00;
	pwdata=8'h00;
	pwrite=1'b0;
	psel=1'b0;
	penable=1'b0;
	tip=1'b0;
 end
endtask
									
									
task write(input [2:0]address,input [7:0]data);								
 begin
      @(negedge pclk)
		psel=1'b1;
      penable=1'b0;
		pwrite=1'b1;
      pwdata=data;
      paddr=address;		
		@(negedge pclk) 
		penable=1'b1;	
	   @(negedge pclk)
		psel=1'b0;
      penable=1'b0;	
																		
 end
 endtask 
 
 task read(input [2:0]address);								
 begin
      @(negedge pclk)
      psel=1'b1;
      penable=1'b0; 
		pwrite=1'b0;      
      paddr=address;		
	   @(negedge pclk) 
		penable=1'b1;						
		@(negedge pclk) 
		psel=1'b0;
      penable=1'b0;																	
 end
 endtask 
 
 task spidr_spi_write(input [7:0]slave_data);
   begin
   @(negedge pclk)
    pwrite=1'b0;
	 data_miso=slave_data;	 
	 receive_data=1'b1;
    @(negedge pclk)
	 receive_data=1'b0;
   end
  endtask
  
 initial
  begin
    initialize;
	 #10 reset;
	 write(3'b000,8'h54);  //0101 0100
	 write(3'b001,8'hf0);	//0001 0000  
	 write(3'b010,8'h12);	//0001 0010
	 write(3'b101,8'h59);	
	 read(3'b000);	
	 read(3'b001);
	 read(3'b010);
	 read(3'b011);
	 spidr_spi_write(8'h95);
	 #20 
	 read(3'b101); 
	 $finish;
	 
  end
									
endmodule