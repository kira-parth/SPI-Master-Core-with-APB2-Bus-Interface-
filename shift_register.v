module shift_register(pclk,preset_n,ss,send_data,lsbfe,cpha,cpol,
                      miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,
							 data_mosi,miso,receive_data,mosi,data_miso);

input pclk,preset_n,ss,send_data,lsbfe,cpha,cpol,miso_receive_pos,miso_receive_neg,mosi_send_pos,mosi_send_neg,
      miso,receive_data;
input [7:0]data_mosi;

output reg mosi;
output [7:0]data_miso;

reg [7:0]rx_shift_register, tx_shift_register;
reg [2:0]rx_up_counter,rx_down_counter,tx_up_counter,tx_down_counter;

// rx shift register -> spidr
assign data_miso = (receive_data==1'b1)?rx_shift_register:8'h00;

// spidr -> tx shift register spidr
always@(posedge pclk, negedge preset_n)
begin
  if(!preset_n)
    tx_shift_register<=8'h00;
  else if(send_data)
    tx_shift_register<=data_mosi;
  else
    tx_shift_register<=tx_shift_register;
end

//receive counters logic and receive data from slave logic

always@(posedge pclk, negedge preset_n)
begin
  if(!preset_n)
    begin
	   rx_up_counter <= 3'b000;
		rx_down_counter <= 3'b111;
		rx_shift_register <= 8'h00;
	 end
  else if(!ss)
   begin
	   if((!cpol&&cpha)||(cpol&&!cpha))
		begin
		  if(lsbfe)
		   begin
			 if(rx_up_counter <= 3'b111)
			   begin
				  if(miso_receive_neg)
				  begin
				    rx_up_counter <= rx_up_counter + 1'b1;
					 rx_shift_register[rx_up_counter]<= miso;
				  end					 
				  else
				   begin
				    rx_up_counter <= rx_up_counter;
					 rx_shift_register[rx_up_counter] <= rx_shift_register[rx_up_counter];
					end
				end
	        else
				  rx_up_counter <= 3'b000;
			end
			else
			begin
			  if(rx_down_counter >= 3'b000)
			    begin
				  if(miso_receive_neg)
				   begin
				    rx_down_counter <= rx_down_counter - 1'b1;
					 rx_shift_register[rx_down_counter]<= miso;
					end
				  else
				   begin
				    rx_down_counter <= rx_down_counter;
					 rx_shift_register[rx_down_counter]<= rx_shift_register[rx_down_counter];
				   end
				end			
			  else
				  rx_down_counter <= 3'b111;
			end		  
		end
	else if((!cpol&&!cpha)||(cpol&&cpha))
	begin 
	if(lsbfe)
		   begin
			 if(rx_up_counter <= 3'b111)
			   begin
				  if(miso_receive_pos)
				  begin
				    rx_up_counter <= rx_up_counter + 1'b1;
					 rx_shift_register[rx_up_counter]<= miso;
				  end
				  else
				   begin
				    rx_up_counter <= rx_up_counter;
					 rx_shift_register[rx_up_counter] <= rx_shift_register[rx_up_counter];
					end
				end
	        else
				  rx_up_counter <= 3'b000;
			end
			else
			begin
			  if(rx_down_counter >= 3'b000)
			    begin
				  if(miso_receive_pos)
				  begin
				    rx_down_counter <= rx_down_counter - 1'b1;
					 rx_shift_register[rx_down_counter]<= miso;
				  end
				  else
				   begin
				    rx_down_counter <= rx_down_counter;
					 rx_shift_register[rx_down_counter]<= rx_shift_register[rx_down_counter];
					end
				end			
			  else
				  rx_down_counter <= 3'b111;
			end		 	
	end		
end
	 
  else
   begin
     rx_up_counter <= rx_up_counter;
	  rx_down_counter <=rx_down_counter;
	  rx_shift_register<= rx_shift_register;
   end	 	 
end


//send counters logic and send data to slave logic

always@(posedge pclk, negedge preset_n)
begin
  if(!preset_n)
    begin
	   tx_up_counter <= 3'b000;
		tx_down_counter <= 3'b111;
		mosi<= 1'b0;
	 end
  else if(!ss)
   begin
	   if((!cpol&&cpha)||(cpol&&!cpha))
		begin
		  if(lsbfe)
		   begin
			 if(tx_up_counter <= 3'b111)
			   begin
				  if(mosi_send_pos)
				  begin
				    tx_up_counter <= tx_up_counter + 1'b1;
					 mosi <= tx_shift_register[tx_up_counter];
				  end					 
				  else
				   begin
				    tx_up_counter <= tx_up_counter;
					 mosi <= mosi;
					end
				end
	        else
				  tx_up_counter <= 3'b000;
			end
			else
			begin
			  if(tx_down_counter >= 3'b000)
			    begin
				  if(mosi_send_pos)
				   begin
				    tx_down_counter <= tx_down_counter - 1'b1;
					 mosi <= tx_shift_register[tx_down_counter];
					end
				  else
				   begin
				    tx_down_counter <= tx_down_counter;
					 mosi <= mosi;
				   end
				end			
			  else
				  tx_down_counter <= 3'b111;
			end		  
		end
	else if((!cpol&&!cpha)||(cpol&&cpha))
	begin 
	if(lsbfe)
		   begin
			 if(tx_up_counter <= 3'b111)
			   begin
				  if(mosi_send_neg)
				  begin
				    tx_up_counter <= tx_up_counter + 1'b1;
					 mosi <= tx_shift_register[tx_up_counter];
				  end
				  else
				   begin
				    tx_up_counter <= tx_up_counter;
					 mosi <=mosi;
					end
				end
	        else
				  tx_up_counter <= 3'b000;
			end
			else
			begin
			  if(tx_down_counter >= 3'b000)
			    begin
				  if(mosi_send_neg)
				  begin
				    tx_down_counter <= tx_down_counter - 1'b1;
					 mosi <= tx_shift_register[tx_down_counter];
				  end
				  else
				   begin
				    tx_down_counter <= tx_down_counter;
					 mosi <= mosi;
					end
				end			
			  else
				  tx_down_counter <= 3'b111;
			end		 	
	end		
end
	 
  else
   begin
     tx_up_counter <= tx_up_counter;
	  tx_down_counter <=tx_down_counter;
	  mosi <= mosi;
   end	 	 
end

endmodule