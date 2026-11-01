module spi_baud_gen(pclk,preset_n,spi_mode,spiswai,sppr,spr,cpol,cpha,ss,
                    sclk,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,baud_rate_divisor);

input pclk,preset_n,spiswai,cpol,cpha,ss;
input [2:0]sppr,spr;
input [1:0]spi_mode;

output reg sclk,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg;
output [11:0]baud_rate_divisor;

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
        if((!ss)&&((spi_mode==2'b00)||((spi_mode==2'b01)&&(!spiswai))))
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
        if((!ss)&&((spi_mode==2'b00)||((spi_mode==2'b01)&&(!spiswai))))
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
endmodule



