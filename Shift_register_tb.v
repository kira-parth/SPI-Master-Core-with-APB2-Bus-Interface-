`timescale 1ns/1ns
module shift_register_tb();

reg pclk,preset_n,ss,send_data,lsbfe,cpha,cpol,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,
    miso,receive_data;
reg [7:0]data_mosi;

wire mosi;
wire [7:0]data_miso;

shift_register dut(pclk,preset_n,ss,send_data,lsbfe,cpha,cpol,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,data_mosi,miso,receive_data,mosi,data_miso);

// variables of baud rate generator
reg spiswai;
reg [2:0]sppr,spr;
reg [1:0]spi_mode;
reg sclk;
wire [11:0]baud_rate_divisor;
wire pre_sclk;
reg [11:0]count;

//baud_rate_divisor
assign baud_rate_divisor=(sppr+1)*2**(spr+1);

// initial value of sclk
assign pre_sclk = (cpol==1)?1'b1:1'b0;

//count logic for sclk

always@(posedge pclk or negedge preset_n)
begin 
    if(!preset_n)
       count<=12'd0;
    else 
      begin
        if((spi_mode==2'b00)||((spi_mode==2'b01)&&(!spiswai))&&(!ss))
          begin 
            if(count==(baud_rate_divisor/2)-1)
              count<=12'd0;
             else
              count<=count+1;
          end               
      end
end

//sclk logic 

always@(posedge pclk or negedge preset_n)
begin 
    if(!preset_n)
       sclk<= pre_sclk;
    else 
      begin
        if((spi_mode==2'b00)||((spi_mode==2'b01)&&(!spiswai))&&(!ss))
          begin 
            if(count==(baud_rate_divisor/2)-1)
              sclk<= ~sclk;
             else
               sclk<= sclk;
          end               
      end
end


//receive flags logic
always@(posedge pclk or negedge preset_n)
begin 
    if(!preset_n)
     begin
       miso_receive_pos<=1'b0;
       miso_receive_neg<=1'b0;
     end
    else 
      begin
          if((cpol&&cpha)||(!cpol&&!cpha))
           begin
             if(!sclk)
               begin
                if(count==(baud_rate_divisor/2)-1) 
                    miso_receive_pos<=1'b1;
                else
                    miso_receive_pos<=1'b0;
               end
             else
                    miso_receive_pos<=1'b0;

           end
          else if((!cpol&&cpha)||(cpol&&!cpha))
           begin
             if(sclk)
               begin
                if(count==(baud_rate_divisor/2)-1) 
                    miso_receive_neg<=1'b1;
                else
                    miso_receive_neg<=1'b0;
               end
             else
                    miso_receive_neg<=1'b0;
  
           end        
      end
end


//send flags logic
always@(posedge pclk or negedge preset_n)
begin 
    if(!preset_n)
     begin
       mosi_send_pos<=1'b0;
       mosi_send_neg<=1'b0;
     end
    else 
      begin
          if((!cpol&&cpha)||(cpol&&!cpha))
           begin
             if(sclk)
               begin
                if(count==(baud_rate_divisor/2)-2'b10) 
                    mosi_send_pos<=1'b1;
                else
                    mosi_send_pos<=1'b0;
               end
             else 
                    mosi_send_pos<=1'b0;

           end
          else if((cpol&&cpha)||(!cpol&&!cpha))
           begin
             if(!sclk)
               begin
                if(count==(baud_rate_divisor/2)-2'b10) 
                    mosi_send_neg<=1'b1;
                else
                    mosi_send_neg<=1'b0;
               end
              else
                   mosi_send_neg<=1'b0;
           end        
      end
end

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
   spiswai=1'b0;
   pclk=1'b0;
	preset_n=1'b0;
	cpol=1'b0;
	cpha=1'b1;
	ss=1'b1;
	lsbfe=1'b0;
	send_data=1'b0;
	receive_data=1'b0;
	data_mosi=8'h00;
	miso_receive_pos=1'b0;
	miso_receive_neg=1'b0;
	mosi_send_pos=1'b0;
	mosi_send_neg=1'b0;
	miso=1'b0;
	sppr=3'b000;
	spr=3'b001;
	spi_mode=2'b00;
end
endtask

task send_to_slave(input [7:0]i);
 begin
   data_mosi=i;
	#10 send_data=1'b1;
	#10 send_data=1'b0;
   ss=1'b0;
	#640; //20*4*8
	ss=1'b1;
	#20;
 end
endtask

task receive_from_slave;
begin
  ss=1'b0;     
  @(negedge sclk)
  miso=1;
  @(negedge sclk)
  miso=0;
  @(negedge sclk)
  miso=1;
  @(negedge sclk)
  miso=0;
  @(negedge sclk)
  miso=1; 
  @(negedge sclk)
  miso=1;
  @(negedge sclk)
  miso=0;
  @(negedge sclk)
  miso=1;        
  @(negedge sclk) //data_Received : 1010 1101 
  receive_data=1;
  #20 receive_data=0;
  ss=1'b1;
  #20;
end
endtask

initial
	begin
		initialize;
		#10;
		reset;
		send_to_slave(8'h56);		
		receive_from_slave;
		$finish;
	end
endmodule


