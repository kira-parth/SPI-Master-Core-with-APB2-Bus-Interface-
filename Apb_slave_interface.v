module apb_slave_interface(pclk,preset_n,paddr,pwrite,psel,penable,pwdata,ss,data_miso,receive_data,tip,
                           prdata,mstr,cpol,cpha,lsbfe,spiswai,sppr,spr,spi_interrupt_request,
									pready,pslverr,send_data,data_mosi,spi_mode);
									
									
input pclk,preset_n,pwrite,psel,penable,ss,receive_data,tip;
input [2:0]paddr;
input [7:0]pwdata,data_miso;

output mstr,cpol,cpha,lsbfe,spiswai,pready,pslverr;
output reg send_data,spi_interrupt_request;								
output reg [7:0]prdata;
output reg [7:0]data_mosi;						
output [2:0]sppr,spr;					
output reg [1:0]spi_mode;						

wire read_en,write_en;

//Registers declaration
reg [7:0]spicr1,spicr2,spibr,spidr;
wire [7:0]spisr;
wire spif,sptef,modf,spie,spe,sptie,modfen,ssoe;

//states of APB									
parameter idle=3'b100,
          setup=3'b101,
			 enable=3'b110;
			 
//modes of SPI
parameter spi_run=2'b00,
          spi_wait=2'b01,
			 spi_stop=2'b10;
			 
reg [1:0]spi_ns;								
reg [2:0]apb_ps,apb_ns;

//APB-FSM
always@(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
     apb_ps<=idle;
  else
     apb_ps<=apb_ns;
end

always@(psel,penable,apb_ps)
begin
  case(apb_ps)
  idle : begin
          if(psel&&!penable)
			    apb_ns=setup;
			 else
			    apb_ns=idle;
          end
  setup : begin
          if(psel&&penable)
			    apb_ns=enable;
			 else if(psel&&!penable)
			    apb_ns=setup;
			 else 
			    apb_ns= idle;			    
          end
 enable : begin
          if(!psel&&!penable)
			    apb_ns=idle;
			 else if(psel&&!penable)
			    apb_ns=setup;
			 else if(psel&&penable)
			    apb_ns= enable;		
          else 
			    apb_ns= idle;					 
          end
  default : apb_ns=idle;
  endcase									
end									

//SPI-FSM									
always@(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
     spi_mode<=spi_run;
  else
     spi_mode<=spi_ns;
end

always@(spe,spiswai,spi_mode)
begin
  case(spi_mode)
  spi_run : begin
            if(!spe)
            spi_ns=spi_wait;
			  else
            spi_ns=spi_run;
			  end
  spi_wait: begin
            if(!spe&&!spiswai)
            spi_ns=spi_wait;
			  else if(!spe&&spiswai)
            spi_ns=spi_stop;
			  else 
			   spi_ns=spi_run;
			  end
  spi_stop: begin
            if(!spe&&!spiswai)
            spi_ns=spi_wait;
			  else if(!spe&&spiswai)
            spi_ns=spi_stop;
			  else 
			   spi_ns=spi_run;
			  end
  default : spi_ns=spi_run;
  endcase									
end

assign read_en=(!pwrite&&(apb_ps==enable))?1'b1:1'b0;

assign write_en=(pwrite&&(apb_ps==enable))?1'b1:1'b0;

assign pslverr=(apb_ps==enable)?tip:1'b0;

assign pready=(apb_ps==enable)?1'b1:1'b0;

//write logic for spicr1 
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    spicr1<= 8'h04;
  else if(write_en)
   begin
    if(paddr==3'b000)
	  spicr1<=pwdata;
    else
	  spicr1<=spicr1; 
   end
  else
     spicr1<= spicr1; 
end

//write logic for spicr2
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    spicr2<= 8'h00;
  else if(write_en)
   begin
    if(paddr==3'b001)
	  spicr2<=(pwdata&8'h1B);
    else
	  spicr2<=spicr2; 
   end
  else
     spicr2<= spicr2; 
end

//write logic for spibr
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    spibr<= 8'h00;
  else if(write_en)
   begin
    if(paddr==3'b010)
	  spibr<=(pwdata&8'h77);
    else
	  spibr<=spibr; 
   end
  else
     spibr<= spibr; 
end

//write logic for spidr
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    spidr<= 8'h00;
  else if(write_en)
   begin
    if(paddr==3'b101)
	  spidr<=pwdata;
    else
	  spidr<=spidr; 
   end
  else if((spidr==pwdata)&&(spidr!=data_miso)&&((spi_mode==spi_run)||(spi_mode==spi_wait)))
		   spidr<= 8'h00;
  else
	 begin
		if(((spi_mode==spi_run)||(spi_mode==spi_wait))&&receive_data)
		  spidr<= data_miso;
		else
		  spidr<=spidr; 
	 end	  
end

//Read logic for spisr
assign spisr=(preset_n==0)?8'h20:({spif,1'b0,sptef,modf,4'b0000});

//send_data logic
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    send_data<= 1'b0;
  else if(write_en)
    send_data<= 1'b0;
  else if((spidr==pwdata)&&(spidr!=data_miso)&&((spi_mode==spi_run)||(spi_mode==spi_wait)))
		 send_data<= 1'b1;				
  else
    send_data<= 1'b0;
end

//data_mosi logic (spidr->tx_shift_register)
always @(posedge pclk,negedge preset_n)
begin
  if(!preset_n)
    data_mosi<= 8'h00;
  else if((spidr==pwdata)&&(spidr!=data_miso)&&((spi_mode==spi_run)||(spi_mode==spi_wait)))
	 data_mosi<= spidr;
  else
    data_mosi<= data_mosi;
	 
end

//spicr1 bits
assign spie= spicr1[7];
assign spe= spicr1[6];
assign sptie= spicr1[5];
assign mstr= spicr1[4];
assign cpol= spicr1[3];
assign cpha= spicr1[2];
assign ssoe= spicr1[1];
assign lsbfe= spicr1[0];

//spicr2 bits
assign modfen= spicr2[4];
assign spiswai= spicr2[1];

//spibr bits
assign sppr= spibr[6:4];
assign spr= spibr[2:0];

//spisr flags logic
assign modf = ((!ss)&&(mstr)&&(modfen)&&(!ssoe));
assign spif = (spidr!=8'h00)?1'b1:1'b0;
assign sptef = (spidr==8'h00)?1'b1:1'b0;

//prdata logic
always @(spicr1,spicr2,spibr,spisr,spidr,paddr,read_en)
begin
   if(read_en)
	  begin
	    case(paddr)
		 3'b000: prdata=spicr1;
	     3'b001: prdata=spicr2;
		 3'b010: prdata=spibr;
		 3'b011: prdata=spisr;
		 3'b101: prdata=spidr;
		 default : prdata=8'h00;
	   endcase
	  end
    else
	  prdata= 8'h00;  
end

//spi interrupt request logic

always @(spie,sptie,spif,modf,sptef)
begin
  if(!spie&&!sptie)
     spi_interrupt_request=1'b0;
  else
     begin
	    if(spie&&!sptie)
			  spi_interrupt_request=(spif||modf);						
       else
		   begin
			  if(!spie&&sptie)
			     spi_interrupt_request= sptef;
			  else
			     spi_interrupt_request= (spif||modf||sptef);
			end	 
	 end
    
end	
							
endmodule								